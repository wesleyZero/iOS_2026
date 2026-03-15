//
//  BatchOutputView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI

struct BatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader

            // ── ACTIVE MIX ───────────────────────────
            groupHeader("Active Mix")

            outputRow(label: "Citric Acid", value: 0.000, unit: "g")
            outputRow(label: "Potassium Sorbate", value: 0.000, unit: "g")
            outputRow(label: "Activation Water", value: 0.000, unit: "g")

            spacerLine

            // Colors
            let sortedColors = Array(viewModel.selectedColors.keys).sorted { $0.rawValue < $1.rawValue }
            ForEach(sortedColors, id: \.id) { color in
                HStack {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 10, height: 10)
                    Text("\(color.rawValue) Color")
                        .font(.system(size: 14, design: .monospaced))
                    Spacer()
                    Text("0.000 ml")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 3)
            }

            if !sortedColors.isEmpty { spacerLine }

            // Terpenes
            let terpenes = Array(viewModel.selectedFlavors.keys.filter {
                if case .terpene = $0 { return true }; return false
            })
            ForEach(terpenes, id: \.id) { flavor in
                outputRow(label: "\(flavor.displayName) Terpene", value: 0, unit: "µL", intFormat: true)
            }

            // Flavor Oils
            let oils = Array(viewModel.selectedFlavors.keys.filter {
                if case .oil = $0 { return true }; return false
            })
            ForEach(oils, id: \.id) { flavor in
                outputRow(label: "\(flavor.displayName) Oil", value: 0.000, unit: "ml")
            }

            if !terpenes.isEmpty || !oils.isEmpty { spacerLine }

            // ── GELATIN MIX ──────────────────────────
            groupHeader("Gelatin Mix")

            outputRow(label: "Gelatin", value: 0.000, unit: "g")
            outputRow(label: "Water", value: 0.000, unit: "ml")

            spacerLine

            // ── SUGAR MIX ────────────────────────────
            groupHeader("Sugar Mix")

            outputRow(label: "Glucose Syrup", value: 0.000, unit: "g")
            outputRow(label: "Granulated Sugar", value: 0.000, unit: "g")
            outputRow(label: "Water", value: 0.000, unit: "g")

            Spacer().frame(height: 12)
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Text("Batch Output")
                .font(.headline)
            Spacer()
            Text("placeholder")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Group Header

    private func groupHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    // MARK: - Output Row

    private func outputRow(label: String, value: Double, unit: String, intFormat: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
            Spacer()
            if intFormat {
                Text(String(format: "%03.0f %@", value, unit))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text(String(format: "%.3f %@", value, unit))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 3)
    }

    // MARK: - Spacer Line

    private var spacerLine: some View {
        Divider()
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }
}
