//
//  AdditionalMeasurementsPopup.swift
//  CandyMan
//
//  Modal popup for recording supplementary mass measurements beyond the core
//  batch fields. Same table layout as CorrectionsView — named rows with
//  initial/final mass and computed diff — but themed with gold accent and
//  backed by the viewModel's additionalMeasurements array. Presented as an
//  overlay from WeightMeasurementsView.
//

import SwiftUI

struct AdditionalMeasurementsPopup: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    let onDismiss: () -> Void

    private var gold: Color { systemConfig.designSecondaryAccent }

    var body: some View {
        @Bindable var viewModel = viewModel

        CMPopupShell(
            title: "Additional Measurements",
            titleColor: systemConfig.designTitle,
            onDismiss: onDismiss,
            lockAction: { viewModel.additionalMeasurementsLocked.toggle() },
            isLocked: viewModel.additionalMeasurementsLocked,
            lockColor: systemConfig.designAlert
        ) {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Label")
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        Text("Initial")
                            .frame(width: 70, alignment: .center)
                        Text("Final")
                            .frame(width: 70, alignment: .center)
                        Text("Diff")
                            .frame(width: 60, alignment: .trailing)
                    }
                    .cmMono10().fontWeight(.semibold)
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.vertical, 6)

                    // Measurement rows
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(viewModel.additionalMeasurements.enumerated()), id: \.element.id) { index, measurement in
                                measurementRow(index: index)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                    }
                    .frame(maxHeight: 260)

                    // Add/Remove buttons
                    if !viewModel.additionalMeasurementsLocked {
                        HStack(spacing: 12) {
                            Button {
                                CMHaptic.light()
                                withAnimation(.cmSpring) { viewModel.addAdditionalMeasurement() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Add Row")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(systemConfig.designTitle)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }

                    ThemedDivider()

                    // Total row
                    HStack(spacing: 4) {
                        Text("Total")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(gold)
                        Spacer()
                        Group {
                            if let total = viewModel.additionalMeasurementsTotal {
                                Text(String(format: "%.3f", total))
                                    .foregroundStyle(gold)
                            } else {
                                Text("—")
                                    .foregroundStyle(CMTheme.textTertiary)
                            }
                        }
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Text("g")
                            .cmMono11()
                            .foregroundStyle(CMTheme.textTertiary)
                            .frame(width: 20, alignment: .leading)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(gold.opacity(0.08))
                }
                .allowsHitTesting(!viewModel.additionalMeasurementsLocked)
                .opacity(viewModel.additionalMeasurementsLocked ? 0.6 : 1.0)
                .animation(.cmSpring, value: viewModel.additionalMeasurementsLocked)
        }
    }

    private func measurementRow(index: Int) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 4) {
            // Editable label
            TextField("Label", text: $viewModel.additionalMeasurements[index].label)
                .cmMono11()
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
                .lineLimit(1)

            Spacer()

            // Initial mass
            OptionalNumericField(value: $viewModel.additionalMeasurements[index].initialMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValidationSlot()

            // Final mass
            OptionalNumericField(value: $viewModel.additionalMeasurements[index].finalMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValidationSlot()

            // Computed difference
            Group {
                if let diff = viewModel.additionalMeasurements[index].difference {
                    Text(String(format: "%.3f", diff))
                        .foregroundStyle(CMTheme.textSecondary)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmValidationSlot(width: 60)

            // Remove button
            if !viewModel.additionalMeasurementsLocked && viewModel.additionalMeasurements.count > 1 {
                Button {
                    CMHaptic.light()
                    let id = viewModel.additionalMeasurements[index].id
                    withAnimation(.cmSpring) { viewModel.removeAdditionalMeasurement(id: id) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(systemConfig.designAlert.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .cmPopupRowBG()
    }
}
