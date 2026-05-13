import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Flavor Oil Picker

struct FlavorOilPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    let adaptiveColumns = [GridItem(.adaptive(minimum: 110))]

    private var selectedOils: [FlavorSelection] {
        viewModel.selectedFlavors.keys.filter { if case .oil = $0 { return true }; return false }
            .sorted { $0.id < $1.id }
    }

    private var oilsChanged: Bool {
        !selectedOils.isEmpty
        || viewModel.oilsLocked
        || viewModel.flavorOilVolumePercent != 0.451
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Flavor Oils").font(.headline).foregroundStyle(CMTheme.textPrimary)
                if oilsChanged {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) {
                            for key in selectedOils { viewModel.selectedFlavors.removeValue(forKey: key) }
                            viewModel.flavorOilVolumePercent = 0.451
                            viewModel.oilsLocked = false
                            if viewModel.selectedFlavors.isEmpty {
                                viewModel.flavorCompositionLocked = false
                            }
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
                Text("\(selectedOils.count)")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(selectedOils.count > 0 ? Color(red: 0.929, green: 0.278, blue: 0.290) : CMTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if !viewModel.oilsLocked || selectedOils.isEmpty {
                oilPickingView(viewModel: viewModel)
            } else {
                oilBlendView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Picking

    private func oilPickingView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let allOils: [FlavorSelection] = FlavorOil.allCases.map { .oil($0) }
        return VStack(spacing: 8) {
            LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                ForEach(allOils) { flavor in
                    flavorTag(flavor: flavor, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)

            if !selectedOils.isEmpty && !viewModel.oilsLocked {
                Button {
                    CMHaptic.medium()
                    withAnimation(.cmSpring) { viewModel.lockOils() }
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

    // MARK: - Blend Sliders

    private func oilBlendView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let oils = selectedOils
        let oilTotal = oils.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0.0", value: $viewModel.flavorOilVolumePercent,
                          format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).fixedSize().selectAllOnFocus()
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
                        value: Binding(
                            get: { viewModel.selectedFlavors[flavor] ?? 0 },
                            set: { newValue in
                                let oldValue = viewModel.selectedFlavors[flavor] ?? 0
                                viewModel.selectedFlavors[flavor] = newValue
                                #if canImport(UIKit)
                                if newValue != oldValue && systemConfig.sliderVibrationsEnabled {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred(intensity: 1.0)
                                }
                                #endif
                            }
                        ),
                        in: 0...100, step: 5
                    )
                    .rainbowSlide(value: viewModel.selectedFlavors[flavor] ?? 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            HStack {
                Text("Oil blend").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Text("\(oilTotal, specifier: "%.0f")%")
                    .fontWeight(.semibold)
                    .foregroundStyle(abs(oilTotal - 100) < 0.5 ? CMTheme.success : CMTheme.danger)
                    .contentTransition(.numericText())
                    .animation(.cmSpring, value: oilTotal)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            ThemedDivider()

            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.unlockOils() }
            } label: {
                Label("Re-pick Oils", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }

    // MARK: - Tag

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
}

// MARK: - Terpene Picker

struct TerpenePickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    let adaptiveColumns = [GridItem(.adaptive(minimum: 110))]

    private var selectedTerpenes: [FlavorSelection] {
        viewModel.selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
            .sorted { $0.id < $1.id }
    }

    private var terpenesChanged: Bool {
        !selectedTerpenes.isEmpty
        || viewModel.terpenesLocked
        || viewModel.terpeneVolumePPM != 199.0
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Terpenes").font(.headline).foregroundStyle(CMTheme.textPrimary)
                if terpenesChanged {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) {
                            for key in selectedTerpenes { viewModel.selectedFlavors.removeValue(forKey: key) }
                            viewModel.terpeneVolumePPM = 199.0
                            viewModel.terpenesLocked = false
                            if viewModel.selectedFlavors.isEmpty {
                                viewModel.flavorCompositionLocked = false
                            }
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
                Text("\(selectedTerpenes.count)")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(selectedTerpenes.count > 0 ? Color(red: 0.929, green: 0.278, blue: 0.290) : CMTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if !viewModel.terpenesLocked || selectedTerpenes.isEmpty {
                terpenePickingView(viewModel: viewModel)
            } else {
                terpeneBlendView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Picking

    private func terpenePickingView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let allTerpenes: [FlavorSelection] = TerpeneFlavor.allCases.map { .terpene($0) }
        return VStack(spacing: 8) {
            LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                ForEach(allTerpenes) { flavor in
                    flavorTag(flavor: flavor, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)

            if !selectedTerpenes.isEmpty && !viewModel.terpenesLocked {
                Button {
                    CMHaptic.medium()
                    withAnimation(.cmSpring) { viewModel.lockTerpenes() }
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

    // MARK: - Blend Sliders

    private func terpeneBlendView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let terpenes = selectedTerpenes
        let terpeneTotal = terpenes.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0.0", value: $viewModel.terpeneVolumePPM,
                          format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).fixedSize().selectAllOnFocus()
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
                        value: Binding(
                            get: { viewModel.selectedFlavors[flavor] ?? 0 },
                            set: { newValue in
                                let oldValue = viewModel.selectedFlavors[flavor] ?? 0
                                viewModel.selectedFlavors[flavor] = newValue
                                #if canImport(UIKit)
                                if newValue != oldValue && systemConfig.sliderVibrationsEnabled {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred(intensity: newValue / 100.0)
                                }
                                #endif
                            }
                        ),
                        in: 0...100, step: 5
                    )
                    .rainbowSlide(value: viewModel.selectedFlavors[flavor] ?? 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            HStack {
                Text("Terpene blend").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Text("\(terpeneTotal, specifier: "%.0f")%")
                    .fontWeight(.semibold)
                    .foregroundStyle(abs(terpeneTotal - 100) < 0.5 ? CMTheme.success : CMTheme.danger)
                    .contentTransition(.numericText())
                    .animation(.cmSpring, value: terpeneTotal)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            ThemedDivider()

            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.unlockTerpenes() }
            } label: {
                Label("Re-pick Terpenes", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }

    // MARK: - Tag

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
}
