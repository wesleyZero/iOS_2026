//
//  ColorPickerView.swift
//  CandyMan
//
//  Color selection UI.
//
//  Two-phase pattern matching the flavor pickers:
//    1. Picking — a circle grid where the user toggles colors on/off
//    2. Blending — sliders for adjusting blend ratios (0–100%)
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ColorPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var colorUseMass = false
    @State private var colorFieldFocused = false
    /// Maximum percentage any single color slider can reach — user-adjustable via wheel picker.
    @State private var maxSliderPercent: Double = 100
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 8) {
            sectionHeader

            if viewModel.colorsLocked {
                blendView(viewModel: viewModel)
            } else {
                pickingView(viewModel: viewModel)
            }
        }

    }

    // MARK: - Header

    private var colorsChanged: Bool {
        !viewModel.selectedColors.isEmpty
        || viewModel.colorsLocked
        || viewModel.colorCompositionLocked
        || viewModel.colorVolumePercent != 0.664
    }

    private var sectionHeader: some View {
        HStack {
            Text("Colors").font(.headline).foregroundStyle(systemConfig.designTitle)
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) {
                    viewModel.selectedColors = [:]
                    viewModel.colorsLocked = false
                    viewModel.colorCompositionLocked = false
                    viewModel.colorVolumePercent = 0.664
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(CMTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(colorsChanged ? 1 : 0)
            .disabled(!colorsChanged)
            Spacer()
            HStack(spacing: 3) {
                Text("\(viewModel.selectedColors.count)")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(viewModel.selectedColors.count > 0 ? systemConfig.designAlert : CMTheme.textTertiary)
                if viewModel.selectedColors.count > 0 {
                    Text(viewModel.selectedColors.count == 1 ? "Color" : "Colors")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Picking State

    private func pickingView(viewModel: BatchConfigViewModel) -> some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(GummyColor.allCases) { color in
                    colorCircle(color: color, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)

            if !viewModel.selectedColors.isEmpty {
                Button {
                    CMHaptic.medium()
                    maxSliderPercent = 100
                    withAnimation(.cmSpring) { viewModel.lockColors() }
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

    // MARK: - Color Circle Button

    @ViewBuilder
    private func colorCircle(color: GummyColor, viewModel: BatchConfigViewModel) -> some View {
        let isSelected = viewModel.isColorSelected(color)
        Button {
            CMHaptic.light()
            withAnimation(.cmSpring) { viewModel.toggleColor(color) }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(color.swiftUIColor.opacity(isSelected ? 1.0 : 0.6)).frame(width: 52, height: 52)
                    Circle().stroke(isSelected ? CMTheme.selectionRing : Color.clear, lineWidth: 2.5)
                        .frame(width: 58, height: 58)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(color.rawValue).font(.caption).foregroundStyle(CMTheme.textPrimary)
            }
            .animation(.cmSpring, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Blend Ratio State

    private func blendView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel

        let sortedColors = Array(viewModel.selectedColors.keys).sorted { $0.rawValue < $1.rawValue }
        let colorTotal   = viewModel.colorBlendTotal
        let rhoMix = systemConfig.estimatedFinalMixDensity
        let rhoColor = systemConfig.densityFoodColoring

        // Mass % binding: mass% = vol% × (ρ_coloring / ρ_mix)
        let massBinding = Binding<Double>(
            get: {
                guard rhoMix > 0 else { return 0 }
                return viewModel.colorVolumePercent * rhoColor / rhoMix
            },
            set: { newMassPct in
                guard rhoMix > 0, rhoColor > 0 else { return }
                viewModel.colorVolumePercent = newMassPct * rhoMix / rhoColor
            }
        )

        // Minimum picker value = smallest multiple of 5 where count × max ≥ 100
        let minPickerValue = Int(ceil(100.0 / Double(sortedColors.count) / 5.0)) * 5
        let maxPickerValues = stride(from: minPickerValue, through: 100, by: 5).map { $0 }

        return VStack(spacing: 0) {

            HStack(alignment: .firstTextBaseline) {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { colorUseMass.toggle() }
                } label: {
                    Image(systemName: colorUseMass ? "lightswitch.on" : "lightswitch.off")
                        .font(.system(size: 20))
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    NumericField(value: colorUseMass ? massBinding : $viewModel.colorVolumePercent, decimals: 3, isFocusedBinding: $colorFieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).skittleSwirlWide(isPaused: colorFieldFocused).fixedSize()
                    Text(colorUseMass ? "% mass" : "% volume").font(.system(size: 20)).foregroundStyle(CMTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            // ── SLIDERS ───────────────────────────────
            ForEach(sortedColors, id: \.id) { color in
                let currentValue = viewModel.selectedColors[color] ?? 0
                VStack(spacing: 4) {
                    HStack {
                        Circle().fill(color.swiftUIColor).frame(width: 14, height: 14)
                        Text(color.rawValue).font(.subheadline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text("\(Int(maxSliderPercent))%")
                            .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                    }
                    WeightedSlider(
                        value: Binding(
                            get: { viewModel.selectedColors[color] ?? 0 },
                            set: { newValue in
                                let oldValue = viewModel.selectedColors[color] ?? 0
                                let othersTotal = sortedColors.filter { $0 != color }
                                    .reduce(0.0) { $0 + (viewModel.selectedColors[$1] ?? 0) }
                                let clamped = min(newValue, 100.0 - othersTotal)
                                viewModel.selectedColors[color] = max(clamped, 0)
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

            // ── BLEND PROGRESS BAR — with optional max-cap wheel picker for ≥ 3 colors ──
            HStack(spacing: 8) {
                PsychedelicProgressBar(progress: colorTotal)

                if sortedColors.count >= 3 {
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

            // ── RE-PICK ───────────────────────────────
            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.unlockColors() }
            } label: {
                Label("Re-pick Colors", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }
}
