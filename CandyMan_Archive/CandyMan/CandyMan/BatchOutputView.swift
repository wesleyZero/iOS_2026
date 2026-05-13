import SwiftUI

struct BatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        VStack(spacing: 0) {
            HStack {
                Text("Batch Output").font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f mL (with overage)", result.vMix))
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(String(format: "%.1f mL (target)", result.vBase))
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }.padding(.horizontal, 16).padding(.vertical, 12)

            activationMixSection(result.activationMix)
            spacerLine
            mixSection(result.gelatinMix)
            spacerLine
            mixSection(result.sugarMix)
            spacerLine
            activesSection
            Spacer().frame(height: 8)
        }
    }

    private func mixSection(_ mix: MixGroup) -> some View {
        VStack(spacing: 0) {
            HStack { Text(mix.name).font(.subheadline).fontWeight(.semibold); Spacer() }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
            ForEach(mix.components) { comp in componentRow(comp) }
        }
    }

    private func activationMixSection(_ mix: MixGroup) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        return VStack(spacing: 0) {
            HStack { Text(mix.name).font(.subheadline).fontWeight(.semibold); Spacer() }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            ForEach(orderedCategories, id: \.rawValue) { category in
                let items = mix.components.filter { $0.activationCategory == category }
                if !items.isEmpty {
                    HStack {
                        Text(category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                    ForEach(items) { comp in componentRow(comp) }
                }
            }
        }
    }

    private func componentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        return HStack(spacing: 6) {
            if let color = colorMatch {
                Circle().fill(color.swiftUIColor).frame(width: 10, height: 10)
            }
            Text(comp.label).font(.system(size: 13, design: .monospaced)).lineLimit(1)
            Spacer()
            if comp.displayUnit == "µL" {
                Text(String(format: "%.0f %@", comp.volume_mL * 1000.0, comp.displayUnit))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            } else if comp.displayUnit == "g" {
                Text(String(format: "%.3f %@", comp.mass_g, comp.displayUnit))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            } else {
                Text(String(format: "%.3f %@", comp.volume_mL, comp.displayUnit))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            }
        }.padding(.horizontal, 20).padding(.vertical, 3)
    }

    private var activesSection: some View {
        @Bindable var viewModel = viewModel
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let totalWells = spec.count * viewModel.trayCount
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue

        return VStack(spacing: 0) {
            HStack {
                Text("Actives").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            HStack(spacing: 6) {
                Text(viewModel.selectedActive.rawValue)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.2f %@", totalActive, unitLabel))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 3)

            if viewModel.selectedActive == .LSD {
                Divider().padding(.horizontal, 20).padding(.vertical, 6)

                // Input row: ug per tab
                HStack(spacing: 6) {
                    Text("ug / tab")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("100", value: $viewModel.lsdUgPerTab,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(width: 70)
                    Text("µg")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20).padding(.vertical, 3)

                // Calculated tabs + microdose remainder
                let tabsNeeded = Int(totalActive / viewModel.lsdUgPerTab)
                let microdoseRemainder = totalActive - (Double(tabsNeeded) * viewModel.lsdUgPerTab)

                HStack(spacing: 6) {
                    Text("Tabs needed")
                        .font(.system(size: 13, design: .monospaced))
                    Spacer()
                    Text("\(tabsNeeded) tabs")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20).padding(.vertical, 3)

                HStack(spacing: 6) {
                    Text("Microdose extra")
                        .font(.system(size: 13, design: .monospaced))
                    Spacer()
                    Text(String(format: "%.2f µg", microdoseRemainder))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(microdoseRemainder < 1.0 ? .green : .orange)
                }
                .padding(.horizontal, 20).padding(.vertical, 3)
            }
        }
    }

    private var spacerLine: some View {
        Divider().padding(.horizontal, 20).padding(.vertical, 8)
    }
}
