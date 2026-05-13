import SwiftUI

struct BatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        VStack(spacing: 0) {
            HStack {
                Text("Batch Output").font(.headline).foregroundStyle(systemConfig.accent)
                Spacer()
                Text(String(format: "%.1f mL (+%.1f%%)", result.vMix, (viewModel.overageFactor - 1.0) * 100.0))
                    .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            activationMixSection(result.activationMix)
            spacerLine
            mixSection(result.gelatinMix)
            spacerLine
            mixSection(result.sugarMix)
            spacerLine
            activesSection
            spacerLine
            additionalWaterInput
            Spacer().frame(height: 8)
        }
    }

    private func mixSection(_ mix: MixGroup) -> some View {
        VStack(spacing: 0) {
            HStack { Text(mix.name).font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary); Spacer() }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
            ForEach(mix.components) { comp in componentRow(comp) }
        }
    }

    private func activationMixSection(_ mix: MixGroup) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        return VStack(spacing: 0) {
            HStack { Text(mix.name).font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary); Spacer() }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            ForEach(orderedCategories, id: \.rawValue) { category in
                let items = mix.components.filter { $0.activationCategory == category }
                if !items.isEmpty {
                    if category != .preservative {
                        HStack {
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(CMTheme.textTertiary)
                            Spacer()
                        }
                        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                    }
                    ForEach(items) { comp in componentRow(comp) }
                }
            }
        }
    }

    private func componentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        let isActivationWaterModified = comp.label == "Activation Water" && viewModel.additionalActiveWater_mL > 0
        let isActivationWaterRow = comp.label == "Activation Water"
        let strawberryRed = Color(red: 0.929, green: 0.278, blue: 0.290)
        let gold = CMTheme.accentWarm

        // Compute kept volume for LSD so we can annotate Activation Water
        let isLSD = viewModel.selectedActive == .LSD
        let ugPerTab = viewModel.lsdUgPerTab
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let tabsNeeded = ugPerTab > 0 ? Int(totalActive / ugPerTab) : 0
        let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)
        let transferWater = systemConfig.lsdTransferWater_mL
        let keptVolume = (isLSD && ugPerTab > 0) ? (lsdInLiquid / ugPerTab) * transferWater : 0.0

        let valueColor: Color = CMTheme.textSecondary

        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                if let color = colorMatch {
                    Circle().fill(color.swiftUIColor).frame(width: 10, height: 10)
                }
                Text(comp.label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if comp.displayUnit == "µL" {
                    Text(String(format: "%.0f", comp.volume_mL * 1000.0))
                        .font(.system(size: 12, design: .monospaced)).foregroundStyle(valueColor)
                        .frame(width: 70, alignment: .trailing)
                } else if comp.displayUnit == "g" {
                    Text(String(format: "%.3f", comp.mass_g))
                        .font(.system(size: 12, design: .monospaced)).foregroundStyle(valueColor)
                        .frame(width: 70, alignment: .trailing)
                } else {
                    Text(String(format: "%.3f", comp.volume_mL))
                        .font(.system(size: 12, design: .monospaced)).foregroundStyle(valueColor)
                        .frame(width: 70, alignment: .trailing)
                }
                Text(comp.displayUnit)
                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 28, alignment: .leading)
            }.padding(.horizontal, 20).padding(.vertical, 2)

            // Activation Water breakdown: show when additional water added OR when LSD kept volume contributes
            let showBreakdown = isActivationWaterRow && (isActivationWaterModified || (isLSD && keptVolume > 0))
            if showBreakdown {
                let baseWater = comp.volume_mL - viewModel.additionalActiveWater_mL - keptVolume
                VStack(spacing: 1) {
                    // Base activation water (before additions)
                    HStack(spacing: 6) {
                        Text("Base")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textTertiary)
                        Spacer()
                        Text(String(format: "%.3f", baseWater))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textTertiary)
                            .frame(width: 70, alignment: .trailing)
                        Text("")
                            .frame(width: 28, alignment: .leading)
                    }
                    // Additional dissolving water (red), only if present
                    if viewModel.additionalActiveWater_mL > 0 {
                        HStack(spacing: 6) {
                            Text("Additional Water")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(strawberryRed.opacity(0.8))
                            Spacer()
                            Text(String(format: "+%.3f", viewModel.additionalActiveWater_mL))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(strawberryRed.opacity(0.8))
                                .frame(width: 70, alignment: .trailing)
                            Text("")
                                .frame(width: 28, alignment: .leading)
                        }
                    }
                    // Kept transfer water (gold), only if LSD and non-zero
                    if isLSD && keptVolume > 0 {
                        HStack(spacing: 6) {
                            Text("LSD Transfer Water")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(gold.opacity(0.9))
                            Spacer()
                            Text(String(format: "+%.3f", keptVolume))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(gold.opacity(0.9))
                                .frame(width: 70, alignment: .trailing)
                            Text("")
                                .frame(width: 28, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 2)
            }
        }
    }

    private var activesSection: some View {
        @Bindable var viewModel = viewModel
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue
        let gold = CMTheme.accentWarm

        return VStack(spacing: 0) {
            HStack {
                Text("Actives").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            if viewModel.selectedActive == .LSD {
                // Header row: "LSD ([concentration] μg / tab)" + total active μg
                let ugPerTab = viewModel.lsdUgPerTab
                HStack(spacing: 6) {
                    Text(String(format: "LSD (%.0f µg / tab)", ugPerTab))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(String(format: "%.1f", totalActive))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 70, alignment: .trailing)
                    Text(unitLabel)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                ThemedDivider(indent: 20).padding(.vertical, 4)

                // Calculated tabs + LSD in liquid (remainder)
                let tabsNeeded = Int(totalActive / ugPerTab)
                let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)

                // Transfer water calculations
                let transferWater = systemConfig.lsdTransferWater_mL
                let keptVolume = ugPerTab > 0 ? (lsdInLiquid / ugPerTab) * transferWater : 0.0
                let discardedVolume = transferWater - keptVolume

                HStack(spacing: 6) {
                    Text("Tabs")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text("\(tabsNeeded)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 70, alignment: .trailing)
                    Text("#")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                HStack(spacing: 6) {
                    Text("LSD in Liquid")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.1f", lsdInLiquid))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(gold)
                        .frame(width: 70, alignment: .trailing)
                    Text("µg")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                // Transfer water divider
                ThemedDivider(indent: 20).padding(.vertical, 4)

                // Total Transfer Water row
                HStack(spacing: 6) {
                    Text("Total Transfer Water")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.3f", transferWater))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 70, alignment: .trailing)
                    Text("mL")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                // Kept row (gold)
                HStack(spacing: 6) {
                    Text("Kept")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.3f", keptVolume))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(gold)
                        .frame(width: 70, alignment: .trailing)
                    Text("mL")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                // Discarded row
                HStack(spacing: 6) {
                    Text("Discarded")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.3f", discardedVolume))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 70, alignment: .trailing)
                    Text("mL")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                // Fine print instruction
                Group {
                    Text("Dissolve 1 Tab in \(String(format: "%.3f", transferWater)) mL of pure distilled water, let it dissolve, then transfer ")
                        .foregroundStyle(CMTheme.textTertiary)
                    + Text(String(format: "%.3f mL", keptVolume))
                        .foregroundStyle(gold)
                    + Text(" of the solution to the Activation Mix and discard \(String(format: "%.3f", discardedVolume)) mL of the remaining solution.")
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 2)

            } else {
                // Non-LSD active: simple total row
                HStack(spacing: 6) {
                    Text(viewModel.selectedActive.rawValue)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.2f", totalActive))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 70, alignment: .trailing)
                    Text(unitLabel)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)
            }
        }
    }

    private var additionalWaterInput: some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 6) {
            Text("Additional Water for Dissolving Active")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Spacer()
            NumericField(value: $viewModel.additionalActiveWater_mL, decimals: 1)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                .frame(width: 50)
            Text("mL")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 4)
    }

    private var spacerLine: some View {
        ThemedDivider(indent: 20).padding(.vertical, 8)
    }
}
