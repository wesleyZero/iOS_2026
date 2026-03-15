import SwiftUI

struct SettingsView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var systemConfig = systemConfig
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    moldVolumeSection(systemConfig: systemConfig).cardStyle()
                    wellsSection(systemConfig: systemConfig).cardStyle()
                    sugarRatioSection(systemConfig: systemConfig).cardStyle()
                    ratiosSection(systemConfig: systemConfig).cardStyle()
                    additivesSection(systemConfig: systemConfig).cardStyle()
                    overageSection(viewModel: viewModel).cardStyle()
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGray4))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func moldVolumeSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Mold Volume").font(.headline); Spacer(); Text("mL / cavity").font(.subheadline).foregroundStyle(.secondary) }
                .padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Image(systemName: shape.sfSymbol).foregroundStyle(.blue).frame(width: 24)
                    Text(shape.rawValue).font(.body); Spacer()
                    TextField("0.0", value: Binding(
                        get: { systemConfig.spec(for: shape).volume_ml },
                        set: { var u = systemConfig.spec(for: shape); u.volume_ml = $0; systemConfig.setSpec(u, for: shape) }
                    ), format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                    Text("mL").font(.subheadline).foregroundStyle(.secondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
            }
            Text("This is the statistical volume of the tray, not the ideal well volume.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func wellsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Wells Per Tray").font(.headline); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Text(shape.rawValue).font(.body); Spacer()
                    TextField("0", value: Binding(
                        get: { systemConfig.spec(for: shape).count },
                        set: { var u = systemConfig.spec(for: shape); u.count = $0; systemConfig.setSpec(u, for: shape) }
                    ), format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 50)
                    Text("wells").font(.subheadline).foregroundStyle(.secondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 16) }
            }
            Text("Count the number of wells on one tray for each mold shape.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func sugarRatioSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Sugar Ratio").font(.headline); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Syrup : Granulated").font(.body); Spacer()
                TextField("1.000", value: $systemConfig.glucoseToSugarMassRatio, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Mass ratio of glucose syrup to granulated table sugar.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func ratiosSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Ratios").font(.headline); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Gelatin to Water").font(.body); Spacer()
                TextField("3.000", value: $systemConfig.gelatinToWaterMassRatio, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.leading, 16)
            HStack {
                Text("Sugar to Water").font(.body); Spacer()
                TextField("4.769", value: $systemConfig.sugarToWaterMassRatio, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Mass ratios of solute to water. Used to compute water requirements for each mix.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func additivesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Additives").font(.headline); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Potassium sorbate").font(.body); Spacer()
                TextField("0.078", value: $systemConfig.potassiumSorbatePercent, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text("%").font(.subheadline).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.leading, 16)
            HStack {
                Text("Citric acid").font(.body); Spacer()
                TextField("0.638", value: $systemConfig.citricAcidPercent, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text("%").font(.subheadline).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Percent volume of the additives in the gummy mixture.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func overageSection(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 0) {
            HStack { Text("Overage").font(.headline); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Extra volume").font(.body); Spacer()
                TextField("3.0", value: $viewModel.overagePercent, format: .number.precision(.fractionLength(1...2)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 50)
                Text("%").font(.subheadline).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Accounts for loss during transfer, stir bars, scum layer, and drips.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }
}
