import SwiftUI

struct MeasurementCalculationsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    // MARK: - Derived Measurements

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

    private var massTotalLoss: Double? {
        guard let br = massBeakerResidue,
              let sr = massSyringeResidue else { return nil }
        return br + sr
    }

    private var massMixTransferredToMold: Double? {
        guard let finalMix = massFinalMixtureInBeaker,
              let totalLoss = massTotalLoss else { return nil }
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
        guard let totalLoss = massTotalLoss,
              let finalMix  = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let totalActive = viewModel.activeConcentration * Double(spec.count * viewModel.trayCount)
        return totalActive * (totalLoss / finalMix)
    }

    /// Average active dose per gummy = (totalActive - activeLoss) / moldsFilled
    private var averageGummyActiveDose: Double? {
        guard let loss  = activeLoss,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let totalActive = viewModel.activeConcentration * Double(spec.count * viewModel.trayCount)
        return (totalActive - loss) / molds
    }

    /// Theoretical mass of potassium sorbate from the batch calculation
    private var massPotassiumSorbate: Double? {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        return result.activationMix.components.first(where: { $0.label == "Potassium Sorbate" })?.mass_g
    }

    /// Theoretical mass of citric acid from the batch calculation
    private var massCitricAcid: Double? {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        return result.activationMix.components.first(where: { $0.label == "Citric Acid" })?.mass_g
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
        guard spec.volume_ml > 0 else { return nil }
        return avgVol / spec.volume_ml
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ThemedDivider()

            // MARK: Input Mixtures
            subsectionHeader("Input Mixtures")
            calcRow("Gelatin Mix Added",     value: massGelatinAdded,  unit: "g")
            calcRow("Sugar Mix Added",        value: massSugarAdded,    unit: "g")
            calcRow("Activation Mix Added",   value: massActiveAdded,   unit: "g")

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Final Mixture
            subsectionHeader("Final Mixture")
            calcRow("Final Mixture in Beaker",       value: massFinalMixtureInBeaker,  unit: "g")
            calcRow("Final Mixture in Tray/s",       value: massMixTransferredToMold,  unit: "g")

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Losses
            subsectionHeader("Losses")
            calcRow("Beaker Residue",                value: massBeakerResidue,         unit: "g")
            calcRow("Syringe Residue",               value: massSyringeResidue,        unit: "g")
            calcRow("Total Residue",                 value: massTotalLoss,             unit: "g")
            calcRow("Lost \(viewModel.selectedActive.rawValue) in Residue", value: activeLoss, unit: viewModel.units.rawValue)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Preservatives
            subsectionHeader("Preservatives")
            calcRow("Potassium Sorbate Mass Fraction",  value: massFractionPotassiumSorbate,  unit: "%", decimals: 4)
            calcRow("Citric Acid Mass Fraction",        value: massFractionCitricAcid,        unit: "%", decimals: 4)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Mixture Densities
            subsectionHeader("Mixture Densities")
            calcRow("Sugar Mix Density",      value: viewModel.calcSugarMixDensity,    unit: "g/mL", decimals: 4)
            calcRow("Gelatin Mix Density",    value: viewModel.calcGelatinMixDensity,  unit: "g/mL", decimals: 4)
            calcRow("Activation Mix Density", value: viewModel.calcActiveMixDensity,   unit: "g/mL", decimals: 4)
            calcRow("Gummy Mixture Density",  value: densityFinalMix,                  unit: "g/mL", decimals: 4)

            if let density = densityFinalMix, density > 0 {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { systemConfig.estimatedFinalMixDensity = density }
                } label: {
                    Text("Use as Estimated ρ")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            abs(systemConfig.estimatedFinalMixDensity - density) < 0.0001
                                ? CMTheme.textTertiary
                                : systemConfig.accent
                        )
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 4)
            }

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Gummies
            subsectionHeader("Gummies")
            calcRow("Average Gummy Mass",            value: massPerGummyMold,        unit: "g")
            calcRow("Average Gummy Volume",          value: averageGummyVolume,      unit: "mL", decimals: 4)
            calcRow("Average Gummy Active Dose",     value: averageGummyActiveDose,  unit: viewModel.units.rawValue)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Overage
            subsectionHeader("Overage")
            calcRow("Overage for Next Batch",       value: overageForNextBatch,     unit: "", decimals: 4)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Significant Figures
            sigFigsSection

            Spacer(minLength: 12)
        }
    }

    // MARK: - Sig Figs Section

    private var sigFigsSection: some View {
        let audit = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig)
        return VStack(spacing: 0) {
            subsectionHeader("Significant Figures")

            // Input Mixtures
            sfSubheader("Input Mixtures")
            sfRow("Gelatin Mix Added",       info: audit.sfGelatinAdded)
            sfRow("Sugar Mix Added",         info: audit.sfSugarAdded)
            sfRow("Activation Mix Added",    info: audit.sfActiveAdded)

            // Final Mixture
            sfSubheader("Final Mixture")
            sfRow("Final Mixture in Beaker", info: audit.sfFinalMixture)
            sfRow("Final Mixture in Tray/s", sfInt: sfMixTransferredToMold(audit: audit))

            // Losses
            sfSubheader("Losses")
            sfRow("Beaker Residue",          info: audit.sfBeakerResidueCalc)
            sfRow("Syringe Residue",         info: audit.sfSyringeResidueCalc)
            sfRow("Total Residue",           sfInt: audit.sfTotalLoss)
            sfRow("Active Loss",             sfInt: sfActiveLossCalc(audit: audit))

            // Preservatives
            sfSubheader("Preservatives")
            sfRow("K-Sorbate Mass Fraction", sfInt: sfMassFractionCalc(numeratorSF: 2))
            sfRow("Citric Acid Mass Fraction", sfInt: sfMassFractionCalc(numeratorSF: 3))

            // Mixture Densities
            sfSubheader("Mixture Densities")
            sfRow("Gummy Mixture Density",   sfInt: audit.sfDensityFinalMix)

            // Gummies
            sfSubheader("Gummies")
            sfRow("Average Gummy Mass",      sfInt: sfAvgGummyMassCalc(audit: audit))
            sfRow("Average Gummy Volume",    sfInt: sfAvgGummyVolumeCalc(audit: audit))
            sfRow("Average Gummy Active Dose", sfInt: sfAvgGummyActiveDoseCalc(audit: audit))

            // Overage
            sfSubheader("Overage")
            sfRow("Overage for Next Batch",  sfInt: sfOverageForNextBatchCalc(audit: audit))
        }
    }

    // MARK: - Sig Fig Propagation Helpers

    /// Mix transferred = finalMixture - totalLoss (subtraction)
    private func sfMixTransferredToMold(audit: SigFigLiveAudit) -> Int? {
        guard let fmInfo = audit.sfFinalMixture,
              let brInfo = audit.sfBeakerResidueCalc,
              let srInfo = audit.sfSyringeResidueCalc else { return nil }
        return SigFigs.addSubtract(fmInfo, brInfo, srInfo)
    }

    /// Active loss = totalActive × (totalLoss / finalMixture) — chain of mult/div
    private func sfActiveLossCalc(audit: SigFigLiveAudit) -> Int? {
        guard let totalLossSF = audit.sfTotalLoss,
              let fmSF = audit.sfFinalMixture?.sigFigs else { return nil }
        return min(totalLossSF, fmSF)
    }

    /// Mass fraction = (theoretical component mass / finalMixture) × 100
    private func sfMassFractionCalc(numeratorSF: Int) -> Int? {
        guard let fmSF = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig).sfFinalMixture?.sigFigs else { return nil }
        return min(numeratorSF, fmSF)
    }

    /// Avg gummy mass = transferred / molds (division)
    private func sfAvgGummyMassCalc(audit: SigFigLiveAudit) -> Int? {
        guard let transferredSF = sfMixTransferredToMold(audit: audit),
              let moldsSF = audit.sfMoldsFilled?.sigFigs else { return nil }
        return min(transferredSF, moldsSF)
    }

    /// Avg gummy volume = massPerGummy / density (division)
    private func sfAvgGummyVolumeCalc(audit: SigFigLiveAudit) -> Int? {
        guard let massSF = sfAvgGummyMassCalc(audit: audit),
              let densitySF = audit.sfDensityFinalMix else { return nil }
        return min(massSF, densitySF)
    }

    /// Avg gummy active dose = (totalActive - activeLoss) / molds
    private func sfAvgGummyActiveDoseCalc(audit: SigFigLiveAudit) -> Int? {
        guard let activeLossSF = sfActiveLossCalc(audit: audit),
              let moldsSF = audit.sfMoldsFilled?.sigFigs else { return nil }
        return min(activeLossSF, moldsSF)
    }

    /// Overage for next batch = avgGummyVolume / volumePerWell (division)
    private func sfOverageForNextBatchCalc(audit: SigFigLiveAudit) -> Int? {
        guard let volSF = sfAvgGummyVolumeCalc(audit: audit) else { return nil }
        let moldVolSF = SigFigs.count(from: String(format: "%.3f", systemConfig.spec(for: viewModel.selectedShape).volume_ml)).sigFigs
        return min(volSF, moldVolSF)
    }

    // MARK: - Helpers

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func calcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Group {
                if let v = value {
                    Text(String(format: "%.\(decimals)f", v))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("—")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            Text(unit)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 5)
    }

    private func sfSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(CMTheme.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 24).padding(.top, 6).padding(.bottom, 1)
    }

    /// Row showing a label and its sig fig count from a SigFigInfo.
    private func sfRow(_ label: String, info: SigFigInfo?) -> some View {
        sfRow(label, sfInt: info?.sigFigs)
    }

    /// Row showing a label and its sig fig count from an Int.
    private func sfRow(_ label: String, sfInt: Int?) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Group {
                if let sf = sfInt {
                    Text("\(sf) SF")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(sf <= 2 ? CMTheme.accentWarm : CMTheme.success)
                } else {
                    Text("—")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 3)
    }
}
