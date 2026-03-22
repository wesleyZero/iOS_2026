//
//  FlavorPickerView.swift
//  CandyMan
//
//  Flavor selection UI for oils and terpenes.
//
//  Both pickers follow the same two-phase pattern:
//    1. Picking — a tag grid where the user toggles flavors on/off
//    2. Blending — sliders for adjusting blend ratios (0–100%)
//
//  Contents:
//    FlavorOilPickerView  – Flavor oil selection & blend ratios
//    TerpenePickerView    – Terpene selection & blend ratios
//    FlavorTagView        – Shared tag button used by both pickers
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Flavor Oil Picker

struct FlavorOilPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var oilUseMass = false
    @State private var oilFieldFocused = false
    /// Maximum percentage any single slider can reach — user-adjustable via wheel picker.
    @State private var maxSliderPercent: Double = 100

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
                Text("Flavor Oils").font(.headline).foregroundStyle(systemConfig.designTitle)
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
                HStack(spacing: 3) {
                    Text("\(selectedOils.count)")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(selectedOils.count > 0 ? systemConfig.designAlert : CMTheme.textTertiary)
                    if selectedOils.count > 0 {
                        Text(selectedOils.count == 1 ? "Flavor" : "Flavors")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                }
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
                    FlavorTagView(flavor: flavor, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)

            if !selectedOils.isEmpty && !viewModel.oilsLocked {
                Button {
                    CMHaptic.medium()
                    maxSliderPercent = 100
                    withAnimation(.cmSpring) { viewModel.lockOils() }
                } label: {
                    Label("Set Blend Ratios", systemImage: "slider.horizontal.3")
                        .modifier(CMButtonStyle(color: systemConfig.designTitle))
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
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let rhoOil = systemConfig.densityFlavorOil

        // Mass % binding: mass% = vol% × (ρ_oil / ρ_mix)
        let massBinding = Binding<Double>(
            get: {
                guard rhoMix > 0 else { return 0 }
                return viewModel.flavorOilVolumePercent * rhoOil / rhoMix
            },
            set: { newMassPct in
                guard rhoMix > 0, rhoOil > 0 else { return }
                viewModel.flavorOilVolumePercent = newMassPct * rhoMix / rhoOil
            }
        )

        // Minimum picker value = smallest multiple of 5 where count × max ≥ 100
        let minPickerValue = Int(ceil(100.0 / Double(oils.count) / 5.0)) * 5
        let maxPickerValues = stride(from: minPickerValue, through: 100, by: 5).map { $0 }

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { oilUseMass.toggle() }
                } label: {
                    Image(systemName: oilUseMass ? "lightswitch.on" : "lightswitch.off")
                        .font(.system(size: 20))
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    NumericField(value: oilUseMass ? massBinding : $viewModel.flavorOilVolumePercent, decimals: 3, isFocusedBinding: $oilFieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).skittleSwirlWide(isPaused: oilFieldFocused).fixedSize()
                    Text(oilUseMass ? "% mass" : "% volume").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            ForEach(oils, id: \.id) { flavor in
                let currentValue = viewModel.selectedFlavors[flavor] ?? 0
                VStack(spacing: 4) {
                    HStack {
                        Text(flavor.displayName).font(.subheadline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text("\(Int(maxSliderPercent))%")
                            .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                    }
                    WeightedSlider(
                        value: Binding(
                            get: { viewModel.selectedFlavors[flavor] ?? 0 },
                            set: { newValue in
                                let oldValue = viewModel.selectedFlavors[flavor] ?? 0
                                let othersTotal = oils.filter { $0 != flavor }
                                    .reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
                                let clamped = min(newValue, 100.0 - othersTotal)
                                viewModel.selectedFlavors[flavor] = max(clamped, 0)
                                if clamped != oldValue && systemConfig.sliderVibrationsEnabled {
                                    CMHaptic.light(intensity: 1.0)
                                }
                            }
                        ),
                        range: 0...maxSliderPercent,
                        step: systemConfig.sliderResolution,
                        tint: CMTheme.textPrimary
                    )
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            // Progress bar row — with optional max-cap wheel picker for ≥ 3 oils
            HStack(spacing: 8) {
                PsychedelicProgressBar(progress: oilTotal)

                if oils.count >= 3 {
                    Picker("", selection: $maxSliderPercent) {
                        ForEach(maxPickerValues, id: \.self) { val in
                            Text("\(val)%").tag(Double(val))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)

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

}

// MARK: - Terpene Picker

struct TerpenePickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var terpUseMass = false
    @State private var terpUsePercent = false
    @State private var terpFieldFocused = false
    /// Maximum percentage any single terpene slider can reach — user-adjustable via wheel picker.
    @State private var maxSliderPercent: Double = 100
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
                Text("Terpenes").font(.headline).foregroundStyle(systemConfig.designTitle)
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
                HStack(spacing: 3) {
                    Text("\(selectedTerpenes.count)")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(selectedTerpenes.count > 0 ? systemConfig.designAlert : CMTheme.textTertiary)
                    if selectedTerpenes.count > 0 {
                        Text(selectedTerpenes.count == 1 ? "Terpene" : "Terpenes")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                }
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
                    FlavorTagView(flavor: flavor, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)

            if !selectedTerpenes.isEmpty && !viewModel.terpenesLocked {
                Button {
                    CMHaptic.medium()
                    maxSliderPercent = 100
                    withAnimation(.cmSpring) { viewModel.lockTerpenes() }
                } label: {
                    Label("Set Blend Ratios", systemImage: "slider.horizontal.3")
                        .modifier(CMButtonStyle(color: systemConfig.designTitle))
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
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let rhoTerp = systemConfig.densityTerpenes
        let densityRatio = rhoMix > 0 ? rhoTerp / rhoMix : 1.0

        // Volume % binding: vol% = vol_ppm / 10000
        let volPercentBinding = Binding<Double>(
            get: { viewModel.terpeneVolumePPM / 10_000.0 },
            set: { viewModel.terpeneVolumePPM = $0 * 10_000.0 }
        )
        // Mass ppm binding: mass_ppm = vol_ppm × (ρ_terpene / ρ_mix)
        let massPpmBinding = Binding<Double>(
            get: { viewModel.terpeneVolumePPM * densityRatio },
            set: { guard rhoTerp > 0 else { return }; viewModel.terpeneVolumePPM = $0 / densityRatio }
        )
        // Mass % binding: mass% = vol_ppm / 10000 × (ρ_terpene / ρ_mix)
        let massPercentBinding = Binding<Double>(
            get: { viewModel.terpeneVolumePPM / 10_000.0 * densityRatio },
            set: { guard rhoTerp > 0 else { return }; viewModel.terpeneVolumePPM = $0 / densityRatio * 10_000.0 }
        )

        // Pick the right binding and unit label
        let activeBinding: Binding<Double> = {
            switch (terpUseMass, terpUsePercent) {
            case (false, false): return $viewModel.terpeneVolumePPM
            case (true,  false): return massPpmBinding
            case (false, true):  return volPercentBinding
            case (true,  true):  return massPercentBinding
            }
        }()
        let goldenYellow = systemConfig.designSecondaryAccent
        // Split unit label into prefix ("ppm" or "%") and suffix ("mass" or "volume")
        let unitPrefix = terpUsePercent ? "%" : "ppm"
        let unitSuffix = terpUseMass ? "mass" : "volume"
        let fractionRange = terpUsePercent ? 1...4 : 1...1

        // Minimum picker value = smallest multiple of 5 where count × max ≥ 100
        let minPickerValue = Int(ceil(100.0 / Double(terpenes.count) / 5.0)) * 5
        let maxPickerValues = stride(from: minPickerValue, through: 100, by: 5).map { $0 }

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { terpUseMass.toggle() }
                } label: {
                    Image(systemName: terpUseMass ? "lightswitch.on" : "lightswitch.off")
                        .font(.system(size: 20))
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    NumericField(value: activeBinding, decimals: terpUsePercent ? 4 : 1, isFocusedBinding: $terpFieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).skittleSwirlWide(isPaused: terpFieldFocused).fixedSize()
                    HStack(spacing: 4) {
                        Text(unitPrefix).font(.system(size: 20)).foregroundStyle(goldenYellow)
                        Text(unitSuffix).font(.system(size: 20)).foregroundStyle(systemConfig.designDetailText)
                    }
                }
                Spacer()
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { terpUsePercent.toggle() }
                } label: {
                    Image(systemName: terpUsePercent ? "lightswitch.on" : "lightswitch.off")
                        .font(.system(size: 20))
                        .foregroundStyle(goldenYellow)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            ForEach(terpenes, id: \.id) { flavor in
                let currentValue = viewModel.selectedFlavors[flavor] ?? 0
                VStack(spacing: 4) {
                    HStack {
                        Text(flavor.displayName).font(.subheadline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text("\(Int(maxSliderPercent))%")
                            .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                    }
                    WeightedSlider(
                        value: Binding(
                            get: { viewModel.selectedFlavors[flavor] ?? 0 },
                            set: { newValue in
                                let oldValue = viewModel.selectedFlavors[flavor] ?? 0
                                let othersTotal = terpenes.filter { $0 != flavor }
                                    .reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
                                let clamped = min(newValue, 100.0 - othersTotal)
                                viewModel.selectedFlavors[flavor] = max(clamped, 0)
                                if clamped != oldValue && systemConfig.sliderVibrationsEnabled {
                                    CMHaptic.light(intensity: clamped / 100.0)
                                }
                            }
                        ),
                        range: 0...maxSliderPercent,
                        step: systemConfig.sliderResolution,
                        tint: CMTheme.textPrimary
                    )
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            // Progress bar row — with optional max-cap wheel picker for ≥ 3 terpenes
            HStack(spacing: 8) {
                PsychedelicProgressBar(progress: terpeneTotal)

                if terpenes.count >= 3 {
                    Picker("", selection: $maxSliderPercent) {
                        ForEach(maxPickerValues, id: \.self) { val in
                            Text("\(val)%").tag(Double(val))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)

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

}

// MARK: - Water Ripple Modifier

/// Draws expanding concentric rings from the center of the view, like a water droplet.
private struct WaterRippleModifier: ViewModifier {
    let trigger: Int
    let color: Color

    @State private var ripples: [UUID] = []

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(ripples, id: \.self) { id in
                        RippleRing(color: color)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous))
                .allowsHitTesting(false)
            )
            .onChange(of: trigger) {
                let id = UUID()
                ripples.append(id)
                // Remove after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    ripples.removeAll { $0 == id }
                }
            }
    }
}

/// A single expanding + fading ripple ring.
private struct RippleRing: View {
    let color: Color
    @State private var scale: CGFloat = 0.0
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    scale = 2.5
                    opacity = 0.0
                }
            }
    }
}

// MARK: - FlavorTagView (shared)

/// Reusable tag button for selecting/deselecting a flavor (oil or terpene).
/// Used by both `FlavorOilPickerView` and `TerpenePickerView`.
private struct FlavorTagView: View {
    let flavor: FlavorSelection
    let viewModel: BatchConfigViewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var rippleTrigger: Int = 0

    var body: some View {
        let isSelected = viewModel.isSelected(flavor)
        Button {
            CMHaptic.light()
            rippleTrigger += 1
            withAnimation(.cmSpring) { viewModel.toggleFlavor(flavor) }
        } label: {
            Text(flavor.displayName)
                .font(.caption).lineLimit(1)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                        .fill(isSelected ? systemConfig.designTitle.opacity(0.25) : CMTheme.chipBG)
                )
                .foregroundStyle(isSelected ? systemConfig.designTitle : CMTheme.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                        .stroke(isSelected ? systemConfig.designTitle.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .modifier(WaterRippleModifier(trigger: rippleTrigger, color: systemConfig.designTitle))
                .animation(.cmSpring, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
