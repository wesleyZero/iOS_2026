//
//  MultiActiveBatchOutputView.swift
//  CandyMan
//
//  Output display for multi-active batches.
//
//  MultiActiveBatchOutputView shows combined gelatin/sugar totals.
//  MultiActiveTrayOutputView shows per-tray activation details.
//

import SwiftUI

struct MultiActiveBatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        let result = BatchCalculator.calculateMultiActive(
            viewModel: viewModel,
            systemConfig: systemConfig
        )

        VStack(spacing: 0) {
            HStack {
                Text("Bulk Output")
                    .font(.headline)
                    .foregroundStyle(systemConfig.designTitle)
                Spacer()
                Text(String(format: "%.1f mL", result.vMix))
                    .font(.subheadline)
                    .foregroundStyle(CMTheme.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            let gelatinOveragePercent = systemConfig.gelatinMixtureOveragePercent
            overageMixSection(result.combinedGelatinMix, overagePercent: gelatinOveragePercent)
            spacerLine

            let sugarOveragePercent = systemConfig.sugarMixtureOveragePercent
            overageMixSection(result.combinedSugarMix, overagePercent: sugarOveragePercent)
            spacerLine

            preservativesSection(result.perTrayResults)

            Spacer().frame(height: 8)
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
            }
            // Total row
            HStack(spacing: 6) {
                Text("Total").cmTotalLabel()
                Spacer()
                if overagePercent > 0 {
                    Text(String(format: "%.3f", totalMass * factor))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(fuchsiaFlare)
                        .frame(width: 60, alignment: .trailing)
                }
                Text(String(format: "%.3f", totalMass))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .frame(width: 70, alignment: .trailing)
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

    // MARK: - Preservatives Section

    private func preservativesSection(_ perTrayResults: [MultiActiveBatchResult.PerTrayResult]) -> some View {
        let citricRatio = systemConfig.citricAcidSolutionRatio
        let sorbateRatio = systemConfig.kSorbateSolutionRatio

        var totalCitricMass = 0.0
        var totalSorbateMass = 0.0
        for tray in perTrayResults {
            if let comp = tray.activationMix.components.first(where: { $0.label == "Citric Acid" }) {
                totalCitricMass += comp.massGrams
            }
            if let comp = tray.activationMix.components.first(where: { $0.label == "Potassium Sorbate" }) {
                totalSorbateMass += comp.massGrams
            }
        }

        return VStack(spacing: 0) {
            HStack { Text("Preservatives").cmSubsectionTitle(); Spacer() }
                .cmSubsectionPadding()

            HStack(spacing: 6) {
                Text(String(format: "+ Citric Acid 1:%.0f", citricRatio)).cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", totalCitricMass * (1.0 + citricRatio))).cmValueSlot()
                Text("g").cmUnitSlot()
            }.cmDataRowPadding()

            HStack(spacing: 6) {
                Text(String(format: "+ KSorbate 1:%.0f", sorbateRatio)).cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", totalSorbateMass * (1.0 + sorbateRatio))).cmValueSlot()
                Text("g").cmUnitSlot()
            }.cmDataRowPadding()
        }
    }

    // MARK: - Helpers

    private var spacerLine: some View {
        Divider()
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}

// MARK: - Tray Output (per-tray details)

struct MultiActiveTrayOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showEspadaToast = false

    var body: some View {
        let result = BatchCalculator.calculateMultiActive(
            viewModel: viewModel,
            systemConfig: systemConfig
        )

        VStack(spacing: 0) {
            HStack {
                Text("Tray Output")
                    .font(.headline)
                    .foregroundStyle(systemConfig.designTitle)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            trayPickerSection(trayCount: result.perTrayResults.count)

            let clampedIndex = min(viewModel.selectedTrayIndex, result.perTrayResults.count - 1)
            if clampedIndex >= 0, clampedIndex < result.perTrayResults.count {
                let perTray = result.perTrayResults[clampedIndex]

                spacerLine

                perTrayPreservativesSection(perTray.activationMix, trayLabel: "Tray \(clampedIndex + 1)")
                spacerLine

                activationMixSection(perTray.activationMix, trayLabel: "Tray \(clampedIndex + 1)")
                spacerLine

                perTrayMixturesSection(gelatinMix: perTray.gelatinMix, sugarMix: perTray.sugarMix)
                spacerLine

                activesSection(config: perTray.trayConfig, vMixPerTray: perTray.vMixPerTray, activationMix: perTray.activationMix)
                spacerLine

                if !viewModel.batchActivated {
                    activateBatchButton(trayLabel: "Tray \(clampedIndex + 1)")
                    Text("Add the activation water before calculating the batch")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }
            }

            Spacer().frame(height: 8)
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
        .animation(.cmSpring, value: viewModel.batchActivated)
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

    // MARK: - Per-Tray Preservatives

    private func perTrayPreservativesSection(_ mix: MixGroup, trayLabel: String) -> some View {
        let citricRatio = systemConfig.citricAcidSolutionRatio
        let sorbateRatio = systemConfig.kSorbateSolutionRatio

        let citricMass = mix.components.first(where: { $0.label == "Citric Acid" })?.massGrams ?? 0.0
        let sorbateMass = mix.components.first(where: { $0.label == "Potassium Sorbate" })?.massGrams ?? 0.0

        return VStack(spacing: 0) {
            HStack { Text("Preservatives").cmSubsectionTitle(); Spacer() }
                .cmSubsectionPadding()

            HStack(spacing: 6) {
                Text(String(format: "+ Citric Acid 1:%.0f", citricRatio)).cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", citricMass * (1.0 + citricRatio))).cmValueSlot()
                    .blur(radius: viewModel.batchActivated ? 0 : 3)
                Text("g").cmUnitSlot()
                    .blur(radius: viewModel.batchActivated ? 0 : 3)
            }.cmDataRowPadding()

            HStack(spacing: 6) {
                Text(String(format: "+ KSorbate 1:%.0f", sorbateRatio)).cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", sorbateMass * (1.0 + sorbateRatio))).cmValueSlot()
                    .blur(radius: viewModel.batchActivated ? 0 : 3)
                Text("g").cmUnitSlot()
                    .blur(radius: viewModel.batchActivated ? 0 : 3)
            }.cmDataRowPadding()
        }
    }

    // MARK: - Per-Tray Activation Mix

    private func activationMixSection(_ mix: MixGroup, trayLabel: String) -> some View {
        let hiddenLabels: Set<String> = ["Citric Acid", "Potassium Sorbate", "LSD Transfer Water"]
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        let visibleComponents = mix.components.filter { !hiddenLabels.contains($0.label) }
        return Group {
            if !visibleComponents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text("\(trayLabel) Activation Mix")
                            .cmSubsectionTitle()
                        Spacer()
                    }
                    .cmSubsectionPadding()

                    ForEach(orderedCategories, id: \.rawValue) { category in
                        let items = visibleComponents.filter { $0.activationCategory == category }
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
                                componentRow(comp)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Per-Tray Actives

    private func activesSection(config: TrayConfig, vMixPerTray: Double, activationMix: MixGroup) -> some View {
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let gummiesPerTray = spec.count
        let totalActive = config.activeConcentration * Double(gummiesPerTray)
        let unitLabel = config.units.rawValue
        let lsdTransferComp = activationMix.components.first { $0.label == "LSD Transfer Water" }
        let gold = systemConfig.designSecondaryAccent

        return VStack(spacing: 0) {
            HStack {
                Text("Active")
                    .cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()

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

                        if let comp = lsdTransferComp {
                            HStack(spacing: 6) {
                                Text(comp.label)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(gold.opacity(0.9))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                Spacer()
                                Text(String(format: "%.3f", comp.volumeML)).cmValueSlot()
                                Text("ml").cmUnitSlot()
                            }
                            .cmDataRowPadding()
                        }
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
        }
    }

    // MARK: - Activate Batch Button

    private func activateBatchButton(trayLabel: String) -> some View {
        Button {
            CMHaptic.heavy()
            withAnimation(.cmSpring) {
                viewModel.batchActivated = true
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
            Label("Calculate \(trayLabel)", systemImage: "bolt.fill")
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

    // MARK: - Per-Tray Mixtures

    private func perTrayMixturesSection(gelatinMix: MixGroup, sugarMix: MixGroup) -> some View {
        VStack(spacing: 0) {
            HStack { Text("Mixtures").cmSubsectionTitle(); Spacer() }
                .cmSubsectionPadding()

            HStack(spacing: 6) {
                Text("Gelatin Mix").cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", gelatinMix.totalMassGrams)).cmValueSlot()
                Text("g").cmUnitSlot()
            }.cmDataRowPadding()

            HStack(spacing: 6) {
                Text("Sugar Mix").cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", sugarMix.totalMassGrams)).cmValueSlot()
                    .blur(radius: viewModel.batchActivated ? 0 : 3)
                Text("g").cmUnitSlot()
                    .blur(radius: viewModel.batchActivated ? 0 : 3)
            }.cmDataRowPadding()
        }
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

    private var spacerLine: some View {
        Divider()
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}
