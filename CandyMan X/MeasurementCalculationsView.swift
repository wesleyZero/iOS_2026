//
//  MeasurementCalculationsView.swift
//  CandyMan
//
//  Post-measurement derived calculations card. After the user enters actual
//  batch masses in WeightMeasurementsView, this collapsible section computes:
//    • Experimental vs theoretical comparison (target volumes, input mixtures,
//      final mixture, quantified error)
//    • Residue losses (beaker + syringe + tray) with percentages
//    • Active substance analysis (dose error, recovery %)
//    • Preservative mass fractions (potassium sorbate, citric acid)
//    • Mixture densities with one-tap application
//    • Gummy mass/volume with tray calibration
//    • Overage factor tracking
//    • Yield metrics (mass, volume, mold fill ratio)
//

import SwiftUI

// MARK: - MeasurementCalculationsView

struct MeasurementCalculationsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded: Bool = true
    @State private var showDensityUpdatedAlert = false
    @State private var showOverageUpdatedAlert = false
    @State private var showTrayVolumeUpdatedAlert = false
    @State private var appliedDensityValue: Double = 0
    @State private var appliedOverageValue: Double = 0
    @State private var appliedTrayVolume: Double = 0

    // MARK: - Colors

    private var darkGray: Color { systemConfig.designDetailText }
    private var gold: Color { systemConfig.designSecondaryAccent }
    private var softGreen: Color { CMTheme.success }

    // MARK: - Batch Result (theoretical)

    private var batchResult: BatchResult {
        BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
    }

    // MARK: - Existing Derived Measurements

    private var massGelatinAdded: Double? {
        guard let a = viewModel.weightBeakerPlusGelatin,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return a - b
    }

    private var massSugarAdded: Double? {
        guard let a = viewModel.weightBeakerPlusSugar,
              let b = viewModel.weightBeakerPlusGelatin else { return nil }
        return a - b
    }

    private var massActiveAdded: Double? {
        guard let a = viewModel.weightBeakerPlusActive,
              let b = viewModel.weightBeakerPlusSugar else { return nil }
        return a - b
    }

    private var massFinalMixtureInBeaker: Double? {
        guard let a = viewModel.weightBeakerPlusActive,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return a - b
    }

    private var massBeakerResidue: Double? {
        guard let a = viewModel.weightBeakerResidue,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return a - b
    }

    private var massSyringeResidue: Double? {
        guard let a = viewModel.weightSyringeResidue,
              let b = viewModel.weightSyringeEmpty else { return nil }
        return a - b
    }

    private var massTrayResidue: Double? {
        guard let a = viewModel.weightTrayPlusResidue,
              let b = viewModel.weightTrayClean else { return nil }
        return a - b
    }

    private var massTotalLoss: Double? {
        guard let br = massBeakerResidue,
              let sr = massSyringeResidue else { return nil }
        return br + sr
    }

    private var massTotalLossWithSurplus: Double? {
        guard let base = massTotalLoss else { return nil }
        return base + (viewModel.extraGummyMixGrams ?? 0.0) + (massTrayResidue ?? 0.0)
    }

    private var massMixTransferredToMold: Double? {
        guard let finalMix = massFinalMixtureInBeaker,
              let totalLoss = massTotalLossWithSurplus else { return nil }
        return finalMix - totalLoss
    }

    private var massPerGummyMold: Double? {
        guard let transferred = massMixTransferredToMold,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        return transferred / molds
    }

    private var densityFinalMix: Double? {
        guard let mass = viewModel.calcMassOfMixInSyringe,
              let vol  = viewModel.volumeSyringeGummyMix,
              vol > 0 else { return nil }
        return mass / vol
    }

    private var averageGummyVolume: Double? {
        guard let density = densityFinalMix, density > 0,
              let massPerGummy = massPerGummyMold else { return nil }
        return massPerGummy / density
    }

    /// Active loss = totalActive × (totalLoss / finalMixtureInBeaker)
    private var activeLoss: Double? {
        guard let totalLoss = massTotalLossWithSurplus,
              let finalMix  = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        let totalActive = viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
        return totalActive * (totalLoss / finalMix)
    }

    /// Average active dose per gummy = (totalActive - activeLoss) / moldsFilled
    private var averageGummyActiveDose: Double? {
        guard let loss  = activeLoss,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        let totalActive = viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
        return (totalActive - loss) / molds
    }

    /// Total mix volume (same formula as BatchCalculator)
    private var vMix: Double {
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        return Double(viewModel.totalGummies(using: systemConfig)) * spec.volumeML * viewModel.overageFactor
    }

    /// Theoretical mass of potassium sorbate (volume % × vMix × density)
    private var massPotassiumSorbate: Double? {
        let v = (systemConfig.potassiumSorbatePercent / 100.0) * vMix
        return v * systemConfig.densityPotassiumSorbate
    }

    /// Theoretical mass of citric acid (volume % × vMix × density)
    private var massCitricAcid: Double? {
        let v = (systemConfig.citricAcidPercent / 100.0) * vMix
        return v * systemConfig.densityCitricAcid
    }

    /// Mass fraction of potassium sorbate in the final mixture (%)
    private var massFractionPotassiumSorbate: Double? {
        guard let mSorbate = massPotassiumSorbate,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (mSorbate / finalMix) * 100.0
    }

    /// Mass fraction of citric acid in the final mixture (%)
    private var massFractionCitricAcid: Double? {
        guard let mCitric = massCitricAcid,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (mCitric / finalMix) * 100.0
    }

    /// Overage for next batch = averageGummyVolume / volumePerWell
    private var overageForNextBatch: Double? {
        guard let avgVol = averageGummyVolume else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        guard spec.volumeML > 0 else { return nil }
        return avgVol / spec.volumeML
    }

    // MARK: - New Experimental Volume Derivations

    /// Experimental gelatin mix volume = mass / measured density
    private var expGelatinMixVolume: Double? {
        guard let mass = massGelatinAdded,
              let density = viewModel.calcGelatinMixDensity,
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental sugar mix volume = mass / measured density
    private var expSugarMixVolume: Double? {
        guard let mass = massSugarAdded,
              let density = viewModel.calcSugarMixDensity,
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental activation mix volume = mass / measured density
    private var expActiveMixVolume: Double? {
        guard let mass = massActiveAdded,
              let density = viewModel.calcActiveMixDensity,
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental final mix volume = total mass in beaker / gummy mix density
    private var expFinalMixVolume: Double? {
        guard let mass = massFinalMixtureInBeaker,
              let density = densityFinalMix,
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental total volume dispensed into molds
    private var expTotalVolumeInMolds: Double? {
        guard let mass = massMixTransferredToMold,
              let density = densityFinalMix,
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental volume per mold cavity
    private var expVolumePerMold: Double? {
        guard let totalVol = expTotalVolumeInMolds,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        return totalVol / molds
    }

    /// Experimental volume per tray
    private var expVolumePerTray: Double? {
        guard let totalVol = expTotalVolumeInMolds,
              viewModel.trayCount > 0 else { return nil }
        return totalVol / Double(viewModel.trayCount)
    }

    /// Experimental final mix mass without overage
    private var expFinalMixMassNoOverage: Double? {
        guard let mass = massFinalMixtureInBeaker,
              viewModel.overageFactor > 0 else { return nil }
        return mass / viewModel.overageFactor
    }

    /// Experimental final mix volume without overage
    private var expFinalMixVolNoOverage: Double? {
        guard let vol = expFinalMixVolume,
              viewModel.overageFactor > 0 else { return nil }
        return vol / viewModel.overageFactor
    }

    // MARK: - Error Calculations

    /// Quantified error = experimental volume (w/o overage) − theoretical target volume
    private var quantifiedError: Double? {
        guard let expVol = expFinalMixVolNoOverage else { return nil }
        return expVol - batchResult.vBase
    }

    /// Relative error = quantified error / theoretical target × 100
    private var relativeError: Double? {
        guard let qErr = quantifiedError,
              batchResult.vBase > 0 else { return nil }
        return (qErr / batchResult.vBase) * 100.0
    }

    // MARK: - Loss Percentages

    private var beakerLossPercent: Double? {
        guard let residue = massBeakerResidue,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (residue / finalMix) * 100.0
    }

    private var syringeLossPercent: Double? {
        guard let residue = massSyringeResidue,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (residue / finalMix) * 100.0
    }

    private var trayLossPercent: Double? {
        guard let residue = massTrayResidue,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (residue / finalMix) * 100.0
    }

    private var totalLossPercent: Double? {
        guard let totalLoss = massTotalLossWithSurplus,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (totalLoss / finalMix) * 100.0
    }

    // MARK: - Active Substance Analysis

    /// The target dose per gummy (what we aimed for)
    private var theoreticalActiveDose: Double {
        viewModel.activeConcentration
    }

    /// Active dose error = experimental − theoretical
    private var activeDoseError: Double? {
        guard let expDose = averageGummyActiveDose else { return nil }
        return expDose - theoreticalActiveDose
    }

    /// Active dose relative error (%)
    private var activeDoseRelativeError: Double? {
        guard let err = activeDoseError,
              theoreticalActiveDose > 0 else { return nil }
        return (err / theoreticalActiveDose) * 100.0
    }

    /// Active recovery % = (totalActive − activeLoss) / totalActive × 100
    private var activeRecoveryPercent: Double? {
        guard let loss = activeLoss else { return nil }
        let totalActive = viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
        guard totalActive > 0 else { return nil }
        return ((totalActive - loss) / totalActive) * 100.0
    }

    // MARK: - Yield

    /// Mass yield = mass transferred to molds / final mix mass × 100
    private var massYieldPercent: Double? {
        guard let transferred = massMixTransferredToMold,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (transferred / finalMix) * 100.0
    }

    /// Volume yield = volume in molds / final mix volume × 100
    private var volumeYieldPercent: Double? {
        guard let moldVol = expTotalVolumeInMolds,
              let mixVol = expFinalMixVolume,
              mixVol > 0 else { return nil }
        return (moldVol / mixVol) * 100.0
    }

    /// Mold fill ratio = molds actually filled / theoretical gummy count
    private var moldFillRatio: Double? {
        guard let molds = viewModel.weightMoldsFilled else { return nil }
        let theoretical = Double(viewModel.totalGummies(using: systemConfig))
        guard theoretical > 0 else { return nil }
        return molds / theoretical
    }

    // MARK: - Theoretical Reference Values

    private var theoVolPerMold: Double {
        let totalGummies = viewModel.totalGummies(using: systemConfig)
        guard totalGummies > 0 else { return 0 }
        return batchResult.vBase / Double(totalGummies)
    }

    private var theoVolPerTray: Double {
        guard viewModel.trayCount > 0 else { return 0 }
        return batchResult.vBase / Double(viewModel.trayCount)
    }

    private var theoFinalMixMassNoOverage: Double {
        guard viewModel.overageFactor > 0 else { return batchResult.totalMassGrams }
        return batchResult.totalMassGrams / viewModel.overageFactor
    }

    // MARK: - Activation Component Breakdown

    @ViewBuilder
    private var activationComponentBreakdown: some View {
        let mix = batchResult.activationMix
        let orderedCategories: [ActivationCategory] = [.terpene, .flavorOil, .color]

        ForEach(orderedCategories, id: \.rawValue) { category in
            let items = mix.components.filter { $0.activationCategory == category }
            if !items.isEmpty {
                HStack {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(CMTheme.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)

                ForEach(items) { comp in
                    activationCalcRow(comp)
                }
            }
        }
    }

    private func activationCalcRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        return HStack(spacing: 6) {
            if let color = colorMatch {
                Circle().fill(color.swiftUIColor).frame(width: 10, height: 10)
            }
            Text(comp.label)
                .cmRowLabel()
            Spacer()
            if comp.displayUnit == "µL" {
                Text(String(format: "%.0f", comp.volumeML * 1000.0))
                    .cmMono12()
                    .foregroundStyle(darkGray)
            } else if comp.displayUnit == "g" {
                Text(String(format: "%.3f", comp.massGrams))
                    .cmMono12()
                    .foregroundStyle(darkGray)
            } else {
                Text(String(format: "%.3f", comp.volumeML))
                    .cmMono12()
                    .foregroundStyle(darkGray)
            }
            Text(comp.displayUnit)
                .cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header — tappable to collapse/expand
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Experiment Data").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            ThemedDivider()
            VStack(spacing: 0) {

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Experimental vs Theoretical Comparison
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            dualCalcHeaderRow()

            // MARK: Target Volumes
            dualSubsectionHeader("Target Volumes")
            dualCalcRow("Volume Per Mold",  exp: expVolumePerMold,        theo: theoVolPerMold,     unit: "mL")
            dualCalcRow("Volume Per Tray",  exp: expVolumePerTray,        theo: theoVolPerTray,     unit: "mL")
            dualCalcRow("Total Volume",     exp: expTotalVolumeInMolds,   theo: batchResult.vBase,  unit: "mL", bold: true)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Input Mixtures (mass)
            dualSubsectionHeader("Input Mixtures — Mass")
            dualCalcRow("Gelatin Mix",    exp: massGelatinAdded,  theo: batchResult.gelatinMix.totalMassGrams,    unit: "g")
            dualCalcRow("Sugar Mix",      exp: massSugarAdded,    theo: batchResult.sugarMix.totalMassGrams,      unit: "g")
            dualCalcRow("Activation Mix", exp: massActiveAdded,   theo: batchResult.activationMix.totalMassGrams, unit: "g")

            // Activation mix component breakdown by category
            activationComponentBreakdown

            ThemedDivider(indent: 20).padding(.vertical, 4)

            // MARK: Input Mixtures (volume)
            dualSubsectionHeader("Input Mixtures — Volume")
            dualCalcRow("Gelatin Mix Vol",    exp: expGelatinMixVolume,  theo: batchResult.gelatinMix.totalVolumeML,    unit: "mL")
            dualCalcRow("Sugar Mix Vol",      exp: expSugarMixVolume,    theo: batchResult.sugarMix.totalVolumeML,      unit: "mL")
            dualCalcRow("Activation Mix Vol", exp: expActiveMixVolume,   theo: batchResult.activationMix.totalVolumeML, unit: "mL")

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Final Mixture
            dualSubsectionHeader("Final Mixture")
            dualCalcRow("Final Mix Mass (+\(String(format: "%.1f", (viewModel.overageFactor - 1) * 100))%)",
                        exp: massFinalMixtureInBeaker,   theo: batchResult.totalMassGrams,   unit: "g")
            dualCalcRow("Final Mix Vol (+\(String(format: "%.1f", (viewModel.overageFactor - 1) * 100))%)",
                        exp: expFinalMixVolume,          theo: batchResult.totalVolumeML,     unit: "mL")
            dualCalcRow("Final Mix Mass (w/o overage)",
                        exp: expFinalMixMassNoOverage,   theo: theoFinalMixMassNoOverage,     unit: "g")
            dualCalcRow("Final Mix Vol (w/o overage)",
                        exp: expFinalMixVolNoOverage,    theo: batchResult.vBase,             unit: "mL", bold: true)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Error
            subsectionHeader("Error")
            signedErrorRow("Quantified Error", value: quantifiedError, unit: "mL")
            signedErrorRow("Relative Error",   value: relativeError,   unit: "%")

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Losses
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Losses")
            lossRow("Beaker Residue",   mass: massBeakerResidue,   pct: beakerLossPercent)
            lossRow("Syringe Residue",  mass: massSyringeResidue,  pct: syringeLossPercent)
            calcRow("Extra Gummy Mix",  value: viewModel.extraGummyMixGrams, unit: "g")
            lossRow("Tray Residue",     mass: massTrayResidue,     pct: trayLossPercent)
            lossRow("Total Residue",    mass: massTotalLossWithSurplus, pct: totalLossPercent)
                .background(CMTheme.rowHighlight)
            ThemedDivider(indent: 20).padding(.vertical, 4)
            calcRow("Lost \(viewModel.selectedActive.rawValue) in Residue", value: activeLoss, unit: viewModel.units.rawValue)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Active Substance Analysis
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Active Substance")
            dualCalcRow("Dose Per Gummy",
                        exp: averageGummyActiveDose,
                        theo: theoreticalActiveDose,
                        unit: viewModel.units.rawValue, decimals: 4)
            signedErrorRow("Dose Error",          value: activeDoseError,         unit: viewModel.units.rawValue, decimals: 4)
            signedErrorRow("Dose Relative Error", value: activeDoseRelativeError, unit: "%")
            calcRow("Active Recovery", value: activeRecoveryPercent, unit: "%", decimals: 2, valueColor: softGreen)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Preservatives
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Preservatives")
            calcRow("Potassium Sorbate Mass Fraction",  value: massFractionPotassiumSorbate,  unit: "w/w%", decimals: 4, valueColor: softGreen)
            calcRow("Citric Acid Mass Fraction",        value: massFractionCitricAcid,        unit: "w/w%", decimals: 4, valueColor: softGreen)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Mixture Densities
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Mixture Densities")
            calcRow("Sugar Mix Density",      value: viewModel.calcSugarMixDensity,    unit: "g/mL", decimals: 4)
            calcRow("Gelatin Mix Density",    value: viewModel.calcGelatinMixDensity,  unit: "g/mL", decimals: 4)
            calcRow("Activation Mix Density", value: viewModel.calcActiveMixDensity,   unit: "g/mL", decimals: 4)
            calcRow("Gummy Mixture Density",  value: densityFinalMix,                  unit: "g/mL", decimals: 4, valueColor: gold)

            if let density = densityFinalMix, density > 0 {
                let alreadyApplied = abs(systemConfig.estimatedFinalMixDensity - density) < 0.0001
                Button {
                    CMHaptic.light()
                    appliedDensityValue = density
                    withAnimation(.cmSpring) { systemConfig.estimatedFinalMixDensity = density }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showDensityUpdatedAlert = true
                    }
                } label: {
                    Text("Update final gummy mixture est. density")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            alreadyApplied
                                ? CMTheme.textTertiary
                                : systemConfig.designAlert
                        )
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(CMTheme.chipBG)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 4)
            }

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Gummies
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Gummies")
            calcRow("Average Gummy Mass",    value: massPerGummyMold,   unit: "g")
            calcRow("Average Gummy Volume",  value: averageGummyVolume, unit: "mL", decimals: 4)

            if let avgVol = averageGummyVolume, avgVol > 0 {
                let currentVol = systemConfig.spec(for: viewModel.selectedShape).volumeML
                let alreadyApplied = abs(currentVol - avgVol) < 0.0001
                Button {
                    CMHaptic.light()
                    appliedTrayVolume = avgVol
                    var spec = systemConfig.spec(for: viewModel.selectedShape)
                    spec.volumeML = avgVol
                    withAnimation(.cmSpring) { systemConfig.setSpec(spec, for: viewModel.selectedShape) }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showTrayVolumeUpdatedAlert = true
                    }
                } label: {
                    Text("Calibrate Tray Volume for \(viewModel.selectedShape.rawValue)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            alreadyApplied
                                ? CMTheme.textTertiary
                                : systemConfig.designAlert
                        )
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(CMTheme.chipBG)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 4)
            }

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Overage
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Overage")
            percentRow("Overage Used This Batch",   pct: (viewModel.overageFactor - 1.0) * 100.0)
            percentRow("Overage for Next Batch",    pct: overageForNextBatch.map { ($0 - 1.0) * 100.0 }, valueColor: gold)

            if let overage = overageForNextBatch, overage > 0 {
                let alreadyApplied = abs(viewModel.overageFactor - overage) < 0.0001
                Button {
                    CMHaptic.light()
                    appliedOverageValue = overage
                    withAnimation(.cmSpring) { viewModel.overageFactor = overage }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showOverageUpdatedAlert = true
                    }
                } label: {
                    Text("Update overage factor in system settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            alreadyApplied
                                ? CMTheme.textTertiary
                                : systemConfig.designAlert
                        )
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(CMTheme.chipBG)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 4)
            }

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: Yield
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            subsectionHeader("Yield")
            calcRow("Mass Yield",      value: massYieldPercent,   unit: "%", decimals: 2)
            calcRow("Volume Yield",    value: volumeYieldPercent, unit: "%", decimals: 2)
            calcRow("Mold Fill Ratio", value: moldFillRatio.map { $0 * 100.0 }, unit: "%", decimals: 1)

            Spacer(minLength: 12)
            }
            .cmExpandTransition()
            } // if isExpanded
        }
        .overlay {
            if showDensityUpdatedAlert {
                PsychedelicAlert3(
                    title: "ρ Estimate Updated",
                    subtitle: "Density locked in. CandyMan sees all.",
                    value: String(format: "%.4f g/mL", appliedDensityValue)
                ) {
                    withAnimation(.easeOut(duration: 0.25)) { showDensityUpdatedAlert = false }
                }
            }
            if showOverageUpdatedAlert {
                PsychedelicAlert4(
                    title: "Overage Factor Set",
                    subtitle: "Dialed in. Next batch is gonna slap.",
                    value: String(format: "%.4f×", appliedOverageValue)
                ) {
                    withAnimation(.easeOut(duration: 0.25)) { showOverageUpdatedAlert = false }
                }
            }
            if showTrayVolumeUpdatedAlert {
                PsychedelicAlert3(
                    title: "Tray Volume Calibrated",
                    subtitle: "\(viewModel.selectedShape.rawValue) well volume updated.",
                    value: String(format: "%.4f mL", appliedTrayVolume)
                ) {
                    withAnimation(.easeOut(duration: 0.25)) { showTrayVolumeUpdatedAlert = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
        }
        .cmSubsectionPadding()
    }

    /// Subsection header for dual-column areas — includes Exp/Theo column labels
    private func dualSubsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
            Text("Exp.").cmColumnHeader()
            Text("Theo.").cmColumnHeader()
            Text("Δ").cmColumnHeader()
            Text("").frame(width: 30) // unit slot spacer
        }
        .cmSubsectionPadding()
    }

    /// Column header row for the Experimental vs Theoretical comparison section
    private func dualCalcHeaderRow() -> some View {
        HStack {
            Text("Exp. vs Theo. Comparison")
                .cmSubsectionTitle()
                .fontWeight(.bold)
            Spacer()
            Text("Exp.").cmColumnHeader()
            Text("Theo.").cmColumnHeader()
            Text("Δ").cmColumnHeader()
            Text("").frame(width: 30) // unit slot spacer
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    /// Side-by-side row: experimental value | theoretical value | delta | unit
    private func dualCalcRow(_ label: String, exp: Double?, theo: Double?, unit: String, decimals: Int = 3, bold: Bool = false) -> some View {
        let delta: Double? = {
            guard let e = exp, let t = theo else { return nil }
            return e - t
        }()

        return HStack(spacing: 4) {
            Text(label)
                .cmMono11()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            // Experimental value
            if let e = exp {
                Text(String(format: "%.\(decimals)f", e))
                    .cmValidationSlot(color: darkGray)
                    .fontWeight(bold ? .bold : .regular)
            } else {
                Text("—").cmValidationSlot(color: CMTheme.textTertiary)
            }
            // Theoretical value
            if let t = theo {
                Text(String(format: "%.\(decimals)f", t))
                    .cmValidationSlot(color: CMTheme.textTertiary)
                    .fontWeight(bold ? .bold : .regular)
            } else {
                Text("—").cmValidationSlot(color: CMTheme.textTertiary)
            }
            // Delta
            if let d = delta {
                let color: Color = abs(d) < (theo.map { abs($0) * 0.01 } ?? 1.0) ? softGreen : systemConfig.designAlert
                Text(String(format: "%+.\(decimals)f", d))
                    .cmValidationSlot(color: color)
                    .fontWeight(.semibold)
            } else {
                Text("—").cmValidationSlot(color: CMTheme.textTertiary)
            }
            Text(unit)
                .frame(width: 30, alignment: .leading)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
        }
        .cmDataRowPadding()
    }

    /// Signed error row with color coding: green if small, red if large
    private func signedErrorRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            if let v = value {
                let color: Color = abs(v) < 1.0 ? softGreen : systemConfig.designAlert
                Text(String(format: "%+.\(decimals)f", v))
                    .cmMono12()
                    .foregroundStyle(color)
                    .fontWeight(.semibold)
            } else {
                Text("—")
                    .cmMono12()
                    .foregroundStyle(CMTheme.textTertiary)
            }
            Text(unit)
                .cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    /// Loss row showing mass + percentage inline
    private func lossRow(_ label: String, mass: Double?, pct: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            if let m = mass {
                Text(String(format: "%.3f", m))
                    .cmMono12()
                    .foregroundStyle(darkGray)
            } else {
                Text("—")
                    .cmMono12()
                    .foregroundStyle(CMTheme.textTertiary)
            }
            Text("g")
                .cmUnitSlot()
            if let p = pct {
                Text(String(format: "(%.1f%%)", p))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(CMTheme.textTertiary)
            }
        }
        .cmDataRowPadding()
    }

    private func calcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3, valueColor: Color? = nil) -> some View {
        return HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            Group {
                if let v = value {
                    Text(String(format: "%.\(decimals)f", v))
                        .cmMono12()
                        .foregroundStyle(valueColor ?? darkGray)
                } else {
                    Text("—")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            Text(unit)
                .cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    private func percentRow(_ label: String, pct: Double, valueColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            Text(String(format: "%.2f%%", pct))
                .cmMono12()
                .foregroundStyle(valueColor ?? darkGray)
        }
        .cmDataRowPadding()
    }

    private func percentRow(_ label: String, pct: Double?, valueColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            if let p = pct {
                Text(String(format: "%.2f%%", p))
                    .cmMono12()
                    .foregroundStyle(valueColor ?? darkGray)
            } else {
                Text("—")
                    .cmMono12()
                    .foregroundStyle(CMTheme.textTertiary)
            }
        }
        .cmDataRowPadding()
    }

}
