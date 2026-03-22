//
//  BatchOutputView.swift
//  CandyMan
//
//  Post-calculate view showing the calculated batch recipe.
//
//  Layout:
//    Gelatin Mix   – gelatin + water (with optional overage)
//    Sugar Mix     – sugar + water (with optional overage)
//    Activation Mix – preservative, colors, oils, terpenes, activation water
//    Actives       – substance totals (LSD has tab-splitting math)
//    Additional Water – user-adjustable extra dissolving water
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
    @State private var showWaterUpdatedAlert = false
    @State private var lastAdditionalWater: Double? = nil

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

            mixSection(result.gelatinMix)
            spacerLine
            overageMixSection(result.sugarMix, overagePercent: systemConfig.sugarMixtureOveragePercent)
            spacerLine
            activationMixSection(result.activationMix)
            spacerLine
            activesSection
            spacerLine
            additionalWaterInput
            Spacer().frame(height: 8)
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            BatchOutputFullScreenView()
                .environment(systemConfig)
                .environment(viewModel)
        }
        .onChange(of: viewModel.additionalActiveWaterML) { oldValue, newValue in
            // Skip the initial binding (first appearance) and only fire on real user edits
            guard lastAdditionalWater != nil else {
                lastAdditionalWater = newValue
                return
            }
            guard oldValue != newValue else { return }
            lastAdditionalWater = newValue
            CMHaptic.medium()
            withAnimation(.cmSpring) { showWaterUpdatedAlert = true }
        }
        .onAppear { lastAdditionalWater = viewModel.additionalActiveWaterML }
        .overlay {
            if showWaterUpdatedAlert {
                PsychedelicAlert5(
                    title: "Batch Updated",
                    subtitle: "All batch output values have been recalculated.",
                    value: String(format: "%.1f mL", viewModel.additionalActiveWaterML)
                ) {
                    withAnimation(.cmSpring) { showWaterUpdatedAlert = false }
                }
            }
        }
    }

    private func mixSection(_ mix: MixGroup) -> some View {
        VStack(spacing: 0) {
            HStack { Text(mix.name).cmSubsectionTitle(); Spacer() }
                .cmSubsectionPadding()
            ForEach(mix.components) { comp in componentRow(comp) }
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

    private func activationMixSection(_ mix: MixGroup) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        return VStack(spacing: 0) {
            HStack { Text(mix.name).cmSubsectionTitle(); Spacer() }
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
                    ForEach(items) { comp in componentRow(comp) }
                }
            }
        }
    }

    private func componentRow(_ comp: BatchComponent) -> some View {
        let colorMatch = GummyColor.allCases.first { "\($0.rawValue) Color" == comp.label }
        let isActivationWaterModified = comp.label == "Activation Water" && viewModel.additionalActiveWaterML > 0
        let isActivationWaterRow = comp.label == "Activation Water"
        let strawberryRed = systemConfig.designAlert
        let gold = systemConfig.designSecondaryAccent

        // Compute kept volume for LSD so we can annotate Activation Water
        let isLSD = viewModel.selectedActive == .lsd
        let ugPerTab = viewModel.lsdUgPerTab
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let tabsNeeded = ugPerTab > 0 ? Int(totalActive / ugPerTab) : 0
        let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)
        let transferWater = systemConfig.lsdTransferWaterML
        let keptVolume = (isLSD && ugPerTab > 0) ? (lsdInLiquid / ugPerTab) * transferWater : 0.0

        let valueColor: Color = CMTheme.textSecondary

        return VStack(spacing: 0) {
            HStack(spacing: 6) {
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

            // Activation Water breakdown: show when additional water added OR when LSD kept volume contributes
            let showBreakdown = isActivationWaterRow && (isActivationWaterModified || (isLSD && keptVolume > 0))
            if showBreakdown {
                let baseWater = comp.volumeML - viewModel.additionalActiveWaterML - keptVolume
                VStack(spacing: 1) {
                    // Base activation water (before additions)
                    HStack(spacing: 6) {
                        Text("Base").cmFinePrint()
                        Spacer()
                        Text(String(format: "%.3f", baseWater))
                            .cmColumnHeader()
                        Text("").frame(width: 28, alignment: .leading)
                    }
                    // Additional dissolving water (red), only if present
                    if viewModel.additionalActiveWaterML > 0 {
                        HStack(spacing: 6) {
                            Text("Additional Water")
                                .cmMono10()
                                .foregroundStyle(strawberryRed.opacity(0.8))
                            Spacer()
                            Text(String(format: "+%.3f", viewModel.additionalActiveWaterML))
                                .cmMono10()
                                .foregroundStyle(strawberryRed.opacity(0.8))
                                .frame(width: 70, alignment: .trailing)
                            Text("").frame(width: 28, alignment: .leading)
                        }
                    }
                    // Kept transfer water (gold), only if LSD and non-zero
                    if isLSD && keptVolume > 0 {
                        HStack(spacing: 6) {
                            Text("LSD Transfer Water")
                                .cmMono10()
                                .foregroundStyle(gold.opacity(0.9))
                            Spacer()
                            Text(String(format: "+%.3f", keptVolume))
                                .cmMono10()
                                .foregroundStyle(gold.opacity(0.9))
                                .frame(width: 70, alignment: .trailing)
                            Text("").frame(width: 28, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 2)
            }
        }
    }

    private var activesSection: some View {
        @Bindable var viewModel = viewModel
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue
        let gold = systemConfig.designSecondaryAccent

        return VStack(spacing: 0) {
            HStack {
                Text("Actives").cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()

            if viewModel.selectedActive == .lsd {
                // Header row: "LSD ([concentration] μg / tab)" + total active μg
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

                // Calculated tabs + LSD in liquid (remainder)
                let tabsNeeded = Int(totalActive / ugPerTab)
                let lsdInLiquid = totalActive - (Double(tabsNeeded) * ugPerTab)

                // Transfer water calculations
                let transferWater = systemConfig.lsdTransferWaterML
                let keptVolume = ugPerTab > 0 ? (lsdInLiquid / ugPerTab) * transferWater : 0.0
                let discardedVolume = transferWater - keptVolume

                HStack(spacing: 6) {
                    Text("Tabs").cmMono12().foregroundStyle(CMTheme.textPrimary)
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

                // Transfer water divider
                ThemedDivider(indent: 20).padding(.vertical, 4)

                // Total Transfer Water row
                HStack(spacing: 6) {
                    Text("Total Transfer Water").cmMono12().foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.3f", transferWater)).cmValueSlot()
                    Text("mL").cmUnitSlot()
                }
                .cmDataRowPadding()

                // Kept row (gold)
                HStack(spacing: 6) {
                    Text("Kept").cmMono12().foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.3f", keptVolume)).cmValueSlot(color: gold)
                    Text("mL").cmUnitSlot()
                }
                .cmDataRowPadding()

                // Discarded row
                HStack(spacing: 6) {
                    Text("Discarded").cmMono12().foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.3f", discardedVolume)).cmValueSlot()
                    Text("mL").cmUnitSlot()
                }
                .cmDataRowPadding()

                // Fine print instruction
                Group {
                    Text("Dissolve 1 Tab in \(String(format: "%.3f", transferWater)) mL of pure distilled water, let it dissolve, then transfer ")
                        .foregroundStyle(CMTheme.textTertiary)
                    + Text(String(format: "%.3f mL", keptVolume))
                        .foregroundStyle(gold)
                    + Text(" of the solution to the Activation Mix and discard \(String(format: "%.3f", discardedVolume)) mL of the remaining solution.")
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .cmMono10()
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 2)

            } else {
                // Non-LSD active: simple total row
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

    private var additionalWaterInput: some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 6) {
            Text("Additional Water for Dissolving Active")
                .cmRowLabel().lineLimit(2)
            Spacer()
            NumericField(value: $viewModel.additionalActiveWaterML, decimals: 1)
                .multilineTextAlignment(.trailing)
                .cmMono12()
                .foregroundStyle(systemConfig.designAlert)
                .frame(width: 50)
            Text("mL").cmUnitSlot()
        }
        .padding(.horizontal, 20).padding(.vertical, 4)
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

                    fullMixSection(result.gelatinMix)
                    fullDivider
                    fullOverageMixSection(result.sugarMix, overagePercent: systemConfig.sugarMixtureOveragePercent)
                    fullDivider
                    fullActivationMixSection(result.activationMix)
                    fullDivider
                    fullActivesSection
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

    private func fullActivationMixSection(_ mix: MixGroup) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        return VStack(spacing: 0) {
            HStack {
                Text(mix.name)
                    .font(.system(size: subHeaderSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 8)

            ForEach(orderedCategories, id: \.rawValue) { category in
                let items = mix.components.filter { $0.activationCategory == category }
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

    private var fullActivesSection: some View {
        let totalWells = viewModel.totalGummies(using: systemConfig)
        let totalActive = viewModel.activeConcentration * Double(totalWells)
        let unitLabel = viewModel.units.rawValue
        let gold = systemConfig.designSecondaryAccent

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
                let transferWater = systemConfig.lsdTransferWaterML
                let keptVolume = ugPerTab > 0 ? (lsdInLiquid / ugPerTab) * transferWater : 0.0
                let discardedVolume = transferWater - keptVolume

                fullRow("Tabs", value: "\(tabsNeeded)", unit: "#")
                fullRow("LSD in Liquid", value: String(format: "%.1f", lsdInLiquid), unit: "µg", valueColor: gold)

                fullDivider

                fullRow("Total Transfer Water", value: String(format: "%.3f", transferWater), unit: "mL")
                fullRow("Kept", value: String(format: "%.3f", keptVolume), unit: "mL", valueColor: gold)
                fullRow("Discarded", value: String(format: "%.3f", discardedVolume), unit: "mL")
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
