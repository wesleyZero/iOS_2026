//
//  BatchCalculator.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//
//  Pure calculation engine — no UI, no state mutation.
//
//  Takes a snapshot of the current batch configuration (`BatchConfigViewModel`)
//  and the global system settings (`SystemConfig`) and returns a `BatchResult`
//  describing the three mix groups that make up a gummy batch:
//
//    1. **Activation Mix** — water + preservatives + colors + flavors + terpenes
//    2. **Gelatin Mix**    — gelatin powder + hydration water
//    3. **Sugar Mix**      — glucose syrup + granulated sugar + water
//
//  The sugar mix is computed as the residual volume so that the three groups
//  sum exactly to the target pour volume (vMix).
//

import Foundation

// MARK: - Activation Category

/// Sub-classification within the activation mix, used for grouping in the UI.
enum ActivationCategory: String {
    case flavorOil    = "Flavor Oils"
    case terpene      = "Terpenes"
    case color        = "Colors"
    case preservative = "Preservatives"
}

// MARK: - Batch Component

/// A single ingredient line item within a mix group.
struct BatchComponent: Identifiable {
    let id = UUID()
    let label: String
    let massGrams: Double      // mass in grams
    let volumeML: Double       // volume in milliliters
    let displayUnit: String    // unit shown in the UI (g, ml, µL)
    var activationCategory: ActivationCategory?
}

// MARK: - Mix Group

/// A named group of `BatchComponent`s (e.g. "Activation Mix").
struct MixGroup: Identifiable {
    let id = UUID()
    let name: String
    let components: [BatchComponent]

    var totalMassGrams: Double { components.reduce(0) { $0 + $1.massGrams } }
    var totalVolumeML: Double  { components.reduce(0) { $0 + $1.volumeML } }
}

// MARK: - Batch Result

/// The complete output of a batch calculation.
///
/// - `vBase`: neat target volume (no overage) = gummy count × cavity volume
/// - `vMix`:  target pour volume = vBase × overage factor
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

/// Stateless calculator — call `BatchCalculator.calculate(...)` to produce a `BatchResult`.
enum BatchCalculator {

    /// Computes the full recipe for the current batch configuration.
    ///
    /// The calculation flows in four stages:
    /// 1. Determine the target pour volume (`vMix`).
    /// 2. Build the activation mix (preservatives, colors, flavors, terpenes, water).
    /// 3. Build the gelatin mix (gelatin powder + hydration water).
    /// 4. Build the sugar mix as the residual that closes the volume budget exactly.
    static func calculate(
        viewModel: BatchConfigViewModel,
        systemConfig: SystemConfig
    ) -> BatchResult {

        // ── 1. Target pour volume ────────────────────────────────────────────
        let spec  = systemConfig.spec(for: viewModel.selectedShape)
        let vBase = Double(viewModel.totalGummies(using: systemConfig)) * spec.volumeML
        let vMix  = vBase * viewModel.overageFactor

        // ── 2. Activation Mix ────────────────────────────────────────────────
        // Every component's volume is a fraction of vMix.
        // Mass = volume × density for each ingredient.
        // Activation water is calculated from solubility (not a fixed fraction).
        var activationComponents: [BatchComponent] = []

        // 2a  Citric acid
        let vCitric = (systemConfig.citricAcidPercent / 100.0) * vMix
        let mCitric = vCitric * systemConfig.densityCitricAcid
        activationComponents.append(BatchComponent(
            label: "Citric Acid", massGrams: mCitric, volumeML: vCitric, displayUnit: "g",
            activationCategory: .preservative
        ))

        // 2b  Potassium sorbate
        let vSorbate = (systemConfig.potassiumSorbatePercent / 100.0) * vMix
        let mSorbate = vSorbate * systemConfig.densityPotassiumSorbate
        activationComponents.append(BatchComponent(
            label: "Potassium Sorbate", massGrams: mSorbate, volumeML: vSorbate, displayUnit: "g",
            activationCategory: .preservative
        ))

        // 2c  Colors — total color volume split by user blend ratios
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

        // 2d  Flavor oils — total oil volume split by blend ratios
        let vOilTotal = (viewModel.flavorOilVolumePercent / 100.0) * vMix
        let oils = viewModel.selectedFlavors.keys.filter { if case .oil = $0 { return true }; return false }
        for oil in oils {
            let fraction = (viewModel.selectedFlavors[oil] ?? 0) / 100.0
            let vOil     = vOilTotal * fraction
            let mOil     = vOil * systemConfig.densityFlavorOil
            activationComponents.append(BatchComponent(
                label: "\(oil.displayName) Oil", massGrams: mOil, volumeML: vOil, displayUnit: "ml",
                activationCategory: .flavorOil
            ))
        }

        // 2e  Terpenes — from PPM, split by blend ratios
        let vTerpTotalML = (viewModel.terpeneVolumePPM / 1_000_000.0) * vMix
        let terpenes = viewModel.selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
        for terp in terpenes {
            let fraction = (viewModel.selectedFlavors[terp] ?? 0) / 100.0
            let vTerp    = vTerpTotalML * fraction
            let mTerp    = vTerp * systemConfig.densityTerpenes
            activationComponents.append(BatchComponent(
                label: "\(terp.displayName) Terpene", massGrams: mTerp, volumeML: vTerp, displayUnit: "µL",
                activationCategory: .terpene
            ))
        }

        // 2f  Activation water — enough to dissolve both preservatives
        //     plus any user-specified additional water for the active substance.
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
        // Volume fraction from gelatin %, then hydration water from the
        // water:gelatin mass ratio (φ_gel). NOT forced to a fixed budget.
        let vGelatin     = (viewModel.gelatinPercentage / 100.0) * vMix
        let mGelatin     = vGelatin * systemConfig.densityGelatin
        let phiGel       = systemConfig.waterToGelatinMassRatio
        let mGelatinWater = mGelatin * phiGel
        let vGelatinWater = mGelatinWater / systemConfig.densityWater

        let gelatinMix = MixGroup(name: "Gelatin Mix", components: [
            BatchComponent(label: "Gelatin", massGrams: mGelatin,      volumeML: vGelatin,      displayUnit: "g"),
            BatchComponent(label: "Water",   massGrams: mGelatinWater, volumeML: vGelatinWater, displayUnit: "ml"),
        ])
        let vGelatinMix = gelatinMix.totalVolumeML

        // ── 4. Sugar Mix — residual volume closure ───────────────────────────
        // vRemaining = vMix - vActivation - vGelatinMix
        // Sugar mass from vRemaining × ρ_mix, then split by glucose:granulated ratio.
        // Water absorbs the residual so the mix closes to vRemaining exactly.
        let vRemaining  = vMix - vActivation - vGelatinMix
        let phiSugar    = systemConfig.sugarToWaterMassRatio
        let rhoMix      = systemConfig.sugarMixDensity
        let mSugarMix   = vRemaining * rhoMix
        let mSugarWater = mSugarMix / (1.0 + phiSugar)
        let mSugarTotal = phiSugar * mSugarWater

        let gRatio        = systemConfig.glucoseToSugarMassRatio
        let mGlucoseSyrup = mSugarTotal * gRatio / (1.0 + gRatio)
        let mGranulated   = mSugarTotal / (1.0 + gRatio)
        let vGlucoseSyrup = mGlucoseSyrup / systemConfig.densityGlucoseSyrup
        let vGranulated   = mGranulated   / systemConfig.densitySucrose

        // Water volume closes the residual exactly (absorbs floating-point remainder).
        let vSugarWater       = vRemaining - vGlucoseSyrup - vGranulated
        let mSugarWaterClosed = vSugarWater * systemConfig.densityWater

        let sugarMix = MixGroup(name: "Sugar Mix", components: [
            BatchComponent(label: "Glucose Syrup",    massGrams: mGlucoseSyrup,    volumeML: vGlucoseSyrup, displayUnit: "g"),
            BatchComponent(label: "Granulated Sugar", massGrams: mGranulated,       volumeML: vGranulated,   displayUnit: "g"),
            BatchComponent(label: "Water",            massGrams: mSugarWaterClosed, volumeML: vSugarWater,   displayUnit: "g"),
        ])

        return BatchResult(
            vBase: vBase,
            vMix: vMix,
            activationMix: activationMix,
            gelatinMix: gelatinMix,
            sugarMix: sugarMix
        )
    }
}
