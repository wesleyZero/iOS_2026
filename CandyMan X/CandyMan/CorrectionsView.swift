//
//  CorrectionsView.swift
//  CandyMan
//
//  Modal popup for recording mass corrections (e.g. spilled material). Shows a
//  table of named entries with initial/final mass fields and a computed diff.
//  The total correction is summed at the bottom. Rows are lockable and
//  add/remove-able. Presented as an overlay from WeightMeasurementsView.
//

import SwiftUI

struct CorrectionsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    let onDismiss: () -> Void

    private var fuchsia: Color { systemConfig.designPrimaryAccent }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 0) {
                // Header — always interactive (never disabled)
                HStack {
                    Text("Corrections")
                        .font(.headline)
                        .foregroundStyle(fuchsia)

                    // Lock button
                    Button {
                        CMHaptic.light()
                        viewModel.correctionsLocked.toggle()
                    } label: {
                        Image(systemName: viewModel.correctionsLocked ? "lock.fill" : "lock.open.fill")
                            .cmLockIcon(isLocked: viewModel.correctionsLocked, color: systemConfig.designAlert)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
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
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .zIndex(1)

                ThemedDivider()

                // Column headers + rows + total (lockable content)
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Name")
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

                    // Correction rows
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(viewModel.corrections.enumerated()), id: \.element.id) { index, _ in
                                correctionRow(index: index)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                    }
                    .frame(maxHeight: 300)

                    // Add row button
                    if !viewModel.correctionsLocked {
                        HStack(spacing: 12) {
                            Button {
                                CMHaptic.light()
                                withAnimation(.cmSpring) { viewModel.addCorrection() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Add Row")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(fuchsia)
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
                            .foregroundStyle(fuchsia)
                        Spacer()
                        Group {
                            if let total = viewModel.correctionsTotal {
                                Text(String(format: "%.3f", total))
                                    .foregroundStyle(fuchsia)
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
                    .background(fuchsia.opacity(0.08))
                }
                .allowsHitTesting(!viewModel.correctionsLocked)
                .opacity(viewModel.correctionsLocked ? 0.6 : 1.0)
                .animation(.cmSpring, value: viewModel.correctionsLocked)
            }
            .cmModalCard()
        }
        .transition(.opacity)
    }

    private func correctionRow(index: Int) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 4) {
            // Editable name
            TextField("Name", text: $viewModel.corrections[index].label)
                .cmMono11()
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
                .lineLimit(1)

            Spacer()

            // Initial mass
            OptionalNumericField(value: $viewModel.corrections[index].initialMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValidationSlot()

            // Final mass
            OptionalNumericField(value: $viewModel.corrections[index].finalMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValidationSlot()

            // Computed difference
            Group {
                if let diff = viewModel.corrections[index].difference {
                    Text(String(format: "%.3f", diff))
                        .foregroundStyle(fuchsia)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmValidationSlot(width: 60)

            // Remove button
            if !viewModel.correctionsLocked && viewModel.corrections.count > 1 {
                Button {
                    CMHaptic.light()
                    let id = viewModel.corrections[index].id
                    withAnimation(.cmSpring) { viewModel.removeCorrection(id: id) }
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
