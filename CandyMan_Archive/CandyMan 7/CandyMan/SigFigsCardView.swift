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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
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

    // MARK: - Content

    private var sigFigsContent: some View {
        let audit = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig)
        return VStack(spacing: 0) {
            sectionHeader("Input Mixtures")
            figureRow("Gelatin Mix Added",       info: audit.sfGelatinAdded)
            figureRow("Sugar Mix Added",         info: audit.sfSugarAdded)
            figureRow("Activation Mix Added",    info: audit.sfActiveAdded)

            sectionHeader("Final Mixture")
            figureRow("Final Mixture in Beaker", info: audit.sfFinalMixture)
            figureRow("Final Mixture in Tray/s", figures: mixTransferredToMoldFigures(audit: audit))

            sectionHeader("Losses")
            figureRow("Beaker Residue",          info: audit.sfBeakerResidueCalc)
            figureRow("Syringe Residue",         info: audit.sfSyringeResidueCalc)
            figureRow("Total Residue",           figures: audit.sfTotalLoss)
            figureRow("Active Loss",             figures: activeLossFigures(audit: audit))

            sectionHeader("Preservatives")
            figureRow("K-Sorbate Mass Fraction", figures: massFractionFigures(numeratorFigures: 2))
            figureRow("Citric Acid Mass Fraction", figures: massFractionFigures(numeratorFigures: 3))

            sectionHeader("Mixture Densities")
            figureRow("Gummy Mixture Density",   figures: audit.sfDensityFinalMix)

            sectionHeader("Gummies")
            figureRow("Average Gummy Mass",      figures: averageGummyMassFigures(audit: audit))
            figureRow("Average Gummy Volume",    figures: averageGummyVolumeFigures(audit: audit))
            figureRow("Average Gummy Active Dose", figures: averageGummyActiveDoseFigures(audit: audit))

            sectionHeader("Overage")
            figureRow("Overage for Next Batch",  figures: overageForNextBatchFigures(audit: audit))
        }
    }

    // MARK: - Sig Fig Propagation

    private func mixTransferredToMoldFigures(audit: SigFigLiveAudit) -> Int? {
        guard let finalMixInfo = audit.sfFinalMixture,
              let beakerResidueInfo = audit.sfBeakerResidueCalc,
              let syringeResidueInfo = audit.sfSyringeResidueCalc else { return nil }
        return SigFigs.addSubtract(finalMixInfo, beakerResidueInfo, syringeResidueInfo)
    }

    private func activeLossFigures(audit: SigFigLiveAudit) -> Int? {
        guard let totalLossFigures = audit.sfTotalLoss,
              let finalMixFigures = audit.sfFinalMixture?.sigFigs else { return nil }
        return min(totalLossFigures, finalMixFigures)
    }

    private func massFractionFigures(numeratorFigures: Int) -> Int? {
        guard let finalMixFigures = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig).sfFinalMixture?.sigFigs else { return nil }
        return min(numeratorFigures, finalMixFigures)
    }

    private func averageGummyMassFigures(audit: SigFigLiveAudit) -> Int? {
        guard let transferredFigures = mixTransferredToMoldFigures(audit: audit),
              let moldsFilledFigures = audit.sfMoldsFilled?.sigFigs else { return nil }
        return min(transferredFigures, moldsFilledFigures)
    }

    private func averageGummyVolumeFigures(audit: SigFigLiveAudit) -> Int? {
        guard let massFigures = averageGummyMassFigures(audit: audit),
              let densityFigures = audit.sfDensityFinalMix else { return nil }
        return min(massFigures, densityFigures)
    }

    private func averageGummyActiveDoseFigures(audit: SigFigLiveAudit) -> Int? {
        guard let activeLoss = activeLossFigures(audit: audit),
              let moldsFilledFigures = audit.sfMoldsFilled?.sigFigs else { return nil }
        return min(activeLoss, moldsFilledFigures)
    }

    private func overageForNextBatchFigures(audit: SigFigLiveAudit) -> Int? {
        guard let volumeFigures = averageGummyVolumeFigures(audit: audit) else { return nil }
        let moldVolumeFigures = SigFigs.count(from: String(format: "%.3f", systemConfig.spec(for: viewModel.selectedShape).volume_ml)).sigFigs
        return min(volumeFigures, moldVolumeFigures)
    }

    // MARK: - UI Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(CMTheme.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 24).padding(.top, 6).padding(.bottom, 1)
    }

    private func figureRow(_ label: String, info: SigFigInfo?) -> some View {
        figureRow(label, figures: info?.sigFigs)
    }

    private func figureRow(_ label: String, figures: Int?) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Group {
                if let count = figures {
                    Text("\(count) SF")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(count <= 2 ? CMTheme.accentWarm : CMTheme.success)
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
