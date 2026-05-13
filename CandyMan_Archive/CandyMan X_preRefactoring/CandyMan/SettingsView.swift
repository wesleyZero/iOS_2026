import SwiftUI

struct SettingsView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showAssignDefaultsAlert = false
    @State private var showFactoryResetAlert = false
    @State private var showResetToDefaultsAlert = false
    @State private var showLoadFromClipboardAlert = false
    @State private var clipboardJSON: [String: Any]? = nil
    @State private var showCustomColorCreator = false
    @State private var resolutionPickerRow: ResolutionPickerRow? = nil

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        @Bindable var systemConfig = systemConfig
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                if isRegular {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 12) {
                            traysSection(systemConfig: systemConfig).cardStyle()
                            densitiesSection(systemConfig: systemConfig).cardStyle()
                            measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
                            containerTareWeightsSection(systemConfig: systemConfig).cardStyle()
                            settingsActionsSection(systemConfig: systemConfig).cardStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 12) {
                            sugarRatioSection(systemConfig: systemConfig).cardStyle()
                            ratiosSection(systemConfig: systemConfig).cardStyle()
                            transferLiquidsSection(systemConfig: systemConfig).cardStyle()
                            defaultUgPerTabSection(systemConfig: systemConfig).cardStyle()
                            additivesSection(systemConfig: systemConfig).cardStyle()
                            overageSection(viewModel: viewModel, systemConfig: systemConfig).cardStyle()
                            appearanceSection(systemConfig: systemConfig).cardStyle()
                            hapticSection(systemConfig: systemConfig).cardStyle()
                            accentColorSection(systemConfig: systemConfig).cardStyle()
                            developerModeSection(systemConfig: systemConfig, viewModel: viewModel).cardStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 12) {
                        traysSection(systemConfig: systemConfig).cardStyle()
                        sugarRatioSection(systemConfig: systemConfig).cardStyle()
                        ratiosSection(systemConfig: systemConfig).cardStyle()
                        transferLiquidsSection(systemConfig: systemConfig).cardStyle()
                        defaultUgPerTabSection(systemConfig: systemConfig).cardStyle()
                        additivesSection(systemConfig: systemConfig).cardStyle()
                        overageSection(viewModel: viewModel, systemConfig: systemConfig).cardStyle()
                        densitiesSection(systemConfig: systemConfig).cardStyle()
                        measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
                        containerTareWeightsSection(systemConfig: systemConfig).cardStyle()
                        appearanceSection(systemConfig: systemConfig).cardStyle()
                        hapticSection(systemConfig: systemConfig).cardStyle()
                        accentColorSection(systemConfig: systemConfig).cardStyle()
                        developerModeSection(systemConfig: systemConfig, viewModel: viewModel).cardStyle()
                        settingsActionsSection(systemConfig: systemConfig).cardStyle()
                    }
                    .padding(.vertical, 12)
                }
            }
            .background(CMTheme.pageBG)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Settings")
            .preferredColorScheme(systemConfig.preferredColorScheme)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .keyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .alert("Factory Reset?", isPresented: $showFactoryResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    CMHaptic.success()
                    withAnimation(.cmSpring) { systemConfig.factoryReset() }
                }
            } message: {
                Text("Are you sure you want to remove all system settings that have been provided by the user. All system settings will be set back to initial values before user modification.")
            }
            .alert("Change Default Settings?", isPresented: $showAssignDefaultsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Assign", role: .destructive) {
                    CMHaptic.success()
                    systemConfig.assignCurrentAsDefaults()
                }
            } message: {
                Text("Are you sure you want to change your default settings? If these defaults are incorrect it can cause very inaccurate calculations.")
            }
            .alert("Reset to Defaults?", isPresented: $showResetToDefaultsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    CMHaptic.success()
                    withAnimation(.cmSpring) { systemConfig.loadSavedDefaults() }
                }
            } message: {
                Text("Are you sure you want to reset all current settings back to your saved default values?")
            }
            .alert("Load Settings from Clipboard?", isPresented: $showLoadFromClipboardAlert) {
                Button("Cancel", role: .cancel) { clipboardJSON = nil }
                Button("Load", role: .destructive) {
                    if let json = clipboardJSON {
                        CMHaptic.success()
                        withAnimation(.cmSpring) { systemConfig.loadSettings(from: json) }
                    }
                    clipboardJSON = nil
                }
            } message: {
                Text("Are you sure you want to overwrite your current settings with the JSON from your clipboard?")
            }
        }
    }

    private func traysSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            // Main section title
            HStack { Text("Trays").font(.headline).foregroundStyle(systemConfig.accent); Spacer() }
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
                    Text(shape.rawValue).font(.body)
                    if !systemConfig.moldVolumeIsDefault(for: shape) {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.resetMoldVolume(for: shape) }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: Binding(
                        get: { systemConfig.spec(for: shape).volume_ml },
                        set: { var u = systemConfig.spec(for: shape); u.volume_ml = $0; systemConfig.setSpec(u, for: shape) }
                    ), decimals: 4)
                    .multilineTextAlignment(.trailing).frame(width: 70)
                    Text("mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
            }
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
                    Text(shape.rawValue).font(.body)
                    if !systemConfig.moldCountIsDefault(for: shape) {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.resetMoldCount(for: shape) }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: Binding(
                        get: { Double(systemConfig.spec(for: shape).count) },
                        set: { var u = systemConfig.spec(for: shape); u.count = Int($0.rounded()); systemConfig.setSpec(u, for: shape) }
                    ), decimals: 0)
                    .multilineTextAlignment(.trailing).frame(width: 70)
                    Text("molds").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
            }
            Divider().padding(.horizontal, 16)
            NavigationLink {
                MoldCalibrationView()
                    .environment(systemConfig)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "scope")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CMTheme.textTertiary)
                    Text("Calibrate Mold")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CMTheme.textTertiary.opacity(0.6))
                }
                .padding(.horizontal, 16).padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { CMHaptic.light() })
        }
    }

    private func sugarRatioSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Sugar Ratio").font(.headline).foregroundStyle(systemConfig.accent); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Syrup : Granulated").font(.body)
                if systemConfig.glucoseToSugarMassRatio != 1.000 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.glucoseToSugarMassRatio = 1.000 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                NumericField(value: $systemConfig.glucoseToSugarMassRatio, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("Mass ratio of glucose syrup to granulated table sugar.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func ratiosSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Ratios").font(.headline).foregroundStyle(systemConfig.accent); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Water to Gelatin").font(.body)
                if systemConfig.waterToGelatinMassRatio != 3.000 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.waterToGelatinMassRatio = 3.000 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                NumericField(value: $systemConfig.waterToGelatinMassRatio, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Divider().padding(.leading, 16)
            HStack {
                Text("Water Mass % in Sugar Mix").font(.body)
                if systemConfig.waterMassPercentInSugarMix != 17.34 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.waterMassPercentInSugarMix = 17.34 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                NumericField(value: $systemConfig.waterMassPercentInSugarMix, decimals: 2)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func transferLiquidsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Transfer Liquids").font(.headline).foregroundStyle(systemConfig.accent); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("LSD Transfer Water").font(.body)
                if systemConfig.lsdTransferWater_mL != 1.000 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.lsdTransferWater_mL = 1.000 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                NumericField(value: $systemConfig.lsdTransferWater_mL, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text("mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func defaultUgPerTabSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Default µg / Tab").font(.headline).foregroundStyle(systemConfig.accent); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("LSD µg per Tab").font(.body)
                if systemConfig.defaultLsdUgPerTab != 117.0 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.defaultLsdUgPerTab = 117.0 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                NumericField(value: $systemConfig.defaultLsdUgPerTab, decimals: 1)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text("µg").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 10)
            Text("The µg / tab value used when resetting or starting a new batch.")
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
                (Text("Additives").font(.headline).foregroundStyle(systemConfig.accent)
                + Text(useMass ? " • Mass" : " • Vol")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary))
                Spacer(minLength: 8)
                if useMass {
                    Text(String(format: "Est. ρ %.3f g/mL", rhoMix))
                        .font(.caption).foregroundStyle(CMTheme.textSecondary)
                }
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { systemConfig.additivesInputAsMassPercent.toggle() }
                } label: {
                    Capsule()
                        .fill(useMass ? systemConfig.accent.opacity(0.5) : CMTheme.toggleOffBG)
                        .frame(width: 36, height: 20)
                        .overlay(alignment: useMass ? .trailing : .leading) {
                            Circle()
                                .fill(useMass ? systemConfig.accent : CMTheme.toggleOffKnob)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 2)
                        }
                }
                .buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            if useMass {
                // Mass mode inputs
                HStack {
                    Text("Potassium sorbate").font(.body)
                    if systemConfig.potassiumSorbatePercent != 0.078 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.potassiumSorbatePercent = 0.078 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: sorbateMassPpmBinding, decimals: 0)
                        .multilineTextAlignment(.trailing).frame(width: 60)
                    Text("ppm").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.leading, 16)
                HStack {
                    Text("Citric acid").font(.body)
                    if systemConfig.citricAcidPercent != 0.638 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.citricAcidPercent = 0.638 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: citricMassBinding, decimals: 3)
                        .multilineTextAlignment(.trailing).frame(width: 60)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Text(String(format: "ppm and %% are fractions of the final mass of the gummy mixture, using the estimated density of %.3f g/mL to calculate the equivalent volume fraction / percentage", rhoMix))
                    .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
            } else {
                // Volume mode inputs
                HStack {
                    Text("Potassium sorbate").font(.body)
                    if systemConfig.potassiumSorbatePercent != 0.078 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.potassiumSorbatePercent = 0.078 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: Binding(
                        get: { systemConfig.potassiumSorbatePercent * 10000.0 },
                        set: { systemConfig.potassiumSorbatePercent = $0 / 10000.0 }
                    ), decimals: 1)
                        .multilineTextAlignment(.trailing).frame(width: 60)
                    Text("ppm").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.leading, 16)
                HStack {
                    Text("Citric acid").font(.body)
                    if systemConfig.citricAcidPercent != 0.638 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.citricAcidPercent = 0.638 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: $systemConfig.citricAcidPercent, decimals: 3)
                        .multilineTextAlignment(.trailing).frame(width: 60)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                Text("ppm and % are fractions of the final volume of the gummy mixture")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    private func overageSection(viewModel: BatchConfigViewModel, systemConfig: SystemConfig) -> some View {
        @Bindable var viewModel = viewModel
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let useGummies = viewModel.overageInputAsGummies
        let totalWells = Double(viewModel.totalGummies(using: systemConfig))

        // Binding: extra gummies ↔ overageFactor
        let gummiesBinding = Binding<Double>(
            get: { (viewModel.overageFactor - 1.0) * totalWells },
            set: { viewModel.overageFactor = totalWells > 0 ? 1.0 + ($0 / totalWells) : 1.0 }
        )

        return VStack(spacing: 0) {
            HStack {
                Text("Overage").font(.headline).foregroundStyle(systemConfig.accent)
                Spacer(minLength: 8)
                if useGummies {
                    Text(String(format: "Est. ρ %.3f g/mL", rhoMix))
                        .font(.caption).foregroundStyle(CMTheme.textSecondary)
                }
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { viewModel.overageInputAsGummies.toggle() }
                } label: {
                    Capsule()
                        .fill(useGummies ? systemConfig.accent.opacity(0.5) : CMTheme.toggleOffBG)
                        .frame(width: 36, height: 20)
                        .overlay(alignment: useGummies ? .trailing : .leading) {
                            Circle()
                                .fill(useGummies ? systemConfig.accent : CMTheme.toggleOffKnob)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 2)
                        }
                }
                .buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            HStack {
                Text("Extra Gummy Mixture Volume").font(.body)
                if viewModel.overageFactor != 1.03 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { viewModel.overageFactor = 1.03 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                if useGummies {
                    NumericField(value: gummiesBinding, decimals: 1)
                        .multilineTextAlignment(.trailing).frame(width: 50)
                    Text("Gummies").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                } else {
                    NumericField(value: $viewModel.overagePercent, decimals: 2)
                        .multilineTextAlignment(.trailing).frame(width: 50)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }
            }.padding(.horizontal, 16).padding(.vertical, 10)
            if useGummies {
                Text("This is the number of extra \(viewModel.selectedShape.rawValue) gummies that the extra final gummy mixture volume will create.")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.bottom, 10)
            }
        }
    }

    private func densitiesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let rows: [(String, ReferenceWritableKeyPath<SystemConfig, Double>)] = [
            ("Water",              \.densityWater),
            ("Glucose Syrup",      \.densityGlucoseSyrup),
            ("Sucrose",            \.densitySucrose),
            ("Gelatin",            \.densityGelatin),
            ("Citric Acid",        \.densityCitricAcid),
            ("Potassium Sorbate",  \.densityPotassiumSorbate),
            ("Flavor Oil",         \.densityFlavorOil),
            ("Food Coloring",      \.densityFoodColoring),
            ("Terpenes",           \.densityTerpenes),
            ("Final Gummy Mixture (Est.)", \.estimatedFinalMixDensity),
        ]
        return VStack(spacing: 0) {
            HStack {
                Text("Substance Densities").font(.headline).foregroundStyle(systemConfig.accent)
                Spacer()
                Text("g/mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                let (label, keyPath) = row
                HStack {
                    Text(label).font(.body)
                    if !systemConfig.densityIsDefault(keyPath) {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.resetDensity(keyPath) }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                    NumericField(value: Binding(
                        get: { systemConfig[keyPath: keyPath] },
                        set: { systemConfig[keyPath: keyPath] = $0 }
                    ), decimals: 4)
                    .multilineTextAlignment(.trailing).frame(width: 70)
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
            ("Molds Filled",          "#", \.resolutionMoldsFilled,       \.resolutionMoldsFilled),
        ]
        return VStack(spacing: 0) {
            HStack { Text("Measurement Resolutions").font(.headline).foregroundStyle(systemConfig.accent); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                let (label, unit, readKP, writeKP) = row
                let currentValue = systemConfig[keyPath: readKP]
                Button {
                    CMHaptic.light()
                    resolutionPickerRow = ResolutionPickerRow(
                        label: label,
                        unit: unit,
                        current: currentValue,
                        onSelect: { newValue in
                            systemConfig[keyPath: writeKP] = newValue
                        }
                    )
                } label: {
                    HStack {
                        Text(label)
                            .font(.body)
                            .foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text(currentValue.label(unit: unit))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(systemConfig.accent)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(systemConfig.accent.opacity(0.12))
                                    .overlay(Capsule().strokeBorder(systemConfig.accent.opacity(0.25), lineWidth: 1))
                            )
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CMTheme.textTertiary)
                            .padding(.leading, 4)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if index < rows.count - 1 { Divider().padding(.leading, 16) }
            }
            Text("Set the precision matching your scale's readout for each measurement input.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary).padding(.horizontal, 16).padding(.vertical, 10)
        }
        .sheet(item: $resolutionPickerRow) { row in
            ResolutionWheelPickerSheet(row: row)
        }
    }

    @State private var showTareWeights = false

    private func containerTareWeightsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let labels = (0..<26).map { String(UnicodeScalar($0 + 65)!) }
        let nonZeroCount = labels.filter { systemConfig.containerTare(for: $0) > 0 }.count

        return VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { showTareWeights.toggle() }
            } label: {
                HStack {
                    Text("Container Tare Weights")
                        .font(.headline).foregroundStyle(systemConfig.accent)
                    if nonZeroCount > 0 {
                        Text("\(nonZeroCount)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(systemConfig.accent.opacity(0.7))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(showTareWeights ? -180 : 0))
                        .animation(.cmExpand, value: showTareWeights)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if showTareWeights {
                ThemedDivider(indent: 16)

                // Reset all button
                if nonZeroCount > 0 {
                    HStack {
                        Spacer()
                        Button {
                            CMHaptic.medium()
                            withAnimation(.cmSpring) { systemConfig.resetAllContainerTares() }
                        } label: {
                            Label("Reset All", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.top, 6)
                }

                ForEach(Array(labels.enumerated()), id: \.offset) { index, letter in
                    let tare = systemConfig.containerTare(for: letter)
                    HStack(spacing: 8) {
                        Text(letter)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(tare > 0 ? CMTheme.textPrimary : CMTheme.textTertiary)
                            .frame(width: 20)
                        NumericField(value: Binding(
                            get: { systemConfig.containerTare(for: letter) },
                            set: { systemConfig.setContainerTare($0, for: letter) }
                        ), decimals: 3)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        Text("g")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(CMTheme.textTertiary)
                        if tare > 0 {
                            Button {
                                CMHaptic.light()
                                withAnimation(.cmSpring) { systemConfig.resetContainerTare(for: letter) }
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(CMTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    if index < labels.count - 1 { Divider().padding(.leading, 48) }
                }
                Text("Saved tare weights are automatically loaded when selecting a container in the dehydration section of a batch.")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    private func appearanceSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Appearance").font(.headline).foregroundStyle(systemConfig.accent)
                Spacer()
                Button {
                    CMHaptic.medium()
                    withAnimation(.cmSpring) {
                        systemConfig.isDarkMode.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(systemConfig.isDarkMode
                                ? CMTheme.chipBG
                                : Color(red: 0.992, green: 0.843, blue: 0.098).opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: systemConfig.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(systemConfig.isDarkMode
                                ? CMTheme.textSecondary
                                : Color(red: 0.992, green: 0.843, blue: 0.098))
                            .symbolEffect(.bounce, value: systemConfig.isDarkMode)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Text(systemConfig.isDarkMode ? "Dark mode active" : "Solarized light mode active")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }

    private func hapticSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Haptics").font(.headline).foregroundStyle(systemConfig.accent)
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
                Text(systemConfig.accentDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(systemConfig.accent)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AccentTheme.originalCases) { theme in
                    accentSwatch(theme: theme, systemConfig: systemConfig)
                }
            }
            .padding(.horizontal, 16)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AccentTheme.extendedCases) { theme in
                    accentSwatch(theme: theme, systemConfig: systemConfig)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 12)

            // Custom accent colors
            if !systemConfig.customAccentColors.isEmpty {
                ThemedDivider(indent: 20).padding(.bottom, 8)

                HStack {
                    Text("Custom Colors")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.bottom, 8)

                ForEach(systemConfig.customAccentColors) { custom in
                    let isSelected = systemConfig.selectedCustomAccentID == custom.id
                    HStack(spacing: 12) {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) {
                                systemConfig.selectedCustomAccentID = custom.id
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(custom.color)
                                        .frame(width: 32, height: 32)
                                    if isSelected {
                                        Circle()
                                            .stroke(CMTheme.selectionRing, lineWidth: 2)
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                                    }
                                }
                                Text(custom.name)
                                    .font(.body)
                                    .foregroundStyle(isSelected ? CMTheme.textPrimary : CMTheme.textSecondary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) {
                                systemConfig.deleteCustomAccentColor(id: custom.id)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }
            }

            // Create custom accent color button
            ThemedDivider(indent: 20).padding(.vertical, 8)

            Button {
                CMHaptic.light()
                showCustomColorCreator = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Create Custom Accent Color")
                        .font(.subheadline).fontWeight(.medium)
                    Spacer()
                }
                .foregroundStyle(systemConfig.accent)
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCustomColorCreator) {
                CustomAccentColorCreatorView(systemConfig: systemConfig)
            }

            Text("Choose the accent color used for buttons, selections, and highlights throughout the app.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }

    private func accentSwatch(theme: AccentTheme, systemConfig: SystemConfig) -> some View {
        let isSelected = systemConfig.accentTheme == theme && systemConfig.selectedCustomAccentID == nil
        return Button {
            CMHaptic.light()
            withAnimation(.cmSpring) {
                systemConfig.selectedCustomAccentID = nil
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
                            .stroke(CMTheme.selectionRing, lineWidth: 2.5)
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

    private func developerModeSection(systemConfig: SystemConfig, viewModel: BatchConfigViewModel) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Developer Mode").font(.headline).foregroundStyle(systemConfig.accent)
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
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synthetic Measurements").font(.body)
                        Text("Fill measurement fields with realistic mock data")
                            .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { systemConfig.syntheticMeasurementsEnabled },
                        set: { newValue in
                            CMHaptic.medium()
                            systemConfig.syntheticMeasurementsEnabled = newValue
                            if newValue {
                                withAnimation(.cmSpring) { systemConfig.applySyntheticMeasurements(to: viewModel) }
                            } else {
                                withAnimation(.cmSpring) { systemConfig.clearSyntheticMeasurements(from: viewModel) }
                            }
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))

                Divider().padding(.horizontal, 16)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synthetic Dataset 1").font(.body)
                        Text("100 synthetic batches for density analysis")
                            .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    }
                    Spacer()
                    Toggle("", isOn: $systemConfig.syntheticDataSet1Enabled)
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

    private func settingsActionsSection(systemConfig: SystemConfig) -> some View {
        let strawberryRed = Color(red: 0.929, green: 0.278, blue: 0.290)
        let hasChanges = systemConfig.hasSettingsChangedFromDefaults
        let hasFactoryChanges = systemConfig.hasSettingsChangedFromFactory
        return VStack(spacing: 0) {
            // Factory reset
            Button {
                CMHaptic.medium()
                showFactoryResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Factory Reset")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(hasFactoryChanges ? strawberryRed : CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!hasFactoryChanges)

            Text("Remove all user provided system defaults back to factory values")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.vertical, 6)

            Divider().padding(.horizontal, 16)

            // Reset to defaults
            Button {
                CMHaptic.medium()
                showResetToDefaultsAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .medium))
                    Text("Reset")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(hasChanges ? strawberryRed : CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!hasChanges)

            Text("Reset settings back to default")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.vertical, 6)

            Divider().padding(.horizontal, 16)

            // Set as default
            Button {
                CMHaptic.medium()
                showAssignDefaultsAlert = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                    Text("Set as default")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(hasChanges ? strawberryRed : CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!hasChanges)

            Divider().padding(.horizontal, 16)

            // Save to clipboard
            Button {
                CMHaptic.light()
                if let jsonString = systemConfig.settingsJSONString() {
                    #if os(iOS) || os(visionOS)
                    UIPasteboard.general.string = jsonString
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(jsonString, forType: .string)
                    #endif
                }
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                    Text("Save all settings to clipboard")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(systemConfig.accent)
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, 16)

            // Load from clipboard
            Button {
                CMHaptic.medium()
                #if os(iOS) || os(visionOS)
                guard let str = UIPasteboard.general.string,
                      let data = str.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                #elseif os(macOS)
                guard let str = NSPasteboard.general.string(forType: .string),
                      let data = str.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                #endif
                clipboardJSON = json
                showLoadFromClipboardAlert = true
            } label: {
                HStack {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 14, weight: .medium))
                    Text("Load settings from clipboard")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(systemConfig.accent)
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Custom Accent Color Creator

struct CustomAccentColorCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    var systemConfig: SystemConfig

    @State private var colorName: String = ""
    @State private var hue: Double = 0.55
    @State private var saturation: Double = 0.7
    @State private var brightness: Double = 0.85

    private var previewColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Color preview
                    RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                        .fill(previewColor)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                                .stroke(CMTheme.cardStroke, lineWidth: 1)
                        )
                        .shadow(color: previewColor.opacity(0.4), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 16)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Name")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(CMTheme.textSecondary)
                        TextField("My Custom Color", text: $colorName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                                    .fill(CMTheme.fieldBG)
                            )
                    }
                    .padding(.horizontal, 16)

                    // HSV sliders
                    VStack(spacing: 16) {
                        hsvSlider(label: "Hue", value: $hue, gradient: hueGradient())
                        hsvSlider(label: "Saturation", value: $saturation, gradient: saturationGradient())
                        hsvSlider(label: "Brightness", value: $brightness, gradient: brightnessGradient())
                    }
                    .padding(.horizontal, 16)

                    // Save button
                    Button {
                        let name = colorName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalName = name.isEmpty ? "Custom \(systemConfig.customAccentColors.count + 1)" : name
                        let newColor = CustomAccentColor(
                            id: UUID(),
                            name: finalName,
                            hue: hue,
                            saturation: saturation,
                            brightness: brightness
                        )
                        CMHaptic.success()
                        withAnimation(.cmSpring) {
                            systemConfig.addCustomAccentColor(newColor)
                            systemConfig.selectedCustomAccentID = newColor.id
                        }
                        dismiss()
                    } label: {
                        Text("Save Color")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                                    .fill(previewColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .background(CMTheme.pageBG)
            .navigationTitle("New Accent Color")
            .preferredColorScheme(systemConfig.preferredColorScheme)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func hsvSlider(label: String, value: Binding<Double>, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.subheadline).monospacedDigit()
                    .foregroundStyle(CMTheme.textSecondary)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(gradient)
                    .frame(height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(CMTheme.overlayHighlight, lineWidth: 1)
                    )
                GeometryReader { geo in
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .frame(width: 24, height: 24)
                        .offset(x: value.wrappedValue * (geo.size.width - 24))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let fraction = drag.location.x / geo.size.width
                                    value.wrappedValue = min(max(fraction, 0), 1)
                                }
                        )
                }
                .frame(height: 28)
            }
        }
    }

    private func hueGradient() -> LinearGradient {
        let colors = stride(from: 0.0, through: 1.0, by: 0.1).map { h in
            Color(hue: h, saturation: saturation, brightness: brightness)
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private func saturationGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0, brightness: brightness),
                Color(hue: hue, saturation: 1, brightness: brightness)
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }

    private func brightnessGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: saturation, brightness: 0),
                Color(hue: hue, saturation: saturation, brightness: 1)
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }
}

// MARK: - Resolution Wheel Picker

/// Identifies a row in the measurement resolutions section so it can drive a sheet.
struct ResolutionPickerRow: Identifiable {
    let id = UUID()
    let label: String
    let unit: String
    let current: MeasurementResolution
    let onSelect: (MeasurementResolution) -> Void
}

/// A sleek bottom-sheet wheel picker for a single MeasurementResolution.
struct ResolutionWheelPickerSheet: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss
    let row: ResolutionPickerRow

    @State private var selected: MeasurementResolution

    init(row: ResolutionPickerRow) {
        self.row = row
        _selected = State(initialValue: row.current)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(CMTheme.textTertiary)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Title
            Text(row.label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CMTheme.textPrimary)
                .padding(.bottom, 4)

            Text("Scale Resolution")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CMTheme.textSecondary)
                .padding(.bottom, 20)

            // Wheel picker
            Picker("", selection: $selected) {
                ForEach(MeasurementResolution.allCases) { res in
                    Text(res.label(unit: row.unit))
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .tag(res)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: selected) { _, newVal in
                CMHaptic.light()
                row.onSelect(newVal)
            }
            .frame(height: 160)
            .padding(.horizontal, 20)

            // Done button
            Button {
                CMHaptic.success()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(systemConfig.accent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(CMTheme.cardBG.ignoresSafeArea())
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(systemConfig.preferredColorScheme)
    }
}
