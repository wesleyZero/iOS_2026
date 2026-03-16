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
                    measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
                    batchIDSection(systemConfig: systemConfig).cardStyle()
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

    // MARK: - Measurement Resolutions

    private func measurementResolutionsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Measurement Resolutions").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // ── Beaker-scale measurements ──
            resolutionSubheader("Beaker scale")
            resolutionPicker("Beaker (Empty)",              binding: $systemConfig.resBeakerEmpty,             unit: "g")
            resolutionPicker("Beaker + Gelatin Mix",        binding: $systemConfig.resBeakerPlusGelatin,       unit: "g")
            resolutionPicker("Substrate + Sugar Mix",       binding: $systemConfig.resSubstratePlusSugar,      unit: "g")
            resolutionPicker("Substrate + Activation Mix",  binding: $systemConfig.resSubstratePlusActivation, unit: "g")
            resolutionPicker("Beaker + Residue",            binding: $systemConfig.resBeakerPlusResidue,       unit: "g")

            Divider().padding(.horizontal, 16).padding(.vertical, 4)

            // ── Syringe-scale measurements ──
            resolutionSubheader("Syringe scale")
            resolutionPicker("Syringe (Clean)",             binding: $systemConfig.resSyringeClean,            unit: "g")
            resolutionPicker("Syringe + Gummy Mix",         binding: $systemConfig.resSyringePlusGummyMix,     unit: "g")
            resolutionPicker("Syringe + Residue",           binding: $systemConfig.resSyringeResidue,          unit: "g")

            Divider().padding(.horizontal, 16).padding(.vertical, 4)

            // ── Volume measurement ──
            resolutionSubheader("Volume")
            resolutionPicker("Syringe Gummy Mixture Vol",   binding: $systemConfig.resSyringeVolume,           unit: "mL")

            Divider().padding(.horizontal, 16).padding(.vertical, 4)

            // ── Mold count ──
            resolutionSubheader("Mold count")
            resolutionPicker("Molds Filled",                binding: $systemConfig.resMoldsFilled,             unit: "molds")

            Text("Sets the resolution of each measurement input. Controls the significant figures shown in calculations via error propagation.")
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    // MARK: - Resolution Helpers

    private func resolutionSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 2)
    }

    private func resolutionPicker(_ label: String, binding: Binding<MeasurementResolution>, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Picker("", selection: binding) {
                ForEach(MeasurementResolution.allCases) { res in
                    Text(res.displayLabel.replacingOccurrences(of: " g", with: " \(unit)")).tag(res)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }

    // MARK: - Batch ID

    private func batchIDSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Batch ID").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            HStack {
                Text("Next batch ID").font(.body)
                Spacer()
                Text(systemConfig.peekNextBatchID())
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            HStack {
                Text("Counter value").font(.body)
                Spacer()
                TextField("0", value: $systemConfig.nextBatchIDValue, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            Text("Base-26 batch identifier [AA–ZZ]. Auto-increments on each save.")
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    // MARK: - Existing Sections

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
