//
//  SettingsView.swift
//  CandyMan
//
//  Full-screen settings panel controlling system-wide configuration stored in
//  SystemConfig. Organized into collapsible category sections:
//
//    • Appearance       — dark/light mode, accent color, theme picker
//    • Mold Geometry    — per-shape volume and cavity count, mold calibration
//    • Batch Defaults   — gelatin %, water ratio, overage, preservative ppm
//    • Active Defaults  — substance densities, concentration units
//    • Flavor Defaults  — terpene PPM, flavor oil volume %
//    • Color Defaults   — color volume %
//    • Additives        — citric acid, potassium sorbate toggles + ppm
//    • Data             — assign-as-defaults, factory reset, JSON import/export

//
//  Also contains helper views: ResolutionPickerRow, CustomColorCreatorView.
//

import SwiftUI

// MARK: - SettingsView

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
    @State private var showDesignColorEditor: SystemConfig.DesignColorRole? = nil
    @State private var resolutionPickerRow: ResolutionPickerRow? = nil

    private var isRegular: Bool { sizeClass == .regular }

    private func categoryLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CMTheme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }

    // MARK: - iPad Two-Column Layout
    // AnyView erasure forces the compiler to resolve each sub-group's type
    // independently, preventing the deeply-nested generic type that causes
    // a stack overflow on physical iPad hardware.

    private var ipadColumns: some View {
        HStack(alignment: .top, spacing: 0) {
            ipadLeftColumn
            ipadRightColumn
        }
    }

    private var ipadLeftColumn: some View {
        VStack(spacing: 12) {
            ipadLeftBatchParams
            ipadLeftCalibration
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var ipadLeftBatchParams: AnyView {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
        return AnyView(Group {
            categoryLabel("Batch Parameters")
            overageSection(viewModel: viewModel, systemConfig: systemConfig).cardStyle()
            additivesSection(systemConfig: systemConfig).cardStyle()
            defaultUgPerTabSection(systemConfig: systemConfig).cardStyle()
            transferLiquidsSection(systemConfig: systemConfig).cardStyle()
        })
    }

    private var ipadLeftCalibration: AnyView {
        @Bindable var systemConfig = systemConfig
        return AnyView(Group {
            categoryLabel("Calibration")
            traysSection(systemConfig: systemConfig).cardStyle()
            densitiesSection(systemConfig: systemConfig).cardStyle()
            measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
            containerTareWeightsSection(systemConfig: systemConfig).cardStyle()
            scalesSection(systemConfig: systemConfig).cardStyle()
        })
    }

    private var ipadRightColumn: some View {
        VStack(spacing: 12) {
            ipadRightMixture
            ipadRightPreferences
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var ipadRightMixture: AnyView {
        @Bindable var systemConfig = systemConfig
        return AnyView(Group {
            categoryLabel("Mixture Parameters")
            ratiosSection(systemConfig: systemConfig).cardStyle()
            sugarRatioSection(systemConfig: systemConfig).cardStyle()
        })
    }

    private var ipadRightPreferences: AnyView {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
        return AnyView(Group {
            categoryLabel("Preferences")
            hapticSection(systemConfig: systemConfig).cardStyle()
            accentColorSection(systemConfig: systemConfig).cardStyle()
            designLanguageSection(systemConfig: systemConfig).cardStyle()
            developerModeSection(systemConfig: systemConfig, viewModel: viewModel).cardStyle()
            settingsActionsSection(systemConfig: systemConfig).cardStyle()
        })
    }

    // MARK: - iPhone Single-Column Layout

    private var iphoneColumn: some View {
        VStack(spacing: 12) {
            iphoneColumnTop
            iphoneColumnBottom
        }
    }

    private var iphoneColumnTop: AnyView {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
        return AnyView(Group {
            categoryLabel("Batch Parameters")
            overageSection(viewModel: viewModel, systemConfig: systemConfig).cardStyle()
            additivesSection(systemConfig: systemConfig).cardStyle()
            defaultUgPerTabSection(systemConfig: systemConfig).cardStyle()
            transferLiquidsSection(systemConfig: systemConfig).cardStyle()

            categoryLabel("Mixture Parameters")
            ratiosSection(systemConfig: systemConfig).cardStyle()
            sugarRatioSection(systemConfig: systemConfig).cardStyle()
        })
    }

    private var iphoneColumnBottom: AnyView {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
        return AnyView(Group {
            categoryLabel("Calibration")
            traysSection(systemConfig: systemConfig).cardStyle()
            densitiesSection(systemConfig: systemConfig).cardStyle()
            measurementResolutionsSection(systemConfig: systemConfig).cardStyle()
            containerTareWeightsSection(systemConfig: systemConfig).cardStyle()
            scalesSection(systemConfig: systemConfig).cardStyle()

            categoryLabel("Preferences")
            hapticSection(systemConfig: systemConfig).cardStyle()
            accentColorSection(systemConfig: systemConfig).cardStyle()
            designLanguageSection(systemConfig: systemConfig).cardStyle()
            developerModeSection(systemConfig: systemConfig, viewModel: viewModel).cardStyle()
            settingsActionsSection(systemConfig: systemConfig).cardStyle()
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isRegular {
                    ipadColumns.padding(.vertical, 12)
                } else {
                    iphoneColumn.padding(.vertical, 12)
                }
            }
            .background(CMTheme.pageBG)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Settings")
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
            // Collapsible header
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { showTrays.toggle() }
            } label: {
                HStack {
                    Text("Trays").cmSectionTitle(accent: systemConfig.accent)
                    Spacer()
                    CMDisclosureChevron(isExpanded: showTrays)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if showTrays {
                // — Mold Volume subtitle —
                HStack {
                    Text("Mold Volume").cmSubsectionTitle()
                    Spacer()
                    Text("mL / mold").cmFootnote()
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
                                    .cmResetIcon()
                            }
                            .buttonStyle(.plain)
                            .cmResetTransition()
                        }
                        Spacer()
                        NumericField(value: Binding(
                            get: { systemConfig.spec(for: shape).volumeML },
                            set: { var u = systemConfig.spec(for: shape); u.volumeML = $0; systemConfig.setSpec(u, for: shape) }
                        ), decimals: 4)
                        .multilineTextAlignment(.trailing).frame(width: 70)
                        Text("mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }.cmSettingsRowPadding()
                    if shape != GummyShape.allCases.last { Divider().padding(.leading, 56) }
                }
                // ———————— Divider between subsections ————————
                Divider().padding(.horizontal, 16).padding(.vertical, 4)

                // — Molds per Tray subtitle —
                HStack {
                    Text("Molds per Tray").cmSubsectionTitle()
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
                                    .cmResetIcon()
                            }
                            .buttonStyle(.plain)
                            .cmResetTransition()
                        }
                        Spacer()
                        NumericField(value: Binding(
                            get: { Double(systemConfig.spec(for: shape).count) },
                            set: { var u = systemConfig.spec(for: shape); u.count = Int($0.rounded()); systemConfig.setSpec(u, for: shape) }
                        ), decimals: 0)
                        .multilineTextAlignment(.trailing).frame(width: 70)
                        Text("molds").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }.cmSettingsRowPadding()
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
    }

    private func sugarRatioSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("Sugar Ratio").cmSectionTitle(accent: systemConfig.accent); Spacer() }.padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("Syrup : Granulated").font(.body)
                if systemConfig.glucoseToSugarMassRatio != 1.000 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.glucoseToSugarMassRatio = 1.000 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                NumericField(value: $systemConfig.glucoseToSugarMassRatio, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text(": 1").font(.body).foregroundStyle(.secondary)
            }.cmSettingsRowPadding()
            Text("Mass ratio of glucose syrup to granulated table sugar.")
                .cmFootnote().cmSettingsRowPadding()
        }
    }

    @State private var waterConcUseVol = false

    private func ratiosSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let useMass = !waterConcUseVol
        let rhoW = systemConfig.densityWater
        let rhoG = systemConfig.densityGelatin
        let rhoSugarAvg = systemConfig.averageSugarDensity

        // ── Gelatin mix: mass% ↔ vol% conversions ──
        // Stored: waterToGelatinMassRatio φ (mass water / mass gelatin)
        // mass% = φ / (φ + 1) × 100
        // vol%  = (φ/ρw) / (φ/ρw + 1/ρg) × 100
        let gelatinMassPercent: Double = {
            let phi = systemConfig.waterToGelatinMassRatio
            return phi / (phi + 1.0) * 100.0
        }()
        let gelatinVolPercent: Double = {
            let phi = systemConfig.waterToGelatinMassRatio
            let vW = phi / rhoW
            let vG = 1.0 / rhoG
            return vW / (vW + vG) * 100.0
        }()
        let gelatinBinding = Binding<Double>(
            get: { useMass ? gelatinMassPercent : gelatinVolPercent },
            set: { newPct in
                let clamped = min(max(newPct, 0.001), 99.999)
                if useMass {
                    // mass% → φ: φ = mass% / (100 - mass%)
                    systemConfig.waterToGelatinMassRatio = clamped / (100.0 - clamped)
                } else {
                    // vol% → φ: vol_water = φ/ρw, vol_gelatin = 1/ρg
                    // vol% = (φ/ρw) / (φ/ρw + 1/ρg) → φ = (vol%/100) × (1/ρg) × ρw / (1 - vol%/100)
                    let f = clamped / 100.0
                    let phi = f * (1.0 / rhoG) * rhoW / (1.0 - f)
                    systemConfig.waterToGelatinMassRatio = phi
                }
            }
        )

        // ── Sugar mix: mass% ↔ vol% conversions ──
        // Stored: waterMassPercentInSugarMix (mass%)
        // vol% = (massPct/ρw) / (massPct/ρw + (100-massPct)/ρsugar) × 100
        let sugarVolPercent: Double = {
            let mW = systemConfig.waterMassPercentInSugarMix
            let mS = 100.0 - mW
            guard mW > 0, mS > 0, rhoW > 0, rhoSugarAvg > 0 else { return 0 }
            let vW = mW / rhoW
            let vS = mS / rhoSugarAvg
            return vW / (vW + vS) * 100.0
        }()
        let sugarBinding = Binding<Double>(
            get: { useMass ? systemConfig.waterMassPercentInSugarMix : sugarVolPercent },
            set: { newPct in
                let clamped = min(max(newPct, 0.01), 99.99)
                if useMass {
                    systemConfig.waterMassPercentInSugarMix = clamped
                } else {
                    // vol% → mass%: vW = massPct/ρw, vS = (100-massPct)/ρsugar
                    // vol% = vW/(vW+vS) → massPct = vol% × ρw / (vol%×ρw + (100-vol%)×ρsugar) × 100... simplified:
                    let f = clamped / 100.0
                    let massPct = f * rhoW / (f * rhoW + (1.0 - f) * rhoSugarAvg) * 100.0
                    systemConfig.waterMassPercentInSugarMix = massPct
                }
            }
        )

        // Default values for reset detection
        let gelatinDefault: Double = useMass
            ? 3.0 / (3.0 + 1.0) * 100.0
            : { let vW = 3.0 / rhoW; let vG = 1.0 / rhoG; return vW / (vW + vG) * 100.0 }()
        let sugarDefault: Double = useMass
            ? 17.34
            : { let vW = 17.34 / rhoW; let vS = (100.0 - 17.34) / rhoSugarAvg; return vW / (vW + vS) * 100.0 }()

        return VStack(spacing: 0) {
            // Header with toggle
            HStack {
                (Text("Water Concentrations").font(.headline).foregroundStyle(systemConfig.accent)
                + Text(useMass ? " • Mass" : " • Vol")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary))
                Spacer(minLength: 8)
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { waterConcUseVol.toggle() }
                } label: {
                    Capsule()
                        .fill(waterConcUseVol ? systemConfig.accent.opacity(0.5) : CMTheme.toggleOffBG)
                        .frame(width: 36, height: 20)
                        .overlay(alignment: waterConcUseVol ? .trailing : .leading) {
                            Circle()
                                .fill(waterConcUseVol ? systemConfig.accent : CMTheme.toggleOffKnob)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 2)
                        }
                }
                .buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            // Water in Gelatin Mix
            HStack {
                Text("Water in Gelatin Mix").font(.body)
                if abs(gelatinBinding.wrappedValue - gelatinDefault) > 0.001 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.waterToGelatinMassRatio = 3.000 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                NumericField(value: gelatinBinding, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 70)
                Text(useMass ? "mass %" : "vol %").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.cmSettingsRowPadding()

            Divider().padding(.leading, 16)

            // Water in Sugar Mix
            HStack {
                Text("Water in Sugar Mix").font(.body)
                if abs(sugarBinding.wrappedValue - sugarDefault) > 0.001 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.waterMassPercentInSugarMix = 17.34 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                NumericField(value: sugarBinding, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 70)
                Text(useMass ? "mass %" : "vol %").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.cmSettingsRowPadding()
        }
    }

    private func transferLiquidsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("LSD Transfer Liquid").cmSectionTitle(accent: systemConfig.accent); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("LSD Transfer Water").font(.body)
                if systemConfig.lsdTransferWaterML != 1.000 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.lsdTransferWaterML = 1.000 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                NumericField(value: $systemConfig.lsdTransferWaterML, decimals: 3)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text("mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.cmSettingsRowPadding()
        }
    }

    private func defaultUgPerTabSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack { Text("LSD Tab Strength").cmSectionTitle(accent: systemConfig.accent); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            HStack {
                Text("LSD µg per Tab").font(.body)
                if systemConfig.defaultLsdUgPerTab != 117.0 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.defaultLsdUgPerTab = 117.0 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                NumericField(value: $systemConfig.defaultLsdUgPerTab, decimals: 1)
                    .multilineTextAlignment(.trailing).frame(width: 60)
                Text("µg").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.cmSettingsRowPadding()
            Text("The µg / tab value used when resetting or starting a new batch.")
                .cmFootnote().cmSettingsRowPadding()
        }
    }

    private func additivesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let useVol = systemConfig.additivesInputAsMassPercent  // toggle ON = vol%

        // Mass % binding for sorbate: mass% = vol% × (ρ_substance / ρ_mix)
        let sorbateMassBinding = Binding<Double>(
            get: {
                guard rhoMix > 0 else { return 0 }
                return systemConfig.potassiumSorbatePercent * systemConfig.densityPotassiumSorbate / rhoMix
            },
            set: { newMassPct in
                guard rhoMix > 0, systemConfig.densityPotassiumSorbate > 0 else { return }
                systemConfig.potassiumSorbatePercent = newMassPct * rhoMix / systemConfig.densityPotassiumSorbate
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
                (Text("Preservatives").font(.headline).foregroundStyle(systemConfig.accent)
                + Text(useVol ? " • Vol" : " • Mass")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary))
                Spacer(minLength: 8)
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { systemConfig.additivesInputAsMassPercent.toggle() }
                } label: {
                    Capsule()
                        .fill(useVol ? systemConfig.accent.opacity(0.5) : CMTheme.toggleOffBG)
                        .frame(width: 36, height: 20)
                        .overlay(alignment: useVol ? .trailing : .leading) {
                            Circle()
                                .fill(useVol ? systemConfig.accent : CMTheme.toggleOffKnob)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 2)
                        }
                }
                .buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            if useVol {
                // Volume mode inputs (toggle ON)
                HStack {
                    Text("Potassium sorbate").font(.body)
                    if systemConfig.potassiumSorbatePercent != 0.078 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.potassiumSorbatePercent = 0.078 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .cmResetIcon()
                        }
                        .buttonStyle(.plain)
                        .cmResetTransition()
                    }
                    Spacer()
                    NumericField(value: Binding(
                        get: { systemConfig.potassiumSorbatePercent },
                        set: { systemConfig.potassiumSorbatePercent = $0 }
                    ), decimals: 4)
                        .multilineTextAlignment(.trailing).frame(width: 80)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.cmSettingsRowPadding()
                Divider().padding(.leading, 16)
                HStack {
                    Text("Citric acid").font(.body)
                    if systemConfig.citricAcidPercent != 0.638 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.citricAcidPercent = 0.638 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .cmResetIcon()
                        }
                        .buttonStyle(.plain)
                        .cmResetTransition()
                    }
                    Spacer()
                    NumericField(value: $systemConfig.citricAcidPercent, decimals: 3)
                        .multilineTextAlignment(.trailing).frame(width: 60)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.cmSettingsRowPadding()
                Text("Volume % of the final gummy mixture.")
                    .cmFootnote().cmSettingsRowPadding()
            } else {
                // Mass mode inputs (toggle OFF — default)
                HStack {
                    Text("Potassium sorbate").font(.body)
                    if systemConfig.potassiumSorbatePercent != 0.078 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.potassiumSorbatePercent = 0.078 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .cmResetIcon()
                        }
                        .buttonStyle(.plain)
                        .cmResetTransition()
                    }
                    Spacer()
                    NumericField(value: sorbateMassBinding, decimals: 4)
                        .multilineTextAlignment(.trailing).frame(width: 80)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.cmSettingsRowPadding()
                Divider().padding(.leading, 16)
                HStack {
                    Text("Citric acid").font(.body)
                    if systemConfig.citricAcidPercent != 0.638 {
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { systemConfig.citricAcidPercent = 0.638 }
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .cmResetIcon()
                        }
                        .buttonStyle(.plain)
                        .cmResetTransition()
                    }
                    Spacer()
                    NumericField(value: citricMassBinding, decimals: 3)
                        .multilineTextAlignment(.trailing).frame(width: 60)
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }.cmSettingsRowPadding()
                Text(String(format: "Mass %% of the final gummy mixture (est. ρ %.3f g/mL).", rhoMix))
                    .cmFootnote().cmSettingsRowPadding()
            }
        }
    }

    private func overageSection(viewModel: BatchConfigViewModel, systemConfig: SystemConfig) -> some View {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
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
                Text("Overage").cmSectionTitle(accent: systemConfig.accent)
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
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
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
            }.cmSettingsRowPadding()
            if useGummies {
                Text("This is the number of extra \(viewModel.selectedShape.rawValue) gummies that the extra final gummy mixture volume will create.")
                    .cmFootnote().padding(.horizontal, 16).padding(.bottom, 10)
            }

            Divider().padding(.horizontal, 16).padding(.vertical, 4)

            // Sugar Mixture Overage
            HStack {
                Text("Sugar Mixture Overage").font(.body)
                if systemConfig.sugarMixtureOveragePercent != 5.0 {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { systemConfig.sugarMixtureOveragePercent = 5.0 }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon()
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                NumericField(value: $systemConfig.sugarMixtureOveragePercent, decimals: 1)
                    .multilineTextAlignment(.trailing).frame(width: 50)
                Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.cmSettingsRowPadding()
            Text("Extra sugar mixture to prepare in case of spills. Shown as a separate column in Batch Output — does not affect the main batch calculation.")
                .cmFootnote().padding(.horizontal, 16).padding(.bottom, 10)


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
            // Collapsible header
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { showDensities.toggle() }
            } label: {
                HStack {
                    Text("Substance Densities").cmSectionTitle(accent: systemConfig.accent)
                    Spacer()
                    if !showDensities {
                        Text("g/mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    CMDisclosureChevron(isExpanded: showDensities)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if showDensities {
                HStack {
                    Spacer()
                    Text("g/mL").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }
                .padding(.horizontal, 16).padding(.bottom, 4)

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
                                    .cmResetIcon()
                            }
                            .buttonStyle(.plain)
                            .cmResetTransition()
                        }
                        Spacer()
                        NumericField(value: Binding(
                            get: { systemConfig[keyPath: keyPath] },
                            set: { systemConfig[keyPath: keyPath] = $0 }
                        ), decimals: 4)
                        .multilineTextAlignment(.trailing).frame(width: 70)
                    }
                    .cmSettingsRowPadding()
                    if index < rows.count - 1 { Divider().padding(.leading, 16) }
                }
                Text("Densities used to convert between mass and volume for each substance.")
                    .cmFootnote().cmSettingsRowPadding()
            }
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
            // Collapsible header
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { showResolutions.toggle() }
            } label: {
                HStack {
                    Text("Measurement Resolutions").cmSectionTitle(accent: systemConfig.accent)
                    Spacer()
                    CMDisclosureChevron(isExpanded: showResolutions)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if showResolutions {
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
                        .cmSettingsRowPadding()
                    }
                    .buttonStyle(.plain)
                    if index < rows.count - 1 { Divider().padding(.leading, 16) }
                }
                Text("Set the precision matching your scale's readout for each measurement input.")
                    .cmFootnote().cmSettingsRowPadding()
            }
        }
        .sheet(item: $resolutionPickerRow) { row in
            ResolutionWheelPickerSheet(row: row)
                .environment(systemConfig)
        }
    }

    @State private var showTrays = false
    @State private var showDensities = false
    @State private var showResolutions = false
    @State private var showTareWeights = false
    @State private var showScales = false
    // Scale management state
    @State private var scaleToEdit: ScaleSpec? = nil
    @State private var showEditScaleConfirm = false
    @State private var showDeleteScaleConfirm = false
    @State private var scaleIndexToDelete: Int? = nil
    @State private var showAddScaleSheet = false
    @State private var newScaleName = ""
    @State private var newScaleResolution: Double = 0.01
    @State private var newScaleCapacity: Double = 500

    // Container management state
    @State private var containerToEdit: SystemConfig.BeakerContainer? = nil
    @State private var showEditContainerConfirm = false
    @State private var showDeleteContainerConfirm = false
    @State private var containerIndexToDelete: Int? = nil
    @State private var showAddContainerSheet = false

    private func containerTareWeightsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let isDefault = systemConfig.containers == SystemConfig.BeakerContainer.factoryDefaults

        return VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { showTareWeights.toggle() }
            } label: {
                HStack {
                    Text("Container Tare Weights")
                        .cmSectionTitle(accent: systemConfig.accent)
                    Spacer()
                    CMDisclosureChevron(isExpanded: showTareWeights)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if showTareWeights {
                ThemedDivider(indent: 16)

                // Column headers
                HStack(spacing: 4) {
                    Text("Container").font(.caption2).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    Text("Tare").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                ForEach(Array(systemConfig.containers.enumerated()), id: \.element.id) { index, container in
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Text(container.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CMTheme.textPrimary)
                            Spacer()
                            Text(String(format: "%.3f g", container.tareWeight))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(CMTheme.textSecondary)
                                .frame(width: 80, alignment: .trailing)
                            // Edit button
                            Button {
                                CMHaptic.light()
                                containerToEdit = container
                                showEditContainerConfirm = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(systemConfig.accent)
                            }
                            .buttonStyle(.plain)
                            // Remove button
                            Button {
                                CMHaptic.light()
                                containerIndexToDelete = index
                                showDeleteContainerConfirm = true
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(CMTheme.lockRed)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)

                        if index < systemConfig.containers.count - 1 { Divider().padding(.leading, 16) }
                    }
                }

                // Add Container button
                ThemedDivider(indent: 16)
                Button {
                    CMHaptic.light()
                    containerToEdit = nil
                    showAddContainerSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(systemConfig.accent)
                        Text("Add Container")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(systemConfig.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if !isDefault {
                    HStack {
                        Spacer()
                        Button {
                            CMHaptic.medium()
                            withAnimation(.cmSpring) { systemConfig.resetAllContainerTares() }
                        } label: {
                            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CMTheme.lockRed)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.top, 4)
                }

                Text("Tare weights are automatically loaded when selecting a container.")
                    .cmFootnote()
                    .cmSettingsRowPadding()
            }
        }
        .alert("Remove Container?", isPresented: $showDeleteContainerConfirm) {
            Button("Cancel", role: .cancel) { containerIndexToDelete = nil }
            Button("Remove", role: .destructive) {
                if let idx = containerIndexToDelete, idx < systemConfig.containers.count {
                    CMHaptic.success()
                    withAnimation(.cmSpring) { _ = systemConfig.containers.remove(at: idx) }
                }
                containerIndexToDelete = nil
            }
        } message: {
            if let idx = containerIndexToDelete, idx < systemConfig.containers.count {
                Text("Are you sure you want to remove \"\(systemConfig.containers[idx].name)\" from the system? This action cannot be undone.")
            } else {
                Text("Are you sure you want to remove this container?")
            }
        }
        .alert("Edit Container?", isPresented: $showEditContainerConfirm) {
            Button("Cancel", role: .cancel) { containerToEdit = nil }
            Button("Edit") {
                showAddContainerSheet = true
            }
        } message: {
            if let container = containerToEdit {
                Text("Are you sure you want to modify \"\(container.name)\"? Changes will affect tare weight calculations.")
            } else {
                Text("Are you sure you want to modify this container?")
            }
        }
        .sheet(isPresented: $showAddContainerSheet, onDismiss: { containerToEdit = nil }) {
            ContainerEditorSheet(
                systemConfig: systemConfig,
                existingContainer: containerToEdit,
                name: containerToEdit?.name ?? "",
                tareWeight: containerToEdit?.tareWeight ?? 0
            )
        }
    }

    private func scalesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        let isDefault = systemConfig.scales == ScaleSpec.factoryDefaults

        return VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { showScales.toggle() }
            } label: {
                HStack {
                    Text("Laboratory Scales")
                        .cmSectionTitle(accent: systemConfig.accent)
                    Spacer()
                    CMDisclosureChevron(isExpanded: showScales)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if showScales {
                ThemedDivider(indent: 16)

                // ── Default Scale per Resolution ──
                HStack {
                    Text("Default Scale").cmSubsectionTitle()
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                ForEach(Array(MeasurementResolution.allCases.reversed()), id: \.self) { resolution in
                    let defaultScale = systemConfig.defaultScale(for: resolution)
                    let isOverridden = systemConfig.defaultScaleIsOverridden(for: resolution)
                    let matchingScales = systemConfig.scales.filter { $0.resolution == resolution.rawValue }

                    HStack(spacing: 8) {
                        Text(resolution.label)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                            .frame(width: 60, alignment: .leading)

                        if isOverridden {
                            Button {
                                CMHaptic.light()
                                withAnimation(.cmSpring) { systemConfig.resetDefaultScale(for: resolution) }
                            } label: {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .cmResetIcon()
                            }
                            .buttonStyle(.plain)
                            .cmResetTransition()
                        }

                        Spacer()

                        if matchingScales.isEmpty {
                            Text("No scale")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(CMTheme.textTertiary)
                        } else if matchingScales.count == 1 {
                            Text(defaultScale?.name ?? "—")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CMTheme.textSecondary)
                        } else {
                            Menu {
                                ForEach(matchingScales) { scale in
                                    Button {
                                        CMHaptic.light()
                                        systemConfig.setDefaultScale(scale.id, for: resolution)
                                    } label: {
                                        HStack {
                                            Text("\(scale.name)  (\(scale.capacityLabel))")
                                            if scale.id == defaultScale?.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(defaultScale?.name ?? "—")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(systemConfig.accent)
                                    if let cap = defaultScale?.capacityLabel {
                                        Text("(\(cap))")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(CMTheme.textTertiary)
                                    }
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(CMTheme.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }

                Text("The default scale for each resolution is the one with the largest capacity. Tap to override.")
                    .cmFootnote()
                    .padding(.horizontal, 16).padding(.top, 2).padding(.bottom, 6)

                // ── Divider between default assignments and scale list ──
                Divider().padding(.horizontal, 16).padding(.vertical, 4)

                // ── Scale List ──
                HStack {
                    Text("Scales").cmSubsectionTitle()
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 4)

                // Column headers
                HStack(spacing: 4) {
                    Text("Scale").font(.caption2).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    Text("Resolution").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 80, alignment: .trailing)
                    Text("Max").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                ForEach(Array(systemConfig.scales.enumerated()), id: \.element.id) { index, scale in
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Text(scale.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CMTheme.textPrimary)
                                .frame(width: 80, alignment: .leading)
                            Spacer()
                            Text(scale.resolutionLabel)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(CMTheme.textSecondary)
                                .frame(width: 80, alignment: .trailing)
                            Text(scale.capacityLabel)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(CMTheme.textSecondary)
                                .frame(width: 80, alignment: .trailing)
                            // Edit button
                            Button {
                                CMHaptic.light()
                                scaleToEdit = scale
                                showEditScaleConfirm = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(systemConfig.accent)
                            }
                            .buttonStyle(.plain)
                            // Remove button
                            Button {
                                CMHaptic.light()
                                scaleIndexToDelete = index
                                showDeleteScaleConfirm = true
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(CMTheme.lockRed)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)

                        if index < systemConfig.scales.count - 1 { Divider().padding(.leading, 16) }
                    }
                }

                // Add Scale button
                ThemedDivider(indent: 16)
                Button {
                    CMHaptic.light()
                    newScaleName = ""
                    newScaleResolution = 0.01
                    newScaleCapacity = 500
                    showAddScaleSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(systemConfig.accent)
                        Text("Add Scale")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(systemConfig.accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if !isDefault {
                    HStack {
                        Spacer()
                        Button {
                            CMHaptic.medium()
                            withAnimation(.cmSpring) { systemConfig.scales = ScaleSpec.factoryDefaults }
                        } label: {
                            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CMTheme.lockRed)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.top, 4)
                }

                Text("Scales are used to recommend measurement equipment based on theoretical batch masses.")
                    .cmFootnote()
                    .cmSettingsRowPadding()
            }
        }
        .alert("Remove Scale?", isPresented: $showDeleteScaleConfirm) {
            Button("Cancel", role: .cancel) { scaleIndexToDelete = nil }
            Button("Remove", role: .destructive) {
                if let idx = scaleIndexToDelete, idx < systemConfig.scales.count {
                    CMHaptic.success()
                    withAnimation(.cmSpring) { _ = systemConfig.scales.remove(at: idx) }
                }
                scaleIndexToDelete = nil
            }
        } message: {
            if let idx = scaleIndexToDelete, idx < systemConfig.scales.count {
                Text("Are you sure you want to remove \"\(systemConfig.scales[idx].name)\" from the system? This action cannot be undone.")
            } else {
                Text("Are you sure you want to remove this scale?")
            }
        }
        .alert("Edit Scale?", isPresented: $showEditScaleConfirm) {
            Button("Cancel", role: .cancel) { scaleToEdit = nil }
            Button("Edit") {
                // Confirmed — present edit sheet
                showAddScaleSheet = true
            }
        } message: {
            if let scale = scaleToEdit {
                Text("Are you sure you want to modify \"\(scale.name)\"? Changes will affect equipment recommendations.")
            } else {
                Text("Are you sure you want to modify this scale?")
            }
        }
        .sheet(isPresented: $showAddScaleSheet, onDismiss: { scaleToEdit = nil }) {
            ScaleEditorSheet(
                systemConfig: systemConfig,
                existingScale: scaleToEdit,
                name: scaleToEdit?.name ?? newScaleName,
                resolution: scaleToEdit?.resolution ?? newScaleResolution,
                capacity: scaleToEdit?.maxCapacity ?? newScaleCapacity
            )
        }
    }

    private func hapticSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Haptics").cmSectionTitle(accent: systemConfig.accent)
                Spacer()
                Toggle("", isOn: $systemConfig.sliderVibrationsEnabled)
                    .labelsHidden()
                    .onChange(of: systemConfig.sliderVibrationsEnabled) { _, newVal in
                        if newVal { CMHaptic.medium() }
                    }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Text("Vibrate proportionally to the slider value when adjusting flavor and color blend ratios.")
                .cmFootnote()
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }

    private func accentColorSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig
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

            // Default accent swatch (Deep Current)
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) {
                    systemConfig.selectedCustomAccentID = nil
                    systemConfig.accentTheme = .deepCurrent
                }
            } label: {
                let isDefault = systemConfig.selectedCustomAccentID == nil
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AccentTheme.deepCurrent.color)
                            .frame(width: 32, height: 32)
                        if isDefault {
                            Circle()
                                .stroke(CMTheme.selectionRing, lineWidth: 2)
                                .frame(width: 38, height: 38)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                    }
                    Text("Deep Current")
                        .font(.body)
                        .foregroundStyle(isDefault ? CMTheme.textPrimary : CMTheme.textSecondary)
                    Text("Default")
                        .font(.caption2)
                        .foregroundStyle(CMTheme.textTertiary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.vertical, 6)

            // Custom accent colors
            if !systemConfig.customAccentColors.isEmpty {
                ThemedDivider(indent: 20).padding(.vertical, 8)

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
                .cmSettingsRowPadding()
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCustomColorCreator) {
                CustomAccentColorCreatorView(systemConfig: systemConfig)
            }

            Text("Choose the accent color used for buttons, selections, and highlights throughout the app.")
                .cmFootnote()
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }

    private func designLanguageSection(systemConfig: SystemConfig) -> some View {
        let hasOverrides = SystemConfig.DesignColorRole.allCases.contains { systemConfig.designColorIsOverridden($0) }
        let activeThemeID = systemConfig.activeDesignThemeID

        return VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Text("Design Language")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                if hasOverrides {
                    Button {
                        CMHaptic.medium()
                        withAnimation(.cmSpring) { systemConfig.resetAllDesignColors() }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CMTheme.lockRed)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // MARK: - Per-role color rows
            ForEach(SystemConfig.DesignColorRole.allCases) { role in
                let color = systemConfig.designColor(for: role)
                let displayName = systemConfig.designColorDisplayName(for: role)

                Button {
                    CMHaptic.light()
                    showDesignColorEditor = role
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(CMTheme.cardStroke, lineWidth: 0.5)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(role.rawValue)
                                .font(.body)
                                .foregroundStyle(CMTheme.textPrimary)
                            Text(displayName)
                                .font(.caption)
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CMTheme.textTertiary.opacity(0.6))
                    }
                    .contentShape(Rectangle())
                    .cmSettingsRowPadding()
                }
                .buttonStyle(.plain)

                if role != SystemConfig.DesignColorRole.allCases.last {
                    Divider().padding(.leading, 56)
                }
            }

            // MARK: - Divider between roles and themes
            ThemedDivider(indent: 0).padding(.vertical, 8)

            // MARK: - Themes section
            HStack {
                Text("Themes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 8)

            ForEach(SystemConfig.designThemes, id: \.id) { theme in
                designThemeRow(systemConfig: systemConfig, theme: theme, isActive: activeThemeID == theme.id)
            }

            Text("Colors used throughout the app for titles, data highlights, and calculation results.")
                .cmFootnote()
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
        .sheet(item: $showDesignColorEditor) { role in
            DesignColorEditorView(systemConfig: systemConfig, role: role)
        }
    }

    @ViewBuilder
    private func designThemeRow(systemConfig: SystemConfig, theme: SystemConfig.DesignTheme, isActive: Bool) -> some View {
        Button {
            CMHaptic.medium()
            withAnimation(.cmSpring) { systemConfig.applyDesignTheme(theme) }
        } label: {
            HStack(spacing: 12) {
                // Mini color dots preview (all 5 role colors)
                HStack(spacing: 3) {
                    ForEach(SystemConfig.DesignColorRole.allCases) { role in
                        Circle()
                            .fill(theme.color(for: role).color)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CMTheme.cardBG.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isActive ? systemConfig.accent : CMTheme.cardStroke, lineWidth: isActive ? 1.5 : 0.5)
                        )
                )

                Text(theme.name)
                    .font(.body)
                    .foregroundStyle(CMTheme.textPrimary)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(systemConfig.accent)
                }
            }
            .contentShape(Rectangle())
            .cmSettingsRowPadding()
        }
        .buttonStyle(.plain)

        if theme.id != SystemConfig.designThemes.last?.id {
            Divider().padding(.leading, 56)
        }
    }

    private func developerModeSection(systemConfig: SystemConfig, viewModel: BatchConfigViewModel) -> some View {
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 0) {
            HStack {
                Text("Developer Mode").cmSectionTitle(accent: systemConfig.accent)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { systemConfig.developerMode },
                    set: { newValue in
                        CMHaptic.medium()
                        systemConfig.developerMode = newValue
                        if newValue {
                            systemConfig.syntheticMeasurementsEnabled = true
                            systemConfig.syntheticDataSet1Enabled = true
                            withAnimation(.cmSpring) {
                                systemConfig.applyDevMode(to: viewModel)
                                systemConfig.applySyntheticMeasurements(to: viewModel)
                            }
                        } else {
                            withAnimation(.cmSpring) {
                                systemConfig.revertDevMode(to: viewModel)
                                systemConfig.syntheticMeasurementsEnabled = false
                                systemConfig.syntheticDataSet1Enabled = false
                                systemConfig.clearSyntheticMeasurements(from: viewModel)
                            }
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
                .cmSettingsRowPadding()
                .cmExpandTransition()

                Divider().padding(.horizontal, 16)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synthetic Measurements").font(.body)
                        Text("Fill measurement fields with realistic mock data")
                            .cmFootnote()
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
                .cmSettingsRowPadding()
                .cmExpandTransition()

                Divider().padding(.horizontal, 16)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synthetic Dataset 1").font(.body)
                        Text("100 synthetic batches for density analysis")
                            .cmFootnote()
                    }
                    Spacer()
                    Toggle("", isOn: $systemConfig.syntheticDataSet1Enabled)
                        .labelsHidden()
                }
                .cmSettingsRowPadding()
                .cmExpandTransition()

                Divider().padding(.horizontal, 16)
                Text("Dataset 1 active: New Bear molds overridden to 77. 4 random flavor oils, 4 random terpenes, and 2 random colors auto-selected.")
                    .cmFootnote()
                    .cmSettingsRowPadding()
                    .cmExpandTransition()
            }
        }
    }

    private func settingsActionsSection(systemConfig: SystemConfig) -> some View {
        let strawberryRed = CMTheme.lockRed
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
                .cmFootnote()
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
                .cmFootnote()
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

// MARK: - Design Color Editor

/// Detail view for picking a color for a single design language role.
/// Shows a swatch grid of presets (like the accent color picker) plus a
/// "Create Custom Color" option that opens HSB sliders.
struct DesignColorEditorView: View {
    @Environment(\.dismiss) private var dismiss
    var systemConfig: SystemConfig
    let role: SystemConfig.DesignColorRole

    @State private var showCustomCreator = false

    /// Returns the currently-active HSB for this role (override or factory).
    private var currentHSB: (h: Double, s: Double, b: Double) {
        if let ov = systemConfig.designColorOverrides[role.rawValue] {
            return (ov.hue, ov.saturation, ov.brightness)
        }
        return role.factoryHSB
    }

    /// Whether a given preset matches the current selection.
    private func isSelected(_ preset: SystemConfig.DesignColorPreset) -> Bool {
        let c = currentHSB
        return abs(preset.hue - c.h) < 0.005
            && abs(preset.saturation - c.s) < 0.005
            && abs(preset.brightness - c.b) < 0.005
    }

    /// Whether the current selection is a custom (non-preset) color.
    private var isCustomSelected: Bool {
        guard systemConfig.designColorIsOverridden(role) else { return false }
        return !role.presets.contains(where: { isSelected($0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with current name
                    HStack {
                        Text(role.rawValue)
                            .font(.headline)
                            .foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text(systemConfig.designColorDisplayName(for: role))
                            .font(.subheadline)
                            .foregroundStyle(systemConfig.designColor(for: role))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    // Description
                    Text(role.usage)
                        .cmFootnote()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.bottom, 12)

                    // Preset swatch grid
                    let columns = [GridItem(.adaptive(minimum: 56))]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(role.presets) { preset in
                            Button {
                                CMHaptic.light()
                                withAnimation(.cmSpring) {
                                    systemConfig.selectDesignPreset(preset, for: role)
                                }
                            } label: {
                                let selected = isSelected(preset)
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(preset.color)
                                            .frame(width: 40, height: 40)
                                        if selected {
                                            Circle()
                                                .stroke(CMTheme.selectionRing, lineWidth: 2.5)
                                                .frame(width: 48, height: 48)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                    Text(preset.name)
                                        .font(.caption2)
                                        .foregroundStyle(selected ? CMTheme.textPrimary : CMTheme.textSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .animation(.cmSpring, value: selected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)

                    // Custom color indicator (if active)
                    if isCustomSelected, let ov = systemConfig.designColorOverrides[role.rawValue] {
                        ThemedDivider(indent: 20).padding(.bottom, 8)

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(ov.color)
                                    .frame(width: 32, height: 32)
                                Circle()
                                    .stroke(CMTheme.selectionRing, lineWidth: 2)
                                    .frame(width: 38, height: 38)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            }
                            Text("Custom Color")
                                .font(.body)
                                .foregroundStyle(CMTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 6)
                    }

                    // Create custom color button
                    ThemedDivider(indent: 20).padding(.vertical, 8)

                    Button {
                        CMHaptic.light()
                        showCustomCreator = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Create Custom Color")
                                .font(.subheadline).fontWeight(.medium)
                            Spacer()
                        }
                        .foregroundStyle(systemConfig.accent)
                        .cmSettingsRowPadding()
                    }
                    .buttonStyle(.plain)

                    // Reset to factory default
                    if systemConfig.designColorIsOverridden(role) {
                        ThemedDivider(indent: 20).padding(.vertical, 4)

                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) {
                                systemConfig.resetDesignColor(role)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Reset to Default")
                                    .font(.subheadline).fontWeight(.medium)
                                Circle()
                                    .fill(role.factoryColor)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(CMTheme.cardStroke, lineWidth: 0.5))
                                Text(role.presets.first?.name ?? "")
                                    .font(.caption)
                                    .foregroundStyle(CMTheme.textTertiary)
                                Spacer()
                            }
                            .foregroundStyle(CMTheme.lockRed)
                            .cmSettingsRowPadding()
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 12)
                }
            }
            .background(CMTheme.pageBG)
            .navigationTitle(role.rawValue)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showCustomCreator) {
                DesignCustomColorCreatorView(systemConfig: systemConfig, role: role)
            }
        }
    }
}

// MARK: - Design Custom Color Creator

/// HSB slider sheet for creating a fully custom design language color.
struct DesignCustomColorCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    var systemConfig: SystemConfig
    let role: SystemConfig.DesignColorRole

    @State private var hue: Double
    @State private var saturation: Double
    @State private var brightness: Double

    init(systemConfig: SystemConfig, role: SystemConfig.DesignColorRole) {
        self.systemConfig = systemConfig
        self.role = role
        if let override = systemConfig.designColorOverrides[role.rawValue] {
            _hue = State(initialValue: override.hue)
            _saturation = State(initialValue: override.saturation)
            _brightness = State(initialValue: override.brightness)
        } else {
            let factory = role.factoryHSB
            _hue = State(initialValue: factory.h)
            _saturation = State(initialValue: factory.s)
            _brightness = State(initialValue: factory.b)
        }
    }

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
                        .frame(height: 100)
                        .overlay(
                            Text(role.rawValue)
                                .font(.headline).foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                                .stroke(CMTheme.cardStroke, lineWidth: 1)
                        )
                        .shadow(color: previewColor.opacity(0.4), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 16)

                    // HSB sliders
                    VStack(spacing: 16) {
                        designHSVSlider(label: "Hue", value: $hue, gradient: hueGradient())
                        designHSVSlider(label: "Saturation", value: $saturation, gradient: saturationGradient())
                        designHSVSlider(label: "Brightness", value: $brightness, gradient: brightnessGradient())
                    }
                    .padding(.horizontal, 16)

                    // Save button
                    Button {
                        CMHaptic.success()
                        withAnimation(.cmSpring) {
                            systemConfig.setDesignColor(hue: hue, saturation: saturation, brightness: brightness, for: role)
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
            .navigationTitle("Custom \(role.rawValue)")
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

    private func designHSVSlider(label: String, value: Binding<Double>, gradient: LinearGradient) -> some View {
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
    }
}

// MARK: - Scale Editor Sheet

/// Sheet for adding a new scale or editing an existing one.
struct ScaleEditorSheet: View {
    var systemConfig: SystemConfig
    /// If non-nil, we are editing this existing scale; otherwise adding a new one.
    var existingScale: ScaleSpec?

    @State var name: String
    @State var resolution: Double
    @State var capacity: Double
    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool { existingScale != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && resolution > 0 && capacity > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scale Name") {
                    TextField("e.g. Scale D", text: $name)
                        .font(.system(size: 16, weight: .medium))
                }
                Section("Resolution (g)") {
                    Picker("Resolution", selection: $resolution) {
                        Text("1 g").tag(1.0)
                        Text("0.1 g").tag(0.1)
                        Text("0.01 g").tag(0.01)
                        Text("0.001 g").tag(0.001)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Max Capacity (g)") {
                    NumericField(value: $capacity, decimals: 0)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .scrollContentBackground(.hidden)
            .background(CMTheme.pageBG)
            .navigationTitle(isEditing ? "Edit Scale" : "Add Scale")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        CMHaptic.success()
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        if let existing = existingScale,
                           let idx = systemConfig.scales.firstIndex(where: { $0.id == existing.id }) {
                            // Update existing
                            systemConfig.scales[idx].name = trimmedName
                            systemConfig.scales[idx].resolution = resolution
                            systemConfig.scales[idx].maxCapacity = capacity
                        } else {
                            // Generate a new unique ID
                            let newID = generateNextID()
                            let newScale = ScaleSpec(id: newID, name: trimmedName, resolution: resolution, maxCapacity: capacity)
                            systemConfig.scales.append(newScale)
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    /// Generates the next alphabetical single-letter ID not already in use, or falls back to UUID prefix.
    private func generateNextID() -> String {
        let usedIDs = Set(systemConfig.scales.map(\.id))
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            let candidate = String(letter)
            if !usedIDs.contains(candidate) { return candidate }
        }
        return UUID().uuidString.prefix(4).uppercased()
    }
}

// MARK: - Container Editor Sheet

/// Sheet for adding a new container or editing an existing one.
struct ContainerEditorSheet: View {
    var systemConfig: SystemConfig
    /// If non-nil, we are editing this existing container; otherwise adding a new one.
    var existingContainer: SystemConfig.BeakerContainer?

    @State var name: String
    @State var tareWeight: Double
    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool { existingContainer != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && tareWeight >= 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Container Name") {
                    TextField("e.g. Beaker 100ml", text: $name)
                        .font(.system(size: 16, weight: .medium))
                }
                Section("Tare Weight (g)") {
                    NumericField(value: $tareWeight, decimals: 3)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .scrollContentBackground(.hidden)
            .background(CMTheme.pageBG)
            .navigationTitle(isEditing ? "Edit Container" : "Add Container")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        CMHaptic.success()
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        if let existing = existingContainer,
                           let idx = systemConfig.containers.firstIndex(where: { $0.id == existing.id }) {
                            // Update existing
                            systemConfig.containers[idx].name = trimmedName
                            systemConfig.containers[idx].tareWeight = tareWeight
                        } else {
                            // Generate a new unique ID from the name
                            let newID = trimmedName.isEmpty ? UUID().uuidString : trimmedName
                            let newContainer = SystemConfig.BeakerContainer(id: newID, name: trimmedName, tareWeight: tareWeight)
                            systemConfig.containers.append(newContainer)
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
