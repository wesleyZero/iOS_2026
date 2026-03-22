//
//  ErrorAnalysisView.swift
//  CandyMan
//
//  Collapsible card comparing theoretical (calculated) masses against actual
//  measured masses for each mix group and the final mixture. Displays both
//  absolute delta (g) and relative percent error, color-coded green/yellow/red
//  by magnitude (≤2%, 2-5%, >5%).
//

import SwiftUI

// MARK: - ErrorAnalysisView

struct ErrorAnalysisView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)

        VStack(spacing: 0) {
            // Header — tappable to collapse/expand
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Error").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ThemedDivider()
                errorContent(result: result)
                    .cmExpandTransition()
            }
        }
    }

    // MARK: - Content (extracted to reduce body complexity)

    @ViewBuilder
    private func errorContent(result: BatchResult) -> some View {
        let theoreticalGelatin = result.gelatinMix.totalMassGrams
        let theoreticalSugar   = result.sugarMix.totalMassGrams
        let theoreticalActive  = result.activationMix.totalMassGrams
        let theoreticalFinal   = result.totalMassGrams

        VStack(spacing: 0) {
            // MARK: Input Mixtures
            errorSubheader("Input Mixtures")
            errorCompRow("Gelatin Mix",
                         theoretical: theoreticalGelatin,
                         measured: viewModel.calcMassGelatinAdded)
            errorCompRow("Sugar Mix",
                         theoretical: theoreticalSugar,
                         measured: viewModel.calcMassSugarAdded)
            errorCompRow("Activation Mix",
                         theoretical: theoreticalActive,
                         measured: viewModel.calcMassActiveAdded)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Final Mixture
            errorSubheader("Final Mixture")
            errorCompRow("Final Mix",
                         theoretical: theoreticalFinal,
                         measured: viewModel.calcMassFinalMixtureInBeaker)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Transfer
            errorSubheader("Transfer")
            errorCompRow("Mix in Mold",
                         theoretical: theoreticalFinal,
                         measured: viewModel.calcMassMixTransferredToMold)

            Spacer(minLength: 12)
        }
    }

    // MARK: - Sub-views

    private func errorSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
            Text("Δ (g)")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
        }
        .cmSubsectionPadding()
    }

    private func errorCompRow(_ label: String, theoretical: Double, measured: Double?) -> some View {
        let delta: Double? = measured.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            // Absolute error
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
            .frame(width: 70, alignment: .trailing)
            // Relative error
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
            .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    /// Color based on magnitude of percent error: green ≤2%, yellow 2-5%, red >5%
    private func errorColor(pct: Double) -> Color {
        if pct <= 2.0 {
            return CMTheme.success
        } else if pct <= 5.0 {
            return systemConfig.designSecondaryAccent
        } else {
            return systemConfig.designAlert
        }
    }
}
