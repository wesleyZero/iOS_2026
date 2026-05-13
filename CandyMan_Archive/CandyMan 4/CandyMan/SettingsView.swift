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
                    densitiesSection(systemConfig: systemConfig).cardStyle()
                    measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
                    hapticSection(systemConfig: systemConfig).cardStyle()
                    developerModeSection(systemConfig: systemConfig, viewModel: viewModel).cardStyle()
                }
                .padding(.vertical, 12)
            }
            .background(CMTheme.pageBG)
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
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
            HStack { Text("Mold Volume").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer(); Text("mL / cavity").font(.subheadline).foregroundStyle(CMTheme.textSecondary) }
                .padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Image(systemName: shape.sfSymbol).foregroundStyle(CMTheme.accent).frame(width: 24)
                    Text(shape.rawValue).font(.body); Spacer()
                    TextField("0.000", value: Binding(
                        get: { systemConfig.spec(for: shape).volume_ml },
                        set: { var u = systemConfig.spec(for: shape); u.volume_ml = $0; systemConfig.setSpec(u, for: shape) }
                    ), format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                    Text("mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
            }
            Text("This is the water-calibrated volume of the mold. To measure the volume of a tray well, tare the weight of the entire gummy tray. Then measure the mass of the entire tray filled with water exactly to the line, then divide that mass by the number of cavities in the tray.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func wellsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Wells Per Tray").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Text(shape.rawValue).font(.body); Spacer()
                    TextField("0", value: Binding(
                        get: { systemConfig.spec(for: shape).count },
                        set: { var u = systemConfig.spec(for: shape); u.count = $0; systemConfig.setSpec(u, for: shape) }
                    ), format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 50)
                    Text("wells").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 16) }
            }
            Text("Count the number of wells on one tray for each mold shape.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func sugarRatioSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Sugar Ratio").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Syrup : Granulated").font(.body); Spacer()
                TextField("1.000", value: $systemConfig.glucoseToSugarMassRatio, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Mass ratio of glucose syrup to granulated table sugar.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func ratiosSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Ratios").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Water to Gelatin").font(.body); Spacer()
                TextField("3.000", value: $systemConfig.waterToGelatinMassRatio, format: .number.precision(.fractionLength(3)))
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
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func additivesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        // Estimated mass percentages:
        // mass_fraction = (vol_fraction × substance_density) / mix_density
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let sorbateMassPct = rhoMix > 0
            ? ((systemConfig.potassiumSorbatePercent / 100.0) * systemConfig.densityPotassiumSorbate / rhoMix) * 100.0
            : 0.0
        let citricMassPct = rhoMix > 0
            ? ((systemConfig.citricAcidPercent / 100.0) * systemConfig.densityCitricAcid / rhoMix) * 100.0
            : 0.0
        return VStack(spacing: 0) {
            HStack {
                Text("Additives").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Text(String(format: "ρ_mix %.3f g/mL", rhoMix))
                    .font(.caption).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Potassium sorbate").font(.body); Spacer()
                TextField("780.0", value: Binding(
                    get: { systemConfig.potassiumSorbatePercent * 10000.0 },
                    set: { systemConfig.potassiumSorbatePercent = $0 / 10000.0 }
                ), format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text("ppm").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.leading, 16)
            HStack {
                Text("Citric acid").font(.body); Spacer()
                TextField("0.638", value: $systemConfig.citricAcidPercent, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Volume fraction of the additives in the gummy mixture.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.horizontal, 16)
            HStack {
                Text("Sorbate est. mass %").font(.caption)
                Spacer()
                Text(String(format: "%.4f %%", sorbateMassPct))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 8)
            Divider().padding(.leading, 16)
            HStack {
                Text("Citric acid est. mass %").font(.caption)
                Spacer()
                Text(String(format: "%.4f %%", citricMassPct))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 8)
        }
    }

    private func overageSection(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 0) {
            HStack { Text("Overage").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Extra Gummy Mixture Volume").font(.body); Spacer()
                TextField("3.0", value: $viewModel.overagePercent, format: .number.precision(.fractionLength(1...2)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 50)
                Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("This is to account for loss of residue and the variation of how molds are filled.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func densitiesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let rows: [(String, WritableKeyPath<SystemConfig, Double>)] = [
            ("Water",              \.densityWater),
            ("Glucose Syrup",      \.densityGlucoseSyrup),
            ("Sucrose",            \.densitySucrose),
            ("Gelatin",            \.densityGelatin),
            ("Citric Acid",        \.densityCitricAcid),
            ("Potassium Sorbate",  \.densityPotassiumSorbate),
            ("Flavor Oil",         \.densityFlavorOil),
            ("Food Coloring",      \.densityFoodColoring),
            ("Terpenes",           \.densityTerpenes),
        ]
        return VStack(spacing: 0) {
            HStack {
                Text("Substance Densities").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Text("g/mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                let (label, keyPath) = row
                HStack {
                    Text(label).font(.body)
                    Spacer()
                    TextField("1.0000", value: Binding(
                        get: { systemConfig[keyPath: keyPath] },
                        set: { systemConfig[keyPath: keyPath] = $0 }
                    ), format: .number.precision(.fractionLength(4)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                if index < rows.count - 1 { Divider().padding(.leading, 16) }
            }
            Text("Densities used to convert between mass and volume for each substance.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func measurementResolutionsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let rows: [(String, String, KeyPath<SystemConfig, MeasurementResolution>, ReferenceWritableKeyPath<SystemConfig, MeasurementResolution>)] = [
            ("Beaker (Empty)",            "g", \.resolutionBeakerEmpty,       \.resolutionBeakerEmpty),
            ("Beaker + Gelatin Mix",      "g", \.resolutionBeakerPlusGelatin, \.resolutionBeakerPlusGelatin),
            ("Substrate + Sugar Mix",     "g", \.resolutionBeakerPlusSugar,   \.resolutionBeakerPlusSugar),
            ("Substrate + Activation Mix","g", \.resolutionBeakerPlusActive,  \.resolutionBeakerPlusActive),
            ("Beaker + Residue",          "g", \.resolutionBeakerResidue,     \.resolutionBeakerResidue),
            ("Syringe (Clean)",           "g", \.resolutionSyringeEmpty,      \.resolutionSyringeEmpty),
            ("Syringe + Gummy Mix",       "g", \.resolutionSyringeWithMix,    \.resolutionSyringeWithMix),
            ("Syringe + Residue",         "g", \.resolutionSyringeResidue,    \.resolutionSyringeResidue),
            ("Molds Filled",          "molds", \.resolutionMoldsFilled,       \.resolutionMoldsFilled),
        ]
        return VStack(spacing: 0) {
            HStack { Text("Measurement Resolutions").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                let (label, unit, readKP, writeKP) = row
                HStack {
                    Text(label).font(.body)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { systemConfig[keyPath: readKP] },
                        set: { systemConfig[keyPath: writeKP] = $0 }
                    )) {
                        ForEach(MeasurementResolution.allCases) { res in
                            Text(res.label(unit: unit)).tag(res)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                if index < rows.count - 1 { Divider().padding(.leading, 16) }
            }
            Text("Set the precision matching your scale's readout for each measurement input.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func hapticSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Haptics").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $systemConfig.sliderVibrationsEnabled)
                    .labelsHidden()
                    .onChange(of: systemConfig.sliderVibrationsEnabled) { _, newVal in
                        if newVal { CMHaptic.medium() }
                    }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Text("Vibrate proportionally to the slider value when adjusting flavor and color blend ratios.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }

    private func developerModeSection(systemConfig: SystemConfig, viewModel: BatchConfigViewModel) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Developer Mode").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { systemConfig.developerMode },
                    set: { newValue in
                        CMHaptic.medium()
                        systemConfig.developerMode = newValue
                        if newValue {
                            withAnimation(.cmSpring) { systemConfig.applyDevMode(to: viewModel) }
                        } else {
                            withAnimation(.cmSpring) { systemConfig.revertDevMode(to: viewModel) }
                        }
                    }
                ))
                .labelsHidden()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            if systemConfig.developerMode {
                Divider().padding(.horizontal, 16)
                HStack {
                    Text("Expand sections by default").font(.body)
                    Spacer()
                    Toggle("", isOn: $systemConfig.expandDetailSectionsByDefault)
                        .labelsHidden()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
                Divider().padding(.horizontal, 16)
                Text("Dataset 1 active: New Bear wells overridden to 77. 4 random flavor oils, 4 random terpenes, and 2 random colors auto-selected.")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
