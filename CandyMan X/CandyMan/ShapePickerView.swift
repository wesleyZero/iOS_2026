//
//  ShapePickerView.swift
//  CandyMan
//
//  Main screen of the app.
//
//  Pre-calculate: the user configures a batch (shape, trays, actives,
//  gelatin %, flavor oils, terpenes, colors) then taps "Calculate".
//
//  Post-calculate: the screen switches to a scrollable list of result
//  sections (batch output, measurements, sig-figs, error analysis, etc.)
//  whose order is user-customizable on iPhone.
//
//  Contents:
//    MainSection          – Ordered enum of post-calculate sections
//    ShapePickerView      – The main view
//    ShapeButtonSwirlOverlay – Animated overlay for the selected shape button
//    InputSummaryView     – Post-calculate configuration summary card
//    CardStyle            – Shared card background modifier
//    ActivesSectionView   – "Actives" input card (owns keyboard @State)
//

import SwiftUI
import SwiftData

// MARK: - Section Ordering

/// Defines the set of result sections shown after the user calculates a batch.
/// The user can reorder these on iPhone; iPad uses a fixed two-column layout.
enum MainSection: String, CaseIterable, Identifiable {
    case inputSummary          = "Summary"
    case batchOutput           = "Batch Output"
    case measurementEquipment  = "Measurement Equipment"
    case batchValidation       = "Batch Validation"
    case relativeFractions     = "Composition Data (Theoretical)"
    case weightMeasurements    = "Batch Measurements"
    case calibrationMeasurements = "Calibration Measurements"
    case measurementCalculations = "Experiment Data"
    case sigFigs               = "Sig Figs"
    case errorAnalysis         = "Error Analysis"
    case resetSection          = "New Batch"

    var id: String { rawValue }

    static let defaultOrder: [MainSection] = [
        .inputSummary, .batchOutput, .measurementEquipment, .batchValidation, .relativeFractions,
        .weightMeasurements, .calibrationMeasurements, .measurementCalculations,
        .sigFigs, .errorAnalysis, .resetSection
    ]

    static func load() -> [MainSection] {
        guard let raw = UserDefaults.standard.array(forKey: "mainSectionOrder") as? [String] else {
            return defaultOrder
        }
        let decoded = raw.compactMap { MainSection(rawValue: $0) }
        // Fill in any sections added after the order was saved
        let missing = defaultOrder.filter { s in !decoded.contains(s) }
        return decoded + missing
    }

    static func save(_ order: [MainSection]) {
        UserDefaults.standard.set(order.map(\.rawValue), forKey: "mainSectionOrder")
    }
}

// MARK: - ShapePickerView

struct ShapePickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext
    @State private var showSettings = false
    @State private var showHistory  = false
    @State private var showTemplates = false
    @State private var showResetTemplateAlert = false
    @State private var showSaveTemplateAlert = false
    @State private var saveTemplateName = ""
    @State private var showCandyManToast = false
    @State private var showResetBatchAlert = false
    @State private var gelatinUseMass = false
    @State private var gelatinFieldFocused = false
    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var saveBatchID = ""
    @State private var savedConfirmation = false
    @State private var sectionOrder: [MainSection] = MainSection.load()
    @State private var isScrolling = false
    private var isRegular: Bool { sizeClass == .regular }

    private var shapeColumns: [GridItem] {
        isRegular
            ? [GridItem(.adaptive(minimum: 140))]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    // MARK: - Readiness Check

    /// Whether all required inputs are filled in and the batch can be calculated.
    private var canCalculate: Bool { readinessIssues.isEmpty }

    /// Returns a list of (section name, description) for each input that isn't ready yet.
    private var readinessIssues: [(section: String, detail: String)] {
        var issues: [(String, String)] = []

        // Trays
        if viewModel.trayCount <= 0 {
            issues.append(("Trays", "set number of trays"))
        }

        // Flavor oils — use the computed property from the view model
        let oils = viewModel.selectedOils
        if !oils.isEmpty {
            let oilTotal = oils.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
            if !viewModel.oilsLocked {
                issues.append(("Flavor Oils", "lock blend ratios"))
            } else if abs(oilTotal - 100) >= 0.5 {
                issues.append(("Flavor Oils", "blend must sum to 100%"))
            }
        }

        // Terpenes — use the computed property from the view model
        let terpenes = viewModel.selectedTerpenes
        if !terpenes.isEmpty {
            let terpTotal = terpenes.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
            if !viewModel.terpenesLocked {
                issues.append(("Terpenes", "lock blend ratios"))
            } else if abs(terpTotal - 100) >= 0.5 {
                issues.append(("Terpenes", "blend must sum to 100%"))
            }
        }

        // Colors
        if !viewModel.selectedColors.isEmpty {
            let colorTotal = viewModel.colorBlendTotal
            if !viewModel.colorsLocked {
                issues.append(("Colors", "lock blend ratios"))
            } else if abs(colorTotal - 100) >= 0.5 {
                issues.append(("Colors", "blend must sum to 100%"))
            }
        }

        return issues
    }

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollViewReader { scrollProxy in
        ScrollView {
            VStack(spacing: 12) {
                // ── Input cards / summary ──
                Color.clear.frame(height: 0).id("scrollTop")
                if viewModel.batchCalculated {
                    // ── Post-calculate: summary + output ──
                    if isRegular {
                        // iPad: summary spans top
                        InputSummaryView().cardStyle()
                            .frame(maxWidth: 600)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        // iPad: two-column output
                        HStack(alignment: .top, spacing: 0) {
                            VStack(spacing: 12) {
                                BatchOutputView().cardStyle()
                                MeasurementEquipmentView().cardStyle()
                                BatchValidationView().cardStyle()
                                RelativeFractionsView().cardStyle()
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: 12) {
                                WeightMeasurementsView().cardStyle()
                                CalibrationMeasurementsView().cardStyle()
                                MeasurementCalculationsView().cardStyle()
                                SigFigsCardView().cardStyle()
                                ErrorAnalysisView().cardStyle()
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                        resetSection.cardStyle()
                            .frame(maxWidth: 400)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        // iPhone: single column
                        ForEach(sectionOrder) { section in
                            sectionView(section).cardStyle()
                        }
                    }
                } else if isRegular {
                    // ── iPad pre-calculate: two-column input grid ──
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 12) {
                            templateSection.cardStyle()
                            chooseShape.cardStyle()
                            chooseTrays(viewModel: viewModel).cardStyle()
                            chooseActive(viewModel: viewModel).cardStyle()
                            chooseGelatin(viewModel: viewModel).cardStyle()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 12) {
                            ColorPickerView().cardStyle()
                            FlavorOilPickerView().cardStyle()
                            TerpenePickerView().cardStyle()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    calculateBatchSection.cardStyle()
                        .frame(maxWidth: 500)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // ── iPhone pre-calculate: single column ──
                    VStack(spacing: 12) {
                        templateSection.cardStyle()
                        chooseShape.cardStyle()
                        chooseTrays(viewModel: viewModel).cardStyle()
                        chooseActive(viewModel: viewModel).cardStyle()
                        chooseGelatin(viewModel: viewModel).cardStyle()
                        ColorPickerView().cardStyle()
                        FlavorOilPickerView().cardStyle()
                        TerpenePickerView().cardStyle()
                        Spacer().frame(height: 4)
                        calculateBatchSection.cardStyle()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Color.clear.frame(height: 0).id("scrollBottom")
            }
            .frame(maxWidth: isRegular ? 1100 : .infinity)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .onScrollPhaseChange { _, newPhase in
            if newPhase.isScrolling {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isScrolling = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isScrolling = false
                }
            }
        }
        .onChange(of: viewModel.batchCalculated) { _, calculated in
            if calculated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.cmSpring) {
                        scrollProxy.scrollTo("scrollTop", anchor: .top)
                    }
                }
            }
        }
        .onChange(of: viewModel.batchCalculated) {
            viewModel.checkAndClearTemplateIfChanged()
        }
        .onChange(of: viewModel.selectedShape) {
            viewModel.checkAndClearTemplateIfChanged()
        }
        .onChange(of: viewModel.trayCount) {
            viewModel.checkAndClearTemplateIfChanged()
        }
        .overlay(alignment: .bottomLeading) {
            VStack(spacing: 8) {
                TopJumpButton1 {
                    CMHaptic.light()
                    withAnimation(.cmSpring) {
                        scrollProxy.scrollTo("scrollTop", anchor: .top)
                    }
                }
                BottomJumpButton1 {
                    CMHaptic.light()
                    withAnimation(.cmSpring) {
                        scrollProxy.scrollTo("scrollBottom", anchor: .bottom)
                    }
                }
            }
            .padding(.leading, 6)
            .padding(.bottom, 6)
            .opacity(isScrolling ? 1 : 0)
            .allowsHitTesting(isScrolling)
        }
        } // ScrollViewReader
        .navigationBarTitleDisplayMode(.inline)
        .background(CMTheme.pageBG.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if showCandyManToast {
                GeometryReader { geo in
                    PsychedelicAlert1()
                        .frame(maxWidth: .infinity)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.25)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .allowsHitTesting(false)
            }
        }
        .keyboardDismissToolbar()
        .toolbar {
            ToolbarItem(placement: .principal) {
                PsychedelicTitleView()
            }
            ToolbarItem(placement: .topBarLeading) {
                GlassHistoryButton { showHistory = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                GlassSettingsButton {
                    CrashReporter.shared.addBreadcrumb("Settings button tapped")
                    showSettings = true
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environment(systemConfig)
                .environment(viewModel)
                .onAppear {
                    CrashReporter.shared.activeScreen = "SettingsView"
                    CrashReporter.shared.addBreadcrumb("SettingsView appeared (fullScreenCover)")
                    CrashReporter.shared.captureEnvironment(from: systemConfig)
                }
                .onDisappear {
                    CrashReporter.shared.activeScreen = "ShapePickerView"
                    CrashReporter.shared.addBreadcrumb("SettingsView dismissed")
                }
        }
        .fullScreenCover(isPresented: $showHistory) {
            BatchHistoryView()
                .environment(systemConfig)
                .environment(viewModel)
        }
        .sheet(isPresented: $showTemplates) {
            TemplateListView()
                .environment(systemConfig)
                .environment(viewModel)
        }
    }

    // MARK: - Calculate Section

    private var calculateBatchSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Calculate Batch")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                if viewModel.activeTemplateID != nil {
                    HStack(spacing: 6) {
                        Text("Info \(Text("saved").foregroundColor(systemConfig.designAlert)) as \(Text(viewModel.activeTemplateName).foregroundColor(systemConfig.designAlert))")
                            .font(.caption)
                            .foregroundStyle(CMTheme.textTertiary)
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                } else {
                    Button {
                        CMHaptic.medium()
                        saveTemplateName = ""
                        showSaveTemplateAlert = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Info \(canCalculate ? Text("not saved").foregroundColor(systemConfig.designAlert) : Text("not saved")) as template")
                                .font(.caption)
                                .foregroundStyle(CMTheme.textTertiary)
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !canCalculate {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(readinessIssues.enumerated()), id: \.offset) { _, issue in
                        HStack(spacing: 4) {
                            Text(issue.section)
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(systemConfig.designAlert)
                            Text("— \(issue.detail)")
                                .cmFootnote()
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 4)
            }

            Button {
                CMHaptic.heavy()
                viewModel.prePopulateRecommendedScales(systemConfig: systemConfig)
                withAnimation(.cmSpring) {
                    viewModel.batchCalculated = true
                    showCandyManToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.4)) { showCandyManToast = false }
                }
            } label: {
                Label("Calculate", systemImage: "function")
                    .font(.headline)
                    .foregroundStyle(!canCalculate ? CMTheme.textTertiary : .white)
                    .shadow(color: canCalculate ? .white.opacity(0.3) : .clear, radius: 2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            // Disabled state fallback
                            RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                                .fill(CMTheme.chipBG)
                            // Psychedelic overlay with dark center vignette (hidden when disabled)
                            PsychedelicButton2(isDisabled: !canCalculate)
                        }
                    )
            }
            .buttonStyle(CMPressStyle())
            .disabled(!canCalculate)
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
        .alert("Save as Template", isPresented: $showSaveTemplateAlert) {
            TextField("Template Name", text: $saveTemplateName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let trimmed = saveTemplateName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                CMHaptic.success()
                viewModel.saveAsTemplate(name: trimmed, modelContext: modelContext)
            }
        } message: {
            Text("Enter a name for this template.")
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        VStack(spacing: 8) {
            CMSectionHeader(title: "New Batch")
            Button {
                CMHaptic.heavy()
                let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
                if systemConfig.developerMode {
                    saveName = "DevMode | Dataset01"
                    saveBatchID = "XX"
                } else {
                    saveName = ""
                    saveBatchID = systemConfig.nextBatchID()
                }
                showSaveSheet = true
                _ = result
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Save Batch Data")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.2), radius: 2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                        .fill(systemConfig.designTitle)
                        .shadow(color: systemConfig.designTitle.opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16)
            Button {
                CMHaptic.medium()
                showResetBatchAlert = true
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.bottom, 12)
            .alert("Reset Batch?", isPresented: $showResetBatchAlert) {
                Button("Reset", role: .destructive) {
                    CMHaptic.medium()
                    withAnimation(.cmSpring) { viewModel.resetBatch(systemConfig: systemConfig) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("All current batch inputs will be cleared.")
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
            SaveBatchSheet(
                saveName: $saveName,
                saveBatchID: $saveBatchID,
                onSave: { saveBatch(result: result) },
                onSaveTemplate: { templateName in
                    viewModel.saveAsTemplate(name: templateName, modelContext: modelContext)
                }
            )
            .environment(systemConfig)
            .presentationDetents([.height(420)])
        }
        .overlay(alignment: .top) {
            if savedConfirmation {
                Text("Batch saved!")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                            .fill(CMTheme.success)
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: savedConfirmation)
    }

    private func saveBatch(result: BatchResult) {
        let batch = viewModel.makeSavedBatch(
            name: saveName.isEmpty ? "Batch \(Date.now.formatted(date: .abbreviated, time: .shortened))" : saveName,
            batchID: saveBatchID.isEmpty ? "AA" : saveBatchID.uppercased(),
            result: result,
            systemConfig: systemConfig
        )
        modelContext.insert(batch)
        showSaveSheet = false
        CMHaptic.success()
        savedConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            savedConfirmation = false
        }
    }

    // MARK: - Section Routing

    @ViewBuilder
    private func sectionView(_ section: MainSection) -> some View {
        switch section {
        case .inputSummary:            InputSummaryView()
        case .batchOutput:             BatchOutputView()
        case .measurementEquipment:    MeasurementEquipmentView()
        case .batchValidation:         BatchValidationView()
        case .relativeFractions:       RelativeFractionsView()
        case .weightMeasurements:      WeightMeasurementsView()
        case .calibrationMeasurements: CalibrationMeasurementsView()
        case .measurementCalculations: MeasurementCalculationsView()
        case .sigFigs:                 SigFigsCardView()
        case .errorAnalysis:           ErrorAnalysisView()
        case .resetSection:            resetSection
        }
    }

    // MARK: - Input Sections

    private func chooseGelatin(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let rhoGelatin = systemConfig.densityGelatin

        // Mass % binding: mass% = vol% × (ρ_gelatin / ρ_mix)
        let massBinding = Binding<Double>(
            get: {
                guard rhoMix > 0 else { return 0 }
                return viewModel.gelatinPercentage * rhoGelatin / rhoMix
            },
            set: { newMassPct in
                guard rhoMix > 0, rhoGelatin > 0 else { return }
                viewModel.gelatinPercentage = newMassPct * rhoMix / rhoGelatin
            }
        )

        return VStack(spacing: 4) {
            sectionHeader(title: "Gelatin",
                          showReset: viewModel.gelatinPercentage != 5.225) {
                viewModel.gelatinPercentage = 5.225
            }
            HStack(alignment: .firstTextBaseline) {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { gelatinUseMass.toggle() }
                } label: {
                    Image(systemName: gelatinUseMass ? "lightswitch.on" : "lightswitch.off")
                        .font(.system(size: 20))
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    NumericField(value: gelatinUseMass ? massBinding : $viewModel.gelatinPercentage, decimals: 3, isFocusedBinding: $gelatinFieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).skittleSwirlWide(isPaused: gelatinFieldFocused).fixedSize()
                    Text(gelatinUseMass ? "% mass" : "% volume").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                }
                Spacer()
            }.padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    // MARK: - Templates

    private var templateSection: some View {
        VStack(spacing: 8) {
            Button {
                CMHaptic.medium()
                showTemplates = true
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(systemConfig.designTitle)
                    Text("Templates")
                        .font(.headline)
                        .foregroundStyle(CMTheme.textPrimary)
                    Button {
                        CMHaptic.medium()
                        showResetTemplateAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .cmResetIcon(color: systemConfig.designAlert)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if viewModel.activeTemplateID != nil {
                Text("The \(Text(viewModel.activeTemplateName).foregroundColor(systemConfig.designAlert)) template is being used.")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            } else {
                Text("No template is being used")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .alert("Reset to Defaults", isPresented: $showResetTemplateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                CMHaptic.medium()
                withAnimation(.cmSpring) {
                    viewModel.clearTemplate(systemConfig: systemConfig)
                }
            }
        } message: {
            Text("This will remove the current template and reset all inputs back to default values.")
        }
    }

    // MARK: - Shape

    private var chooseShape: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shape").font(.headline).foregroundStyle(systemConfig.designTitle)
                if viewModel.selectedShape != .newBear {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { viewModel.selectedShape = .newBear }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                let spec = systemConfig.spec(for: viewModel.selectedShape)
                HStack(spacing: 0) {
                    Text("\(spec.count)")
                        .foregroundStyle(systemConfig.designAlert)
                    Text(" Gummies / Tray • ")
                        .foregroundStyle(CMTheme.textTertiary)
                    Text(String(format: "%.1f", spec.volumeML))
                        .foregroundStyle(systemConfig.designAlert)
                    Text(" ml / Gummy")
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .font(.subheadline).fontWeight(.semibold)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            LazyVGrid(columns: shapeColumns, spacing: 12) {
                ForEach(GummyShape.allCases) { shape in shapeButton(for: shape) }
            }.padding(12)
        }
    }

    // MARK: - Trays

    private func chooseTrays(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let perTray = spec.count
        let totalGummies = viewModel.totalGummies(using: systemConfig)
        let traysChanged = viewModel.trayCount != 0 || viewModel.extraGummies != 0
        let fractionalTrays = perTray > 0
            ? Double(totalGummies) / Double(perTray)
            : Double(viewModel.trayCount)

        return VStack(spacing: 4) {
            // Header
            HStack {
                Text("Trays").font(.headline).foregroundStyle(systemConfig.designTitle)
                if traysChanged {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) {
                            viewModel.trayCount = 0
                            viewModel.extraGummies = 0
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
                HStack(spacing: 3) {
                    Text("\(totalGummies)")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(systemConfig.designAlert)
                        .contentTransition(.numericText())
                    Text("Gummies")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // Tray count picker
            HStack {
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.trayCount = max(0, viewModel.trayCount - 1) }
                } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundStyle(systemConfig.designTitle)
                }
                Spacer()
                Text("\(viewModel.trayCount)")
                    .font(.system(size: 20, weight: .bold))
                    .skittleSwirl()
                    .contentTransition(.numericText())
                Text("Tray\(viewModel.trayCount == 1 ? "" : "s")").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.trayCount = min(20, viewModel.trayCount + 1) }
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(systemConfig.designTitle)
                }
            }.padding(.horizontal, 24).padding(.vertical, 8)

            // Separator
            Text("+")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 2)

            // Extra gummies picker
            HStack {
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.extraGummies = max(0, viewModel.extraGummies - 1) }
                } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundStyle(systemConfig.designTitle)
                }
                Spacer()
                Text("\(viewModel.extraGummies)")
                    .font(.system(size: 20, weight: .bold))
                    .skittleSwirl()
                    .contentTransition(.numericText())
                Text("Gumm\(viewModel.extraGummies == 1 ? "y" : "ies")").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Button {
                    CMHaptic.selection()
                    let max = perTray - 1
                    withAnimation(.cmSpring) { viewModel.extraGummies = min(max, viewModel.extraGummies + 1) }
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(systemConfig.designTitle)
                }
                .opacity(viewModel.extraGummies < perTray - 1 ? 1 : 0.3)
                .disabled(viewModel.extraGummies >= perTray - 1)
            }.padding(.horizontal, 24).padding(.vertical, 8)

            // Fine print
            Text("\(perTray) gummies / tray")
                .cmFootnote()
                .padding(.bottom, 8)
        }
    }

    private func chooseActive(viewModel: BatchConfigViewModel) -> some View {
        ActivesSectionView(viewModel: viewModel)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, detail: String? = nil, showReset: Bool = false, onReset: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title).font(.headline).foregroundStyle(systemConfig.designTitle)
            if showReset {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { onReset?() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .cmResetTransition()
            }
            Spacer()
            if let detail { Text(detail).font(.subheadline).foregroundStyle(CMTheme.textSecondary) }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func shapeButton(for shape: GummyShape) -> some View {
        let sel = viewModel.selectedShape == shape
        return Button {
            CMHaptic.medium()
            withAnimation(.cmSpring) { viewModel.selectedShape = shape }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: shape.sfSymbol).font(.system(size: 34))
                Text(shape.rawValue).font(.subheadline).fontWeight(.medium)
            }
            .foregroundStyle(sel ? AnyShapeStyle(.clear) : AnyShapeStyle(CMTheme.textSecondary))
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                    .fill(CMTheme.fieldBG)
            )
            .overlay {
                if sel {
                    ShapeButtonSwirlOverlay(sfSymbol: shape.sfSymbol, name: shape.rawValue, cornerRadius: CMTheme.buttonRadius)
                }
            }
            .contentShape(Rectangle())
            .animation(.cmSpring, value: sel)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShapeButtonSwirlOverlay

/// Animated overlay for the selected shape button — renders the icon + label
/// with a rotating AngularGradient (SkittleSwirl) as the foreground, plus
/// an animated gradient border. Drawn on top of the dark base for max contrast.
private struct ShapeButtonSwirlOverlay: View {
    let sfSymbol: String
    let name: String
    var cornerRadius: CGFloat = CMTheme.buttonRadius

    @State private var phase: CGFloat = 0

    private let candyColors: [Color] = [
        Color(red: 1.00, green: 0.00, blue: 0.30),
        Color(red: 1.00, green: 0.35, blue: 0.00),
        Color(red: 1.00, green: 0.95, blue: 0.00),
        Color(red: 0.00, green: 1.00, blue: 0.40),
        Color(red: 0.00, green: 0.85, blue: 1.00),
        Color(red: 0.55, green: 0.00, blue: 1.00),
        Color(red: 1.00, green: 0.00, blue: 0.70),
        Color(red: 1.00, green: 0.00, blue: 0.30),
    ]

    private var gradient: AngularGradient {
        AngularGradient(colors: candyColors, center: .center, angle: .degrees(phase))
    }

    var body: some View {
        ZStack {
            // Animated gradient border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(gradient, lineWidth: 1.5)

            // Animated gradient icon + text
            VStack(spacing: 10) {
                Image(systemName: sfSymbol).font(.system(size: 34))
                Text(name).font(.subheadline).fontWeight(.medium)
            }
            .foregroundStyle(gradient)
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - InputSummaryView (post-calculate)

struct InputSummaryView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var copiedConfirmation = false
    @State private var copiedLabel = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Batch Configuration").font(.headline).foregroundStyle(systemConfig.designTitle)
                Spacer()
                GlassCopyButton { copyConfigJSON() }
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            let wellCount = viewModel.totalGummies(using: systemConfig)

            // Core inputs
            summaryRow("Shape", value: viewModel.selectedShape.rawValue)
            summaryRow("Trays", value: "\(viewModel.trayCount)")
            summaryRow("Gummies", value: "\(wellCount)")
            summaryRow("Active", value: viewModel.selectedActive.rawValue)
            summaryRow("Concentration", value: String(format: "%.2f %@ / gummy", viewModel.activeConcentration, viewModel.units.rawValue))
            summaryRow("Gelatin %", value: String(format: "%.3f%%", viewModel.gelatinPercentage))

            // Terpenes — use view model's computed property
            let terpenes = viewModel.selectedFlavors.filter { if case .terpene = $0.key { return true }; return false }
            if !terpenes.isEmpty {
                summarySubheader("Terpenes")
                summaryRow("PPM", value: String(format: "%.1f", viewModel.terpeneVolumePPM))
                ForEach(terpenes.sorted(by: { $0.key.id < $1.key.id }), id: \.key) { flavor, pct in
                    summaryRow(flavor.displayName, value: String(format: "%.0f%%", pct))
                }
            }

            // Flavor Oils
            let oils = viewModel.selectedFlavors.filter { if case .oil = $0.key { return true }; return false }
            if !oils.isEmpty {
                summarySubheader("Flavor Oils")
                summaryRow("Volume %", value: String(format: "%.3f%%", viewModel.flavorOilVolumePercent))
                ForEach(oils.sorted(by: { $0.key.id < $1.key.id }), id: \.key) { flavor, pct in
                    summaryRow(flavor.displayName, value: String(format: "%.0f%%", pct))
                }
            }

            // Colors
            if !viewModel.selectedColors.isEmpty {
                summarySubheader("Colors")
                summaryRow("Volume %", value: String(format: "%.3f%%", viewModel.colorVolumePercent))
                ForEach(viewModel.selectedColors.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { color, pct in
                    summaryRow(color.rawValue, value: String(format: "%.0f%%", pct))
                }
            }

            Spacer().frame(height: 8)
        }
        .copyAlert(isShowing: $copiedConfirmation, label: copiedLabel)
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).cmMono12().foregroundStyle(CMTheme.textPrimary).lineLimit(1)
            Spacer()
            Text(value)
                .cmMono12().foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func summarySubheader(_ title: String) -> some View {
        HStack {
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
    }

    // MARK: - Copy Config JSON

    private func copyConfigJSON() {
        let wellCount = viewModel.totalGummies(using: systemConfig)
        var dict: [String: Any] = [
            "shape": viewModel.selectedShape.rawValue,
            "trays": viewModel.trayCount,
            "gummies": wellCount,
            "active": viewModel.selectedActive.rawValue,
            "concentration": viewModel.activeConcentration,
            "concentrationUnit": viewModel.units.rawValue,
            "gelatinPercent": viewModel.gelatinPercentage,
        ]

        // Terpenes
        let terpenes = viewModel.selectedFlavors.filter { if case .terpene = $0.key { return true }; return false }
        if !terpenes.isEmpty {
            var terpDict: [String: Any] = ["ppm": viewModel.terpeneVolumePPM]
            var blend: [String: Double] = [:]
            for (flavor, pct) in terpenes.sorted(by: { $0.key.id < $1.key.id }) {
                blend[flavor.displayName] = pct
            }
            terpDict["blend"] = blend
            dict["terpenes"] = terpDict
        }

        // Flavor Oils
        let oils = viewModel.selectedFlavors.filter { if case .oil = $0.key { return true }; return false }
        if !oils.isEmpty {
            var oilDict: [String: Any] = ["volumePercent": viewModel.flavorOilVolumePercent]
            var blend: [String: Double] = [:]
            for (flavor, pct) in oils.sorted(by: { $0.key.id < $1.key.id }) {
                blend[flavor.displayName] = pct
            }
            oilDict["blend"] = blend
            dict["flavorOils"] = oilDict
        }

        // Colors
        if !viewModel.selectedColors.isEmpty {
            var colorDict: [String: Any] = ["volumePercent": viewModel.colorVolumePercent]
            var blend: [String: Double] = [:]
            for (color, pct) in viewModel.selectedColors.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                blend[color.rawValue] = pct
            }
            colorDict["blend"] = blend
            dict["colors"] = colorDict
        }

        BatchDetailCopyUtility.copyJSON(dict, label: "Batch Config", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel)
    }
}

// MARK: - CardStyle

struct CardStyle: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme  // forces re-render on mode change

    func body(content: Content) -> some View {
        let _ = colorScheme  // read to establish dependency
        content
            .background(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .fill(CMTheme.cardBG)
                    .overlay(
                        RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                            .stroke(CMTheme.cardStroke, lineWidth: 0.5)
                    )
                    .shadow(color: CMTheme.cardShadow, radius: CMTheme.cardShadowRadius, x: 0, y: 6)
            )
            .padding(.horizontal, sizeClass == .regular ? 24 : 16)
            .padding(.vertical, 6)
    }
}
extension View { func cardStyle() -> some View { modifier(CardStyle()) } }

// MARK: - ActivesSectionView

/// Standalone sub-view for the "Actives" card so it can hold its own @State
/// for keyboard tracking and pause the psychedelic animation while the user types.
private struct ActivesSectionView: View {
    var viewModel: BatchConfigViewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var activeFieldFocused = false

    var body: some View {
        @Bindable var viewModel = viewModel
        let activesChanged = viewModel.activeConcentration != 10.0
            || viewModel.lsdUgPerTab != 117.0

        VStack(spacing: 8) {
            // Section header
            HStack {
                Text("Actives").font(.headline).foregroundStyle(systemConfig.designTitle)
                if activesChanged {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) {
                            viewModel.activeConcentration = 10.0
                            viewModel.lsdUgPerTab = 117.0
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .cmResetTransition()
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            HStack(spacing: 8) {
                ForEach(Active.allCases) { substance in
                    let isSelected = viewModel.selectedActive == substance
                    Button {
                        CMHaptic.selection()
                        withAnimation(.cmSpring) { viewModel.selectedActive = substance }
                    } label: {
                        Text(substance.rawValue)
                            .font(.headline)
                            .foregroundStyle(isSelected ? .white : CMTheme.textTertiary)
                            .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                                        .fill(CMTheme.chipBG)
                                    PsychedelicButton2(isDisabled: !isSelected)
                                }
                            )
                    }
                    .buttonStyle(CMPressStyle())
                }
            }
            .padding(.horizontal, 16)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                NumericField(value: $viewModel.activeConcentration, decimals: 1, isFocusedBinding: $activeFieldFocused)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).skittleSwirlWide(isPaused: activeFieldFocused).fixedSize()
                Text("\(viewModel.selectedActive.unit.rawValue) / gummy").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 24).padding(.vertical, 12)

            if viewModel.selectedActive == .lsd {
                Divider().padding(.horizontal, 16)
                HStack {
                    Text("µg per tab").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    NumericField(value: $viewModel.lsdUgPerTab, decimals: 1)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold)).frame(width: 90)
                    Text("µg").font(.system(size: 18)).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 24).padding(.bottom, 12)
            }
        }
    }
}
