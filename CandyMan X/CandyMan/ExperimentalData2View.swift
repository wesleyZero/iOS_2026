//
//  ExperimentalData2View.swift
//  CandyMan
//
//  "Experiment Data 2" card for the main post-calculate page.
//  Compares individual sub-component masses (experimental vs theoretical)
//  within each mixture: Gelatin, Sugar, and Activation.
//
//  Columns (left → right): Theo (g) | Exp (g) | Δ (g) | Δ (%)
//

import SwiftUI

// MARK: - ExperimentalData2View

struct ExperimentalData2View: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    // Column widths
    private let colWidth: CGFloat = 52

    // MARK: - Theoretical (from BatchCalculator)

    private var result: BatchResult {
        BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
    }

    private var multiResult: MultiActiveBatchResult? {
        guard viewModel.multiActiveEnabled else { return nil }
        return BatchCalculator.calculateMultiActive(viewModel: viewModel, systemConfig: systemConfig)
    }

    private var perTrayResult: MultiActiveBatchResult.PerTrayResult? {
        guard let multi = multiResult else { return nil }
        let idx = min(viewModel.selectedTrayIndex, multi.perTrayResults.count - 1)
        guard idx >= 0 else { return nil }
        return multi.perTrayResults[idx]
    }

    private var sugarOverage: Double {
        1.0 + systemConfig.sugarMixtureOveragePercent / 100.0
    }
    private var gelatinOverage: Double {
        1.0 + systemConfig.gelatinMixtureOveragePercent / 100.0
    }

    // Bulk mix groups — use multi-active combined mixes when enabled
    private var bulkGelatinMix: MixGroup { multiResult?.combinedGelatinMix ?? result.gelatinMix }
    private var bulkSugarMix: MixGroup { multiResult?.combinedSugarMix ?? result.sugarMix }

    // Gelatin Mix theoretical sub-components (with overage applied — matches preparation target)
    private var theoGelatinMass: Double { bulkGelatinMix.components[0].massGrams * gelatinOverage }
    private var theoGelatinWaterMass: Double { bulkGelatinMix.components[1].massGrams * gelatinOverage }
    private var theoGelatinMixTotal: Double { bulkGelatinMix.totalMassGrams * gelatinOverage }

    // Sugar Mix theoretical sub-components (with overage applied)
    // Components order: [0] Glucose Syrup, [1] Granulated Sugar, [2] Water
    private var theoGlucoseSyrupMass: Double { bulkSugarMix.components[0].massGrams * sugarOverage }
    private var theoGranulatedMass: Double { bulkSugarMix.components[1].massGrams * sugarOverage }
    private var theoSugarWaterMass: Double { bulkSugarMix.components[2].massGrams * sugarOverage }
    private var theoSugarMixTotal: Double { bulkSugarMix.totalMassGrams * sugarOverage }

    // Activation Mix theoretical sub-components (found by label)
    // Substance masses from BatchCalculator (pure ingredient, no solution water)
    private var theoCitricAcidSubstanceMass: Double {
        result.activationMix.components.first { $0.label == "Citric Acid" }?.massGrams ?? 0
    }
    private var theoKSorbateSubstanceMass: Double {
        result.activationMix.components.first { $0.label == "Potassium Sorbate" }?.massGrams ?? 0
    }
    private var theoActivationWaterMass: Double {
        result.activationMix.components.filter { $0.label == "Additional Water" || $0.label == "LSD Transfer Water" }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoFlavorOilsMass: Double {
        result.activationMix.components.filter { $0.activationCategory == .flavorOil }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoColorMass: Double {
        result.activationMix.components.filter { $0.activationCategory == .color }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoTerpsMass: Double {
        result.activationMix.components.filter { $0.activationCategory == .terpene }.reduce(0.0) { $0 + $1.massGrams }
    }
    // Activation mix total excludes preservatives (added during transfer, not in activation tray)
    private var theoActivationMixTotal: Double {
        result.activationMix.totalMassGrams - theoCitricAcidSubstanceMass - theoKSorbateSubstanceMass
    }

    // Mixture Densities — theoretical (mass / volume from BatchCalculator)
    private var theoGelatinMixDensity: Double {
        let vol = result.gelatinMix.totalVolumeML
        guard vol > 0 else { return 0 }
        return result.gelatinMix.totalMassGrams / vol
    }
    private var theoSugarMixDensity: Double {
        let vol = result.sugarMix.totalVolumeML
        guard vol > 0 else { return 0 }
        return result.sugarMix.totalMassGrams / vol
    }
    private var theoActivationMixDensity: Double {
        let vol = result.activationMix.totalVolumeML
        guard vol > 0 else { return 0 }
        return result.activationMix.totalMassGrams / vol
    }
    private var theoFinalMixDensity: Double {
        let vol = result.totalVolumeML
        guard vol > 0 else { return 0 }
        return result.totalMassGrams / vol
    }

    // MARK: - Losses

    /// Activation tray residue = activation tray residue reading − activation container tare.
    /// Matches the "Residue Loss" row in the Activation Mixture subsection of Batch Measurements.
    private var calcActivationTrayResidue: Double? {
        guard let residue = viewModel.hpActivationTrayResidue else { return nil }
        let activVol = result.activationMix.totalVolumeML
        let containerID = viewModel.hpActivationTrayID
            ?? systemConfig.recommendedBeaker(forVolumeML: activVol)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return residue - tare
    }

    /// Beaker residue in HP mode = raw residue reading − substrate container tare.
    private var calcHPBeakerResidue: Double? {
        guard let residue = viewModel.weightBeakerResidue else { return nil }
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return residue - tare
    }

    /// Tray residue from the Molds section = tray+residue reading − mold tray tare.
    private var calcTrayResidue: Double? {
        guard let reading = viewModel.weightTrayPlusResidue else { return nil }
        let trayID = viewModel.hpMoldsTrayID ?? systemConfig.trays.first?.id
        let tare = trayID.map { systemConfig.trayTare(for: $0) } ?? 0
        return reading - tare
    }

    private var lossValues: [Double?] {
        [calcHPBeakerResidue, calcActivationTrayResidue, calcSyringeResidue,
         calcTrayResidue, viewModel.extraGummyMixGrams]
    }

    /// Sum of all measured losses (beaker residue + activation tray residue +
    /// syringe residue + tray residue + extra gummy mix).
    private var totalLossMass: Double? {
        let available = lossValues.compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +)
    }

    private var lossesRecordedCount: Int { lossValues.compactMap { $0 }.count }
    private var lossesTotalCount: Int { lossValues.count }

    /// Syringe residue = syringe residue reading − syringe tare (transfer syringe).
    private var calcSyringeResidue: Double? {
        guard let residue = viewModel.weightSyringeResidue else { return nil }
        let syringeID = viewModel.hpTransferSyringeID ?? systemConfig.syringes.first?.id
        let tare = syringeID.map { systemConfig.syringeTare(for: $0) } ?? 0
        return residue - tare
    }

    /// Net gummy mixture mass from HP flow (activation transfer − substrate beaker+stir bar tare).
    private var hpGummyMixtureMass: Double? {
        guard let transfer = viewModel.hpSubstrateActivationTransfer else { return nil }
        let tare = viewModel.hpSubstrateTare(systemConfig: systemConfig)
        return transfer - tare
    }

    /// Total active substance that went into the gummy mixture.
    private var totalActiveAmount: Double {
        viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
    }

    /// Active substance lost in all losses, assuming uniform distribution in the mixture.
    /// activeLost = totalActive × (totalLossMass / gummyMixtureMass)
    private var activeLostInLosses: Double? {
        guard let loss = totalLossMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        return totalActiveAmount * (loss / mixMass)
    }

    /// Average active dose per gummy after accounting for losses.
    private var avgGummyDoseAfterLoss: Double? {
        guard let lost = activeLostInLosses,
              let moldsFilled = viewModel.weightMoldsFilled,
              moldsFilled > 0 else { return nil }
        return (totalActiveAmount - lost) / moldsFilled
    }

    // MARK: - Gummy Properties (Theoretical)

    /// Theoretical mass per gummy = total batch mass / total gummies.
    private var theoGummyMass: Double {
        let gummies = Double(viewModel.totalGummies(using: systemConfig))
        guard gummies > 0 else { return 0 }
        return result.totalMassGrams / gummies
    }

    /// Theoretical volume per gummy = theoGummyMass / dynamically computed final mix density.
    private var theoGummyVolume: Double {
        guard theoFinalMixDensity > 0 else { return 0 }
        return theoGummyMass / theoFinalMixDensity
    }

    /// Theoretical active concentration per gummy = user-configured dose.
    private var theoGummyConcentration: Double {
        viewModel.activeConcentration
    }

    // MARK: - Gummy Properties (Experimental)

    /// HP density of gummy mixture — uses the same measured syringe tare as calcDensityFinalMix
    /// to keep the density shown in Mixture Densities consistent with the one used for per-gummy volume.
    private var hpDensityGummyMix: Double? {
        viewModel.calcDensityFinalMix(systemConfig: systemConfig)
    }

    /// Net gummy mix transferred to trays = syringe+mix − syringe(residue).
    private var hpNetGummyMixTransferred: Double? {
        guard let syringeWithMix = viewModel.weightSyringeWithMix,
              let syringeResidue = viewModel.weightSyringeResidue else { return nil }
        return syringeWithMix - syringeResidue
    }

    /// Experimental mass per gummy = net total gummy mixture / molds filled.
    private var expGummyMass: Double? {
        guard let mixtureMass = hpGummyMixtureMass,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        return mixtureMass / molds
    }

    /// Experimental volume per gummy = expGummyMass / gummy mixture density.
    private var expGummyVolume: Double? {
        guard let mass = expGummyMass,
              let density = hpDensityGummyMix,
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental active concentration per gummy = avgGummyDoseAfterLoss (already computed).
    private var expGummyConcentration: Double? {
        avgGummyDoseAfterLoss
    }

    // Total theoretical batch mass including solution water from preservatives.
    // Gelatin overage is NOT included — overage is prepared extra, not part of the final gummy.
    private var theoTotalWithSolutions: Double {
        result.totalMassGrams
            + theoCitricAcidSubstanceMass * systemConfig.citricAcidSolutionRatio
            + theoKSorbateSubstanceMass * systemConfig.kSorbateSolutionRatio
    }

    // MARK: - Preservative Mass Fractions

    /// Theoretical citric acid mass fraction (%) = pure substance mass / total batch mass × 100.
    private var theoCitricAcidFraction: Double {
        guard theoTotalWithSolutions > 0 else { return 0 }
        return (theoCitricAcidSubstanceMass / theoTotalWithSolutions) * 100.0
    }

    /// Experimental citric acid mass fraction (%) = transfer solution / (1 + ratio) / gummy mixture mass × 100.
    private var expCitricAcidFraction: Double? {
        guard let citric = expTransferCitricAcidMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        let substanceMass = citric / (1.0 + systemConfig.citricAcidSolutionRatio)
        return (substanceMass / mixMass) * 100.0
    }

    /// Theoretical potassium sorbate mass fraction (%) = pure substance mass / total batch mass × 100.
    private var theoKSorbateFraction: Double {
        guard theoTotalWithSolutions > 0 else { return 0 }
        return (theoKSorbateSubstanceMass / theoTotalWithSolutions) * 100.0
    }

    /// Experimental potassium sorbate mass fraction (%) = transfer solution / (1 + ratio) / gummy mixture mass × 100.
    private var expKSorbateFraction: Double? {
        guard let ksorbate = expTransferKSorbateMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        let substanceMass = ksorbate / (1.0 + systemConfig.kSorbateSolutionRatio)
        return (substanceMass / mixMass) * 100.0
    }

    /// Theoretical gelatin mass fraction (%) = gelatin substance mass (no overage) / total batch mass × 100.
    private var theoGelatinFraction: Double {
        guard theoTotalWithSolutions > 0 else { return 0 }
        return (result.gelatinMix.components[0].massGrams / theoTotalWithSolutions) * 100.0
    }

    /// Experimental gelatin mass fraction (%) = measured gelatin / gummy mixture mass × 100.
    private var expGelatinFraction: Double? {
        guard let gelatin = expGelatinMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (gelatin / mixMass) * 100.0
    }

    // MARK: - Experimental (from HP cumulative scale readings)

    // Gelatin
    private var expGelatinWaterMass: Double? {
        viewModel.hpIndividualGelatinWater(systemConfig: systemConfig)
    }
    private var expGelatinMass: Double? {
        viewModel.hpIndividualGelatin
    }
    private var expGelatinMixTotal: Double? {
        guard let g = expGelatinMass, let w = expGelatinWaterMass else { return nil }
        return g + w
    }

    // Sugar
    private var expSugarWaterMass: Double? {
        viewModel.hpIndividualSugarWater(systemConfig: systemConfig)
    }
    private var expGlucoseSyrupMass: Double? {
        viewModel.hpIndividualGlucoseSyrup
    }
    private var expGranulatedMass: Double? {
        viewModel.hpIndividualGranulated
    }
    private var expSugarMixTotal: Double? {
        guard let g = expGranulatedMass, let gl = expGlucoseSyrupMass, let w = expSugarWaterMass else { return nil }
        return g + gl + w
    }

    // Activation (order matches tray measurements: Active → Activation Water → Flavor Oils → Terps → Color)
    private var expActiveMass: Double? {
        viewModel.hpIndividualActive(systemConfig: systemConfig)
    }
    private var expActivationWaterMass: Double? {
        guard let water = viewModel.hpAdditionalActivationWater, let active = viewModel.hpActive else { return nil }
        return water - active
    }
    private var expFlavorOilsMass: Double? {
        guard let oils = viewModel.hpFlavorOils, let water = viewModel.hpAdditionalActivationWater else { return nil }
        return oils - water
    }
    private var expTerpsMass: Double? {
        guard let terps = viewModel.hpTerps, let oils = viewModel.hpFlavorOils else { return nil }
        return terps - oils
    }
    private var expColorMass: Double? {
        guard let color = viewModel.hpColor, let terps = viewModel.hpTerps else { return nil }
        return color - terps
    }
    private var expActivationMixTotal: Double? {
        let values = [expActiveMass, expActivationWaterMass,
                      expFlavorOilsMass, expTerpsMass, expColorMass]
        let available = values.compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +)
    }


    // MARK: - Tray Transfer Comparisons

    private var trayActivationMix: MixGroup { perTrayResult?.activationMix ?? result.activationMix }
    private var traySugarMix: MixGroup { perTrayResult?.sugarMix ?? result.sugarMix }
    private var trayGelatinMix: MixGroup { perTrayResult?.gelatinMix ?? result.gelatinMix }

    // Beaker tare (theoretical from system settings, experimental from measured reading)
    private var trayTransferBeakerID: String? {
        viewModel.hpTrayTransferBeakerID ?? viewModel.hpSubstrateBeakerID
    }
    private var theoTransferBeakerTare: Double {
        guard let id = trayTransferBeakerID else { return 0 }
        return systemConfig.containerTare(for: id)
    }
    private var expTransferBeakerMass: Double? {
        viewModel.hpTrayTransferBeakerReading
    }

    // Theoretical transfer masses (per-tray, no overage — overage stays as beaker residue)
    private var theoTransferSugarMass: Double { traySugarMix.totalMassGrams }
    private var theoTransferGelatinMass: Double { trayGelatinMix.totalMassGrams }
    private var theoTransferKSorbateSolutionMass: Double {
        let substance = trayActivationMix.components.first { $0.label == "Potassium Sorbate" }?.massGrams ?? 0
        return substance * (1.0 + systemConfig.kSorbateSolutionRatio)
    }
    private var theoTransferCitricAcidSolutionMass: Double {
        let substance = trayActivationMix.components.first { $0.label == "Citric Acid" }?.massGrams ?? 0
        return substance * (1.0 + systemConfig.citricAcidSolutionRatio)
    }
    private var theoTransferActivationMass: Double {
        let citric = trayActivationMix.components.first { $0.label == "Citric Acid" }?.massGrams ?? 0
        let ksorbate = trayActivationMix.components.first { $0.label == "Potassium Sorbate" }?.massGrams ?? 0
        return trayActivationMix.totalMassGrams - citric - ksorbate
    }

    // Experimental transfer masses — each is the difference between consecutive cumulative readings
    private var expTransferSugarMass: Double? {
        guard let sugar = viewModel.hpSubstrateSugarTransfer,
              let prev = viewModel.hpTrayTransferBeakerReading ?? viewModel.hpGelatin else { return nil }
        return sugar - prev
    }
    private var expTransferGelatinMass: Double? {
        guard let gelatin = viewModel.hpSubstrateGelatinTransfer,
              let prev = viewModel.hpSubstrateSugarTransfer else { return nil }
        return gelatin - prev
    }
    private var expTransferKSorbateMass: Double? {
        guard let ksorbate = viewModel.hpSubstrateKSorbateTransfer else { return nil }
        if let prev = viewModel.hpSubstrateGelatinTransfer { return ksorbate - prev }
        if let prev = viewModel.hpSubstrateSugarTransfer { return ksorbate - prev }
        return nil
    }
    private var expTransferCitricAcidMass: Double? {
        guard let citric = viewModel.hpSubstrateCitricAcidTransfer,
              let prev = viewModel.hpSubstrateKSorbateTransfer else { return nil }
        return citric - prev
    }
    private var expTransferActivationMass: Double? {
        guard let activation = viewModel.hpSubstrateActivationTransfer else { return nil }
        if let prev = viewModel.hpSubstrateCitricAcidTransfer { return activation - prev }
        if let prev = viewModel.hpSubstrateKSorbateTransfer { return activation - prev }
        if let prev = viewModel.hpSubstrateGelatinTransfer { return activation - prev }
        if let prev = viewModel.hpSubstrateSugarTransfer { return activation - prev }
        return nil
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Button {
                guard viewModel.batchActivated else { return }
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Experiment Data 2").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    if !viewModel.batchActivated {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(systemConfig.designAlert)
                            Text("Please activate batch")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(systemConfig.designAlert)
                        }
                    } else {
                        CMDisclosureChevron(isExpanded: isExpanded)
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded && viewModel.batchActivated {
                ThemedDivider()

                // MARK: Gelatin Mixture
                comparisonSubheader("Bulk Gelatin Mixture")
                comparisonRow("Water",
                              theoretical: theoGelatinWaterMass,
                              experimental: expGelatinWaterMass)
                comparisonRow("Gelatin",
                              theoretical: theoGelatinMass,
                              experimental: expGelatinMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Gelatin Mix Total",
                              theoretical: theoGelatinMixTotal,
                              experimental: expGelatinMixTotal,
                              bold: true)
                    .background(CMTheme.totalRowBG)

                if systemConfig.gelatinMixtureOveragePercent > 0 {
                    Text(String(format: "Gelatin theoretical values include %.0f%% overage.", systemConfig.gelatinMixtureOveragePercent))
                        .cmMono10()
                        .foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 20).padding(.top, 4)
                }

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Sugar Mixture
                comparisonSubheader("Bulk Sugar Mixture")
                comparisonRow("Water",
                              theoretical: theoSugarWaterMass,
                              experimental: expSugarWaterMass)
                comparisonRow("Glucose Syrup",
                              theoretical: theoGlucoseSyrupMass,
                              experimental: expGlucoseSyrupMass)
                comparisonRow("Granulated Sugar",
                              theoretical: theoGranulatedMass,
                              experimental: expGranulatedMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Sugar Mix Total",
                              theoretical: theoSugarMixTotal,
                              experimental: expSugarMixTotal,
                              bold: true)
                    .background(CMTheme.totalRowBG)

                if systemConfig.sugarMixtureOveragePercent > 0 {
                    Text(String(format: "Sugar theoretical values include %.0f%% overage.", systemConfig.sugarMixtureOveragePercent))
                        .cmMono10()
                        .foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 20).padding(.top, 4)
                }

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Activation Mixture
                comparisonSubheader("Activation Mixture")
                comparisonRow(viewModel.selectedActive == .lsd ? "LSD Tabs in Water" : "Active",
                              theoretical: 0,
                              experimental: expActiveMass)
                comparisonRow(viewModel.selectedActive == .lsd ? "LSD 1:1 Solution" : "Activation Water",
                              theoretical: theoActivationWaterMass,
                              experimental: expActivationWaterMass)
                comparisonRow("Flavor Oils",
                              theoretical: theoFlavorOilsMass,
                              experimental: expFlavorOilsMass)
                comparisonRow("Terps",
                              theoretical: theoTerpsMass,
                              experimental: expTerpsMass)
                comparisonRow("Color",
                              theoretical: theoColorMass,
                              experimental: expColorMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Activation Mix Total",
                              theoretical: theoActivationMixTotal,
                              experimental: expActivationMixTotal,
                              bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Tray Transfers
                comparisonSubheader("Tray Transfers")
                comparisonRow("Beaker",
                              theoretical: theoTransferBeakerTare,
                              experimental: expTransferBeakerMass)
                comparisonRow("+ Sugar Mixture",
                              theoretical: theoTransferSugarMass,
                              experimental: expTransferSugarMass)
                comparisonRow("+ Gelatin Mix",
                              theoretical: theoTransferGelatinMass,
                              experimental: expTransferGelatinMass)
                comparisonRow(String(format: "+ KSorbate 1:%.0f", systemConfig.kSorbateSolutionRatio),
                              theoretical: theoTransferKSorbateSolutionMass,
                              experimental: expTransferKSorbateMass)
                comparisonRow(String(format: "+ Citric Acid 1:%.0f", systemConfig.citricAcidSolutionRatio),
                              theoretical: theoTransferCitricAcidSolutionMass,
                              experimental: expTransferCitricAcidMass)
                comparisonRow("+ Activation Mixture",
                              theoretical: theoTransferActivationMass,
                              experimental: expTransferActivationMass)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Mixture Densities
                densitySubheader("Mixture Densities")
                densityRow("Gelatin Mix",
                           theoretical: theoGelatinMixDensity,
                           experimental: viewModel.calcGelatinMixDensity)
                densityRow("Sugar Mix",
                           theoretical: theoSugarMixDensity,
                           experimental: viewModel.calcSugarMixDensity)
                densityRow("Activation Mix",
                           theoretical: theoActivationMixDensity,
                           experimental: viewModel.calcActiveMixDensity)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                densityRow("Gummy Mixture",
                           theoretical: theoFinalMixDensity,
                           experimental: viewModel.calcDensityFinalMix(systemConfig: systemConfig),
                           bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Losses
                lossesSubheader("Losses")
                lossRow("Beaker Residue",
                        value: calcHPBeakerResidue,
                        subtitle: "residue reading − substrate beaker tare")
                lossRow("Activation Tray Residue",
                        value: calcActivationTrayResidue)
                lossRow("Syringe Residue",
                        value: calcSyringeResidue)
                lossRow("Tray Residue",
                        value: calcTrayResidue)
                lossRow("Extra Gummy Mixture",
                        value: viewModel.extraGummyMixGrams)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                lossRow("Total Losses",
                        value: totalLossMass,
                        subtitle: lossesRecordedCount > 0 && lossesRecordedCount < lossesTotalCount
                            ? "\(lossesRecordedCount) of \(lossesTotalCount) sources recorded"
                            : nil,
                        bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Active Lost
                activeLostSubheader("Active Lost")
                lossRow("Gummy Mixture Mass",
                        value: hpGummyMixtureMass)
                lossRow("Total Active",
                        value: totalActiveAmount,
                        unit: viewModel.units.rawValue)
                lossRow("Total Losses",
                        value: totalLossMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                lossRow("Active Lost",
                        value: activeLostInLosses,
                        unit: viewModel.units.rawValue,
                        bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Gummies
                gummySubheader("Gummies")
                gummyRow("Volume",
                         theoretical: theoGummyVolume,
                         experimental: expGummyVolume,
                         unit: "mL",
                         format: "%.3f")
                gummyRow("Mass",
                         theoretical: theoGummyMass,
                         experimental: expGummyMass,
                         unit: "g",
                         format: "%.3f")
                gummyRow("Concentration",
                         theoretical: theoGummyConcentration,
                         experimental: expGummyConcentration,
                         unit: viewModel.units.rawValue,
                         format: "%.3f")
                massFractionRow("Citric Acid",
                                theoretical: theoCitricAcidFraction,
                                experimental: expCitricAcidFraction)
                massFractionRow("K Sorbate",
                                theoretical: theoKSorbateFraction,
                                experimental: expKSorbateFraction)
                massFractionRow("Gelatin",
                                theoretical: theoGelatinFraction,
                                experimental: expGelatinFraction)

                if !hasAnyData {
                    Text("Record high-precision weight measurements to populate experimental data.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.top, 8)
                }

                Spacer().frame(height: 12)
            }
        }
        .onChange(of: viewModel.batchActivated) { _, activated in
            if !activated { withAnimation(.cmSpring) { isExpanded = false } }
        }
    }

    private var hasAnyData: Bool {
        expGelatinMass != nil || expGranulatedMass != nil || expActiveMass != nil
        || viewModel.calcGelatinMixDensity != nil || viewModel.calcSugarMixDensity != nil
        || viewModel.calcActiveMixDensity != nil || viewModel.calcDensityFinalMix(systemConfig: systemConfig) != nil
    }

    // MARK: - Sub-views

    private func comparisonSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("theo (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("exp (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func comparisonRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?,
        bold: Bool = false
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = (theoretical > 0) ? delta.map { ($0 / theoretical) * 100.0 } : nil

        return HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()

            // Theoretical (g)
            Text(String(format: "%.3f", theoretical))
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth, alignment: .trailing)

            // Experimental (g)
            Text(experimental.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)

            // Difference (g)
            Group {
                if let d = delta {
                    Text(String(format: "%+.3f", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth, alignment: .trailing)

            // Difference (%)
            Group {
                if let p = pctError {
                    Text(String(format: "%+.2f", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    /// Color based on magnitude of percent error: green ≤2%, yellow 2–5%, red >5%
    private func errorColor(pct: Double) -> Color {
        if pct <= 2.0 {
            return CMTheme.success
        } else if pct <= 5.0 {
            return systemConfig.designSecondaryAccent
        } else {
            return systemConfig.designAlert
        }
    }

    // MARK: - Density sub-views

    private func densitySubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("theo (g/mL)")
                .cmFinePrint()
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("exp (g/mL)")
                .cmFinePrint()
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("Δ (g/mL)")
                .cmFinePrint()
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func densityRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?,
        bold: Bool = false
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()

            // Theoretical (g/mL)
            Text(String(format: "%.4f", theoretical))
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth + 6, alignment: .trailing)

            // Experimental (g/mL)
            Text(experimental.map { String(format: "%.4f", $0) } ?? "—")
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth + 6, alignment: .trailing)

            // Difference (g/mL)
            Group {
                if let d = delta {
                    Text(String(format: "%+.4f", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth + 6, alignment: .trailing)

            // Difference (%)
            Group {
                if let p = pctError {
                    Text(String(format: "%+.2f", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    // MARK: - Losses sub-views

    private func lossesSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("exp (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            // Spacer for unit column alignment
            Text("")
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func lossRow(
        _ label: String,
        value: Double?,
        subtitle: String? = nil,
        unit: String = "g",
        bold: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .cmMono12()
                    .fontWeight(bold ? .bold : .regular)
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)
            Text(unit)
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmDataRowPadding()
    }

    private func activeLostSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    // MARK: - Gummy sub-views

    private func gummySubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("theo")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("exp")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func gummyRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?,
        unit: String,
        format: String = "%.3f",
        pctFormat: String = "%.2f"
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text("\(label) (\(unit))")
                .cmMono12()
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()

            // Theoretical
            Text(String(format: format, theoretical))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth, alignment: .trailing)

            // Experimental
            Text(experimental.map { String(format: format, $0) } ?? "—")
                .cmMono12()
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)

            // Difference (quantity)
            Group {
                if let d = delta {
                    Text(String(format: "%+\(format.dropFirst())", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)

            // Relative % error
            Group {
                if let p = pctError {
                    Text(String(format: "%+\(pctFormat.dropFirst())", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    /// Row for mass fraction comparison: theo (%), exp (%), "—" for Δ quantity, Δ (%) relative error.
    private func massFractionRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = experimental.map { theoretical > 0 ? (($0 - theoretical) / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text("\(label) (%)")
                .cmMono12()
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()

            // Theoretical (%)
            Text(String(format: "%.3f", theoretical))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth, alignment: .trailing)

            // Experimental (%)
            Text(experimental.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)

            // Δ quantity (percentage points)
            Group {
                if let d = delta {
                    Text(String(format: "%+.3f", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)

            // Relative % error
            Group {
                if let p = pctError {
                    Text(String(format: "%+.2f", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }
}
