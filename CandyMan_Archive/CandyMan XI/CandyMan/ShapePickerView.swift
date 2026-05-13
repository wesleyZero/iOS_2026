import SwiftUI
import SwiftData

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
    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var saveBatchID = ""
    @State private var savedConfirmation = false

    private var isRegular: Bool { sizeClass == .regular }

    private var shapeColumns: [GridItem] {
        isRegular
            ? [GridItem(.adaptive(minimum: 140))]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    // MARK: - Readiness check

    private var canCalculate: Bool { readinessIssues.isEmpty }

    /// Returns a list of (section name, description) for each input that isn't ready yet.
    private var readinessIssues: [(section: String, detail: String)] {
        var issues: [(String, String)] = []

        // Trays
        if viewModel.trayCount <= 0 {
            issues.append(("Trays", "set number of trays"))
        }

        // Flavor oils
        let oils = viewModel.selectedFlavors.keys.filter { if case .oil = $0 { return true }; return false }
        if !oils.isEmpty {
            let oilTotal = oils.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
            if !viewModel.oilsLocked {
                issues.append(("Flavor Oils", "lock blend ratios"))
            } else if abs(oilTotal - 100) >= 0.5 {
                issues.append(("Flavor Oils", "blend must sum to 100%"))
            }
        }

        // Terpenes
        let terpenes = viewModel.selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
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
                        InputSummaryView().cardStyle()
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        BatchOutputView().cardStyle()
                        BatchValidationView().cardStyle()
                        RelativeFractionsView().cardStyle()
                        WeightMeasurementsView().cardStyle()
                        CalibrationMeasurementsView().cardStyle()
                        MeasurementCalculationsView().cardStyle()
                        SigFigsCardView().cardStyle()
                        ErrorAnalysisView().cardStyle()
                        resetSection.cardStyle()
                    }
                } else if isRegular {
                    // ── iPad pre-calculate: two-column input grid ──
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 12) {
                            templateSection.cardStyle()
                            chooseShape.cardStyle()
                            chooseTrays(viewModel: viewModel).cardStyle()
                            FlavorOilPickerView().cardStyle()
                            TerpenePickerView().cardStyle()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 12) {
                            chooseActive(viewModel: viewModel).cardStyle()
                            chooseGelatin(viewModel: viewModel).cardStyle()
                            ColorPickerView().cardStyle()
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
                        FlavorOilPickerView().cardStyle()
                        TerpenePickerView().cardStyle()
                        Spacer().frame(height: 4)
                        ColorPickerView().cardStyle()
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
        .onChange(of: viewModel.batchCalculated) { _, calculated in
            if calculated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.cmSpring) {
                        scrollProxy.scrollTo("scrollTop", anchor: .top)
                    }
                }
            }
        }
        .onChange(of: viewModel.templateInputsChanged) { _, changed in
            if changed, viewModel.activeTemplateID != nil {
                withAnimation(.cmSpring) {
                    viewModel.activeTemplateID = nil
                    viewModel.activeTemplateName = ""
                }
            }
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
        }
        } // ScrollViewReader
        .navigationBarTitleDisplayMode(.inline)
        .background(CMTheme.pageBG.ignoresSafeArea())
        .scrollDismissesKeyboard(.immediately)
        .preferredColorScheme(.dark)
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
                Button { showHistory = true } label: {
                    Image(systemName: "book.circle")
                        .foregroundStyle(CMTheme.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill").foregroundStyle(CMTheme.textSecondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView().environment(systemConfig).environment(viewModel)
        }
        .fullScreenCover(isPresented: $showHistory) {
            BatchHistoryView()
        }
        .sheet(isPresented: $showTemplates) {
            TemplateListView()
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
                        Text("Info \(Text("saved").foregroundColor(Color(red: 0.929, green: 0.278, blue: 0.290))) as \(Text(viewModel.activeTemplateName).foregroundColor(Color(red: 0.929, green: 0.278, blue: 0.290)))")
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
                            Text("Info \(canCalculate ? Text("not saved").foregroundColor(Color(red: 0.929, green: 0.278, blue: 0.290)) : Text("not saved")) as template")
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
                                .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                            Text("— \(issue.detail)")
                                .font(.caption)
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 4)
            }

            Button {
                CMHaptic.heavy()
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
                CMHaptic.medium()
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
                Label("Save Batch", systemImage: "square.and.arrow.down")
                    .modifier(CMButtonStyle(color: systemConfig.accent))
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
                onSave: { saveBatch(result: result) }
            )
            .presentationDetents([.height(280)])
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
                    NumericField(value: gelatinUseMass ? massBinding : $viewModel.gelatinPercentage, decimals: 3)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).skittleSwirlWide().fixedSize()
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
                        .foregroundStyle(systemConfig.accent)
                    Text("Templates")
                        .font(.headline)
                        .foregroundStyle(CMTheme.textPrimary)
                    Button {
                        CMHaptic.medium()
                        showResetTemplateAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
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
                Text("The \(Text(viewModel.activeTemplateName).foregroundColor(Color(red: 0.929, green: 0.278, blue: 0.290))) template is being used.")
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
                Text("Shape").font(.headline).foregroundStyle(systemConfig.accent)
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
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                let spec = systemConfig.spec(for: viewModel.selectedShape)
                HStack(spacing: 0) {
                    Text("\(spec.count)")
                        .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
                    Text(" Gummies / Tray • ")
                        .foregroundStyle(CMTheme.textTertiary)
                    Text(String(format: "%.1f", spec.volume_ml))
                        .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
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
                Text("Trays").font(.headline).foregroundStyle(systemConfig.accent)
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
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                HStack(spacing: 3) {
                    Text("\(totalGummies)")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.929, green: 0.278, blue: 0.290))
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
                    Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundStyle(systemConfig.accent)
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
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(systemConfig.accent)
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
                    Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundStyle(systemConfig.accent)
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
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(systemConfig.accent)
                }
                .opacity(viewModel.extraGummies < perTray - 1 ? 1 : 0.3)
                .disabled(viewModel.extraGummies >= perTray - 1)
            }.padding(.horizontal, 24).padding(.vertical, 8)

            // Fine print
            Text("\(perTray) gummies / tray")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.bottom, 8)
        }
    }

    private func chooseActive(viewModel: BatchConfigViewModel) -> some View {
        ActivesSectionView(viewModel: viewModel)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, detail: String? = nil, showReset: Bool = false, onReset: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title).font(.headline).foregroundStyle(systemConfig.accent)
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
                .transition(.scale.combined(with: .opacity))
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
            withAnimation(.linear(duration: 2.65).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Input Summary (post-calculate)

struct InputSummaryView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Batch Configuration").font(.headline).foregroundStyle(systemConfig.accent)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            let wellCount = viewModel.totalGummies(using: systemConfig)

            // Core inputs
            summaryRow("Shape", value: viewModel.selectedShape.rawValue)
            summaryRow("Trays", value: "\(viewModel.trayCount) + \(viewModel.extraGummies)  (\(wellCount) gummies)")
            summaryRow("Active", value: viewModel.selectedActive.rawValue)
            summaryRow("Concentration", value: String(format: "%.2f %@ / gummy", viewModel.activeConcentration, viewModel.units.rawValue))
            summaryRow("Gelatin %", value: String(format: "%.3f%%", viewModel.gelatinPercentage))

            // Terpenes
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
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
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
}

struct CardStyle: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .fill(CMTheme.cardBG)
                    .overlay(
                        RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
                    .shadow(color: CMTheme.cardShadow, radius: CMTheme.cardShadowRadius, x: 0, y: 6)
            )
            .padding(.horizontal, sizeClass == .regular ? 24 : 16)
            .padding(.vertical, 6)
    }
}
extension View { func cardStyle() -> some View { modifier(CardStyle()) } }
// MARK: - Psychedelic Alerts

/// Psychedelic Alert 1: Iridescent rotating angular gradient with counter-rotating overlay,
/// hue-shifting text, pulsing glow aura, breathing scale, and 3D wobble.
struct PsychedelicAlert1: View {
    @State private var phase: CGFloat = 0
    @State private var breathe: CGFloat = 1.0
    @State private var glowPulse: CGFloat = 0.5
    @State private var wobble: CGFloat = 0

    private let psychedelicColors: [Color] = [
        Color(red: 1.0, green: 0.05, blue: 0.5),   // neon pink
        Color(red: 0.7, green: 0.0, blue: 1.0),     // vivid purple
        Color(red: 0.2, green: 0.0, blue: 1.0),     // deep indigo
        Color(red: 0.0, green: 0.5, blue: 1.0),     // electric blue
        Color(red: 0.0, green: 1.0, blue: 0.8),     // acid cyan
        Color(red: 0.0, green: 1.0, blue: 0.3),     // toxic green
        Color(red: 0.8, green: 1.0, blue: 0.0),     // electric lime
        Color(red: 1.0, green: 0.8, blue: 0.0),     // golden
        Color(red: 1.0, green: 0.3, blue: 0.0),     // lava orange
        Color(red: 1.0, green: 0.05, blue: 0.5),    // back to neon pink
    ]

    var body: some View {
        ZStack {
            // Outer glow aura
            Capsule()
                .fill(
                    AngularGradient(colors: psychedelicColors, center: .center, angle: .degrees(-phase))
                )
                .blur(radius: 20 + glowPulse * 10)
                .opacity(0.6)
                .scaleEffect(1.15 + glowPulse * 0.1)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)

            // Main pill
            Text("Because the CandyMan can!!")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 1.0, green: 0.9, blue: 0.95)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .hueRotation(.degrees(phase * 2))
                .shadow(color: .white.opacity(0.8), radius: 2)
                .shadow(color: Color(red: 1.0, green: 0.05, blue: 0.5).opacity(0.6), radius: 8)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        // Base rotating gradient
                        Capsule()
                            .fill(
                                AngularGradient(colors: psychedelicColors, center: .center, angle: .degrees(phase))
                            )

                        // Counter-rotating overlay gradient for interference pattern
                        Capsule()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        Color(red: 0.0, green: 1.0, blue: 1.0).opacity(0.5),
                                        Color(red: 1.0, green: 0.0, blue: 1.0).opacity(0.5),
                                        Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.5),
                                        Color(red: 0.0, green: 1.0, blue: 1.0).opacity(0.5),
                                    ],
                                    center: .center,
                                    angle: .degrees(-phase + 180)
                                )
                            )
                            .blendMode(.screen)

                        // Glass overlay
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .opacity(0.25)

                        // Shimmering border
                        Capsule()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .white.opacity(0.9),
                                        .clear,
                                        Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.6),
                                        .clear,
                                        Color(red: 1.0, green: 0.05, blue: 0.5).opacity(0.6),
                                        .clear,
                                        .white.opacity(0.9),
                                    ],
                                    center: .center,
                                    angle: .degrees(-phase * 2)
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: Color(red: 0.7, green: 0.0, blue: 1.0).opacity(glowPulse), radius: 16, y: 2)
                    .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(glowPulse * 0.5), radius: 24, y: -2)
                    .shadow(color: Color(red: 1.0, green: 0.05, blue: 0.5).opacity(glowPulse * 0.7), radius: 20, x: 4)
                )
        }
        .scaleEffect(breathe)
        .rotation3DEffect(.degrees(wobble), axis: (x: 0.1, y: 1, z: 0.05))
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                breathe = 1.04
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                wobble = 4
            }
        }
    }
}

/// **SkittleSwirl** — Animated "CandyMan X" title with a rotating angular gradient
/// in Skittles candy + rave neon colors. Do not delete.
struct PsychedelicTitleView: View {
    @State private var phase: CGFloat = 0

    /// Skittles candy + rave neon palette, bookended for seamless loop.
    private let candyColors: [Color] = [
        Color(red: 1.00, green: 0.00, blue: 0.30),  // Neon strawberry
        Color(red: 1.00, green: 0.35, blue: 0.00),  // Skittles orange
        Color(red: 1.00, green: 0.95, blue: 0.00),  // Electric lemon
        Color(red: 0.00, green: 1.00, blue: 0.40),  // Rave green
        Color(red: 0.00, green: 0.85, blue: 1.00),  // Neon cyan
        Color(red: 0.55, green: 0.00, blue: 1.00),  // Grape rave
        Color(red: 1.00, green: 0.00, blue: 0.70),  // Hot magenta
        Color(red: 1.00, green: 0.00, blue: 0.30),  // Neon strawberry (loop)
    ]

    var body: some View {
        Text("CandyMan Χ")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(
                AngularGradient(
                    colors: candyColors,
                    center: .center,
                    angle: .degrees(phase)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 2.65).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
    }
}

/// Psychedelic button background matching PsychedelicAlert2 aesthetic.
/// Animated plasma gradient with neon shimmer border and pulsing glow.
struct PsychedelicButton1: View {
    var cornerRadius: CGFloat = CMTheme.buttonRadius
    var isDisabled: Bool = false

    @State private var phase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3

    private let plasmaColors: [Color] = [
        Color(red: 0.0, green: 0.0, blue: 0.2),
        Color(red: 0.3, green: 0.0, blue: 0.8),
        Color(red: 0.8, green: 0.0, blue: 0.6),
        Color(red: 1.0, green: 0.2, blue: 0.0),
        Color(red: 1.0, green: 0.8, blue: 0.0),
        Color(red: 0.0, green: 1.0, blue: 0.5),
        Color(red: 0.0, green: 0.4, blue: 1.0),
        Color(red: 0.0, green: 0.0, blue: 0.2),
    ]

    var body: some View {
        ZStack {
            // Base plasma
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                )

            // Counter-rotating shimmer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                            Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.3),
                            Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.3),
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                        ],
                        center: .center,
                        angle: .degrees(-phase + 180)
                    )
                )
                .blendMode(.screen)

            // Glass overlay for depth
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .opacity(0.2)

            // Neon border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7),
                            .clear,
                            Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5),
                            .clear,
                            Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.7),
                            .clear,
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7),
                        ],
                        center: .center,
                        angle: .degrees(-phase)
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(glowPulse), radius: 12, y: 4)
        .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(glowPulse * 0.5), radius: 8, y: -2)
        .opacity(isDisabled ? 0 : 1)
        .onAppear { startAnimationsIfNeeded() }
        .onChange(of: isDisabled) { _, disabled in
            if !disabled { startAnimationsIfNeeded() }
        }
    }

    private func startAnimationsIfNeeded() {
        guard !isDisabled, phase == 0 else { return }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            phase = 360
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
    }
}

/// **PsychedelicProgressBar** — A progress bar styled like PsychedelicButton2.
/// The plasma + vignette fill extends only to the progress percentage.
/// White text showing the percentage sits centered with a dark vignette behind it.
struct PsychedelicProgressBar: View {
    var progress: Double  // 0...100
    var cornerRadius: CGFloat = CMTheme.buttonRadius

    @State private var phase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3

    private let plasmaColors: [Color] = [
        Color(red: 0.0, green: 0.0, blue: 0.2),
        Color(red: 0.3, green: 0.0, blue: 0.8),
        Color(red: 0.8, green: 0.0, blue: 0.6),
        Color(red: 1.0, green: 0.2, blue: 0.0),
        Color(red: 1.0, green: 0.8, blue: 0.0),
        Color(red: 0.0, green: 1.0, blue: 0.5),
        Color(red: 0.0, green: 0.4, blue: 1.0),
        Color(red: 0.0, green: 0.0, blue: 0.2),
    ]

    private let vignetteColor = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var fraction: CGFloat { min(max(CGFloat(progress) / 100.0, 0), 1) }
    private var isComplete: Bool { abs(progress - 100) < 0.5 }

    var body: some View {
        GeometryReader { geo in
            let fillWidth = geo.size.width * fraction

            ZStack {
                // Empty track — jet black
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.black)

                // Filled portion — psychedelic plasma clipped to progress width
                ZStack {
                    // Base plasma
                    AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))

                    // Counter-rotating shimmer
                    AngularGradient(
                        colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                            Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.3),
                            Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.3),
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                        ],
                        center: .center,
                        angle: .degrees(-phase + 180)
                    )
                    .blendMode(.screen)

                    // Glass overlay
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .opacity(0.2)

                    // Dark center vignette — scales with progress (gentle 1/4 decay)
                    // At low progress: slightly reduced vignette → more plasma visible
                    // At high progress: full vignette → dark center, plasma at edges
                    RadialGradient(
                        colors: [
                            vignetteColor.opacity(0.75 + 0.25 * fraction * fraction),  // 0.75→1.0
                            vignetteColor.opacity(0.71 + 0.24 * fraction),             // 0.71→0.95
                            vignetteColor.opacity(0.45 + 0.25 * fraction),             // 0.45→0.70
                            vignetteColor.opacity(0.19 + 0.16 * fraction),             // 0.19→0.35
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geo.size.width * (0.41 + 0.14 * fraction), 90)  // 0.41→0.55 of width
                    )
                }
                .frame(width: fillWidth)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: fraction >= 0.98 ? cornerRadius : 4,
                        topTrailingRadius: fraction >= 0.98 ? cornerRadius : 4
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                // Neon border on the full bar
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7 * Double(fraction)),
                                .clear,
                                Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5 * Double(fraction)),
                                .clear,
                                Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.7 * Double(fraction)),
                                .clear,
                                Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7 * Double(fraction)),
                            ],
                            center: .center,
                            angle: .degrees(-phase)
                        ),
                        lineWidth: 1.5
                    )

                // Percentage text — centered in the filled portion
                if fillWidth > 30 {
                    Text("\(Int(progress))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                        .position(x: fillWidth / 2, y: geo.size.height / 2)
                } else if progress > 0 {
                    Text("\(Int(progress))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(CMTheme.textTertiary)
                        .position(x: fillWidth + 20, y: geo.size.height / 2)
                }
            }
            .shadow(
                color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(Double(glowPulse) * Double(fraction)),
                radius: 12, y: 4
            )
            .shadow(
                color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(Double(glowPulse) * 0.5 * Double(fraction)),
                radius: 8, y: -2
            )
        }
        .frame(height: 44)
        .animation(.cmSpring, value: progress)
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            phase = 360
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
    }
}

// MARK: - ActivesSectionView

/// Standalone sub-view for the "Actives" card so it can hold its own @State
/// for keyboard tracking and pause the psychedelic animation while the user types.
private struct ActivesSectionView: View {
    var viewModel: BatchConfigViewModel
    @Environment(SystemConfig.self) private var systemConfig

    @State private var keyboardVisible = false

    var body: some View {
        @Bindable var viewModel = viewModel
        let activesChanged = viewModel.activeConcentration != 10.0
            || viewModel.lsdUgPerTab != 117.0

        VStack(spacing: 8) {
            // Section header
            HStack {
                Text("Actives").font(.headline).foregroundStyle(systemConfig.accent)
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
                    .transition(.scale.combined(with: .opacity))
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
                                    PsychedelicButton2(isDisabled: !isSelected, isPaused: keyboardVisible)
                                }
                            )
                    }
                    .buttonStyle(CMPressStyle())
                }
            }
            .padding(.horizontal, 16)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                NumericField(value: $viewModel.activeConcentration, decimals: 1)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).skittleSwirlWide().fixedSize()
                Text("\(viewModel.selectedActive.unit.rawValue) / gummy").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 24).padding(.vertical, 12)

            if viewModel.selectedActive == .LSD {
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                keyboardVisible = false
            }
        }
    }
}

/// PsychedelicButton2 — Same plasma animation as PsychedelicButton1 but with a dark
/// center vignette that fades to transparent at the edges. The text sits on a dark
/// background that gradually reveals the psychedelic animation toward the button edges.
struct PsychedelicButton2: View {
    var cornerRadius: CGFloat = CMTheme.buttonRadius
    var isDisabled: Bool = false
    var isPaused: Bool = false

    @State private var phase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3

    private let plasmaColors: [Color] = [
        Color(red: 0.0, green: 0.0, blue: 0.2),
        Color(red: 0.3, green: 0.0, blue: 0.8),
        Color(red: 0.8, green: 0.0, blue: 0.6),
        Color(red: 1.0, green: 0.2, blue: 0.0),
        Color(red: 1.0, green: 0.8, blue: 0.0),
        Color(red: 0.0, green: 1.0, blue: 0.5),
        Color(red: 0.0, green: 0.4, blue: 1.0),
        Color(red: 0.0, green: 0.0, blue: 0.2),
    ]

    /// The dark grey matching the page background
    private let vignetteColor = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        ZStack {
            // Base plasma
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                )

            // Counter-rotating shimmer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                            Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.3),
                            Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.3),
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                        ],
                        center: .center,
                        angle: .degrees(-phase + 180)
                    )
                )
                .blendMode(.screen)

            // Glass overlay for depth
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .opacity(0.2)

            // ── Dark center vignette ──
            // Opaque dark grey in center, fading to transparent at edges
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            vignetteColor,
                            vignetteColor,
                            vignetteColor.opacity(0.95),
                            vignetteColor.opacity(0.6),
                            vignetteColor.opacity(0.25),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )

            // Neon border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7),
                            .clear,
                            Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5),
                            .clear,
                            Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.7),
                            .clear,
                            Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7),
                        ],
                        center: .center,
                        angle: .degrees(-phase)
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(glowPulse), radius: 12, y: 4)
        .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(glowPulse * 0.5), radius: 8, y: -2)
        .opacity(isDisabled ? 0 : 1)
        .onAppear { startAnimationsIfNeeded() }
        .onChange(of: isDisabled) { _, disabled in
            if !disabled { startAnimationsIfNeeded() }
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                // Freeze animation by snapping phase to a static value without animation
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    phase = 0
                    glowPulse = 0.3
                }
            } else {
                // Keyboard dismissed — restart on next run loop so the animation
                // transaction doesn't interfere with the scroll-view layout pass.
                DispatchQueue.main.async {
                    startAnimationsIfNeeded()
                }
            }
        }
    }

    private func startAnimationsIfNeeded() {
        guard !isDisabled, phase == 0 else { return }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            phase = 360
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
    }
}

/// Psychedelic Alert 2: Morphing radial plasma with concentric rings, kaleidoscope shimmer,
/// pulsing neon border, floating particles feel, and dissolving text entrance.
struct PsychedelicAlert2: View {
    let title: String
    let subtitle: String
    let buttonLabel: String
    let onDismiss: () -> Void
    @State private var phase: CGFloat = 0
    @State private var ringPulse: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var iconSpin: CGFloat = 0
    @State private var plasmaShift: CGFloat = 0

    private let plasmaColors: [Color] = [
        Color(red: 0.0, green: 0.0, blue: 0.2),     // deep void
        Color(red: 0.3, green: 0.0, blue: 0.8),     // indigo plasma
        Color(red: 0.8, green: 0.0, blue: 0.6),     // magenta fire
        Color(red: 1.0, green: 0.2, blue: 0.0),     // solar flare
        Color(red: 1.0, green: 0.8, blue: 0.0),     // golden nova
        Color(red: 0.0, green: 1.0, blue: 0.5),     // alien green
        Color(red: 0.0, green: 0.4, blue: 1.0),     // deep ocean
        Color(red: 0.0, green: 0.0, blue: 0.2),     // back to void
    ]

    private let ringColors: [Color] = [
        Color(red: 1.0, green: 0.0, blue: 0.8),
        Color(red: 0.0, green: 0.8, blue: 1.0),
        Color(red: 1.0, green: 1.0, blue: 0.0),
        Color(red: 1.0, green: 0.0, blue: 0.8),
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop with color-shifting tint
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 0.0, blue: 0.5).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                    .hueRotation(.degrees(phase * 1.5))
                    .ignoresSafeArea()
                )
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 20) {
                // Animated icon with orbital rings
                ZStack {
                    // Outer orbital ring 1
                    Circle()
                        .stroke(
                            AngularGradient(colors: ringColors, center: .center, angle: .degrees(phase)),
                            lineWidth: 2
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(phase))
                        .opacity(0.7)

                    // Outer orbital ring 2 (counter)
                    Circle()
                        .stroke(
                            AngularGradient(colors: ringColors, center: .center, angle: .degrees(-phase * 2)),
                            lineWidth: 1.5
                        )
                        .frame(width: 95, height: 95)
                        .rotationEffect(.degrees(-phase * 0.5))
                        .opacity(0.4)

                    // Pulsing glow behind icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.6),
                                    Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 35 + ringPulse * 10
                            )
                        )
                        .frame(width: 70, height: 70)
                        .hueRotation(.degrees(phase * 3))

                    // Icon
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(iconSpin))
                        )
                        .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.8), radius: 8)
                        .shadow(color: Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5), radius: 16)
                }

                // Title
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .hueRotation(.degrees(phase))
                    .shadow(color: Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.5), radius: 4)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Subtitle
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .hueRotation(.degrees(-phase * 0.5))
                    .opacity(textOpacity)

                // Button
                Button {
                    onDismiss()
                } label: {
                    Text(buttonLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.8, green: 0.0, blue: 0.6),
                                                Color(red: 0.3, green: 0.0, blue: 1.0),
                                                Color(red: 0.0, green: 0.5, blue: 1.0),
                                            ],
                                            startPoint: UnitPoint(x: plasmaShift, y: 0),
                                            endPoint: UnitPoint(x: plasmaShift + 1, y: 1)
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        AngularGradient(
                                            colors: [.white.opacity(0.6), .clear, .white.opacity(0.3), .clear, .white.opacity(0.6)],
                                            center: .center,
                                            angle: .degrees(phase * 2)
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
                .buttonStyle(CMPressStyle())
                .padding(.top, 4)
                .opacity(textOpacity)
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(
                ZStack {
                    // Plasma background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                        )
                        .opacity(0.4)

                    // Dark glass
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)

                    // Neon border
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.8),
                                    Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5),
                                    Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.8),
                                    Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.5),
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.8),
                                ],
                                center: .center,
                                angle: .degrees(-phase)
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(0.6), radius: 30, y: 10)
                .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(ringPulse * 0.4), radius: 20, y: -5)
            )
            .scaleEffect(0.95 + ringPulse * 0.05)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                iconSpin = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                ringPulse = 1.0
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                plasmaShift = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}


