import SwiftUI

struct BatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        VStack(spacing: 0) {
            HStack {
                Text("Batch Output").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f mL (+ overage)", result.vMix))
                        .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    Text(String(format: "%.1f mL", result.vBase))
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                }
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
        let valueColor: Color = isActivationWaterModified ? Color(red: 0.929, green: 0.278, blue: 0.290) : CMTheme.textSecondary
        let strawberryRed = Color(red: 0.929, green: 0.278, blue: 0.290)
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

            // Activation Water breakdown when additional water is added
            if isActivationWaterModified {
                let originalWater = comp.volume_mL - viewModel.additionalActiveWater_mL
                VStack(spacing: 1) {
                    HStack(spacing: 6) {
                        Spacer()
                        Text(String(format: "%.3f", originalWater))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textTertiary)
                            .frame(width: 70, alignment: .trailing)
                        Text("")
                            .frame(width: 28, alignment: .leading)
                    }
                    HStack(spacing: 6) {
                        Spacer()
                        Text(String(format: "+%.3f", viewModel.additionalActiveWater_mL))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(strawberryRed.opacity(0.8))
                            .frame(width: 70, alignment: .trailing)
                        Text("")
                            .frame(width: 28, alignment: .leading)
                    }
                    HStack(spacing: 6) {
                        Spacer()
                        Rectangle()
                            .fill(CMTheme.textTertiary.opacity(0.4))
                            .frame(width: 70, height: 1)
                        Text("")
                            .frame(width: 28, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 2)
            }
        }
    }

    private var activesSection: some View {
        @Bindable var viewModel = viewModel
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let totalWells = spec.count * viewModel.trayCount
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue

        return VStack(spacing: 0) {
            HStack {
                Text("Actives").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

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

            if viewModel.selectedActive == .LSD {
                Divider().padding(.horizontal, 20).padding(.vertical, 6)

                // Input row: ug per tab
                HStack(spacing: 6) {
                    Text("ug / tab")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    TextField("100", value: $viewModel.lsdUgPerTab,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(width: 70)
                        .selectAllOnFocus()
                    Text("µg")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 28, alignment: .leading)
                }
                .padding(.horizontal, 20).padding(.vertical, 2)

                // Calculated tabs + microdose remainder
                let tabsNeeded = Int(totalActive / viewModel.lsdUgPerTab)
                let microdoseRemainder = totalActive - (Double(tabsNeeded) * viewModel.lsdUgPerTab)

                HStack(spacing: 6) {
                    Text("Tabs needed")
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
                    Text("Microdose extra")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.2f", microdoseRemainder))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(microdoseRemainder < 1.0 ? CMTheme.success : CMTheme.accentWarm)
                        .frame(width: 70, alignment: .trailing)
                    Text("µg")
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
            TextField("0.0", value: $viewModel.additionalActiveWater_mL,
                      format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                .frame(width: 50)
                .selectAllOnFocus()
            Text("mL")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290).opacity(0.7))
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 4)
    }

    private var spacerLine: some View {
        ThemedDivider(indent: 20).padding(.vertical, 8)
    }
}
