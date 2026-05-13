//
//  ColorPickerView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ColorPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

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
            Text("Colors").font(.headline).foregroundStyle(CMTheme.textPrimary)
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
            Text("\(viewModel.selectedColors.count)")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(viewModel.selectedColors.count > 0 ? Color(red: 0.929, green: 0.278, blue: 0.290) : CMTheme.textTertiary)
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
                    withAnimation(.cmSpring) { viewModel.lockColors() }
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
                    Circle().stroke(isSelected ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2.5)
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

        return VStack(spacing: 0) {

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0.0", value: $viewModel.colorVolumePercent,
                          format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(CMTheme.textPrimary).fixedSize().selectAllOnFocus()
            }
            .padding(.vertical, 8)

            // ── SLIDERS ───────────────────────────────
            ForEach(sortedColors, id: \.id) { color in
                VStack(spacing: 4) {
                    HStack {
                        Circle().fill(color.swiftUIColor).frame(width: 14, height: 14)
                        Text(color.rawValue).font(.subheadline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text("\(viewModel.selectedColors[color] ?? 0, specifier: "%.0f")%")
                            .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { viewModel.selectedColors[color] ?? 0 },
                            set: { newValue in
                                let oldValue = viewModel.selectedColors[color] ?? 0
                                viewModel.selectedColors[color] = newValue
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
                    .rainbowSlide(value: viewModel.selectedColors[color] ?? 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            // ── BLEND PROGRESS BAR ───────────────────
            PsychedelicProgressBar(progress: colorTotal)
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
