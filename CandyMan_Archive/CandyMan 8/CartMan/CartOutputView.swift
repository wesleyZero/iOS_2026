//
//  CartOutputView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI

struct CartOutputView: View {
    @Environment(CartConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        let result = CartCalculator.calculate(viewModel: viewModel)

        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Cart Output")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton {
                    CMHaptic.success()
                    CMClipboard.copy(outputText(result: result))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Composition visual bar
            compositionBar(result: result)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Total batch volumes
            CMSectionHeader(title: "Total Batch", detail: String(format: "%.2f ml", result.totalOutput_mL))

            outputRow("Weed Distillate", value: String(format: "%.4f ml", result.weedDistillate_mL),
                      color: Color(red: 0.2, green: 0.7, blue: 0.3))
            outputRow("Base", value: String(format: "%.4f ml", result.base_mL),
                      color: Color(red: 0.4, green: 0.6, blue: 0.9))
            outputRow("Cut", value: String(format: "%.4f ml", result.cut_mL),
                      color: Color(red: 0.9, green: 0.6, blue: 0.2))
            outputRow("Total Terpenes", value: String(format: "%.4f ml", result.totalTerpenes_mL),
                      color: Color(red: 0.7, green: 0.3, blue: 0.8))

            ThemedDivider()

            // Per-cart volumes
            if viewModel.cartCount > 1 {
                CMSectionHeader(title: "Per Cart", detail: viewModel.cartSize.rawValue)

                outputRow("Weed Distillate", value: String(format: "%.4f ml", result.perCartWeed_mL),
                          color: Color(red: 0.2, green: 0.7, blue: 0.3))
                outputRow("Base", value: String(format: "%.4f ml", result.perCartBase_mL),
                          color: Color(red: 0.4, green: 0.6, blue: 0.9))
                outputRow("Cut", value: String(format: "%.4f ml", result.perCartCut_mL),
                          color: Color(red: 0.9, green: 0.6, blue: 0.2))
                outputRow("Terpenes", value: String(format: "%.4f ml", result.perCartTerp_mL),
                          color: Color(red: 0.7, green: 0.3, blue: 0.8))

                ThemedDivider()
            }

            // Terpene breakdown
            if !result.terpeneBreakdown.isEmpty {
                CMSectionHeader(title: "Terpene Breakdown")

                ForEach(result.terpeneBreakdown) { comp in
                    outputRow(comp.label, value: terpDisplayValue(comp.volume_mL),
                              color: Color(red: 0.7, green: 0.3, blue: 0.8).opacity(0.7))
                }
            }

            // Composition percentages
            ThemedDivider()
            CMSectionHeader(title: "Composition")

            compositionRow("Weed", pct: result.weedPercent, color: Color(red: 0.2, green: 0.7, blue: 0.3))
            compositionRow("Base", pct: result.basePercent, color: Color(red: 0.4, green: 0.6, blue: 0.9))
            compositionRow("Cut", pct: result.cutPercent, color: Color(red: 0.9, green: 0.6, blue: 0.2))
            compositionRow("Terpenes", pct: result.terpPercent, color: Color(red: 0.7, green: 0.3, blue: 0.8))

            Spacer().frame(height: 12)
        }
    }

    // MARK: - Composition Bar

    private func compositionBar(result: CartResult) -> some View {
        let total = result.finalVolume_mL
        guard total > 0 else { return AnyView(EmptyView()) }

        let segments: [(Double, Color)] = [
            (result.weedDistillate_mL / total, Color(red: 0.2, green: 0.7, blue: 0.3)),
            (result.base_mL / total, Color(red: 0.4, green: 0.6, blue: 0.9)),
            (result.cut_mL / total, Color(red: 0.9, green: 0.6, blue: 0.2)),
            (result.totalTerpenes_mL / total, Color(red: 0.7, green: 0.3, blue: 0.8)),
        ]

        return AnyView(
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                        if seg.0 > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(seg.1)
                                .frame(width: max(4, geo.size.width * seg.0))
                        }
                    }
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        )
    }

    // MARK: - Row Helpers

    private func outputRow(_ label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 3)
    }

    private func compositionRow(_ label: String, pct: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.1f%%", pct))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 3)
    }

    private func terpDisplayValue(_ volume_mL: Double) -> String {
        if volume_mL < 0.01 {
            return String(format: "%.1f µL", volume_mL * 1000)
        } else {
            return String(format: "%.4f ml", volume_mL)
        }
    }

    // MARK: - Copy Text

    private func outputText(result: CartResult) -> String {
        var lines: [String] = []
        lines.append("Cart Batch Output")
        lines.append("─────────────────")
        lines.append(String(format: "Cart Size: %@  ×%d", viewModel.cartSize.rawValue, viewModel.cartCount))
        lines.append(String(format: "Total Volume: %.4f ml", result.totalOutput_mL))
        lines.append("")
        lines.append(String(format: "Weed Distillate: %.4f ml (%.1f%%)", result.weedDistillate_mL, result.weedPercent))
        lines.append(String(format: "Base:            %.4f ml (%.1f%%)", result.base_mL, result.basePercent))
        lines.append(String(format: "Cut:             %.4f ml (%.1f%%)", result.cut_mL, result.cutPercent))
        lines.append(String(format: "Terpenes:        %.4f ml (%.1f%%)", result.totalTerpenes_mL, result.terpPercent))
        if !result.terpeneBreakdown.isEmpty {
            lines.append("")
            lines.append("Terpene Breakdown:")
            for comp in result.terpeneBreakdown {
                lines.append(String(format: "  %@: %.4f ml", comp.label, comp.volume_mL))
            }
        }
        return lines.joined(separator: "\n")
    }
}
