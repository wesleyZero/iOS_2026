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
    private let colWidth: CGFloat = 58

    // MARK: - Theoretical (from BatchCalculator)

    private var result: BatchResult {
        BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
    }

    private var sugarOverage: Double {
        1.0 + systemConfig.sugarMixtureOveragePercent / 100.0
    }

    // Gelatin Mix theoretical sub-components
    private var theoGelatinMass: Double { result.gelatinMix.components[0].massGrams }
    private var theoGelatinWaterMass: Double { result.gelatinMix.components[1].massGrams }
    private var theoGelatinMixTotal: Double { result.gelatinMix.totalMassGrams }

    // Sugar Mix theoretical sub-components (with overage applied)
    // Components order: [0] Glucose Syrup, [1] Granulated Sugar, [2] Water
    private var theoGlucoseSyrupMass: Double { result.sugarMix.components[0].massGrams * sugarOverage }
    private var theoGranulatedMass: Double { result.sugarMix.components[1].massGrams * sugarOverage }
    private var theoSugarWaterMass: Double { result.sugarMix.components[2].massGrams * sugarOverage }
    private var theoSugarMixTotal: Double { result.sugarMix.totalMassGrams * sugarOverage }

    // Activation Mix theoretical sub-components (found by label)
    private var theoCitricAcidMass: Double {
        result.activationMix.components.first { $0.label == "Citric Acid" }?.massGrams ?? 0
    }
    private var theoActivationWaterMass: Double {
        result.activationMix.components.first { $0.label == "Activation Water" }?.massGrams ?? 0
    }
    private var theoKSorbateMass: Double {
        result.activationMix.components.first { $0.label == "Potassium Sorbate" }?.massGrams ?? 0
    }
    private var theoFlavorOilsTerpsMass: Double {
        result.activationMix.totalMassGrams - theoCitricAcidMass - theoActivationWaterMass - theoKSorbateMass
    }
    private var theoActivationMixTotal: Double { result.activationMix.totalMassGrams }

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

    /// Sum of all measured losses (beaker residue + activation tray residue +
    /// syringe residue + tray residue + extra gummy mix).
    private var totalLossMass: Double? {
        let beaker    = calcHPBeakerResidue
        let actTray   = calcActivationTrayResidue
        let syringe   = calcSyringeResidue
        let tray      = calcTrayResidue
        let extra     = viewModel.extraGummyMixGrams

        let values = [beaker, actTray, syringe, tray, extra]
        let available = values.compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +)
    }

    /// Syringe residue = syringe residue reading − syringe tare (transfer syringe).
    private var calcSyringeResidue: Double? {
        guard let residue = viewModel.weightSyringeResidue else { return nil }
        let syringeID = viewModel.hpTransferSyringeID ?? systemConfig.syringes.first?.id
        let tare = syringeID.map { systemConfig.syringeTare(for: $0) } ?? 0
        return residue - tare
    }

    /// Net gummy mixture mass from HP flow (activation transfer − substrate tare).
    private var hpGummyMixtureMass: Double? {
        guard let transfer = viewModel.hpSubstrateActivationTransfer else { return nil }
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
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

    /// Theoretical volume per gummy = mold cavity volume (mL).
    private var theoGummyVolume: Double {
        systemConfig.spec(for: viewModel.selectedShape).volumeML
    }

    /// Theoretical mass per gummy = total batch mass (no overage) / total gummies.
    /// Uses vBase (neat target volume) with the theoretical final mix density.
    private var theoGummyMass: Double {
        let gummies = Double(viewModel.totalGummies(using: systemConfig))
        guard gummies > 0 else { return 0 }
        return result.totalMassGrams / gummies
    }

    /// Theoretical active concentration per gummy = user-configured dose.
    private var theoGummyConcentration: Double {
        viewModel.activeConcentration
    }

    // MARK: - Gummy Properties (Experimental)

    /// Experimental mass per gummy from HP data:
    /// (gummyMixtureMass − totalLosses) / moldsFilled
    private var expGummyMass: Double? {
        guard let mixMass = hpGummyMixtureMass,
              let losses = totalLossMass,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        return (mixMass - losses) / molds
    }

    /// Experimental volume per gummy = expGummyMass / experimental final density.
    private var expGummyVolume: Double? {
        guard let mass = expGummyMass,
              let density = viewModel.calcDensityFinalMix(systemConfig: systemConfig),
              density > 0 else { return nil }
        return mass / density
    }

    /// Experimental active concentration per gummy = avgGummyDoseAfterLoss (already computed).
    private var expGummyConcentration: Double? {
        avgGummyDoseAfterLoss
    }

    // MARK: - Preservative Mass Fractions

    /// Theoretical citric acid mass fraction (%) = citric acid mass / total batch mass × 100.
    private var theoCitricAcidFraction: Double {
        let total = result.totalMassGrams
        guard total > 0 else { return 0 }
        return (theoCitricAcidMass / total) * 100.0
    }

    /// Experimental citric acid mass fraction (%) = measured citric acid / gummy mixture mass × 100.
    private var expCitricAcidFraction: Double? {
        guard let citric = expCitricAcidMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (citric / mixMass) * 100.0
    }

    /// Theoretical potassium sorbate mass fraction (%) = K sorbate mass / total batch mass × 100.
    private var theoKSorbateFraction: Double {
        let total = result.totalMassGrams
        guard total > 0 else { return 0 }
        return (theoKSorbateMass / total) * 100.0
    }

    /// Experimental potassium sorbate mass fraction (%) = measured K sorbate / gummy mixture mass × 100.
    private var expKSorbateFraction: Double? {
        guard let ksorbate = expKSorbateMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (ksorbate / mixMass) * 100.0
    }

    /// Theoretical gelatin mass fraction (%) = gelatin mass / total batch mass × 100.
    private var theoGelatinFraction: Double {
        let total = result.totalMassGrams
        guard total > 0 else { return 0 }
        return (theoGelatinMass / total) * 100.0
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
    private var expGelatinMass: Double? {
        viewModel.hpIndividualGelatin(systemConfig: systemConfig)
    }
    private var expGelatinWaterMass: Double? {
        viewModel.hpIndividualGelatinWater
    }
    private var expGelatinMixTotal: Double? {
        guard let g = expGelatinMass, let w = expGelatinWaterMass else { return nil }
        return g + w
    }

    // Sugar
    private var expGranulatedMass: Double? {
        viewModel.hpIndividualGranulated(systemConfig: systemConfig)
    }
    private var expGlucoseSyrupMass: Double? {
        viewModel.hpIndividualGlucoseSyrup
    }
    private var expSugarWaterMass: Double? {
        viewModel.hpIndividualSugarWater
    }
    private var expSugarMixTotal: Double? {
        guard let g = expGranulatedMass, let gl = expGlucoseSyrupMass, let w = expSugarWaterMass else { return nil }
        return g + gl + w
    }

    // Activation
    private var expCitricAcidMass: Double? {
        viewModel.hpIndividualCitricAcid(systemConfig: systemConfig)
    }
    private var expActivationWaterMass: Double? {
        viewModel.hpIndividualActivationWater
    }
    private var expKSorbateMass: Double? {
        viewModel.hpIndividualKSorbate
    }
    private var expFlavorOilsTerpsMass: Double? {
        viewModel.hpIndividualFlavorOilsTerpsActive
    }
    private var expActivationMixTotal: Double? {
        guard let c = expCitricAcidMass, let w = expActivationWaterMass,
              let k = expKSorbateMass, let f = expFlavorOilsTerpsMass else { return nil }
        return c + w + k + f
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
                comparisonSubheader("Gelatin Mixture")
                comparisonRow("Gelatin",
                              theoretical: theoGelatinMass,
                              experimental: expGelatinMass)
                comparisonRow("Water",
                              theoretical: theoGelatinWaterMass,
                              experimental: expGelatinWaterMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Gelatin Mix Total",
                              theoretical: theoGelatinMixTotal,
                              experimental: expGelatinMixTotal,
                              bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Sugar Mixture
                comparisonSubheader("Sugar Mixture")
                comparisonRow("Granulated Sugar",
                              theoretical: theoGranulatedMass,
                              experimental: expGranulatedMass)
                comparisonRow("Glucose Syrup",
                              theoretical: theoGlucoseSyrupMass,
                              experimental: expGlucoseSyrupMass)
                comparisonRow("Water",
                              theoretical: theoSugarWaterMass,
                              experimental: expSugarWaterMass)
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
                comparisonRow("Citric Acid",
                              theoretical: theoCitricAcidMass,
                              experimental: expCitricAcidMass)
                comparisonRow("Activation Water",
                              theoretical: theoActivationWaterMass,
                              experimental: expActivationWaterMass)
                comparisonRow("K Sorbate",
                              theoretical: theoKSorbateMass,
                              experimental: expKSorbateMass)
                comparisonRow("Oils/Terps/Active",
                              theoretical: theoFlavorOilsTerpsMass,
                              experimental: expFlavorOilsTerpsMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Activation Mix Total",
                              theoretical: theoActivationMixTotal,
                              experimental: expActivationMixTotal,
                              bold: true)
                    .background(CMTheme.totalRowBG)

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
        expGelatinMass != nil || expGranulatedMass != nil || expCitricAcidMass != nil
        || viewModel.calcGelatinMixDensity != nil || viewModel.calcSugarMixDensity != nil
        || viewModel.calcActiveMixDensity != nil || viewModel.calcDensityFinalMix(systemConfig: systemConfig) != nil
    }

    // MARK: - Sub-views

    private func comparisonSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
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
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

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
            Spacer()
            Text("theo (g/mL)")
                .cmFinePrint()
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("exp (g/mL)")
                .cmFinePrint()
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("Δ (g/mL)")
                .cmFinePrint()
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
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    // MARK: - Gummy sub-views

    private func gummySubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
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

            // Δ quantity — not applicable for mass fractions
            Text("—")
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
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
