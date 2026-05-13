//
//  BatchOutputView.swift
//  CandyMan
//
//  Post-calculate view showing the calculated batch recipe.
//
//  Layout:
//    Gelatin Mix   – gelatin + water (with optional overage)
//    Sugar Mix     – sugar + water (with optional overage)
//    Activation Mix – preservative solutions, colors, oils, terpenes, additional water
//    Actives       – substance totals (LSD has tab-splitting math)
//
//  Also contains BatchOutputFullScreenView for iPad full-screen display.
//

import SwiftUI

// MARK: - BatchOutputView

struct BatchOutputView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showFullScreen = false
    private var batchActivated: Bool { viewModel.batchActivated }
    @State private var showEspadaToast = false

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        VStack(spacing: 0) {
            HStack {
                Text("Batch Output").font(.headline).foregroundStyle(systemConfig.designTitle)
                Spacer()
                if sizeClass == .regular {
                    Button {
                        CMHaptic.medium()
                        showFullScreen = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(CMTheme.chipBG)
                            )
                    }
                    .buttonStyle(CMPressStyle())
                }
                Text(String(format: "%.1f mL (+%.1f%%)", result.vMix, (viewModel.overageFactor - 1.0) * 100.0))
                    .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            overageMixSection(result.gelatinMix, overagePercent: systemConfig.gelatinMixtureOveragePercent)
            spacerLine
            overageMixSection(result.sugarMix, overagePercent: systemConfig.sugarMixtureOveragePercent)
            spacerLine
            preservativesSection(result.activationMix)
            spacerLine
            activationMixSection(result.activationMix)
            spacerLine
            activesSection(result.activationMix)
            spacerLine
            if !batchActivated {
                activateBatchButton
                Text("Add the activation mix before calculating the batch")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(CMTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }
            Spacer().frame(height: 8)
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            BatchOutputFullScreenView()
                .environment(systemConfig)
                .environment(viewModel)
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
        .animation(.cmSpring, value: batchActivated)
        .animation(.cmSpring, value: showEspadaToast)
    }

    private func mixSection(_ mix: MixGroup) -> some View {
        VStack(spacing: 0) {
            HStack { Text(mix.name).cmSubsectionTitle(); Spacer() }
                .cmSubsectionPadding()
            ForEach(mix.components) { comp in
                if batchActivated {
                    componentRow(comp)
                } else {
                    redactedComponentRow(comp)
                }
            }
        }
    }

    /// Renders a mix group with an optional overage percentage column and fine-print note.
    /// Used for both the gelatin and sugar mix sections, which share identical layout.
    private func overageMixSection(_ mix: MixGroup, overagePercent: Double) -> some View {
        let factor = 1.0 + overagePercent / 100.0
        let fuchsiaFlare = systemConfig.designPrimaryAccent

        return VStack(spacing: 0) {
            HStack {
                Text(mix.name).cmSubsectionTitle()
                Spacer()
                Text(String(format: "%.1f mL", mix.totalVolumeML * factor))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                if overagePercent > 0 {
                    Text(String(format: "+%.0f%%", overagePercent))
                        .cmMono10().fontWeight(.semibold)
                        .foregroundStyle(fuchsiaFlare.opacity(0.7))
                }
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
                    Text(String(format: "%.3f", comp.massGrams)).cmValueSlot()
                    Text(comp.displayUnit).cmUnitSlot()
                }
                .cmDataRowPadding()
            }

            if overagePercent > 0 {
                Group {
                    Text("\(mix.name) values include a ")
                        .foregroundStyle(CMTheme.textTertiary)
                    + Text(String(format: "%.0f%%", overagePercent))
                        .foregroundStyle(fuchsiaFlare)
                    + Text(" overage factor to account for mixture that will stick to the sides of the beaker.")
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .cmMono10()
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 2)
            }
        }
    }

    private func preservativesSection(_ activationMix: MixGroup) -> some View {
        let citricComp = activationMix.components.first { $0.label == "Citric Acid" }
        let sorbateComp = activationMix.components.first { $0.label == "Potassium Sorbate" }
        let citricRatio = systemConfig.citricAcidSolutionRatio
        let sorbateRatio = systemConfig.kSorbateSolutionRatio

        return VStack(spacing: 0) {
            HStack { Text("Preservatives").cmSubsectionTitle(); Spacer() }
                .cmSubsectionPadding()

            if let comp = citricComp {
                let solutionMass = comp.massGrams * (1.0 + citricRatio)
                HStack(spacing: 6) {
                    Text(String(format: "+ Citric Acid 1:%.0f", citricRatio)).cmRowLabel()
                    Spacer()
                    Text(String(format: "%.3f", solutionMass)).cmValueSlot()
                    Text("g").cmUnitSlot()
                }.cmDataRowPadding()
            }

            if let comp = sorbateComp {
                let solutionMass = comp.massGrams * (1.0 + sorbateRatio)
                HStack(spacing: 6) {
                    Text(String(format: "+ KSorbate 1:%.0f", sorbateRatio)).cmRowLabel()
                    Spacer()
                    Text(String(format: "%.3f", solutionMass)).cmValueSlot()
                    Text("g").cmUnitSlot()
                }.cmDataRowPadding()
            }
        }
    }

    private func activationMixSection(_ mix: MixGroup) -> some View {
        let hiddenLabels: Set<String> = ["Citric Acid", "Potassium Sorbate", "LSD Transfer Water"]
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        let visibleComponents = mix.components.filter { !hiddenLabels.contains($0.label) }
        return Group {
            if !visibleComponents.isEmpty {
                VStack(spacing: 0) {
                    HStack { Text(mix.name).cmSubsectionTitle(); Spacer() }
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
                            ForEach(items) { comp in componentRow(comp) }
                        }
                    }
                }
            }
        }
    }

    private func componentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        let strawberryRed = systemConfig.designAlert
        let gold = systemConfig.designSecondaryAccent

        let valueColor: Color = CMTheme.textSecondary
        let isAdditionalWater = comp.label == "Additional Water"
        let isLSDTransfer = comp.label == "LSD Transfer Water"

        return HStack(spacing: 6) {
            if let color = colorMatch {
                Circle().fill(color.swiftUIColor).frame(width: 10, height: 10)
            }
            if isAdditionalWater {
                Text(comp.label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(strawberryRed.opacity(0.8))
                    .lineLimit(1).minimumScaleFactor(0.7)
            } else if isLSDTransfer {
                Text(comp.label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(gold.opacity(0.9))
                    .lineLimit(1).minimumScaleFactor(0.7)
            } else {
                Text(comp.label).cmRowLabel()
            }
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

    private func activesSection(_ activationMix: MixGroup) -> some View {
        @Bindable var viewModel = viewModel
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue
        let gold = systemConfig.designSecondaryAccent
        let lsdTransferComp = activationMix.components.first { $0.label == "LSD Transfer Water" }

        return VStack(spacing: 0) {
            HStack {
                Text("Actives").cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()

            if viewModel.selectedActive == .lsd {
                let ugPerTab = viewModel.lsdUgPerTab
                HStack(spacing: 6) {
                    Text(String(format: "LSD (%.0f µg / tab)", ugPerTab))
                        .cmRowLabel()
                    Spacer()
                    Text(String(format: "%.1f", totalActive)).cmValueSlot()
                    Text(unitLabel).cmUnitSlot()
                }
                .cmDataRowPadding()

                ThemedDivider(indent: 20).padding(.vertical, 4)

                let tabsNeeded = Int(totalActive / ugPerTab)
                let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)

                HStack(spacing: 6) {
                    Text("Tabs").cmMono12().foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                    Spacer()
                    Text("\(tabsNeeded)").cmValueSlot()
                    Text("#").cmUnitSlot()
                }
                .cmDataRowPadding()

                HStack(spacing: 6) {
                    Text("LSD in Liquid").cmMono12().foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.1f", lsdInLiquid)).cmValueSlot(color: gold)
                    Text("µg").cmUnitSlot()
                }
                .cmDataRowPadding()

                if lsdInLiquid > 0, let comp = lsdTransferComp {
                    HStack(spacing: 6) {
                        Text(comp.label)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(gold.opacity(0.9))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Spacer()
                        Text(String(format: "%.3f", comp.volumeML)).cmValueSlot(color: gold)
                        Text("ml").cmUnitSlot()
                    }
                    .cmDataRowPadding()
                }

            } else {
                HStack(spacing: 6) {
                    Text(viewModel.selectedActive.rawValue)
                        .cmMono12().foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                    Spacer()
                    Text(String(format: "%.2f", totalActive)).cmValueSlot()
                    Text(unitLabel).cmUnitSlot()
                }
                .cmDataRowPadding()
            }
        }
    }

    private var activateBatchButton: some View {
        Button {
            CMHaptic.heavy()
            withAnimation(.cmSpring) {
                viewModel.batchActivated = true
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
            Label("Activate Batch", systemImage: "bolt.fill")
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

    private var spacerLine: some View {
        ThemedDivider(indent: 20).padding(.vertical, 8)
    }
}

// MARK: - Full Screen Batch Output (iPad)

struct BatchOutputFullScreenView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss

    // Scale factor: roughly 2.5x the normal 12pt text
    private let labelSize: CGFloat = 28
    private let valueSize: CGFloat = 28
    private let headerSize: CGFloat = 34
    private let subHeaderSize: CGFloat = 30
    private let categorySize: CGFloat = 24
    private let unitWidth: CGFloat = 60
    private let valueWidth: CGFloat = 150

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Batch Output")
                            .font(.system(size: headerSize, weight: .bold, design: .monospaced))
                            .foregroundStyle(systemConfig.designTitle)
                        Spacer()
                        Text(String(format: "%.1f mL (+%.1f%%)", result.vMix, (viewModel.overageFactor - 1.0) * 100.0))
                            .font(.system(size: subHeaderSize, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 32).padding(.vertical, 20)

                    fullOverageMixSection(result.gelatinMix, overagePercent: systemConfig.gelatinMixtureOveragePercent)
                    fullDivider
                    fullOverageMixSection(result.sugarMix, overagePercent: systemConfig.sugarMixtureOveragePercent)
                    fullDivider
                    fullPreservativesSection(result.activationMix)
                    fullDivider
                    fullActivationMixSection(result.activationMix)
                    fullDivider
                    fullActivesSection(result.activationMix)
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(CMTheme.pageBG)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private func fullMixSection(_ mix: MixGroup) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(mix.name)
                    .font(.system(size: subHeaderSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 8)
            ForEach(mix.components) { comp in fullComponentRow(comp) }
        }
    }

    /// Full-screen version of `overageMixSection` — identical layout but with larger fonts.
    private func fullOverageMixSection(_ mix: MixGroup, overagePercent: Double) -> some View {
        let factor = 1.0 + overagePercent / 100.0
        let fuchsiaFlare = systemConfig.designPrimaryAccent

        return VStack(spacing: 0) {
            HStack {
                Text(mix.name)
                    .font(.system(size: subHeaderSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Text(String(format: "%.1f mL", mix.totalVolumeML * factor))
                    .font(.system(size: categorySize, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                if overagePercent > 0 {
                    Text(String(format: "+%.0f%%", overagePercent))
                        .font(.system(size: categorySize, weight: .semibold, design: .monospaced))
                        .foregroundStyle(fuchsiaFlare.opacity(0.7))
                }
            }
            .padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 8)

            ForEach(mix.components) { comp in
                HStack(spacing: 10) {
                    Text(comp.label)
                        .font(.system(size: labelSize, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer()
                    if overagePercent > 0 {
                        Text(String(format: "%.3f", comp.massGrams * factor))
                            .font(.system(size: valueSize, weight: .medium, design: .monospaced))
                            .foregroundStyle(fuchsiaFlare)
                            .frame(width: valueWidth, alignment: .trailing)
                    }
                    Text(String(format: "%.3f", comp.massGrams))
                        .font(.system(size: valueSize, weight: .medium, design: .monospaced))
                        .foregroundStyle(CMTheme.textSecondary)
                        .frame(width: valueWidth, alignment: .trailing)
                    Text(comp.displayUnit)
                        .font(.system(size: labelSize, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                        .frame(width: unitWidth, alignment: .leading)
                }
                .padding(.horizontal, 40).padding(.vertical, 4)
            }
        }
    }

    private func fullPreservativesSection(_ activationMix: MixGroup) -> some View {
        let citricComp = activationMix.components.first { $0.label == "Citric Acid" }
        let sorbateComp = activationMix.components.first { $0.label == "Potassium Sorbate" }
        let citricRatio = systemConfig.citricAcidSolutionRatio
        let sorbateRatio = systemConfig.kSorbateSolutionRatio

        return VStack(spacing: 0) {
            HStack {
                Text("Preservatives")
                    .font(.system(size: subHeaderSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 8)

            if let comp = citricComp {
                let solutionMass = comp.massGrams * (1.0 + citricRatio)
                fullRow(String(format: "+ Citric Acid 1:%.0f", citricRatio),
                        value: String(format: "%.3f", solutionMass), unit: "g")
            }
            if let comp = sorbateComp {
                let solutionMass = comp.massGrams * (1.0 + sorbateRatio)
                fullRow(String(format: "+ KSorbate 1:%.0f", sorbateRatio),
                        value: String(format: "%.3f", solutionMass), unit: "g")
            }
        }
    }

    private func fullActivationMixSection(_ mix: MixGroup) -> some View {
        let hiddenLabels: Set<String> = ["Citric Acid", "Potassium Sorbate", "LSD Transfer Water"]
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        let visibleComponents = mix.components.filter { !hiddenLabels.contains($0.label) }
        return Group {
            if !visibleComponents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(mix.name)
                            .font(.system(size: subHeaderSize, weight: .semibold, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 8)

                    ForEach(orderedCategories, id: \.rawValue) { category in
                        let items = visibleComponents.filter { $0.activationCategory == category }
                        if !items.isEmpty {
                            if category != .preservative {
                                HStack {
                                    Text(category.rawValue)
                                        .font(.system(size: categorySize, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(CMTheme.textTertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, 40).padding(.top, 12).padding(.bottom, 4)
                            }
                            ForEach(items) { comp in fullComponentRow(comp) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Component Row

    private func fullComponentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        let valueColor: Color = CMTheme.textSecondary

        return HStack(spacing: 10) {
            if let color = colorMatch {
                Circle().fill(color.swiftUIColor).frame(width: 18, height: 18)
            }
            Text(comp.label)
                .font(.system(size: labelSize, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
            if comp.displayUnit == "µL" {
                Text(String(format: "%.0f", comp.volumeML * 1000.0))
                    .font(.system(size: valueSize, weight: .medium, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .frame(width: valueWidth, alignment: .trailing)
            } else if comp.displayUnit == "g" {
                Text(String(format: "%.3f", comp.massGrams))
                    .font(.system(size: valueSize, weight: .medium, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .frame(width: valueWidth, alignment: .trailing)
            } else {
                Text(String(format: "%.3f", comp.volumeML))
                    .font(.system(size: valueSize, weight: .medium, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .frame(width: valueWidth, alignment: .trailing)
            }
            Text(comp.displayUnit)
                .font(.system(size: labelSize, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: unitWidth, alignment: .leading)
        }
        .padding(.horizontal, 40).padding(.vertical, 4)
    }

    // MARK: - Actives Section

    private func fullActivesSection(_ activationMix: MixGroup) -> some View {
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue
        let gold = systemConfig.designSecondaryAccent
        let lsdTransferComp = activationMix.components.first { $0.label == "LSD Transfer Water" }

        return VStack(spacing: 0) {
            HStack {
                Text("Actives")
                    .font(.system(size: subHeaderSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 8)

            if viewModel.selectedActive == .lsd {
                let ugPerTab = viewModel.lsdUgPerTab
                fullRow(String(format: "LSD (%.0f µg / tab)", ugPerTab),
                        value: String(format: "%.1f", totalActive), unit: unitLabel)

                fullDivider

                let tabsNeeded = Int(totalActive / ugPerTab)
                let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)

                fullRow("Tabs", value: "\(tabsNeeded)", unit: "#")
                fullRow("LSD in Liquid", value: String(format: "%.1f", lsdInLiquid), unit: "µg", valueColor: gold)
                if lsdInLiquid > 0, let comp = lsdTransferComp {
                    fullRow("LSD Transfer Water", value: String(format: "%.3f", comp.volumeML), unit: "ml", valueColor: gold)
                }
            } else {
                fullRow(viewModel.selectedActive.rawValue,
                        value: String(format: "%.2f", totalActive), unit: unitLabel)
            }
        }
    }

    // MARK: - Helpers

    private func fullRow(_ label: String, value: String, unit: String, valueColor: Color = CMTheme.textSecondary) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: labelSize, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
            Text(value)
                .font(.system(size: valueSize, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
                .frame(width: valueWidth, alignment: .trailing)
            Text(unit)
                .font(.system(size: labelSize, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: unitWidth, alignment: .leading)
        }
        .padding(.horizontal, 40).padding(.vertical, 4)
    }

    private var fullDivider: some View {
        ThemedDivider(indent: 32).padding(.vertical, 12)
    }
}
