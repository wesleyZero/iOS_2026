import SwiftUI

struct SigFigsCardView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Significant Figures")
                        .font(.headline)
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                        .animation(.cmExpand, value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                sigFigsContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
                Spacer(minLength: 12)
            }
        }
    }

    // MARK: - Sig Figs Content

    private var sigFigsContent: some View {
        let audit = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig)
        return VStack(spacing: 0) {
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

    private func sfMixTransferredToMold(audit: SigFigLiveAudit) -> Int? {
        guard let fmInfo = audit.sfFinalMixture,
              let brInfo = audit.sfBeakerResidueCalc,
              let srInfo = audit.sfSyringeResidueCalc else { return nil }
        return SigFigs.addSubtract(fmInfo, brInfo, srInfo)
    }

    private func sfActiveLossCalc(audit: SigFigLiveAudit) -> Int? {
        guard let totalLossSF = audit.sfTotalLoss,
              let fmSF = audit.sfFinalMixture?.sigFigs else { return nil }
        return min(totalLossSF, fmSF)
    }

    private func sfMassFractionCalc(numeratorSF: Int) -> Int? {
        guard let fmSF = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig).sfFinalMixture?.sigFigs else { return nil }
        return min(numeratorSF, fmSF)
    }

    private func sfAvgGummyMassCalc(audit: SigFigLiveAudit) -> Int? {
        guard let transferredSF = sfMixTransferredToMold(audit: audit),
              let moldsSF = audit.sfMoldsFilled?.sigFigs else { return nil }
        return min(transferredSF, moldsSF)
    }

    private func sfAvgGummyVolumeCalc(audit: SigFigLiveAudit) -> Int? {
        guard let massSF = sfAvgGummyMassCalc(audit: audit),
              let densitySF = audit.sfDensityFinalMix else { return nil }
        return min(massSF, densitySF)
    }

    private func sfAvgGummyActiveDoseCalc(audit: SigFigLiveAudit) -> Int? {
        guard let activeLossSF = sfActiveLossCalc(audit: audit),
              let moldsSF = audit.sfMoldsFilled?.sigFigs else { return nil }
        return min(activeLossSF, moldsSF)
    }

    private func sfOverageForNextBatchCalc(audit: SigFigLiveAudit) -> Int? {
        guard let volSF = sfAvgGummyVolumeCalc(audit: audit) else { return nil }
        let moldVolSF = SigFigs.count(from: String(format: "%.3f", systemConfig.spec(for: viewModel.selectedShape).volume_ml)).sigFigs
        return min(volSF, moldVolSF)
    }

    // MARK: - UI Helpers

    private func sfSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(CMTheme.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 24).padding(.top, 6).padding(.bottom, 1)
    }

    private func sfRow(_ label: String, info: SigFigInfo?) -> some View {
        sfRow(label, sfInt: info?.sigFigs)
    }

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
