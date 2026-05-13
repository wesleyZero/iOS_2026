import SwiftUI

struct FlavorPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    let adaptiveColumns = [GridItem(.adaptive(minimum: 110))]

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 8) {
            sectionHeader

            if viewModel.selectedFlavors.isEmpty {
                pickingView(viewModel: viewModel)
            } else if !viewModel.flavorsLocked {
                pickingView(viewModel: viewModel)
            } else {
                blendView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header

    private var flavorsChanged: Bool {
        !viewModel.selectedFlavors.isEmpty
        || viewModel.flavorsLocked
        || viewModel.flavorCompositionLocked
        || viewModel.flavorSourceTab != .terpenes
        || viewModel.terpeneVolumePPM != 199.0
        || viewModel.flavorOilVolumePercent != 0.451
    }

    private var sectionHeader: some View {
        HStack {
            Text("Flavors").font(.headline).foregroundStyle(CMTheme.textPrimary)
            if flavorsChanged {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) {
                        viewModel.selectedFlavors = [:]
                        viewModel.flavorsLocked = false
                        viewModel.flavorCompositionLocked = false
                        viewModel.flavorSourceTab = .terpenes
                        viewModel.terpeneVolumePPM = 199.0
                        viewModel.flavorOilVolumePercent = 0.451
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
            Text("\(viewModel.selectedFlavors.count) selected")
                .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Picking State

    private func pickingView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 8) {
            Picker("Source", selection: $viewModel.flavorSourceTab) {
                ForEach(FlavorSourceType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .onChange(of: viewModel.flavorSourceTab) { CMHaptic.selection() }

            LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                ForEach(currentFlavors) { flavor in
                    flavorTag(flavor: flavor, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)

            if viewModel.flavorSourceTab == .oils && terpeneCount > 0 {
                Text("+ \(terpeneCount) Terpene\(terpeneCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            } else if viewModel.flavorSourceTab == .terpenes && oilCount > 0 {
                Text("+ \(oilCount) Flavor Oil\(oilCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if !viewModel.selectedFlavors.isEmpty {
                Button {
                    CMHaptic.medium()
                    withAnimation(.cmSpring) { viewModel.lockFlavors() }
                } label: {
                    Label("Set Blend Ratios", systemImage: "slider.horizontal.3")
                        .modifier(CMButtonStyle(color: systemConfig.accent))
                }
                .buttonStyle(CMPressStyle())
                .padding(.horizontal, 16).padding(.bottom, 12)
            } else {
                Spacer().frame(height: 4)
            }
        }
    }

    // MARK: - Blend Ratio State

    private func blendView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel

        let terpenes = Array(viewModel.selectedFlavors.terpeneEntries.keys)
        let oils = Array(viewModel.selectedFlavors.oilEntries.keys)
        let terpeneTotal = viewModel.selectedFlavors.terpeneBlendTotal
        let oilTotal = viewModel.selectedFlavors.oilBlendTotal

        return VStack(spacing: 0) {

            // ── TERPENES ──────────────────────────────
            if !terpenes.isEmpty {
                HStack {
                    Text("Terpene Volume").font(.headline).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text("ppm").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }
                .padding(.horizontal, 16).padding(.top, 12)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0.0", value: $viewModel.terpeneVolumePPM,
                              format: .number.precision(.fractionLength(1...3)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).fixedSize().selectAllOnFocus()
                    Text("ppm").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                }
                .padding(.vertical, 8)

                ForEach(terpenes, id: \.id) { flavor in
                    VStack(spacing: 4) {
                        HStack {
                            Text(flavor.displayName).font(.subheadline).foregroundStyle(CMTheme.textPrimary)
                            Spacer()
                            Text("\(viewModel.selectedFlavors[flavor] ?? 0, specifier: "%.0f")%")
                                .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                        }
                        Slider(
                            value: hapticSliderBinding(
                                get: { viewModel.selectedFlavors[flavor] ?? 0 },
                                set: { viewModel.selectedFlavors[flavor] = $0 },
                                vibrationsEnabled: systemConfig.sliderVibrationsEnabled
                            ),
                            in: 0...100, step: 5
                        ).tint(.blue)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }

                HStack {
                    Text("Terpene blend").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text("\(terpeneTotal, specifier: "%.0f")%")
                        .fontWeight(.semibold)
                        .foregroundStyle(abs(terpeneTotal - 100) < CMTheme.blendSumTolerance ? CMTheme.success : CMTheme.danger)
                        .contentTransition(.numericText())
                        .animation(.cmSpring, value: terpeneTotal)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            if !terpenes.isEmpty && !oils.isEmpty {
                Divider().padding(.horizontal, 16).padding(.vertical, 4)
            }

            // ── FLAVOR OILS ───────────────────────────
            if !oils.isEmpty {
                HStack {
                    Text("Flavor Oil Volume").font(.headline).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text("%").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                }
                .padding(.horizontal, 16).padding(.top, 12)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0.0", value: $viewModel.flavorOilVolumePercent,
                              format: .number.precision(.fractionLength(1...3)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).fixedSize().selectAllOnFocus()
                    Text("%").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                }
                .padding(.vertical, 8)

                ForEach(oils, id: \.id) { flavor in
                    VStack(spacing: 4) {
                        HStack {
                            Text(flavor.displayName).font(.subheadline).foregroundStyle(CMTheme.textPrimary)
                            Spacer()
                            Text("\(viewModel.selectedFlavors[flavor] ?? 0, specifier: "%.0f")%")
                                .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                        }
                        Slider(
                            value: hapticSliderBinding(
                                get: { viewModel.selectedFlavors[flavor] ?? 0 },
                                set: { viewModel.selectedFlavors[flavor] = $0 },
                                vibrationsEnabled: systemConfig.sliderVibrationsEnabled
                            ),
                            in: 0...100, step: 5
                        ).tint(.orange)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }

                HStack {
                    Text("Oil blend").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text("\(oilTotal, specifier: "%.0f")%")
                        .fontWeight(.semibold)
                        .foregroundStyle(abs(oilTotal - 100) < CMTheme.blendSumTolerance ? CMTheme.success : CMTheme.danger)
                        .contentTransition(.numericText())
                        .animation(.cmSpring, value: oilTotal)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            ThemedDivider()

            // ── RE-PICK ───────────────────────────────
            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.unlockFlavors() }
            } label: {
                Label("Re-pick Flavors", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }

    // MARK: - Tag Button

    @ViewBuilder
    private func flavorTag(flavor: FlavorSelection, viewModel: BatchConfigViewModel) -> some View {
        let isSelected = viewModel.isSelected(flavor)
        Button {
            CMHaptic.light()
            withAnimation(.cmSpring) { viewModel.toggleFlavor(flavor) }
        } label: {
            Text(flavor.displayName)
                .font(.caption).lineLimit(1)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                        .fill(isSelected ? systemConfig.accent.opacity(0.25) : CMTheme.chipBG)
                )
                .foregroundStyle(isSelected ? systemConfig.accent : CMTheme.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                        .stroke(isSelected ? systemConfig.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .animation(.cmSpring, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var currentFlavors: [FlavorSelection] {
        switch viewModel.flavorSourceTab {
        case .terpenes: return TerpeneFlavor.allCases.map { .terpene($0) }
        case .oils:     return FlavorOil.allCases.map { .oil($0) }
        }
    }

    private var terpeneCount: Int {
        viewModel.selectedFlavors.terpeneEntries.count
    }

    private var oilCount: Int {
        viewModel.selectedFlavors.oilEntries.count
    }
}
