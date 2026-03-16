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
                    traysSection(systemConfig: systemConfig).cardStyle()
                    sugarRatioSection(systemConfig: systemConfig).cardStyle()
                    ratiosSection(systemConfig: systemConfig).cardStyle()
                    additivesSection(systemConfig: systemConfig).cardStyle()
                    overageSection(viewModel: viewModel).cardStyle()
                    densitiesSection(systemConfig: systemConfig).cardStyle()
                    measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
                    hapticSection(systemConfig: systemConfig).cardStyle()
                    accentColorSection(systemConfig: systemConfig).cardStyle()
                    developerModeSection(systemConfig: systemConfig, viewModel: viewModel).cardStyle()
                }
                .padding(.vertical, 12)
            }
            .background(CMTheme.pageBG)
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .keyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func traysSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            // Main section title
            HStack { Text("Trays").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)

            // — Mold Volume subtitle —
            HStack {
                Text("Mold Volume").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Text("mL / mold").font(.caption).foregroundStyle(CMTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.bottom, 4)

            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Image(systemName: shape.sfSymbol).foregroundStyle(systemConfig.accent).frame(width: 24)
                    Text(shape.rawValue).font(.body); Spacer()
                    TextField("0.000", value: Binding(
                        get: { systemConfig.spec(for: shape).volume_ml },
                        set: { var u = systemConfig.spec(for: shape); u.volume_ml = $0; systemConfig.setSpec(u, for: shape) }
                    ), format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                    Text("mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
            }
            Text("Water-calibrated volume per mold. Fill a tray with water, weigh it, and divide by the number of molds.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)

            // ———————— Divider between subsections ————————
            Divider().padding(.horizontal, 16).padding(.vertical, 4)

            // — Molds per Tray subtitle —
            HStack {
                Text("Molds per Tray").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 4)

            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Image(systemName: shape.sfSymbol).foregroundStyle(systemConfig.accent).frame(width: 24)
                    Text(shape.rawValue).font(.body); Spacer()
                    TextField("0", value: Binding(
                        get: { systemConfig.spec(for: shape).count },
                        set: { var u = systemConfig.spec(for: shape); u.count = $0; systemConfig.setSpec(u, for: shape) }
                    ), format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 50).selectAllOnFocus()
                    Text("molds").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
            }
            Text("Count the number of molds on one tray for each mold shape.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)

            Divider().padding(.horizontal, 16)
            NavigationLink {
                MoldCalibrationView()
                    .environment(systemConfig)
            } label: {
                HStack {
                    Image(systemName: "target").foregroundStyle(systemConfig.accent)
                    Text("Calibrate a Mold").font(.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { CMHaptic.medium() })
        }
    }

    private func sugarRatioSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Sugar Ratio").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Syrup : Granulated").font(.body); Spacer()
                TextField("1.000", value: $systemConfig.glucoseToSugarMassRatio, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
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
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.leading, 16)
            HStack {
                Text("Water Mass % in Sugar Mix").font(.body); Spacer()
                TextField("17.34", value: $systemConfig.waterMassPercentInSugarMix, format: .number.precision(.fractionLength(2)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Mass ratios of solute to water. Used to compute water requirements for each mix.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func additivesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let useMass = systemConfig.additivesInputAsMassPercent

        // Mass ppm binding for sorbate: mass_ppm = vol_ppm × (ρ_substance / ρ_mix)
        let sorbateMassPpmBinding = Binding<Double>(
            get: {
                guard rhoMix > 0 else { return 0 }
                return systemConfig.potassiumSorbatePercent * 10000.0 * systemConfig.densityPotassiumSorbate / rhoMix
            },
            set: { newMassPpm in
                guard rhoMix > 0, systemConfig.densityPotassiumSorbate > 0 else { return }
                systemConfig.potassiumSorbatePercent = (newMassPpm / 10000.0) * rhoMix / systemConfig.densityPotassiumSorbate
            }
        )
        // Mass % binding for citric: mass% = vol% × (ρ_substance / ρ_mix)
        let citricMassBinding = Binding<Double>(
            get: {
                guard rhoMix > 0 else { return 0 }
                return systemConfig.citricAcidPercent * systemConfig.densityCitricAcid / rhoMix
            },
            set: { newMassPct in
                guard rhoMix > 0, systemConfig.densityCitricAcid > 0 else { return }
                systemConfig.citricAcidPercent = newMassPct * rhoMix / systemConfig.densityCitricAcid
            }
        )

        return VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Additives").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer(minLength: 8)
                if useMass {
                    Text(String(format: "Estimated ρ %.3f g/mL", rhoMix))
                        .font(.caption).foregroundStyle(CMTheme.textSecondary)
                }
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { systemConfig.additivesInputAsMassPercent.toggle() }
                } label: {
                    Capsule()
                        .fill(useMass ? systemConfig.accent.opacity(0.5) : Color.white.opacity(0.08))
                        .frame(width: 36, height: 20)
                        .overlay(alignment: useMass ? .trailing : .leading) {
                            Circle()
                                .fill(useMass ? systemConfig.accent : Color.white.opacity(0.35))
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 2)
                        }
                }
                .buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            if useMass {
                // Mass mode inputs
                HStack {
                    Text("Potassium sorbate").font(.body); Spacer()
                    TextField("1063", value: sorbateMassPpmBinding, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                    Text("ppm").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.leading, 16)
                HStack {
                    Text("Citric acid").font(.body); Spacer()
                    TextField("0.812", value: citricMassBinding, format: .number.precision(.fractionLength(3)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Text(String(format: "ppm and %% are fractions of the final mass of the gummy mixture, using the estimated density of %.3f g/mL to calculate the equivalent volume fraction / percentage", rhoMix))
                    .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
            } else {
                // Volume mode inputs
                HStack {
                    Text("Potassium sorbate").font(.body); Spacer()
                    TextField("780.0", value: Binding(
                        get: { systemConfig.potassiumSorbatePercent * 10000.0 },
                        set: { systemConfig.potassiumSorbatePercent = $0 / 10000.0 }
                    ), format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                    Text("ppm").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.leading, 16)
                HStack {
                    Text("Citric acid").font(.body); Spacer()
                    TextField("0.64", value: $systemConfig.citricAcidPercent, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60).selectAllOnFocus()
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Text("ppm and % are fractions of the final volume of the gummy mixture")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    private func overageSection(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 0) {
            HStack { Text("Overage").font(.headline).foregroundStyle(CMTheme.textPrimary); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Extra Gummy Mixture Volume").font(.body); Spacer()
                TextField("3.0", value: $viewModel.overagePercent, format: .number.precision(.fractionLength(1...2)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 50).selectAllOnFocus()
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
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70).selectAllOnFocus()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                if index < rows.count - 1 { Divider().padding(.leading, 16) }
            }
            Text("Densities used to convert between mass and volume for each substance.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.horizontal, 16)
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { systemConfig.resetDensitiesToDefault() }
            } label: {
                Text("Reset to Default")
                    .font(.subheadline)
                    .foregroundStyle(systemConfig.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.vertical, 12)
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
            ("Molds Filled",          "#", \.resolutionMoldsFilled,       \.resolutionMoldsFilled),
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

    private func accentColorSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let columns = [GridItem(.adaptive(minimum: 56))]
        return VStack(spacing: 0) {
            HStack {
                Text("Accent Color")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Text(systemConfig.accentTheme.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(systemConfig.accent)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AccentTheme.allCases) { theme in
                    let isSelected = systemConfig.accentTheme == theme
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) {
                            systemConfig.accentTheme = theme
                        }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 40, height: 40)
                                if isSelected {
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: 2.5)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }
                            }
                            Text(theme.rawValue)
                                .font(.caption2)
                                .foregroundStyle(isSelected ? CMTheme.textPrimary : CMTheme.textSecondary)
                        }
                        .animation(.cmSpring, value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 12)

            Text("Choose the accent color used for buttons, selections, and highlights throughout the app.")
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
                Text("Dataset 1 active: New Bear molds overridden to 77. 4 random flavor oils, 4 random terpenes, and 2 random colors auto-selected.")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
