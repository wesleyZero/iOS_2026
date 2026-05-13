//
//  AdditionalMeasurementsPopup.swift
//  CandyMan
//

import SwiftUI

struct AdditionalMeasurementsPopup: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    let onDismiss: () -> Void

    private static let gold = Color(red: 0.85, green: 0.68, blue: 0.25)
    private static let lockRed = Color(red: 0.929, green: 0.278, blue: 0.290)

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Additional Measurements")
                        .font(.headline)
                        .foregroundStyle(systemConfig.accent)

                    // Lock button
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { viewModel.additionalMeasurementsLocked.toggle() }
                    } label: {
                        Image(systemName: viewModel.additionalMeasurementsLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(viewModel.additionalMeasurementsLocked ? Self.lockRed : CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Close button
                    Button {
                        CMHaptic.light()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)

                ThemedDivider()

                // Column headers
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
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
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
                            .foregroundStyle(systemConfig.accent)
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
                        .foregroundStyle(Self.gold)
                    Spacer()
                    Group {
                        if let total = viewModel.additionalMeasurementsTotal {
                            Text(String(format: "%.3f", total))
                                .foregroundStyle(Self.gold)
                        } else {
                            Text("—")
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                    }
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Text("g")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 20, alignment: .leading)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Self.gold.opacity(0.08))
            }
            .background(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .fill(CMTheme.cardBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .stroke(CMTheme.cardStroke, lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .disabled(viewModel.additionalMeasurementsLocked)
            .opacity(viewModel.additionalMeasurementsLocked ? 0.6 : 1.0)
        }
        .transition(.opacity)
    }

    private func measurementRow(index: Int) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 4) {
            // Editable label
            TextField("Label", text: $viewModel.additionalMeasurements[index].label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
                .lineLimit(1)

            Spacer()

            // Initial mass
            OptionalNumericField(value: $viewModel.additionalMeasurements[index].initialMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 70)

            // Final mass
            OptionalNumericField(value: $viewModel.additionalMeasurements[index].finalMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 70)

            // Computed difference
            Group {
                if let diff = viewModel.additionalMeasurements[index].difference {
                    Text(String(format: "%.3f", diff))
                        .foregroundStyle(Color(white: 0.45))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .frame(width: 60, alignment: .trailing)

            // Remove button
            if !viewModel.additionalMeasurementsLocked && viewModel.additionalMeasurements.count > 1 {
                Button {
                    CMHaptic.light()
                    let id = viewModel.additionalMeasurements[index].id
                    withAnimation(.cmSpring) { viewModel.removeAdditionalMeasurement(id: id) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Self.lockRed.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(CMTheme.fieldBG)
        )
    }
}
