//
//  BatchCalculator.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation

// MARK: - Component (a single ingredient line item)

enum ActivationCategory: String {
    case flavorOil    = "Flavor Oils"
    case terpene      = "Terpenes"
    case color        = "Colors"
    case preservative = "Preservatives"
}

struct BatchComponent: Identifiable {
    let id = UUID()
    let label: String
    let mass_g: Double
    let volume_mL: Double
    let displayUnit: String   // "g", "ml", or "µL"
    var activationCategory: ActivationCategory? = nil
}

// MARK: - Mix Group

struct MixGroup: Identifiable {
    let id = UUID()
    let name: String
    let components: [BatchComponent]

    var totalMass_g: Double   { components.reduce(0) { $0 + $1.mass_g } }
    var totalVolume_mL: Double { components.reduce(0) { $0 + $1.volume_mL } }
}

// MARK: - Full Batch Result

struct BatchResult {
    let vBase: Double   // volume before overage
    let vMix: Double    // volume after overage
    let activationMix: MixGroup
    let gelatinMix: MixGroup
    let sugarMix: MixGroup

    var totalMass_g: Double {
        activationMix.totalMass_g + gelatinMix.totalMass_g + sugarMix.totalMass_g
    }
    var totalVolume_mL: Double {
        activationMix.totalVolume_mL + gelatinMix.totalVolume_mL + sugarMix.totalVolume_mL
    }
}

// MARK: - Calculator

struct BatchCalculator {

    static func calculate(
        viewModel: BatchConfigViewModel,
        systemConfig: SystemConfig
    ) -> BatchResult {

        // ── 1. Total target volume ───────────────────────────────────────────
        let spec  = systemConfig.spec(for: viewModel.selectedShape)
        let vBase = Double(spec.count * viewModel.trayCount) * spec.volume_ml
        let vMix  = vBase * viewModel.overageFactor

        // ── 2. Activation Mix ────────────────────────────────────────────────
        // All activation components are allocated as a fraction of vMix.
        // Masses are derived from volume × density.
        // Activation water is the residual: vActivation - sum(all other activation volumes).
        var activationComponents: [BatchComponent] = []

        // 2.1 Citric acid: V = %vol × vMix
        let vCitric = (systemConfig.citricAcidPercent / 100.0) * vMix
        let mCitric = vCitric * systemConfig.densityCitricAcid
        activationComponents.append(BatchComponent(
            label: "Citric Acid", mass_g: mCitric, volume_mL: vCitric, displayUnit: "g",
            activationCategory: .preservative
        ))

        // 2.2 Potassium sorbate: V = %vol × vMix
        let vSorbate = (systemConfig.potassiumSorbatePercent / 100.0) * vMix
        let mSorbate = vSorbate * systemConfig.densityPotassiumSorbate
        activationComponents.append(BatchComponent(
            label: "Potassium Sorbate", mass_g: mSorbate, volume_mL: vSorbate, displayUnit: "g",
            activationCategory: .preservative
        ))

        // 2.3 Colors: total color vol from %vol, split by blend
        let vColorTotal = (viewModel.colorVolumePercent / 100.0) * vMix
        let sortedColors = Array(viewModel.selectedColors.keys).sorted { $0.rawValue < $1.rawValue }
        for color in sortedColors {
            let fraction = (viewModel.selectedColors[color] ?? 0) / 100.0
            let vColor   = vColorTotal * fraction
            let mColor   = vColor * systemConfig.densityFoodColoring
            activationComponents.append(BatchComponent(
                label: "\(color.rawValue) Color", mass_g: mColor, volume_mL: vColor, displayUnit: "ml",
                activationCategory: .color
            ))
        }

        // 2.4 Flavor oils: total oil vol from %vol, split by blend
        let vOilTotal = (viewModel.flavorOilVolumePercent / 100.0) * vMix
        let oils = Array(viewModel.selectedFlavors.keys.filter {
            if case .oil = $0 { return true }; return false
        })
        for oil in oils {
            let fraction = (viewModel.selectedFlavors[oil] ?? 0) / 100.0
            let vOil     = vOilTotal * fraction
            let mOil     = vOil * systemConfig.densityFlavorOil
            activationComponents.append(BatchComponent(
                label: "\(oil.displayName) Oil", mass_g: mOil, volume_mL: vOil, displayUnit: "ml",
                activationCategory: .flavorOil
            ))
        }

        // 2.5 Terpenes: from PPM, split by blend
        let vTerpTotal_mL = (viewModel.terpeneVolumePPM / 1_000_000.0) * vMix
        let terpenes = Array(viewModel.selectedFlavors.keys.filter {
            if case .terpene = $0 { return true }; return false
        })
        for terp in terpenes {
            let fraction = (viewModel.selectedFlavors[terp] ?? 0) / 100.0
            let vTerp    = vTerpTotal_mL * fraction
            let mTerp    = vTerp * systemConfig.densityTerpenes
            activationComponents.append(BatchComponent(
                label: "\(terp.displayName) Terpene", mass_g: mTerp, volume_mL: vTerp, displayUnit: "µL",
                activationCategory: .terpene
            ))
        }

        // 2.6 Activation water — absorbs the remaining volume of the activation budget.
        // Budget = citric%vol + sorbate%vol + color%vol + oil%vol + terpene_ppm (all as fractions of vMix).
        // Water fills whatever is left so the activation mix closes to its budget volume.
        let vActivationBudget = vCitric + vSorbate + vColorTotal + vOilTotal + vTerpTotal_mL
        // Activation water is the residual volume within the activation mix slice.
        // We need to know the activation mix's total slice first.
        // The activation mix doesn't have its own explicit %vol budget — it is whatever
        // citric + sorbate + colors + oils + terps + water sum to. Water is calculated from
        // solubility so the preservatives fully dissolve, and is the physical minimum.
        let waterForCitric  = SubstanceSolubility.citricAcid.minWaterML(toDissolveGrams: mCitric)
        let waterForSorbate = SubstanceSolubility.potassiumSorbate.minWaterML(toDissolveGrams: mSorbate)
        let vActivationWater = waterForCitric + waterForSorbate + viewModel.additionalActiveWater_mL
        let mActivationWater = vActivationWater * systemConfig.densityWater
        activationComponents.append(BatchComponent(
            label: "Activation Water", mass_g: mActivationWater, volume_mL: vActivationWater, displayUnit: "ml",
            activationCategory: .preservative
        ))

        let activationMix = MixGroup(name: "Activation Mix", components: activationComponents)
        let vActivation   = activationMix.totalVolume_mL

        // ── 3. Gelatin Mix ───────────────────────────────────────────────────
        // Gelatin volume = %vol × vMix (theoretical volume fraction).
        // Water mass = mGelatin × φ_gel (physical ratio), volume = mWater / ρ_water.
        // The gelatin mix total volume is vGelatin + vGelatinWater — it is NOT forced to
        // a budget slice; it is fully determined by the gelatin % and hydration ratio.
        var gelatinComponents: [BatchComponent] = []

        let vGelatin      = (viewModel.gelatinPercentage / 100.0) * vMix
        let mGelatin      = vGelatin * systemConfig.densityGelatin
        gelatinComponents.append(BatchComponent(
            label: "Gelatin", mass_g: mGelatin, volume_mL: vGelatin, displayUnit: "g"
        ))

        let phi_gel        = systemConfig.waterToGelatinMassRatio
        let mGelatinWater  = mGelatin * phi_gel
        let vGelatinWater  = mGelatinWater / systemConfig.densityWater
        gelatinComponents.append(BatchComponent(
            label: "Water", mass_g: mGelatinWater, volume_mL: vGelatinWater, displayUnit: "ml"
        ))

        let gelatinMix  = MixGroup(name: "Gelatin Mix", components: gelatinComponents)
        let vGelatinMix = gelatinMix.totalVolume_mL

        // ── 4. Sugar Mix — fills the remaining volume exactly ────────────────
        // vRemaining is the volume left after activation and gelatin.
        // Total sugar mix mass is derived from vRemaining × ρ_mix.
        // Component volumes are back-derived from mass / individual density, then the
        // last component (water) absorbs any floating-point residual so the mix closes
        // exactly to vRemaining.
        var sugarComponents: [BatchComponent] = []

        let vRemaining  = vMix - vActivation - vGelatinMix
        let phi_sugar   = systemConfig.sugarToWaterMassRatio
        let rhoMix      = systemConfig.sugarMixDensity
        let mSugarMix   = vRemaining * rhoMix
        let mSugarWater = mSugarMix / (1.0 + phi_sugar)
        let mSugarTotal = phi_sugar * mSugarWater

        // Split sugar by glucose:granulated ratio
        let gRatio       = systemConfig.glucoseToSugarMassRatio
        let mGlucoseSyrup = mSugarTotal * gRatio / (1.0 + gRatio)
        let mGranulated   = mSugarTotal / (1.0 + gRatio)

        let vGlucoseSyrup = mGlucoseSyrup / systemConfig.densityGlucoseSyrup
        let vGranulated   = mGranulated   / systemConfig.densitySucrose

        // Water volume is the residual so sugar mix closes to vRemaining exactly.
        let vSugarWater = vRemaining - vGlucoseSyrup - vGranulated
        let mSugarWaterClosed = vSugarWater * systemConfig.densityWater

        sugarComponents.append(BatchComponent(
            label: "Glucose Syrup",    mass_g: mGlucoseSyrup,     volume_mL: vGlucoseSyrup,  displayUnit: "g"
        ))
        sugarComponents.append(BatchComponent(
            label: "Granulated Sugar", mass_g: mGranulated,        volume_mL: vGranulated,    displayUnit: "g"
        ))
        sugarComponents.append(BatchComponent(
            label: "Water",            mass_g: mSugarWaterClosed,  volume_mL: vSugarWater,    displayUnit: "g"
        ))

        let sugarMix = MixGroup(name: "Sugar Mix", components: sugarComponents)

        return BatchResult(
            vBase: vBase,
            vMix: vMix,
            activationMix: activationMix,
            gelatinMix: gelatinMix,
            sugarMix: sugarMix
        )
    }
}
