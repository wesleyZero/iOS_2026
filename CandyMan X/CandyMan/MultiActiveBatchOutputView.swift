//
//  MultiActiveBatchOutputView.swift
//  CandyMan
//
//  Per-tray output display for multi-active batches.
//
//  Shows combined gelatin/sugar totals for the entire batch,
//  then a tray picker to view each tray's activation mix and
//  active substance details individually.
//
//  Includes per-tray Activate Batch and Additional Active Water
//  buttons, with per-tray redaction (values hidden until activated).
//

import SwiftUI

struct MultiActiveBatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showAdditionalWaterPopup = false
    @State private var showEspadaToast = false

    private var trayActivated: Bool { viewModel.batchActivated }

    var body: some View {
        // trayConfigs are saved by the Calculate button before entering post-calculate mode
        let result = BatchCalculator.calculateMultiActive(
            viewModel: viewModel,
            systemConfig: systemConfig
        )

        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Multi-Active Batch Output")
                    .font(.headline)
                    .foregroundStyle(systemConfig.designTitle)
                Spacer()
                Text(String(format: "%.1f mL", result.vMix))
                    .font(.subheadline)
                    .foregroundStyle(CMTheme.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // Combined Gelatin Mix (always visible — shared across trays)
            combinedMixSection(result.combinedGelatinMix)
            spacerLine

            // Combined Sugar Mix (always visible — shared across trays)
            let overagePercent = systemConfig.sugarMixtureOveragePercent
            overageMixSection(result.combinedSugarMix, overagePercent: overagePercent)
            spacerLine

            // Tray Picker
            trayPickerSection(trayCount: result.perTrayResults.count)

            let clampedIndex = min(viewModel.selectedTrayIndex, result.perTrayResults.count - 1)
            if clampedIndex >= 0, clampedIndex < result.perTrayResults.count {
                let perTray = result.perTrayResults[clampedIndex]

                spacerLine

                // Per-tray activation mix (redacted until activated)
                activationMixSection(perTray.activationMix, trayLabel: "Tray \(clampedIndex + 1)")
                spacerLine

                // Per-tray actives (redacted until activated)
                activesSection(config: perTray.trayConfig, vMixPerTray: perTray.vMixPerTray)
                spacerLine

                // Per-tray additional water + activate button
                if !trayActivated {
                    additionalWaterSection
                    activateBatchButton(trayLabel: "Tray \(clampedIndex + 1)")
                } else {
                    additionalWaterSection
                }
            }

            Spacer().frame(height: 8)
        }
        .overlay {
            if showAdditionalWaterPopup {
                MultiActiveAdditionalWaterPopup {
                    withAnimation(.cmSpring) { showAdditionalWaterPopup = false }
                }
                .environment(viewModel)
                .environment(systemConfig)
                .transition(.opacity)
            }
        }
        .overlay {
            if showEspadaToast {
                GeometryReader { geo in
                    PsychedelicAlert1(text: "ESPADAAAA")
                        .frame(maxWidth: .infinity)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.3)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .allowsHitTesting(false)
            }
        }
        .animation(.cmSpring, value: showAdditionalWaterPopup)
        .animation(.cmSpring, value: trayActivated)
        .animation(.cmSpring, value: showEspadaToast)
    }

    // MARK: - Tray Picker

    private func trayPickerSection(trayCount: Int) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Per-Tray Details")
                    .cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()

            Picker("Tray", selection: Binding(
                get: { viewModel.selectedTrayIndex },
                set: { newIndex in
                    guard newIndex != viewModel.selectedTrayIndex else { return }
                    viewModel.loadTrayConfig(newIndex)
                }
            )) {
                ForEach(0..<trayCount, id: \.self) { i in
                    Text("Tray \(i + 1)").tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Combined Mix Section

    private func combinedMixSection(_ mix: MixGroup) -> some View {
        let totalMass = mix.components.reduce(0) { $0 + $1.massGrams }

        return VStack(spacing: 0) {
            HStack {
                Text(mix.name)
                    .cmSubsectionTitle()
                Spacer()
                Text("Combined")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
            }
            .cmSubsectionPadding()
            ForEach(mix.components) { comp in
                if trayActivated {
                    componentRow(comp)
                } else {
                    redactedComponentRow(comp)
                }
            }
            // Total row
            HStack(spacing: 6) {
                Text("Total").cmTotalLabel()
                Spacer()
                if trayActivated {
                    Text(String(format: "%.3f", totalMass))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("██████")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary.opacity(0.4))
                }
                Text("g")
                    .cmMono11()
                    .foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 28, alignment: .leading)
            }
            .cmDataRowPadding()
            .padding(.vertical, 2)
            .background(CMTheme.totalRowBG)
        }
    }

    // MARK: - Overage Mix Section

    private func overageMixSection(_ mix: MixGroup, overagePercent: Double) -> some View {
        let factor = 1.0 + overagePercent / 100.0
        let fuchsiaFlare = systemConfig.designPrimaryAccent
        let totalMass = mix.components.reduce(0) { $0 + $1.massGrams }

        return VStack(spacing: 0) {
            HStack {
                Text(mix.name)
                    .cmSubsectionTitle()
                Spacer()
                if overagePercent > 0 {
                    Text(String(format: "+%.0f%%", overagePercent))
                        .cmMono10().fontWeight(.semibold)
                        .foregroundStyle(fuchsiaFlare.opacity(0.7))
                }
                Text("Combined")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
            }
            .cmSubsectionPadding()

            ForEach(mix.components) { comp in
                if trayActivated {
                    HStack(spacing: 6) {
                        Text(comp.label).cmRowLabel()
                        Spacer()
                        if overagePercent > 0 {
                            Text(String(format: "%.3f", comp.massGrams * factor))
                                .cmValueSlot(width: 60, color: fuchsiaFlare)
                        }
                        Text(String(format: "%.3f", comp.massGrams))
                            .cmValueSlot()
                        Text(comp.displayUnit).cmUnitSlot()
                    }
                    .cmDataRowPadding()
                } else {
                    redactedComponentRow(comp)
                }
            }
            // Total row
            HStack(spacing: 6) {
                Text("Total").cmTotalLabel()
                Spacer()
                if trayActivated {
                    if overagePercent > 0 {
                        Text(String(format: "%.3f", totalMass * factor))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(fuchsiaFlare)
                            .frame(width: 60, alignment: .trailing)
                    }
                    Text(String(format: "%.3f", totalMass))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("██████")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary.opacity(0.4))
                }
                Text("g")
                    .cmMono11()
                    .foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 28, alignment: .leading)
            }
            .cmDataRowPadding()
            .padding(.vertical, 2)
            .background(CMTheme.totalRowBG)
        }
    }

    // MARK: - Per-Tray Activation Mix

    private func activationMixSection(_ mix: MixGroup, trayLabel: String) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        return VStack(spacing: 0) {
            HStack {
                Text("\(trayLabel) Activation Mix")
                    .cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()

            ForEach(orderedCategories, id: \.rawValue) { category in
                let items = mix.components.filter { $0.activationCategory == category }
                if !items.isEmpty {
                    if category != .preservative {
                        HStack {
                            Text(category.rawValue)
                                .cmFootnote().fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                    }
                    ForEach(items) { comp in
                        if trayActivated {
                            componentRow(comp)
                        } else {
                            redactedComponentRow(comp)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Per-Tray Actives

    private func activesSection(config: TrayConfig, vMixPerTray: Double) -> some View {
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let gummiesPerTray = spec.count
        let totalActive = config.activeConcentration * Double(gummiesPerTray)
        let unitLabel = config.units.rawValue

        return VStack(spacing: 0) {
            HStack {
                Text("Active")
                    .cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()

            if trayActivated {
                if config.selectedActive == .lsd {
                    let ugPerTab = config.lsdUgPerTab
                    HStack(spacing: 6) {
                        Text(String(format: "LSD (%.0f µg / tab)", ugPerTab))
                            .cmRowLabel()
                        Spacer()
                        Text(String(format: "%.1f", totalActive)).cmValueSlot()
                        Text(unitLabel).cmUnitSlot()
                    }
                    .cmDataRowPadding()

                    if ugPerTab > 0 {
                        let tabsNeeded = Int(totalActive / ugPerTab)
                        let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)
                        HStack(spacing: 6) {
                            Text("Tabs Needed").cmRowLabel()
                            Spacer()
                            Text("\(tabsNeeded)").cmValueSlot()
                            Text("tabs").cmUnitSlot()
                        }
                        .cmDataRowPadding()

                        if lsdInLiquid > 0 {
                            HStack(spacing: 6) {
                                Text("LSD in Liquid").cmRowLabel()
                                Spacer()
                                Text(String(format: "%.1f", lsdInLiquid)).cmValueSlot()
                                Text(unitLabel).cmUnitSlot()
                            }
                            .cmDataRowPadding()
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(config.selectedActive.rawValue).cmRowLabel()
                        Spacer()
                        Text(String(format: "%.1f", totalActive)).cmValueSlot()
                        Text(unitLabel).cmUnitSlot()
                    }
                    .cmDataRowPadding()

                    HStack(spacing: 6) {
                        Text("Per Gummy").cmRowLabel()
                        Spacer()
                        Text(String(format: "%.1f", config.activeConcentration)).cmValueSlot()
                        Text(unitLabel).cmUnitSlot()
                    }
                    .cmDataRowPadding()
                }
            } else {
                // Redacted
                HStack(spacing: 6) {
                    Text(config.selectedActive.rawValue).cmRowLabel()
                    Spacer()
                    Text("██████")
                        .cmValueSlot(color: CMTheme.textTertiary.opacity(0.4))
                    Text(unitLabel).cmUnitSlot()
                }
                .cmDataRowPadding()
            }
        }
    }

    // MARK: - Additional Water Section

    @ViewBuilder
    private var additionalWaterSection: some View {
        if trayActivated {
            // Static text row (post-activation)
            HStack(spacing: 6) {
                Text("Additional Water for Dissolving Active")
                    .cmRowLabel().lineLimit(2)
                Spacer()
                Text(String(format: "%.1f", viewModel.additionalActiveWaterML))
                    .cmValueSlot(color: systemConfig.designAlert)
                Text("mL").cmUnitSlot()
            }
            .padding(.horizontal, 20).padding(.vertical, 4)
        } else {
            // Psychedelic button (pre-activation)
            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { showAdditionalWaterPopup = true }
            } label: {
                HStack(spacing: 6) {
                    Label("Additional Water for Dissolving Active", systemImage: "drop.fill")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    if viewModel.additionalActiveWaterML > 0 {
                        Text(String(format: "%.1f mL", viewModel.additionalActiveWaterML))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(systemConfig.designAlert)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                            .fill(CMTheme.chipBG)
                        PsychedelicButton2()
                    }
                )
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 4)
        }
    }

    // MARK: - Activate Batch Button

    private func activateBatchButton(trayLabel: String) -> some View {
        Button {
            CMHaptic.heavy()
            withAnimation(.cmSpring) {
                viewModel.batchActivated = true
                // Sync per-tray activation state
                if viewModel.trayActivationStates.indices.contains(viewModel.selectedTrayIndex) {
                    viewModel.trayActivationStates[viewModel.selectedTrayIndex].activated = true
                }
                if sizeClass == .regular {
                    viewModel.showEspadaToast = true
                } else {
                    showEspadaToast = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showEspadaToast = false
                    viewModel.showEspadaToast = false
                }
            }
        } label: {
            Label("Activate \(trayLabel)", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.3), radius: 2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                            .fill(CMTheme.chipBG)
                        PsychedelicButton2()
                    }
                )
        }
        .buttonStyle(CMPressStyle())
        .padding(.horizontal, 16).padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func componentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        let valueColor: Color = CMTheme.textSecondary

        return HStack(spacing: 6) {
            if let color = colorMatch {
                Circle().fill(color.swiftUIColor).frame(width: 10, height: 10)
            }
            Text(comp.label).cmRowLabel()
            Spacer()
            if comp.displayUnit == "µL" {
                Text(String(format: "%.0f", comp.volumeML * 1000.0))
                    .cmValueSlot(color: valueColor)
            } else if comp.displayUnit == "g" {
                Text(String(format: "%.3f", comp.massGrams))
                    .cmValueSlot(color: valueColor)
            } else {
                Text(String(format: "%.3f", comp.volumeML))
                    .cmValueSlot(color: valueColor)
            }
            Text(comp.displayUnit).cmUnitSlot()
        }.cmDataRowPadding()
    }

    private func redactedComponentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        return HStack(spacing: 6) {
            if let color = colorMatch {
                Circle().fill(color.swiftUIColor).frame(width: 10, height: 10)
            }
            Text(comp.label).cmRowLabel()
            Spacer()
            Text("██████")
                .cmValueSlot(color: CMTheme.textTertiary.opacity(0.4))
            Text(comp.displayUnit).cmUnitSlot()
        }.cmDataRowPadding()
    }

    private var spacerLine: some View {
        Divider()
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}

// MARK: - Multi-Active Additional Water Popup

struct MultiActiveAdditionalWaterPopup: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    let onDismiss: () -> Void

    @State private var editingValue: Double = 0.0

    private var strawberryRed: Color { systemConfig.designAlert }

    var body: some View {
        @Bindable var viewModel = viewModel

        CMPopupShell(
            title: "Additional Water",
            titleColor: strawberryRed,
            onDismiss: onDismiss
        ) {
            VStack(spacing: 12) {
                Text("How much additional water for dissolving active?")
                    .cmMono11()
                    .foregroundStyle(CMTheme.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    NumericField(value: $editingValue, decimals: 1)
                        .multilineTextAlignment(.center)
                        .cmMono12()
                        .foregroundStyle(strawberryRed)
                        .frame(width: 80)
                        .cmFieldStyle()

                    Text("mL")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 16)

            ThemedDivider()

            // OK button
            Button {
                CMHaptic.medium()
                viewModel.additionalActiveWaterML = editingValue
                // Sync per-tray activation state
                if viewModel.trayActivationStates.indices.contains(viewModel.selectedTrayIndex) {
                    viewModel.trayActivationStates[viewModel.selectedTrayIndex].additionalActiveWaterML = editingValue
                }
                onDismiss()
            } label: {
                Text("OK")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                                .fill(CMTheme.chipBG)
                            PsychedelicButton2()
                        }
                    )
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .onAppear {
            editingValue = viewModel.additionalActiveWaterML
        }
    }
}
