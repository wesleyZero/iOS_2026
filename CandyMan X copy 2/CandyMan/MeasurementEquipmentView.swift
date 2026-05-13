//
//  MeasurementEquipmentView.swift
//  CandyMan
//
//  Collapsible post-calculate section that recommends which laboratory scale
//  and beaker to use for each sub-mixture, based on theoretical masses and
//  volumes from the batch calculator and the user's configured scales.
//

import SwiftUI

struct MeasurementEquipmentView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)

        // Overage factors
        let sugarOverage = 1.0 + systemConfig.sugarMixtureOveragePercent / 100.0

        // Theoretical masses (with overage where applicable)
        let gelatinMass = result.gelatinMix.totalMassGrams
        let gelatinVol  = result.gelatinMix.totalVolumeML
        let sugarMass   = result.sugarMix.totalMassGrams * sugarOverage
        let sugarVol    = result.sugarMix.totalVolumeML * sugarOverage
        let activMass   = result.activationMix.totalMassGrams
        let activVol    = result.activationMix.totalVolumeML
        // Substrate beaker holds gelatin + sugar combined
        let substrateMass = gelatinMass + sugarMass
        let substrateVol  = gelatinVol + sugarVol
        // Total mixture = everything
        let totalMass = substrateMass + activMass
        let totalVol  = substrateVol + activVol

        // Build recommendation rows
        let rows: [EquipmentRow] = [
            makeRow(label: "Substrate Beaker", mixMass: substrateMass, mixVol: substrateVol,
                    note: "Gelatin + Sugar mix"),
            makeRow(label: "Sugar Mix Beaker", mixMass: sugarMass, mixVol: sugarVol,
                    note: nil),
            makeRow(label: "Activation Tray", mixMass: activMass, mixVol: activVol,
                    note: nil),
            makeRow(label: "Total Mixture", mixMass: totalMass, mixVol: totalVol,
                    note: "All mixes combined"),
        ]

        VStack(spacing: 0) {
            // Collapsible header
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Measurement Equipment")
                        .font(.headline)
                        .foregroundStyle(systemConfig.designTitle)
                    Spacer()
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ThemedDivider(indent: 16)

                // Column headers
                HStack(spacing: 4) {
                    Text("Mixture")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    Text("Container")
                        .font(.caption2).foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 90, alignment: .trailing)
                    Text("Scale")
                        .font(.caption2).foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                ForEach(Array(rows.enumerated()), id: \.element.label) { index, row in
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.label)
                                    .cmMono12()
                                    .foregroundStyle(CMTheme.textPrimary)
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                if let note = row.note {
                                    Text(note)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(CMTheme.textTertiary)
                                }
                            }
                            Spacer()
                            Text(row.beakerName ?? "—")
                                .cmMono11()
                                .foregroundStyle(row.beakerName != nil ? CMTheme.textSecondary : CMTheme.textTertiary)
                                .frame(width: 90, alignment: .trailing)
                            Text(row.scaleName ?? "—")
                                .cmMono11()
                                .foregroundStyle(row.scaleName != nil ? systemConfig.designTitle : CMTheme.textTertiary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 5)

                        if index < rows.count - 1 {
                            ThemedDivider(indent: 16)
                        }
                    }
                }

                // Footnote
                Text("Recommendations based on theoretical masses and your configured scales and containers.")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 10)
            }
        }
    }

    // MARK: - Row Model

    private struct EquipmentRow {
        let label: String
        let note: String?
        let beakerName: String?
        let scaleName: String?
    }

    private func makeRow(label: String, mixMass: Double, mixVol: Double, note: String?) -> EquipmentRow {
        // Recommend beaker based on volume
        let beaker = systemConfig.recommendedBeaker(forVolumeML: mixVol)
        let beakerTare = beaker.map { systemConfig.containerTare(for: $0.id) } ?? 0

        // Total mass on scale = mix mass + beaker tare
        let totalOnScale = mixMass + beakerTare
        let scale = systemConfig.recommendedScale(forMassGrams: totalOnScale)

        return EquipmentRow(
            label: label,
            note: note,
            beakerName: beaker?.name,
            scaleName: scale?.name
        )
    }
}
