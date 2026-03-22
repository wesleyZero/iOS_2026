//
//  SigFigsCardView.swift
//  CandyMan
//
//  Collapsible card displaying live significant-figures propagation for every
//  derived quantity in the batch. Uses SigFigLiveAudit to pull per-field SF
//  counts, then applies standard mul/div and add/sub propagation rules to show
//  how measurement precision flows through the calculation chain — from input
//  mixtures through losses, preservatives, densities, and per-gummy results.
//
//  Color-coded: green (>2 SF) vs warm accent (≤2 SF) for quick visual audit.
//

import SwiftUI

// MARK: - SigFigsCardView

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
                        .cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                sigFigsContent
                    .cmExpandTransition()
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

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // Final Mixture
            sfSubheader("Final Mixture")
            sfRow("Final Mixture in Beaker", info: audit.sfFinalMixture)
            sfRow("Final Mixture in Tray/s", sfInt: sfMixTransferredToMold(audit: audit))

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // Losses
            sfSubheader("Losses")
            sfRow("Beaker Residue",          info: audit.sfBeakerResidueCalc)
            sfRow("Syringe Residue",         info: audit.sfSyringeResidueCalc)
            sfRow("Total Residue",           sfInt: audit.sfTotalLoss)
            sfRow("Active Loss",             sfInt: sfActiveLossCalc(audit: audit))

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // Preservatives
            sfSubheader("Preservatives")
            sfRow("K-Sorbate Mass Fraction", sfInt: sfMassFractionCalc(numeratorSF: 2, audit: audit))
            sfRow("Citric Acid Mass Fraction", sfInt: sfMassFractionCalc(numeratorSF: 3, audit: audit))

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // Mixture Densities
            sfSubheader("Mixture Densities")
            sfRow("Gummy Mixture Density",   sfInt: audit.sfDensityFinalMix)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // Gummies
            sfSubheader("Gummies")
            sfRow("Average Gummy Mass",      sfInt: sfAvgGummyMassCalc(audit: audit))
            sfRow("Average Gummy Volume",    sfInt: sfAvgGummyVolumeCalc(audit: audit))
            sfRow("Average Gummy Active Dose", sfInt: sfAvgGummyActiveDoseCalc(audit: audit))

            ThemedDivider(indent: 20).padding(.vertical, 8)

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

    private func sfMassFractionCalc(numeratorSF: Int, audit: SigFigLiveAudit) -> Int? {
        guard let fmSF = audit.sfFinalMixture?.sigFigs else { return nil }
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
        let moldVolSF = SigFigs.count(from: String(format: "%.3f", systemConfig.spec(for: viewModel.selectedShape).volumeML)).sigFigs
        return min(volSF, moldVolSF)
    }

    // MARK: - UI Helpers

    private func sfSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
        }
        .cmSubsectionPadding()
    }

    private func sfRow(_ label: String, info: SigFigInfo?) -> some View {
        sfRow(label, sfInt: info?.sigFigs)
    }

    private func sfRow(_ label: String, sfInt: Int?) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            Group {
                if let sf = sfInt {
                    Text("\(sf) SF")
                        .cmMono12()
                        .foregroundStyle(sf <= 2 ? systemConfig.designSecondaryAccent : CMTheme.success)
                } else {
                    Text("—")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
        }
        .cmDataRowPadding()
    }
}
