//
//  ColorPickerView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI

struct ColorPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel

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

    private var sectionHeader: some View {
        HStack {
            Text("Colors").font(.headline)
            Spacer()
            Text("\(viewModel.selectedColors.count) selected")
                .font(.subheadline).foregroundStyle(.secondary)
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
                    viewModel.lockColors()
                } label: {
                    Label("Set Blend Ratios", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            }
        }
    }

    // MARK: - Color Circle Button

    @ViewBuilder
    private func colorCircle(color: GummyColor, viewModel: BatchConfigViewModel) -> some View {
        let isSelected = viewModel.isColorSelected(color)
        Button {
            viewModel.toggleColor(color)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(color.swiftUIColor).frame(width: 52, height: 52)
                    Circle().stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2.5)
                        .frame(width: 58, height: 58)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Text(color.rawValue).font(.caption).foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Blend Ratio State

    private func blendView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel

        let sortedColors = Array(viewModel.selectedColors.keys).sorted { $0.rawValue < $1.rawValue }
        let colorTotal   = viewModel.colorBlendTotal

        return VStack(spacing: 0) {

            // ── COLOR VOLUME ──────────────────────────
            HStack {
                Text("Color Volume").font(.headline)
                Spacer()
                Text("%").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.top, 12)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0.0", value: $viewModel.colorVolumePercent,
                          format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .bold)).fixedSize()
                Text("%").font(.system(size: 20)).foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)

            // ── SLIDERS ───────────────────────────────
            ForEach(sortedColors, id: \.id) { color in
                VStack(spacing: 4) {
                    HStack {
                        Circle().fill(color.swiftUIColor).frame(width: 14, height: 14)
                        Text(color.rawValue).font(.subheadline)
                        Spacer()
                        Text("\(viewModel.selectedColors[color] ?? 0, specifier: "%.0f")%")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { viewModel.selectedColors[color] ?? 0 },
                            set: { viewModel.selectedColors[color] = $0 }
                        ),
                        in: 0...100, step: 5
                    ).tint(color.swiftUIColor)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            // ── BLEND TOTAL ───────────────────────────
            HStack {
                Text("Color blend").font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(colorTotal, specifier: "%.0f")%")
                    .fontWeight(.semibold)
                    .foregroundStyle(abs(colorTotal - 100) < 0.5 ? .green : .red)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider().padding(.horizontal, 16)

            // ── RE-PICK ───────────────────────────────
            Button {
                viewModel.unlockColors()
            } label: {
                Label("Re-pick Colors", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }
}
