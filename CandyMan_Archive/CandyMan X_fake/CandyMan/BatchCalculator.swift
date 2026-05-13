//
//  BatchCalculator.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation

// MARK: - Component (a single ingredient line item)

/// Categories for classifying activation mix components.
enum ActivationCategory: String {
    case flavorOil    = "Flavor Oils"
    case terpene      = "Terpenes"
    case color        = "Colors"
    case preservative = "Preservatives"
}

/// A single ingredient line item within a mix group.
struct BatchComponent: Identifiable {
    let id = UUID()
    let label: String
    let massGrams: Double
    let volumeML: Double
    let displayUnit: String
    var activationCategory: ActivationCategory?
}

// MARK: - Mix Group

/// A named group of batch components (e.g., "Activation Mix").
struct MixGroup: Identifiable {
    let id = UUID()
    let name: String
    let components: [BatchComponent]

    var totalMassGrams: Double { components.reduce(0) { $0 + $1.massGrams } }
    var totalVolumeML: Double { components.reduce(0) { $0 + $1.volumeML } }
}

// MARK: - Full Batch Result

/// The complete result of a batch calculation.
struct BatchResult {
    let vBase: Double
    let vMix: Double
    let activationMix: MixGroup
    let gelatinMix: MixGroup
    let sugarMix: MixGroup

    var totalMassGrams: Double {
        activationMix.totalMassGrams + gelatinMix.totalMassGrams + sugarMix.totalMassGrams
    }
    var totalVolumeML: Double {
        activationMix.totalVolumeML + gelatinMix.totalVolumeML + sugarMix.totalVolumeML
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
        let vBase = Double(viewModel.totalGummies(using: systemConfig)) * spec.volumeML
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
            label: "Citric Acid", massGrams: mCitric, volumeML: vCitric, displayUnit: "g",
            activationCategory: .preservative
        ))

        // 2.2 Potassium sorbate: V = %vol × vMix
        let vSorbate = (systemConfig.potassiumSorbatePercent / 100.0) * vMix
        let mSorbate = vSorbate * systemConfig.densityPotassiumSorbate
        activationComponents.append(BatchComponent(
            label: "Potassium Sorbate", massGrams: mSorbate, volumeML: vSorbate, displayUnit: "g",
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
                label: "\(color.rawValue) Color", massGrams: mColor, volumeML: vColor, displayUnit: "ml",
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
                label: "\(oil.displayName) Oil", massGrams: mOil, volumeML: vOil, displayUnit: "ml",
                activationCategory: .flavorOil
            ))
        }

        // 2.5 Terpenes: from PPM, split by blend
        let vTerpTotalML = (viewModel.terpeneVolumePPM / 1_000_000.0) * vMix
        let terpenes = Array(viewModel.selectedFlavors.keys.filter {
            if case .terpene = $0 { return true }; return false
        })
        for terp in terpenes {
            let fraction = (viewModel.selectedFlavors[terp] ?? 0) / 100.0
            let vTerp    = vTerpTotalML * fraction
            let mTerp    = vTerp * systemConfig.densityTerpenes
            activationComponents.append(BatchComponent(
                label: "\(terp.displayName) Terpene", massGrams: mTerp, volumeML: vTerp, displayUnit: "µL",
                activationCategory: .terpene
            ))
        }

        // 2.6 Activation water — absorbs the remaining volume of the activation budget.
        // Budget = citric%vol + sorbate%vol + color%vol + oil%vol + terpene_ppm (all as fractions of vMix).
        // Water fills whatever is left so the activation mix closes to its budget volume.
        let vActivationBudget = vCitric + vSorbate + vColorTotal + vOilTotal + vTerpTotalML
        // Activation water is the residual volume within the activation mix slice.
        // We need to know the activation mix's total slice first.
        // The activation mix doesn't have its own explicit %vol budget — it is whatever
        // citric + sorbate + colors + oils + terps + water sum to. Water is calculated from
        // solubility so the preservatives fully dissolve, and is the physical minimum.
        let waterForCitric  = SubstanceSolubility.citricAcid.minWaterML(toDissolveGrams: mCitric)
        let waterForSorbate = SubstanceSolubility.potassiumSorbate.minWaterML(toDissolveGrams: mSorbate)
        let vActivationWater = waterForCitric + waterForSorbate + viewModel.additionalActiveWaterML
        let mActivationWater = vActivationWater * systemConfig.densityWater
        activationComponents.append(BatchComponent(
            label: "Activation Water", massGrams: mActivationWater, volumeML: vActivationWater, displayUnit: "ml",
            activationCategory: .preservative
        ))

        let activationMix = MixGroup(name: "Activation Mix", components: activationComponents)
        let vActivation   = activationMix.totalVolumeML

        // ── 3. Gelatin Mix ───────────────────────────────────────────────────
        // Gelatin volume = %vol × vMix (theoretical volume fraction).
        // Water mass = mGelatin × φ_gel (physical ratio), volume = mWater / ρ_water.
        // The gelatin mix total volume is vGelatin + vGelatinWater — it is NOT forced to
        // a budget slice; it is fully determined by the gelatin % and hydration ratio.
        var gelatinComponents: [BatchComponent] = []

        let vGelatin      = (viewModel.gelatinPercentage / 100.0) * vMix
        let mGelatin      = vGelatin * systemConfig.densityGelatin
        gelatinComponents.append(BatchComponent(
            label: "Gelatin", massGrams: mGelatin, volumeML: vGelatin, displayUnit: "g"
        ))

        let phiGel        = systemConfig.waterToGelatinMassRatio
        let mGelatinWater  = mGelatin * phiGel
        let vGelatinWater  = mGelatinWater / systemConfig.densityWater
        gelatinComponents.append(BatchComponent(
            label: "Water", massGrams: mGelatinWater, volumeML: vGelatinWater, displayUnit: "ml"
        ))

        let gelatinMix  = MixGroup(name: "Gelatin Mix", components: gelatinComponents)
        let vGelatinMix = gelatinMix.totalVolumeML

        // ── 4. Sugar Mix — fills the remaining volume exactly ────────────────
        // vRemaining is the volume left after activation and gelatin.
        // Total sugar mix mass is derived from vRemaining × ρ_mix.
        // Component volumes are back-derived from mass / individual density, then the
        // last component (water) absorbs any floating-point residual so the mix closes
        // exactly to vRemaining.
        var sugarComponents: [BatchComponent] = []

        let vRemaining  = vMix - vActivation - vGelatinMix
        let phiSugar   = systemConfig.sugarToWaterMassRatio
        let rhoMix      = systemConfig.sugarMixDensity
        let mSugarMix   = vRemaining * rhoMix
        let mSugarWater = mSugarMix / (1.0 + phiSugar)
        let mSugarTotal = phiSugar * mSugarWater

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
            label: "Glucose Syrup",    massGrams: mGlucoseSyrup,     volumeML: vGlucoseSyrup,  displayUnit: "g"
        ))
        sugarComponents.append(BatchComponent(
            label: "Granulated Sugar", massGrams: mGranulated,        volumeML: vGranulated,    displayUnit: "g"
        ))
        sugarComponents.append(BatchComponent(
            label: "Water",            massGrams: mSugarWaterClosed,  volumeML: vSugarWater,    displayUnit: "g"
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
