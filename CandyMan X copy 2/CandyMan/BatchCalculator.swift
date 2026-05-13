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

// MARK: - Multi-Active Batch Result

/// Result of a multi-active batch calculation where each tray has independent settings.
struct MultiActiveBatchResult {
    let vBase: Double
    let vMix: Double
    let perTrayResults: [PerTrayResult]
    let combinedGelatinMix: MixGroup
    let combinedSugarMix: MixGroup

    struct PerTrayResult: Identifiable {
        let id: Int  // tray index (0-based)
        let activationMix: MixGroup
        let trayConfig: TrayConfig
        let vMixPerTray: Double
    }
}

// MARK: - Calculator

/// Stateless calculator — call `BatchCalculator.calculate(...)` to produce a `BatchResult`.
enum BatchCalculator {

    // MARK: - Single-Active

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

        // ── 2–4. Build mix groups using helpers ──────────────────────────────
        let activationMix = buildActivationMix(
            vMix: vMix,
            colorVolumePercent: viewModel.colorVolumePercent,
            selectedColors: viewModel.selectedColors,
            flavorOilVolumePercent: viewModel.flavorOilVolumePercent,
            selectedFlavors: viewModel.selectedFlavors,
            terpeneVolumePPM: viewModel.terpeneVolumePPM,
            additionalActiveWaterML: viewModel.additionalActiveWaterML,
            systemConfig: systemConfig
        )

        let gelatinMix = buildGelatinMix(
            vMix: vMix,
            gelatinPercentage: viewModel.gelatinPercentage,
            systemConfig: systemConfig
        )

        let vRemaining = vMix - activationMix.totalVolumeML - gelatinMix.totalVolumeML
        let sugarMix = buildSugarMix(vRemaining: vRemaining, systemConfig: systemConfig)

        return BatchResult(
            vBase: vBase,
            vMix: vMix,
            activationMix: activationMix,
            gelatinMix: gelatinMix,
            sugarMix: sugarMix
        )
    }

    // MARK: - Multi-Active

    /// Computes recipes for a multi-active batch where each tray has independent settings.
    ///
    /// Algorithm:
    /// 1. Compute total vMix across all trays (same shape, equal per-tray share).
    /// 2. For each tray: build activation mix using that tray's config, with 0 additional water.
    /// 3. For each tray: build gelatin mix using that tray's gelatin %.
    /// 4. Aggregate gelatin across all trays. Sugar mix fills the residual.
    static func calculateMultiActive(
        viewModel: BatchConfigViewModel,
        systemConfig: SystemConfig
    ) -> MultiActiveBatchResult {

        // ── 1. Target pour volume (entire batch) ─────────────────────────────
        let spec  = systemConfig.spec(for: viewModel.selectedShape)
        let vBase = Double(viewModel.totalGummies(using: systemConfig)) * spec.volumeML
        let vMix  = vBase * viewModel.overageFactor
        let vMixPerTray = vMix / Double(max(1, viewModel.trayCount))

        // ── 2 & 3. Per-tray activation + gelatin mixes ──────────────────────
        var perTrayResults: [MultiActiveBatchResult.PerTrayResult] = []
        var totalActivationVolume = 0.0
        var totalGelatinMass = 0.0
        var totalGelatinWaterMass = 0.0
        var totalGelatinVolume = 0.0
        var totalGelatinWaterVolume = 0.0

        for (index, trayConfig) in viewModel.trayConfigs.enumerated() {
            // Per-tray additional water: use flat property for selected tray, stored state for others
            let additionalWater: Double
            if index == viewModel.selectedTrayIndex {
                additionalWater = viewModel.additionalActiveWaterML
            } else if viewModel.trayActivationStates.indices.contains(index) {
                additionalWater = viewModel.trayActivationStates[index].additionalActiveWaterML
            } else {
                additionalWater = 0
            }

            let activationMix = buildActivationMix(
                vMix: vMixPerTray,
                colorVolumePercent: trayConfig.colorVolumePercent,
                selectedColors: trayConfig.selectedColors,
                flavorOilVolumePercent: trayConfig.flavorOilVolumePercent,
                selectedFlavors: trayConfig.selectedFlavors,
                terpeneVolumePPM: trayConfig.terpeneVolumePPM,
                additionalActiveWaterML: additionalWater,
                systemConfig: systemConfig
            )
            totalActivationVolume += activationMix.totalVolumeML

            // Per-tray gelatin mix
            let gelatinMix = buildGelatinMix(
                vMix: vMixPerTray,
                gelatinPercentage: trayConfig.gelatinPercentage,
                systemConfig: systemConfig
            )
            for comp in gelatinMix.components {
                if comp.label == "Gelatin" {
                    totalGelatinMass += comp.massGrams
                    totalGelatinVolume += comp.volumeML
                } else {
                    totalGelatinWaterMass += comp.massGrams
                    totalGelatinWaterVolume += comp.volumeML
                }
            }

            perTrayResults.append(.init(
                id: trayConfig.id,
                activationMix: activationMix,
                trayConfig: trayConfig,
                vMixPerTray: vMixPerTray
            ))
        }

        // ── 4. Combined gelatin mix ──────────────────────────────────────────
        let combinedGelatinMix = MixGroup(name: "Gelatin Mix", components: [
            BatchComponent(label: "Gelatin", massGrams: totalGelatinMass, volumeML: totalGelatinVolume, displayUnit: "g"),
            BatchComponent(label: "Water", massGrams: totalGelatinWaterMass, volumeML: totalGelatinWaterVolume, displayUnit: "ml"),
        ])

        // ── 5. Sugar mix — residual volume closure ───────────────────────────
        let vRemaining = vMix - totalActivationVolume - combinedGelatinMix.totalVolumeML
        let combinedSugarMix = buildSugarMix(vRemaining: vRemaining, systemConfig: systemConfig)

        return MultiActiveBatchResult(
            vBase: vBase,
            vMix: vMix,
            perTrayResults: perTrayResults,
            combinedGelatinMix: combinedGelatinMix,
            combinedSugarMix: combinedSugarMix
        )
    }

    // MARK: - Helpers

    /// Builds the activation mix for a given volume budget.
    private static func buildActivationMix(
        vMix: Double,
        colorVolumePercent: Double,
        selectedColors: [GummyColor: Double],
        flavorOilVolumePercent: Double,
        selectedFlavors: [FlavorSelection: Double],
        terpeneVolumePPM: Double,
        additionalActiveWaterML: Double,
        systemConfig: SystemConfig
    ) -> MixGroup {
        var components: [BatchComponent] = []

        // Citric acid
        let vCitric = (systemConfig.citricAcidPercent / 100.0) * vMix
        let mCitric = vCitric * systemConfig.densityCitricAcid
        components.append(BatchComponent(
            label: "Citric Acid", massGrams: mCitric, volumeML: vCitric, displayUnit: "g",
            activationCategory: .preservative
        ))

        // Potassium sorbate
        let vSorbate = (systemConfig.potassiumSorbatePercent / 100.0) * vMix
        let mSorbate = vSorbate * systemConfig.densityPotassiumSorbate
        components.append(BatchComponent(
            label: "Potassium Sorbate", massGrams: mSorbate, volumeML: vSorbate, displayUnit: "g",
            activationCategory: .preservative
        ))

        // Colors
        let vColorTotal = (colorVolumePercent / 100.0) * vMix
        let sortedColors = Array(selectedColors.keys).sorted { $0.rawValue < $1.rawValue }
        for color in sortedColors {
            let fraction = (selectedColors[color] ?? 0) / 100.0
            let vColor   = vColorTotal * fraction
            let mColor   = vColor * systemConfig.densityFoodColoring
            components.append(BatchComponent(
                label: "\(color.rawValue) Color", massGrams: mColor, volumeML: vColor, displayUnit: "ml",
                activationCategory: .color
            ))
        }

        // Flavor oils
        let vOilTotal = (flavorOilVolumePercent / 100.0) * vMix
        let oils = selectedFlavors.keys.filter { if case .oil = $0 { return true }; return false }
        for oil in oils {
            let fraction = (selectedFlavors[oil] ?? 0) / 100.0
            let vOil     = vOilTotal * fraction
            let mOil     = vOil * systemConfig.densityFlavorOil
            components.append(BatchComponent(
                label: "\(oil.displayName) Oil", massGrams: mOil, volumeML: vOil, displayUnit: "ml",
                activationCategory: .flavorOil
            ))
        }

        // Terpenes
        let vTerpTotalML = (terpeneVolumePPM / 1_000_000.0) * vMix
        let terpenes = selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
        for terp in terpenes {
            let fraction = (selectedFlavors[terp] ?? 0) / 100.0
            let vTerp    = vTerpTotalML * fraction
            let mTerp    = vTerp * systemConfig.densityTerpenes
            components.append(BatchComponent(
                label: "\(terp.displayName) Terpene", massGrams: mTerp, volumeML: vTerp, displayUnit: "µL",
                activationCategory: .terpene
            ))
        }

        // Activation water — solubility-based + additional
        let waterForCitric  = SubstanceSolubility.citricAcid.minWaterML(toDissolveGrams: mCitric)
        let waterForSorbate = SubstanceSolubility.potassiumSorbate.minWaterML(toDissolveGrams: mSorbate)
        let vActivationWater = waterForCitric + waterForSorbate + additionalActiveWaterML
        let mActivationWater = vActivationWater * systemConfig.densityWater
        components.append(BatchComponent(
            label: "Activation Water", massGrams: mActivationWater, volumeML: vActivationWater, displayUnit: "ml",
            activationCategory: .preservative
        ))

        return MixGroup(name: "Activation Mix", components: components)
    }

    /// Builds the gelatin mix for a given volume budget and gelatin percentage.
    private static func buildGelatinMix(
        vMix: Double,
        gelatinPercentage: Double,
        systemConfig: SystemConfig
    ) -> MixGroup {
        let vGelatin      = (gelatinPercentage / 100.0) * vMix
        let mGelatin      = vGelatin * systemConfig.densityGelatin
        let phiGel        = systemConfig.waterToGelatinMassRatio
        let mGelatinWater = mGelatin * phiGel
        let vGelatinWater = mGelatinWater / systemConfig.densityWater

        return MixGroup(name: "Gelatin Mix", components: [
            BatchComponent(label: "Gelatin", massGrams: mGelatin, volumeML: vGelatin, displayUnit: "g"),
            BatchComponent(label: "Water", massGrams: mGelatinWater, volumeML: vGelatinWater, displayUnit: "ml"),
        ])
    }

    /// Builds the sugar mix to fill the remaining volume exactly (residual closure).
    private static func buildSugarMix(
        vRemaining: Double,
        systemConfig: SystemConfig
    ) -> MixGroup {
        let phiSugar    = systemConfig.sugarToWaterMassRatio
        let rhoMix      = systemConfig.sugarMixDensity
        let mSugarMix   = vRemaining * rhoMix
        let mSugarWater = mSugarMix / (1.0 + phiSugar)
        let mSugarTotal = phiSugar * mSugarWater

        let gRatio        = systemConfig.glucoseToSugarMassRatio
        let mGlucoseSyrup = mSugarTotal * gRatio / (1.0 + gRatio)
        let mGranulated   = mSugarTotal / (1.0 + gRatio)
        let vGlucoseSyrup = mGlucoseSyrup / systemConfig.densityGlucoseSyrup
        let vGranulated   = mGranulated / systemConfig.densitySucrose

        let vSugarWater       = vRemaining - vGlucoseSyrup - vGranulated
        let mSugarWaterClosed = vSugarWater * systemConfig.densityWater

        return MixGroup(name: "Sugar Mix", components: [
            BatchComponent(label: "Glucose Syrup", massGrams: mGlucoseSyrup, volumeML: vGlucoseSyrup, displayUnit: "g"),
            BatchComponent(label: "Granulated Sugar", massGrams: mGranulated, volumeML: vGranulated, displayUnit: "g"),
            BatchComponent(label: "Water", massGrams: mSugarWaterClosed, volumeML: vSugarWater, displayUnit: "g"),
        ])
    }
}
