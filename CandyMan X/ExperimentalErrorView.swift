//
//  ExperimentalErrorView.swift
//  CandyMan
//
//  Live "Error (Exp. vs Theoretical)" card for the main page.
//  Compares experimental (measured) values against theoretical (calculated)
//  values for each mix group and the final mixture.
//  Shows absolute error (Δ) and relative percent error, color-coded by
//  magnitude: green ≤2%, yellow 2-5%, red >5%.
//

import SwiftUI

// MARK: - ExperimentalErrorView

struct ExperimentalErrorView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    // MARK: - Theoretical values (from BatchCalculator)

    private var result: BatchResult {
        BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
    }

    private var theoGelatinMass: Double { result.gelatinMix.totalMassGrams }
    private var theoGelatinVol: Double { result.gelatinMix.totalVolumeML }
    private var theoSugarMass: Double { result.sugarMix.totalMassGrams }
    private var theoSugarVol: Double { result.sugarMix.totalVolumeML }
    private var theoActivationMass: Double { result.activationMix.totalMassGrams }
    private var theoActivationVol: Double { result.activationMix.totalVolumeML }
    private var theoFinalMass: Double { result.totalMassGrams }
    private var theoFinalVol: Double { result.totalVolumeML }

    // MARK: - Experimental masses (from scale readings)

    private var expGelatinMass: Double? { viewModel.calcMassGelatinAdded }
    private var expSugarMass: Double? { viewModel.calcMassSugarAdded }
    private var expActivationMass: Double? { viewModel.calcMassActiveAdded }
    private var expFinalMass: Double? { viewModel.calcMassFinalMixtureInBeaker }

    // MARK: - Experimental volumes (mass / measured density)

    private var expGelatinVol: Double? {
        guard let m = expGelatinMass, let d = viewModel.calcGelatinMixDensity, d > 0 else { return nil }
        return m / d
    }
    private var expSugarVol: Double? {
        guard let m = expSugarMass, let d = viewModel.calcSugarMixDensity, d > 0 else { return nil }
        return m / d
    }
    private var expActivationVol: Double? {
        guard let m = expActivationMass, let d = viewModel.calcActiveMixDensity, d > 0 else { return nil }
        return m / d
    }
    private var expFinalVol: Double? {
        guard let gv = expGelatinVol, let sv = expSugarVol, let av = expActivationVol else { return nil }
        return gv + sv + av
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
                    Text("Error (Exp. vs Theoretical)").cmSectionTitle(accent: systemConfig.designTitle)
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

                // MARK: Mass Error
                errorSubheader("Mass Error", col1: "Δ (g)", col2: "Δ (%)")
                errorRow("Gelatin Mix",    theoretical: theoGelatinMass,    experimental: expGelatinMass)
                errorRow("Sugar Mix",      theoretical: theoSugarMass,      experimental: expSugarMass)
                errorRow("Activation Mix", theoretical: theoActivationMass, experimental: expActivationMass)
                errorRow("Final Mix",      theoretical: theoFinalMass,      experimental: expFinalMass, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Volume Error
                errorSubheader("Volume Error", col1: "Δ (mL)", col2: "Δ (%)")
                errorRow("Gelatin Mix",    theoretical: theoGelatinVol,    experimental: expGelatinVol)
                errorRow("Sugar Mix",      theoretical: theoSugarVol,      experimental: expSugarVol)
                errorRow("Activation Mix", theoretical: theoActivationVol, experimental: expActivationVol)
                errorRow("Final Mix",      theoretical: theoFinalVol,      experimental: expFinalVol, bold: true)
                    .background(CMTheme.totalRowBG)

                Spacer().frame(height: 12)
            } // end if isExpanded
        }
        .onChange(of: viewModel.batchActivated) { _, activated in
            if !activated { withAnimation(.cmSpring) { isExpanded = false } }
        }
    }

    // MARK: - Sub-views

    private func errorSubheader(_ title: String, col1: String, col2: String) -> some View {
        CMTwoColumnSubheader(title: title, col1: col1, col2: col2)
    }

    private func errorRow(_ label: String, theoretical: Double, experimental: Double?, bold: Bool = false) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
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
            .fontWeight(bold ? .bold : .regular)
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
            .fontWeight(bold ? .bold : .regular)
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
