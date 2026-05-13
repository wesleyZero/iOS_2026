//
//  TerpenePickerView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI

struct TerpenePickerView: View {
    @Environment(CartConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    private var cannabisTerps: [TerpeneSelection] {
        CannabisTerpene.allCases.map { .cannabis($0) }
    }

    private var flavorTerps: [TerpeneSelection] {
        FlavorTerpene.allCases.map { .flavor($0) }
    }

    private var selectedCannabis: [(TerpeneSelection, Double)] {
        viewModel.selectedTerpenes
            .filter { if case .cannabis = $0.key { return true }; return false }
            .sorted { $0.key.id < $1.key.id }
    }

    private var selectedFlavors: [(TerpeneSelection, Double)] {
        viewModel.selectedTerpenes
            .filter { if case .flavor = $0.key { return true }; return false }
            .sorted { $0.key.id < $1.key.id }
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Terpene Blend")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                if !viewModel.selectedTerpenes.isEmpty {
                    Text("\(viewModel.selectedTerpenes.count) selected")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Source tabs
            Picker("Source", selection: $viewModel.terpeneSourceTab) {
                ForEach(TerpeneSourceType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .disabled(viewModel.terpenesLocked)

            // Chip grid
            if !viewModel.terpenesLocked {
                let items = viewModel.terpeneSourceTab == .cannabis ? cannabisTerps : flavorTerps
                let columns = [GridItem(.adaptive(minimum: 130))]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items) { terp in
                        terpChip(terp)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if !viewModel.selectedTerpenes.isEmpty {
                    Button {
                        CMHaptic.medium()
                        withAnimation(.cmSpring) { viewModel.lockTerpenes() }
                    } label: {
                        Label("Lock Selection", systemImage: "lock")
                            .modifier(CMButtonStyle(color: systemConfig.accent, isDisabled: false))
                    }
                    .buttonStyle(CMPressStyle())
                    .padding(.horizontal, 16)
                }
            } else if !viewModel.terpeneCompositionLocked {
                // Blend sliders
                VStack(spacing: 0) {
                    if !selectedCannabis.isEmpty {
                        blendSection(title: "Cannabis Terpenes", items: selectedCannabis)
                    }
                    if !selectedFlavors.isEmpty {
                        blendSection(title: "Flavor Terpenes", items: selectedFlavors)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { viewModel.unlockTerpenes() }
                    } label: {
                        Label("Unlock", systemImage: "lock.open")
                            .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                            .foregroundStyle(CMTheme.textPrimary)
                    }
                    .buttonStyle(CMPressStyle())

                    let canLock = canLockComposition
                    Button {
                        CMHaptic.medium()
                        withAnimation(.cmSpring) { viewModel.lockComposition() }
                    } label: {
                        Label("Lock Blend", systemImage: "checkmark.seal")
                            .modifier(CMButtonStyle(color: systemConfig.accent, isDisabled: !canLock))
                    }
                    .buttonStyle(CMPressStyle())
                    .disabled(!canLock)
                }
                .padding(.horizontal, 16)
            } else {
                // Locked summary
                VStack(spacing: 4) {
                    ForEach(Array(viewModel.selectedTerpenes.sorted { $0.key.id < $1.key.id }), id: \.key) { terp, pct in
                        HStack {
                            Text(terp.displayName)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(CMTheme.textPrimary)
                            Spacer()
                            Text(String(format: "%.0f%%", pct))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(CMTheme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                    }

                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { viewModel.unlockComposition() }
                    } label: {
                        Label("Edit Blend", systemImage: "slider.horizontal.3")
                            .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                            .foregroundStyle(CMTheme.textPrimary)
                    }
                    .buttonStyle(CMPressStyle())
                    .padding(.horizontal, 16)
                }
            }

            Spacer().frame(height: 8)
        }
    }

    private var canLockComposition: Bool {
        let cannabisTotal = selectedCannabis.reduce(0.0) { $0 + $1.1 }
        let flavorTotal = selectedFlavors.reduce(0.0) { $0 + $1.1 }
        let cannabisOK = selectedCannabis.isEmpty || abs(cannabisTotal - 100) < 0.5
        let flavorsOK = selectedFlavors.isEmpty || abs(flavorTotal - 100) < 0.5
        return cannabisOK && flavorsOK
    }

    private func blendSection(title: String, items: [(TerpeneSelection, Double)]) -> some View {
        @Bindable var viewModel = viewModel
        let total = items.reduce(0.0) { $0 + $1.1 }
        return VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", total))
                    .font(.caption)
                    .foregroundStyle(abs(total - 100) < 0.5 ? CMTheme.success : CMTheme.danger)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ForEach(items, id: \.0) { terp, pct in
                HStack {
                    Text(terp.displayName)
                        .font(.system(size: 13))
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(width: 120, alignment: .leading)

                    Slider(value: Binding(
                        get: { viewModel.selectedTerpenes[terp] ?? 0 },
                        set: { newVal in
                            let rounded = (newVal / 5).rounded() * 5
                            let old = viewModel.selectedTerpenes[terp] ?? 0
                            viewModel.selectedTerpenes[terp] = rounded
                            if systemConfig.sliderVibrationsEnabled && rounded != old {
                                CMHaptic.selection()
                            }
                        }
                    ), in: 0...100, step: 5)
                    .tint(systemConfig.accent)

                    Text(String(format: "%.0f%%", viewModel.selectedTerpenes[terp] ?? 0))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func terpChip(_ terp: TerpeneSelection) -> some View {
        let sel = viewModel.isSelected(terp)
        return Button {
            CMHaptic.light()
            withAnimation(.cmSpring) { viewModel.toggleTerpene(terp) }
        } label: {
            Text(terp.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(sel ? systemConfig.accent : CMTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                        .fill(sel ? systemConfig.accent.opacity(0.12) : CMTheme.chipBG)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                        .stroke(sel ? systemConfig.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
