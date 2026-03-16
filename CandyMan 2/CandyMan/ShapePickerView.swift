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
                // ── Input cards — disabled once calculated ──
                Group {
                    chooseShape.cardStyle()
                    chooseTrays(viewModel: viewModel).cardStyle()
                    chooseActive(viewModel: viewModel).cardStyle()
                    chooseGelatin(viewModel: viewModel).cardStyle()
                    FlavorPickerView().cardStyle()
                    ColorPickerView().cardStyle()
                }
                .disabled(viewModel.batchCalculated)

                // ── Calculate card ──────────────────────────
                if !viewModel.batchCalculated {
                    calculateBatchSection.cardStyle()
                }

                // ── Output cards ────────────────────────────
                if viewModel.batchCalculated {
                    BatchOutputView().cardStyle()
                    BatchValidationView().cardStyle()
                    WeightMeasurementsView().cardStyle()
                    MeasurementCalculationsView().cardStyle()
                    resetSection.cardStyle()
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Gummy Batch")
        .background(Color(.systemGray4))
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill").foregroundStyle(.primary)
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
            HStack { Text("Calculate Batch").font(.headline); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)

            if !canCalculate {
                Text("All selected flavor and color blends must sum to 100%")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }

            Button {
                viewModel.batchCalculated = true
            } label: {
                Label("Calculate", systemImage: "function")
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(canCalculate ? Color.blue : Color(.systemGray4))
                    .foregroundStyle(canCalculate ? .white : .secondary)
                    .cornerRadius(12).font(.headline)
            }
            .disabled(!canCalculate)
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        VStack(spacing: 8) {
            HStack { Text("New Batch").font(.headline); Spacer() }
                .padding(.horizontal, 16).padding(.vertical, 12)
            Button {
                viewModel.resetBatch()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(.systemGray4))
                    .foregroundStyle(.primary)
                    .cornerRadius(12).font(.headline)
            }
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
    }

    // MARK: - Input Sections

    private func chooseGelatin(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 4) {
            sectionHeader(title: "Gelatin", detail: String(format: "%.2f%%", viewModel.gelatinPercentage))
            HStack {
                TextField("0.0", value: $viewModel.gelatinPercentage,
                          format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).frame(width: 120)
                Text("%").font(.system(size: 20)).foregroundStyle(.secondary)
            }.padding(.horizontal, 24).padding(.vertical, 12)
            Text("Volume percentage of gelatin in the gummy mixture.")
                .font(.caption).foregroundStyle(.secondary)
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
                Button { viewModel.trayCount = max(1, viewModel.trayCount - 1) } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundStyle(.blue)
                }
                Spacer()
                Text("\(viewModel.trayCount)").font(.system(size: 20, weight: .bold))
                Text("Tray\(viewModel.trayCount == 1 ? "" : "s")").font(.system(size: 20)).foregroundStyle(.secondary)
                Spacer()
                Button { viewModel.trayCount = min(20, viewModel.trayCount + 1) } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(.blue)
                }
            }.padding(.horizontal, 24).padding(.vertical, 12)
            Text("\(viewModel.trayCount) \(viewModel.selectedShape.rawValue.lowercased()) tray\(viewModel.trayCount == 1 ? "" : "s") = \(viewModel.trayCount * systemConfig.spec(for: viewModel.selectedShape).count) units")
                .font(.caption).foregroundStyle(.secondary)
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
            HStack {
                TextField("0.0", value: $viewModel.activeConcentration,
                          format: .number.precision(.fractionLength(1...6)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).frame(width: 120)
                Text(viewModel.selectedActive.unit.rawValue).font(.system(size: 20)).foregroundStyle(.secondary)
            }.padding(.horizontal, 24).padding(.vertical, 12)

            if viewModel.selectedActive == .LSD {
                Divider().padding(.horizontal, 16)
                HStack {
                    Text("µg per tab").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    TextField("100", value: $viewModel.lsdUgPerTab,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold)).frame(width: 90)
                    Text("µg").font(.system(size: 18)).foregroundStyle(.secondary)
                }.padding(.horizontal, 24).padding(.bottom, 12)
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, detail: String) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func shapeButton(for shape: GummyShape) -> some View {
        let sel = viewModel.selectedShape == shape
        return Button { viewModel.selectedShape = shape } label: {
            VStack(spacing: 10) {
                Image(systemName: shape.sfSymbol).font(.system(size: 34))
                Text(shape.rawValue).font(.subheadline).fontWeight(.medium)
            }
            .foregroundStyle(sel ? .blue : .gray)
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 16)
            .background(sel ? Color.blue.opacity(0.08) : Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(sel ? Color.blue : .clear, lineWidth: 2))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color(.systemGray6)).cornerRadius(16).padding(.horizontal, 16).padding(.vertical, 6)
    }
}
extension View { func cardStyle() -> some View { modifier(CardStyle()) } }
