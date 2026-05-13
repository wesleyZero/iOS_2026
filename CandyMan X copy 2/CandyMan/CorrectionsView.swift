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
    let section: BatchConfigViewModel.CorrectionSection
    let onDismiss: () -> Void
    @State private var pendingDeleteID: UUID? = nil

    private var fuchsia: Color { systemConfig.designPrimaryAccent }

    private var entries: [BatchConfigViewModel.CorrectionEntry] {
        viewModel.correctionsArray(for: section)
    }

    private var isLocked: Bool {
        viewModel.correctionsLocked(for: section)
    }

    private var total: Double? {
        viewModel.correctionsTotalFor(section)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        let entriesBinding: Binding<[BatchConfigViewModel.CorrectionEntry]> = Binding(
            get: { viewModel.correctionsArray(for: section) },
            set: { newValue in
                switch section {
                case .gelatin:    viewModel.corrections = newValue
                case .sugar:      viewModel.sugarCorrections = newValue
                case .activation: viewModel.activationCorrections = newValue
                }
            }
        )

        CMPopupShell(
            title: "\(section.rawValue) Corrections",
            titleColor: fuchsia,
            onDismiss: onDismiss,
            lockAction: { viewModel.setCorrectionsLocked(!isLocked, for: section) },
            isLocked: isLocked,
            lockColor: systemConfig.designAlert
        ) {
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
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, _ in
                                correctionRow(index: index, entries: entriesBinding)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                    }
                    .frame(maxHeight: 300)

                    // Add row button
                    if !isLocked {
                        HStack(spacing: 12) {
                            Button {
                                CMHaptic.light()
                                withAnimation(.cmSpring) { viewModel.addCorrection(for: section) }
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
                            if let total = total {
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
                .allowsHitTesting(!isLocked)
                .opacity(isLocked ? 0.6 : 1.0)
                .animation(.cmSpring, value: isLocked)
        }
        .alert("Delete Row?", isPresented: Binding(
            get: { pendingDeleteID != nil },
            set: { if !$0 { pendingDeleteID = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeleteID = nil }
            Button("Delete", role: .destructive) {
                if let id = pendingDeleteID {
                    CMHaptic.medium()
                    withAnimation(.cmSpring) { viewModel.removeCorrection(id: id, for: section) }
                }
                pendingDeleteID = nil
            }
        } message: {
            Text("Are you sure you want to delete this correction row?")
        }
    }

    private func correctionRow(index: Int, entries: Binding<[BatchConfigViewModel.CorrectionEntry]>) -> some View {
        return HStack(spacing: 4) {
            // Editable name
            TextField("Name", text: entries[index].label)
                .cmMono11()
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
                .lineLimit(1)

            Spacer()

            // Initial mass
            OptionalNumericField(value: entries[index].initialMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValidationSlot()

            // Final mass
            OptionalNumericField(value: entries[index].finalMass, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValidationSlot()

            // Computed difference
            Group {
                if let diff = entries.wrappedValue[index].difference {
                    Text(String(format: "%.3f", diff))
                        .foregroundStyle(fuchsia)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmValidationSlot(width: 60)

            // Remove button
            if !isLocked && entries.wrappedValue.count > 1 {
                Button {
                    CMHaptic.light()
                    pendingDeleteID = entries.wrappedValue[index].id
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
