import SwiftUI

struct ShapePickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var showSettings = false
    @State private var showHistory  = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // MARK: - Readiness check

    private var canCalculate: Bool {
        // Flavors: if any selected, blends must sum to 100
        let terpenes = viewModel.selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
        let oils     = viewModel.selectedFlavors.keys.filter { if case .oil     = $0 { return true }; return false }
        let terpTotal = terpenes.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
        let oilTotal  = oils.reduce(0.0)    { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
        let flavorsOK = (terpenes.isEmpty || abs(terpTotal - 100) < 0.5)
                     && (oils.isEmpty     || abs(oilTotal  - 100) < 0.5)
                     && (viewModel.selectedFlavors.isEmpty || viewModel.flavorsLocked)

        // Colors: if any selected, blend must sum to 100
        let colorTotal = viewModel.colorBlendTotal
        let colorsOK   = viewModel.selectedColors.isEmpty
                      || (viewModel.colorsLocked && abs(colorTotal - 100) < 0.5)

        return flavorsOK && colorsOK
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(spacing: 12) {
                // ── Input cards / summary ──
                if viewModel.batchCalculated {
                    InputSummaryView().cardStyle()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Group {
                        chooseShape.cardStyle()
                        chooseTrays(viewModel: viewModel).cardStyle()
                        chooseActive(viewModel: viewModel).cardStyle()
                        chooseGelatin(viewModel: viewModel).cardStyle()
                        FlavorPickerView().cardStyle()
                        ColorPickerView().cardStyle()
                        calculateBatchSection.cardStyle()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // ── Output cards ────────────────────────────
                if viewModel.batchCalculated {
                    Group {
                        BatchOutputView().cardStyle()
                        BatchValidationView().cardStyle()
                        RelativeFractionsView().cardStyle()
                        WeightMeasurementsView().cardStyle()
                        MeasurementCalculationsView().cardStyle()
                        resetSection.cardStyle()
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Gummy Batch")
        .background(CMTheme.pageBG)
        .scrollDismissesKeyboard(.immediately)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .foregroundStyle(CMTheme.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill").foregroundStyle(CMTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(systemConfig).environment(viewModel)
        }
        .sheet(isPresented: $showHistory) {
            BatchHistoryView()
        }
    }

    // MARK: - Calculate Section

    private var calculateBatchSection: some View {
        VStack(spacing: 8) {
            CMSectionHeader(title: "Calculate Batch")

            if !canCalculate {
                Text("All selected flavor and color blends must sum to 100%")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16)
            }

            Button {
                CMHaptic.heavy()
                withAnimation(.cmSpring) { viewModel.batchCalculated = true }
            } label: {
                Label("Calculate", systemImage: "function")
                    .modifier(CMButtonStyle(color: CMTheme.accent, isDisabled: !canCalculate))
            }
            .buttonStyle(CMPressStyle())
            .disabled(!canCalculate)
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        VStack(spacing: 8) {
            CMSectionHeader(title: "New Batch")
            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.resetBatch() }
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
    }

    // MARK: - Input Sections

    private func chooseGelatin(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        let finalMixVol = result.activationMix.totalVolume_mL + result.gelatinMix.totalVolume_mL + result.sugarMix.totalVolume_mL
        let gelatinGoopVolPct = finalMixVol > 0 ? (result.gelatinMix.totalVolume_mL / finalMixVol) * 100.0 : 0.0
        return VStack(spacing: 4) {
            sectionHeader(title: "Gelatin", detail: String(format: "Gelatin Goop Vol %% %.3f", gelatinGoopVolPct))
            HStack {
                TextField("0.0", value: $viewModel.gelatinPercentage,
                          format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).frame(width: 120)
                Text("%").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 24).padding(.vertical, 12)
            Text("Volume percentage of gelatin in the gummy mixture.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    private var chooseShape: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Shape",
                          detail: String(format: "%.3f ml / mold",
                                         systemConfig.spec(for: viewModel.selectedShape).volume_ml))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(GummyShape.allCases) { shape in shapeButton(for: shape) }
            }.padding(12)
        }
    }

    private func chooseTrays(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig
        return VStack(spacing: 4) {
            sectionHeader(title: "Trays",
                          detail: "\(systemConfig.spec(for: viewModel.selectedShape).count) per tray")
            HStack {
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.trayCount = max(1, viewModel.trayCount - 1) }
                } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundStyle(CMTheme.accent)
                }
                Spacer()
                Text("\(viewModel.trayCount)")
                    .font(.system(size: 20, weight: .bold)).foregroundStyle(CMTheme.textPrimary)
                    .contentTransition(.numericText())
                Text("Tray\(viewModel.trayCount == 1 ? "" : "s")").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.trayCount = min(20, viewModel.trayCount + 1) }
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(CMTheme.accent)
                }
            }.padding(.horizontal, 24).padding(.vertical, 12)
            Text("\(viewModel.trayCount) \(viewModel.selectedShape.rawValue.lowercased()) tray\(viewModel.trayCount == 1 ? "" : "s") = \(viewModel.trayCount * systemConfig.spec(for: viewModel.selectedShape).count) units")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
            Spacer()
        }
    }

    private func chooseActive(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 8) {
            sectionHeader(title: "Actives",
                          detail: "\(String(format: "%.1f", viewModel.activeConcentration)) \(viewModel.units.rawValue) \(viewModel.selectedActive.rawValue) / gummy")
            HStack {
                Picker("Substance", selection: $viewModel.selectedActive) {
                    ForEach(Active.allCases) { s in Text(s.rawValue).tag(s) }
                }
            }.pickerStyle(.segmented).padding(.horizontal, 16)
            .onChange(of: viewModel.selectedActive) { CMHaptic.selection() }
            HStack {
                TextField("0.0", value: $viewModel.activeConcentration,
                          format: .number.precision(.fractionLength(1...6)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).frame(width: 120)
                Text(viewModel.selectedActive.unit.rawValue).font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 24).padding(.vertical, 12)

            if viewModel.selectedActive == .LSD {
                Divider().padding(.horizontal, 16)
                HStack {
                    Text("µg per tab").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    TextField("100", value: $viewModel.lsdUgPerTab,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold)).frame(width: 90)
                    Text("µg").font(.system(size: 18)).foregroundStyle(CMTheme.textSecondary)
                }.padding(.horizontal, 24).padding(.bottom, 12)
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, detail: String) -> some View {
        HStack {
            Text(title).font(.headline).foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(detail).font(.subheadline).foregroundStyle(CMTheme.textSecondary)
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
            .foregroundStyle(sel ? CMTheme.accent : CMTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                    .fill(sel ? CMTheme.accent.opacity(0.12) : CMTheme.fieldBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                    .stroke(sel ? CMTheme.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
            .animation(.cmSpring, value: sel)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Summary (post-calculate)

struct InputSummaryView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Batch Configuration").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            let spec = systemConfig.spec(for: viewModel.selectedShape)
            let wellCount = spec.count * viewModel.trayCount

            // Core inputs
            summaryRow("Shape", value: viewModel.selectedShape.rawValue)
            summaryRow("Trays", value: "\(viewModel.trayCount)  (\(wellCount) gummies)")
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
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}
extension View { func cardStyle() -> some View { modifier(CardStyle()) } }
