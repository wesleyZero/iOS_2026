//
//  SyringePickerSheet.swift
//  CandyMan
//
//  Bottom-sheet wheel picker for selecting a syringe from
//  SystemConfig.syringes. Shows syringe name and current tare mass.
//  Follows the same pattern as ContainerPickerSheet.
//

import SwiftUI

/// Data model for driving the syringe picker sheet.
struct SyringePickerRow: Identifiable {
    let id = UUID()
    let label: String            // e.g. "Transfer Syringe"
    let currentID: String?       // currently selected SyringeContainer.id
    let onSelect: (String) -> Void
}

struct SyringePickerSheet: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss
    let row: SyringePickerRow

    @State private var selectedID: String

    init(row: SyringePickerRow) {
        self.row = row
        _selectedID = State(initialValue: row.currentID ?? SystemConfig.factorySyringes.first!.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(CMTheme.textTertiary)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Title
            Text(row.label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CMTheme.textPrimary)
                .padding(.bottom, 4)

            Text("Select Syringe")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CMTheme.textSecondary)
                .padding(.bottom, 20)

            // Wheel picker showing "Syringe 60mL  (30.000 g)"
            Picker("", selection: $selectedID) {
                ForEach(systemConfig.syringes) { syringe in
                    Text("\(syringe.name)  (\(syringe.formattedTareWeight))")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .tag(syringe.id)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: selectedID) { _, newVal in
                CMHaptic.light()
                row.onSelect(newVal)
            }
            .frame(height: 160)
            .padding(.horizontal, 20)

            // Done button
            Button {
                CMHaptic.success()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(systemConfig.designTitle)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(CMTheme.cardBG.ignoresSafeArea())
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.hidden)
    }
}
