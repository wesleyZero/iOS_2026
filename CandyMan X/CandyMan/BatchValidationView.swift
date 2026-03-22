//
//  BatchValidationView.swift
//  CandyMan
//
//  Post-calculate validation card that checks the calculated batch
//  against reference targets (volume budget, density estimates, etc.).
//

import SwiftUI

// MARK: - BatchValidationView

struct BatchValidationView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isExpanded = false

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        let spec = systemConfig.spec(for: viewModel.selectedShape)

        // Pre-compute totals for reuse
        let activeTotalMass   = result.activationMix.totalMassGrams
        let activeTotalVol    = result.activationMix.totalVolumeML
        let gelatinTotalMass  = result.gelatinMix.totalMassGrams
        let gelatinTotalVol   = result.gelatinMix.totalVolumeML
        let sugarTotalMass    = result.sugarMix.totalMassGrams
        let sugarTotalVol     = result.sugarMix.totalVolumeML

        let finalMixMass      = activeTotalMass  + gelatinTotalMass  + sugarTotalMass
        let finalMixVol       = activeTotalVol   + gelatinTotalVol   + sugarTotalVol
        let finalOverageMass  = finalMixMass * viewModel.overageFactor
        let finalOverageVol   = finalMixVol  * viewModel.overageFactor

        let targetVol           = spec.volumeML * Double(spec.count) * Double(viewModel.trayCount)
        let finalMixVolNoOverage = finalMixVol / viewModel.overageFactor
        let quantifiedError     = finalMixVolNoOverage - targetVol
        let relativeError       = (targetVol > 0) ? (quantifiedError / targetVol) * 100.0 : 0.0

        VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Quantitative Data (Theoretical)").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            ThemedDivider()

            // MARK: Target Volumes
            subsectionHeader("Target Volumes")
            volOnlyRow("Volume Per Mold",  volume: spec.volumeML)
            volOnlyRow("Volume Per Tray",  volume: spec.volumeML * Double(spec.count))
            volOnlyRow("Total Volume",     volume: targetVol, valueColor: systemConfig.designSecondaryAccent)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Active Mix Components
            subsectionHeader("Active Mix Components")
            componentRows(result.activationMix.components)
            totalRow(mass: activeTotalMass, volume: activeTotalVol)

            // MARK: Gelatin Mix Components
            subsectionHeader("Gelatin Mix Components")
            componentRows(result.gelatinMix.components)
            totalRow(mass: gelatinTotalMass, volume: gelatinTotalVol)

            // MARK: Sugar Mix Components
            subsectionHeader("Sugar Mix Components")
            componentRows(result.sugarMix.components)
            totalRow(mass: sugarTotalMass, volume: sugarTotalVol)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Mixtures
            subsectionHeader("Mixtures")
            compRow("Active Mix",  mass: activeTotalMass,  volume: activeTotalVol)
            compRow("Gelatin Mix", mass: gelatinTotalMass, volume: gelatinTotalVol)
            compRow("Sugar Mix",   mass: sugarTotalMass,   volume: sugarTotalVol)
            totalRow(label: "Final Mix", mass: finalMixMass, volume: finalMixVol, volColor: systemConfig.designSecondaryAccent)

            let overagePct = (viewModel.overageFactor - 1.0) * 100.0
            finePrintNote(overagePct: overagePct, targetVol: targetVol)

            Spacer().frame(height: 12)
            } // end if isExpanded
        }
    }

    // MARK: - Sub-views

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
            Text("mass (g)")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
            Text("vol (mL)")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
        }
        .cmSubsectionPadding()
    }

    @ViewBuilder
    private func componentRows(_ components: [BatchComponent]) -> some View {
        ForEach(components) { c in
            HStack(spacing: 6) {
                Text(c.label)
                    .cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", c.massGrams))
                    .cmValueSlot()
                Text(String(format: "%.3f", c.volumeML))
                    .cmValueSlot()
            }
            .cmDataRowPadding()
        }
    }

    private func totalRow(label: String = "Total", mass: Double, volume: Double, volColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.3f", mass))
                .cmValueSlot()
            Text(String(format: "%.3f", volume))
                .cmMono12()
                .foregroundStyle(volColor ?? CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
        .background(CMTheme.totalRowBG)
    }

    private func compRow(_ label: String, mass: Double, volume: Double, bold: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", mass))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func volOnlyRow(_ label: String, volume: Double, bold: Bool = false, valueColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("—")
                .cmMono12().foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .cmMono12()
                .foregroundStyle(valueColor ?? CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func errorRow(_ label: String, value: String, highlight: Double) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .cmMono12()
                .foregroundStyle(highlight < 1.0 ? CMTheme.success : systemConfig.designAlert)
                .fontWeight(.semibold)
        }
        .cmDataRowPadding()
    }

    private func finePrintNote(overagePct: Double, targetVol: Double) -> some View {
        var str = AttributedString("All data is going to be ")
        str.foregroundColor = UIColor(CMTheme.textTertiary)

        var pctPart = AttributedString(String(format: "%.1f%%", overagePct))
        pctPart.foregroundColor = UIColor(systemConfig.designSecondaryAccent)
        str += pctPart

        var mid = AttributedString(" higher than the target of ")
        mid.foregroundColor = UIColor(CMTheme.textTertiary)
        str += mid

        var volPart = AttributedString(String(format: "%.0f mL", targetVol))
        volPart.foregroundColor = UIColor(systemConfig.designSecondaryAccent)
        str += volPart

        var end = AttributedString(" as specified in the system settings.")
        end.foregroundColor = UIColor(CMTheme.textTertiary)
        str += end

        return Text(str)
            .cmMono10()
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
}

// MARK: - Composition Data (Theoretical) View

struct RelativeFractionsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isExpanded = false

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)

        let activeTotalMass   = result.activationMix.totalMassGrams
        let activeTotalVol    = result.activationMix.totalVolumeML
        let gelatinTotalMass  = result.gelatinMix.totalMassGrams
        let gelatinTotalVol   = result.gelatinMix.totalVolumeML
        let sugarTotalMass    = result.sugarMix.totalMassGrams
        let sugarTotalVol     = result.sugarMix.totalVolumeML

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Composition Data (Theoretical)").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            ThemedDivider()

            // MARK: Active Mix Components
            fracSubheader("Active Mix Components")
            fracComponentRows(result.activationMix.components, totalMass: finalMixMass, totalVol: finalMixVol)
            fracTotalRow(mass: activeTotalMass, volume: activeTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

            // MARK: Gelatin Mix Components
            fracSubheader("Gelatin Mix Components")
            fracComponentRows(result.gelatinMix.components, totalMass: finalMixMass, totalVol: finalMixVol)
            fracTotalRow(mass: gelatinTotalMass, volume: gelatinTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

            // MARK: Sugar Mix Components
            fracSubheader("Sugar Mix Components")
            fracComponentRows(result.sugarMix.components, totalMass: finalMixMass, totalVol: finalMixVol)
            fracTotalRow(mass: sugarTotalMass, volume: sugarTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Mixtures
            fracSubheader("Mixtures")
            fracRow("Active Mix",  massPct: pct(activeTotalMass, of: finalMixMass),  volPct: pct(activeTotalVol, of: finalMixVol))
            fracRow("Gelatin Mix", massPct: pct(gelatinTotalMass, of: finalMixMass), volPct: pct(gelatinTotalVol, of: finalMixVol))
            fracRow("Sugar Mix",   massPct: pct(sugarTotalMass, of: finalMixMass),   volPct: pct(sugarTotalVol, of: finalMixVol))

            fracTotalRow(label: "Final Mix", mass: finalMixMass, volume: finalMixVol, totalMass: finalMixMass, totalVol: finalMixVol)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Custom Metrics
            customMetricsSubheader("Custom Metrics")
            fracRow("Goop Ratio",
                    massPct: gelatinTotalMass > 0 ? sugarTotalMass / gelatinTotalMass : 0,
                    volPct: gelatinTotalVol > 0 ? sugarTotalVol / gelatinTotalVol : 0)
            Text("The goop ratio is defined as the total sugar mixture divided by the total gelatin mixture (water included in each mixture), in mass and volume units.")
                .cmFootnote()
                .padding(.horizontal, 16).padding(.top, 6)

            Spacer().frame(height: 12)
            } // end if isExpanded
        }
    }

    // MARK: - Helpers

    private func pct(_ part: Double, of whole: Double) -> Double {
        whole > 0 ? (part / whole) * 100.0 : 0
    }

    private func customMetricsSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
            Text("mass")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
            Text("vol")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
        }
        .cmSubsectionPadding()
    }

    private func fracSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .cmSubsectionTitle()
            Spacer()
            Text("mass %")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
            Text("vol %")
                .cmFinePrint()
                .frame(width: 70, alignment: .trailing)
        }
        .cmSubsectionPadding()
    }

    @ViewBuilder
    private func fracComponentRows(_ components: [BatchComponent], totalMass: Double, totalVol: Double) -> some View {
        ForEach(components) { c in
            HStack(spacing: 6) {
                Text(c.label)
                    .cmRowLabel()
                Spacer()
                Text(String(format: "%.3f", pct(c.massGrams, of: totalMass)))
                    .cmValueSlot()
                Text(String(format: "%.3f", pct(c.volumeML, of: totalVol)))
                    .cmValueSlot()
            }
            .cmDataRowPadding()
        }
    }

    private func fracTotalRow(label: String = "Total", mass: Double, volume: Double, totalMass: Double, totalVol: Double) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12().fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.3f", pct(mass, of: totalMass)))
                .cmMono12().fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", pct(volume, of: totalVol)))
                .cmMono12().fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
        .background(CMTheme.totalRowBG)
    }

    private func fracRow(_ label: String, massPct: Double, volPct: Double, bold: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", massPct))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volPct))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
    }
}
