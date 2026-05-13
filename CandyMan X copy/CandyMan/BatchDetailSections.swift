//
//  BatchDetailSections.swift
//  CandyMan
//
//  Detail sections shown when viewing a saved batch from BatchHistoryView.
//  Each section is a standalone SwiftUI view that reads from a SavedBatch
//  model and renders summary cards, charts, and copy-to-clipboard actions.
//
//  Contents:
//    BatchDetailCopyUtility        — shared JSON copy + confirmation helper
//    DehydrationChartPoint         — Identifiable data point for the drying chart
//    BatchSummarySection           — batch ID, date, shape, active, tray count
//    BatchComponentsSection        — per-component mass breakdown table
//    BatchFlavorsSection           — flavor composition pie chart + list
//    BatchColorsSection            — color composition list
//    DehydrationSection            — drying curve line chart (mass vs time)
//    BatchHPMeasurementsSection    — high-precision weight measurements
//    BatchExperimentalData2Section — experimental data (masses, volumes, densities, losses, gummies)
//    BatchSigFigSection            — significant figures analysis for experimental computations
//    BatchNotesSection             — free-text notes editor
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Shared JSON Copy Utility

/// Utility for copying batch detail data as JSON.
enum BatchDetailCopyUtility {
    /// Copies a dictionary as formatted JSON to the system pasteboard and triggers the confirmation banner.
    static func copyJSON(_ dict: [String: Any], label: String = "JSON", copiedConfirmation: Binding<Bool>, copiedLabel: Binding<String>? = nil) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return }
        CMClipboard.copy(str)
        CMHaptic.success()
        copiedLabel?.wrappedValue = label
        copiedConfirmation.wrappedValue = true
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            copiedConfirmation.wrappedValue = false
        }
    }
}

// MARK: - Dehydration Chart Point

/// A single data point for the dehydration chart.
private struct DehydrationChartPoint: Identifiable {
    let id = UUID()
    let hours: Double
    let massPercent: Double
    let dehydPercent: Double
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Collapsible Section Chevron
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// A centered chevron strip shown at the bottom of a section header to indicate
/// collapse / expand state.
struct CollapsibleChevron: View {
    let isExpanded: Bool

    var body: some View {
        HStack {
            Spacer()
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.bottom, 6)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Quantitative Data (Theoretical) Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchQuantitativeDataSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }

        let activeTotalMass   = activationItems.reduce(0.0) { $0 + $1.massGrams }
        let activeTotalVol    = activationItems.reduce(0.0) { $0 + $1.volumeML }
        let gelatinTotalMass  = gelatinItems.reduce(0.0) { $0 + $1.massGrams }
        let gelatinTotalVol   = gelatinItems.reduce(0.0) { $0 + $1.volumeML }
        let sugarTotalMass    = sugarItems.reduce(0.0) { $0 + $1.massGrams }
        let sugarTotalVol     = sugarItems.reduce(0.0) { $0 + $1.volumeML }

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        let overageFactor    = batch.vBaseML > 0 ? batch.vMixML / batch.vBaseML : 1.0
        let targetVol        = batch.vBaseML
        let volPerMold       = batch.wellCount > 0 ? targetVol / Double(batch.wellCount) : 0
        let volPerTray       = batch.trayCount > 0 ? targetVol / Double(batch.trayCount) : 0

        let finalMixVolNoOverage = overageFactor > 0 ? finalMixVol / overageFactor : finalMixVol
        let quantifiedError      = finalMixVolNoOverage - targetVol
        let relativeError        = targetVol > 0 ? (quantifiedError / targetVol) * 100.0 : 0.0

        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Quantitative Data (Theoretical)",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                copyAction: { BatchDetailCopyUtility.copyJSON(quantitativeDataJSON(), label: "Quantitative Data (Theoretical)", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
                ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    validationSubheader("Target Volumes")
                    validationVolOnlyRow("Volume Per Mold", volume: volPerMold)
                    validationVolOnlyRow("Volume Per Tray", volume: volPerTray)
                    validationVolOnlyRow("Total Volume",    volume: targetVol, bold: true)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Active Mix Components")
                    validationActivationComponentRows(activationItems)
                    validationTotalRow(mass: activeTotalMass, volume: activeTotalVol)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Gelatin Mix Components")
                    validationComponentRows(gelatinItems)
                    validationTotalRow(mass: gelatinTotalMass, volume: gelatinTotalVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Sugar Mix Components")
                    validationComponentRows(sugarItems)
                    validationTotalRow(mass: sugarTotalMass, volume: sugarTotalVol)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Input Mixtures")
                    validationCompRow("Active Mix",  mass: activeTotalMass,  volume: activeTotalVol)
                    validationCompRow("Gelatin Mix", mass: gelatinTotalMass, volume: gelatinTotalVol)
                    validationCompRow("Sugar Mix",   mass: sugarTotalMass,   volume: sugarTotalVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Final Mixture")
                    validationCompRow("Final Mix (+\(String(format: "%.1f", (overageFactor - 1) * 100))%)",    mass: finalMixMass,                        volume: finalMixVol)
                    validationCompRow("Final Mix (without overage)", mass: finalMixMass / overageFactor,         volume: finalMixVolNoOverage, bold: true)
                        .background(CMTheme.totalRowBG)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Error")
                    validationErrorRow("Quantified Error",
                                       value: String(format: "%+.3f mL", quantifiedError),
                                       highlight: abs(quantifiedError))
                    validationErrorRow("Relative Error",
                                       value: String(format: "%+.3f%%", relativeError),
                                       highlight: abs(relativeError))

                    Spacer().frame(height: 12)
                }
            }
        }
    }

    // MARK: - Helpers

    private func validationSubheader(_ title: String) -> some View {
        CMTwoColumnSubheader(title: title, col1: "mass (g)", col2: "vol (mL)", bottomPadding: 2)
    }

    @ViewBuilder
    private func validationComponentRows(_ items: [SavedBatchComponent]) -> some View {
        ForEach(items.indices, id: \.self) { i in
            HStack {
                Text(items[i].label)
                    .cmMono11().foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", items[i].massGrams)).cmValidationSlot()
                Text(String(format: "%.3f", items[i].volumeML)).cmValidationSlot()
            }
            .cmDataRowPadding()
        }
    }

    @ViewBuilder
    private func validationActivationComponentRows(_ items: [SavedBatchComponent]) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        ForEach(orderedCategories, id: \.rawValue) { category in
            let categoryItems = items.filter { $0.category == category.rawValue }
            if !categoryItems.isEmpty {
                if category != .preservative {
                    HStack {
                        Text(category.rawValue)
                            .cmSubsectionTitle().fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                }
                ForEach(categoryItems.indices, id: \.self) { i in
                    HStack {
                        Text(categoryItems[i].label)
                            .cmMono11().foregroundStyle(CMTheme.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Spacer()
                        Text(String(format: "%.3f", categoryItems[i].massGrams)).cmValidationSlot()
                        Text(String(format: "%.3f", categoryItems[i].volumeML)).cmValidationSlot()
                    }
                    .cmDataRowPadding()
                }
            }
        }
    }

    private func validationTotalRow(mass: Double, volume: Double) -> some View {
        HStack {
            Text("Total").cmTotalLabel()
            Spacer()
            Text(String(format: "%.3f", mass))
                .cmValidationSlot(color: CMTheme.textPrimary).fontWeight(.semibold)
            Text(String(format: "%.3f", volume))
                .cmValidationSlot(color: CMTheme.textPrimary).fontWeight(.semibold)
        }
        .cmSavedRowPadding()
        .background(CMTheme.totalRowBG)
    }

    private func validationCompRow(_ label: String, mass: Double, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", mass))
                .cmValueSlot(color: bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
            Text(String(format: "%.3f", volume))
                .cmValueSlot(color: bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
        }
        .cmDataRowPadding()
    }

    private func validationVolOnlyRow(_ label: String, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("—").cmValueSlot(color: CMTheme.textTertiary)
            Text(String(format: "%.3f", volume))
                .cmValueSlot(color: bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
        }
        .cmDataRowPadding()
    }

    private func validationErrorRow(_ label: String, value: String, highlight: Double) -> some View {
        HStack {
            Text(label)
                .cmMono12().foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .cmMono12()
                .foregroundStyle(highlight < 1.0 ? CMTheme.success : systemConfig.designAlert)
                .fontWeight(.semibold)
        }
        .cmDataRowPadding()
    }

    // MARK: - JSON

    private func quantitativeDataJSON() -> [String: Any] {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }
        let aTM = activationItems.reduce(0.0) { $0 + $1.massGrams }
        let aTV = activationItems.reduce(0.0) { $0 + $1.volumeML }
        let gTM = gelatinItems.reduce(0.0) { $0 + $1.massGrams }
        let gTV = gelatinItems.reduce(0.0) { $0 + $1.volumeML }
        let sTM = sugarItems.reduce(0.0) { $0 + $1.massGrams }
        let sTV = sugarItems.reduce(0.0) { $0 + $1.volumeML }
        let fMM = aTM + gTM + sTM; let fMV = aTV + gTV + sTV
        let of = batch.vBaseML > 0 ? batch.vMixML / batch.vBaseML : 1.0
        let tv = batch.vBaseML
        let fMVno = of > 0 ? fMV / of : fMV
        let qErr = fMVno - tv
        let rErr = tv > 0 ? (qErr / tv) * 100.0 : 0.0
        return [
            "targetVolumes": ["volumePerMold_mL": batch.wellCount > 0 ? tv / Double(batch.wellCount) : 0, "volumePerTray_mL": batch.trayCount > 0 ? tv / Double(batch.trayCount) : 0, "totalTargetVolume_mL": tv],
            "mixTotals": ["activationMix": ["massGrams": aTM, "volumeML": aTV], "gelatinMix": ["massGrams": gTM, "volumeML": gTV], "sugarMix": ["massGrams": sTM, "volumeML": sTV]],
            "finalMix": ["withOverage": ["massGrams": fMM, "volumeML": fMV], "withoutOverage": ["massGrams": fMM / of, "volumeML": fMVno]],
            "error": ["quantifiedError_mL": qErr, "relativeErrorPct": rErr],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Composition Data (Theoretical) Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchRelativeDataSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }

        let activeTotalMass   = activationItems.reduce(0.0) { $0 + $1.massGrams }
        let activeTotalVol    = activationItems.reduce(0.0) { $0 + $1.volumeML }
        let gelatinTotalMass  = gelatinItems.reduce(0.0) { $0 + $1.massGrams }
        let gelatinTotalVol   = gelatinItems.reduce(0.0) { $0 + $1.volumeML }
        let sugarTotalMass    = sugarItems.reduce(0.0) { $0 + $1.massGrams }
        let sugarTotalVol     = sugarItems.reduce(0.0) { $0 + $1.volumeML }

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Composition Data (Theoretical)",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                copyAction: { BatchDetailCopyUtility.copyJSON(relativeDataJSON(), label: "Composition Data (Theoretical)", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
                ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    relativeSubheader("Active Mix Components")
                    relativeActivationComponentRows(activationItems, totalMass: finalMixMass, totalVol: finalMixVol)
                    relativeTotalRow(mass: activeTotalMass, volume: activeTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Gelatin Mix Components")
                    relativeComponentRows(gelatinItems, totalMass: finalMixMass, totalVol: finalMixVol)
                    relativeTotalRow(mass: gelatinTotalMass, volume: gelatinTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Sugar Mix Components")
                    relativeComponentRows(sugarItems, totalMass: finalMixMass, totalVol: finalMixVol)
                    relativeTotalRow(mass: sugarTotalMass, volume: sugarTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Input Mixtures")
                    relativeRow("Active Mix",  massPct: pct(activeTotalMass, of: finalMixMass),  volPct: pct(activeTotalVol, of: finalMixVol))
                    relativeRow("Gelatin Mix", massPct: pct(gelatinTotalMass, of: finalMixMass), volPct: pct(gelatinTotalVol, of: finalMixVol))
                    relativeRow("Sugar Mix",   massPct: pct(sugarTotalMass, of: finalMixMass),   volPct: pct(sugarTotalVol, of: finalMixVol))
                }

                VStack(spacing: 0) {
                    relativeRow("Final Mix", massPct: 100.0, volPct: 100.0, bold: true)
                        .background(CMTheme.totalRowBG)
                        .padding(.top, 8)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    customMetricsSubheader("Custom Metrics")
                    relativeRow("Goop Ratio",
                                massPct: gelatinTotalMass > 0 ? sugarTotalMass / gelatinTotalMass : 0,
                                volPct: gelatinTotalVol > 0 ? sugarTotalVol / gelatinTotalVol : 0)
                    Text("The goop ratio is defined as the total sugar mixture divided by the total gelatin mixture (water included in each mixture), in mass and volume units.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.top, 6)

                    Spacer().frame(height: 12)
                }
            }
        }
    }

    // MARK: - Helpers

    private func pct(_ part: Double, of whole: Double) -> Double {
        whole > 0 ? (part / whole) * 100.0 : 0
    }

    private func customMetricsSubheader(_ title: String) -> some View {
        CMTwoColumnSubheader(title: title, col1: "mass", col2: "vol", bottomPadding: 2)
    }

    private func relativeSubheader(_ title: String) -> some View {
        CMTwoColumnSubheader(title: title, col1: "mass %", col2: "vol %", bottomPadding: 2)
    }

    @ViewBuilder
    private func relativeComponentRows(_ items: [SavedBatchComponent], totalMass: Double, totalVol: Double) -> some View {
        ForEach(items.indices, id: \.self) { i in
            HStack {
                Text(items[i].label)
                    .cmMono11().foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", pct(items[i].massGrams, of: totalMass))).cmValidationSlot()
                Text(String(format: "%.3f", pct(items[i].volumeML, of: totalVol))).cmValidationSlot()
            }
            .cmDataRowPadding()
        }
    }

    @ViewBuilder
    private func relativeActivationComponentRows(_ items: [SavedBatchComponent], totalMass: Double, totalVol: Double) -> some View {
        let orderedCategories: [ActivationCategory] = [.preservative, .color, .flavorOil, .terpene]
        ForEach(orderedCategories, id: \.rawValue) { category in
            let categoryItems = items.filter { $0.category == category.rawValue }
            if !categoryItems.isEmpty {
                if category != .preservative {
                    HStack {
                        Text(category.rawValue)
                            .cmSubsectionTitle().fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                }
                ForEach(categoryItems.indices, id: \.self) { i in
                    HStack {
                        Text(categoryItems[i].label)
                            .cmMono11().foregroundStyle(CMTheme.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Spacer()
                        Text(String(format: "%.3f", pct(categoryItems[i].massGrams, of: totalMass))).cmValidationSlot()
                        Text(String(format: "%.3f", pct(categoryItems[i].volumeML, of: totalVol))).cmValidationSlot()
                    }
                    .cmDataRowPadding()
                }
            }
        }
    }

    private func relativeTotalRow(mass: Double, volume: Double, totalMass: Double, totalVol: Double) -> some View {
        HStack {
            Text("Total").cmTotalLabel()
            Spacer()
            Text(String(format: "%.3f", pct(mass, of: totalMass)))
                .cmValidationSlot(color: CMTheme.textPrimary).fontWeight(.semibold)
            Text(String(format: "%.3f", pct(volume, of: totalVol)))
                .cmValidationSlot(color: CMTheme.textPrimary).fontWeight(.semibold)
        }
        .cmSavedRowPadding()
        .background(CMTheme.totalRowBG)
    }

    private func relativeRow(_ label: String, massPct: Double, volPct: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", massPct))
                .cmValueSlot(color: bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
            Text(String(format: "%.3f", volPct))
                .cmValueSlot(color: bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
        }
        .cmDataRowPadding()
    }

    // MARK: - JSON

    private func relativeDataJSON() -> [String: Any] {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }
        let aTM = activationItems.reduce(0.0) { $0 + $1.massGrams }
        let aTV = activationItems.reduce(0.0) { $0 + $1.volumeML }
        let gTM = gelatinItems.reduce(0.0) { $0 + $1.massGrams }
        let gTV = gelatinItems.reduce(0.0) { $0 + $1.volumeML }
        let sTM = sugarItems.reduce(0.0) { $0 + $1.massGrams }
        let sTV = sugarItems.reduce(0.0) { $0 + $1.volumeML }
        let fMM = aTM + gTM + sTM; let fMV = aTV + gTV + sTV
        func p(_ part: Double, _ whole: Double) -> Double { whole > 0 ? (part / whole) * 100.0 : 0 }
        return [
            "components": sortedComponents.map { ["label": $0.label, "group": $0.group, "massPct": p($0.massGrams, fMM), "volumePct": p($0.volumeML, fMV)] as [String: Any] },
            "mixTotals": ["activationMix": ["massPct": p(aTM, fMM), "volumePct": p(aTV, fMV)], "gelatinMix": ["massPct": p(gTM, fMM), "volumePct": p(gTV, fMV)], "sugarMix": ["massPct": p(sTM, fMM), "volumePct": p(sTV, fMV)]],
            "goopRatio": ["mass": gTM > 0 ? sTM / gTM : 0, "volume": gTV > 0 ? sTV / gTV : 0],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - HP Measurements Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchHPMeasurementsSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Batch Measurements",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                copyAction: { BatchDetailCopyUtility.copyJSON(hpMeasurementsJSON(), label: "Batch Measurements", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
            VStack(spacing: 0) {

                // MARK: Gelatin Mixture
                hpSubsection("Gelatin Mixture")
                if let id = batch.hpSubstrateBeakerID { hpInfoRow("Substrate Beaker", value: id) }
                if let id = batch.hpSubstrateStirBarID { hpInfoRow("Stir Bar", value: id) }
                if let id = batch.hpSubstrateScaleID { hpInfoRow("Scale", value: id) }
                hpTareRow("Beaker Tare", value: batch.frozenSubstrateBeakerTare)
                hpCumulativeRow("+ Water", cumulative: batch.hpGelatinWater, individual: batch.hpIndividualGelatinWater)
                hpCumulativeRow("+ Gelatin", cumulative: batch.hpGelatin, individual: batch.hpIndividualGelatin)
                if let corrTotal = batch.correctionTotal(for: "gelatin") {
                    hpTotalRow("Corrections", value: corrTotal)
                }
                // Show individual correction entries
                ForEach(batch.savedCorrections.filter { $0.section == "gelatin" }) { c in
                    hpCorrectionRow(c)
                }
                hpTotalRow("Net Total | Gelatin Mixture", value: batch.hpGelatinMixtureTotal.map {
                    $0 + (batch.correctionTotal(for: "gelatin") ?? 0)
                })

                ThemedDivider(indent: 16).padding(.top, 8)

                // MARK: Sugar Mixture
                hpSubsection("Sugar Mixture")
                if let id = batch.hpSugarMixBeakerID { hpInfoRow("Sugar Mix Beaker", value: id) }
                if let id = batch.hpSugarMixStirBarID { hpInfoRow("Stir Bar", value: id) }
                if let id = batch.hpSugarMixScaleID { hpInfoRow("Scale", value: id) }
                hpTareRow("Beaker Tare", value: batch.frozenSugarMixBeakerTare)
                hpCumulativeRow("+ Water", cumulative: batch.hpSugarWater, individual: batch.hpIndividualSugarWater)
                hpCumulativeRow("+ Glucose Syrup", cumulative: batch.hpGlucoseSyrup, individual: batch.hpIndividualGlucoseSyrup)
                hpCumulativeRow("+ Granulated Sugar", cumulative: batch.hpGranulated, individual: batch.hpIndividualGranulated)
                if let corrTotal = batch.correctionTotal(for: "sugar") {
                    hpTotalRow("Corrections", value: corrTotal)
                }
                ForEach(batch.savedCorrections.filter { $0.section == "sugar" }) { c in
                    hpCorrectionRow(c)
                }
                hpTotalRow("Net Total | Sugar Mixture", value: batch.hpSugarMixtureTotal.map {
                    $0 + (batch.correctionTotal(for: "sugar") ?? 0)
                })

                ThemedDivider(indent: 16).padding(.top, 8)

                // MARK: Activation Mixture
                hpSubsection("Activation Mixture")
                if let id = batch.hpActivationTrayID { hpInfoRow("Activation Tray", value: id) }
                if let id = batch.hpActivationScaleID { hpInfoRow("Scale", value: id) }
                hpTareRow("Tray Tare", value: batch.frozenActivationTrayTare)
                hpCumulativeRow("+ Active", cumulative: batch.hpActive, individual: batch.hpIndividualActive)
                hpCumulativeRow("+ Citric Acid", cumulative: batch.hpCitricAcid, individual: batch.hpIndividualCitricAcid)
                hpCumulativeRow("+ Potassium Sorbate", cumulative: batch.hpKSorbate, individual: batch.hpIndividualKSorbate)
                hpCumulativeRow("+ (Base) Activation Water", cumulative: batch.hpActivationWater, individual: batch.hpIndividualActivationWater)
                hpCumulativeRow("+ Additional Activation Water", cumulative: batch.hpAdditionalActivationWater, individual: batch.hpIndividualAdditionalActivationWater)
                hpCumulativeRow("+ Flavor Oils", cumulative: batch.hpFlavorOils, individual: batch.hpIndividualFlavorOils)
                hpCumulativeRow("+ Color", cumulative: batch.hpColor, individual: batch.hpIndividualColor)
                hpCumulativeRow("+ Terps", cumulative: batch.hpTerps, individual: batch.hpIndividualTerps)
                hpCumulativeRow("Activation Tray Residue", cumulative: batch.hpActivationTrayResidue, individual: nil)
                if let corrTotal = batch.correctionTotal(for: "activation") {
                    hpTotalRow("Corrections", value: corrTotal)
                }
                ForEach(batch.savedCorrections.filter { $0.section == "activation" }) { c in
                    hpCorrectionRow(c)
                }
                hpTotalRow("Net Total | Activation Mixture", value: batch.hpActivationMixtureTotal.map {
                    $0 + (batch.correctionTotal(for: "activation") ?? 0)
                })

                ThemedDivider(indent: 16).padding(.top, 8)

                // MARK: Transfer
                hpSubsection("Transfer & Final Mixture")
                if let id = batch.hpTransferSyringeID { hpInfoRow("Transfer Syringe", value: id) }
                if let id = batch.hpTransferScaleID { hpInfoRow("Transfer Scale", value: id) }
                hpWeightRow("Substrate + Sugar Transfer", value: batch.hpSubstrateSugarTransfer)
                hpWeightRow("Substrate + Activation Transfer", value: batch.hpSubstrateActivationTransfer)

                // Transfer measurements
                hpWeightRow("Syringe (Clean)", value: batch.weightSyringeEmpty)
                hpWeightRow("Syringe + Gummy Mix", value: batch.weightSyringeWithMix)
                hpVolumeRow("Syringe Gummy Mix Vol", value: batch.volumeSyringeGummyMix)
                hpWeightRow("Syringe + Residue", value: batch.weightSyringeResidue)

                ThemedDivider(indent: 16).padding(.top, 8)

                // MARK: Molds
                hpSubsection("Molds")
                if let id = batch.hpMoldsTrayID { hpInfoRow("Tray", value: id) }
                if let id = batch.hpMoldsScaleID { hpInfoRow("Scale", value: id) }
                hpWeightRow("Tray (Clean)", value: batch.weightTrayClean)
                hpWeightRow("Tray + Residue", value: batch.weightTrayPlusResidue)
                hpMoldsRow("Molds Filled", value: batch.weightMoldsFilled)
                hpWeightRow("Extra Gummy Mix", value: batch.extraGummyMixGrams)

                ThemedDivider(indent: 16).padding(.top, 8)

                // MARK: Mixture Densities
                hpSubsection("Mixture Densities — Gelatin Mix")
                hpWeightRow("Syringe (Clean)", value: batch.densitySyringeCleanGelatin)
                hpWeightRow("Syringe + Gelatin Mix", value: batch.densitySyringePlusGelatinMass)
                hpVolumeRow("Syringe + Gelatin Mix Vol", value: batch.densitySyringePlusGelatinVol)
                hpDensityRow("Gelatin Mix Density", value: batch.calcGelatinMixDensity)

                hpSubsection("Mixture Densities — Sugar Mix")
                hpWeightRow("Syringe (Clean)", value: batch.densitySyringeCleanSugar)
                hpWeightRow("Syringe + Sugar Mix", value: batch.densitySyringePlusSugarMass)
                hpVolumeRow("Syringe + Sugar Mix Vol", value: batch.densitySyringePlusSugarVol)
                hpDensityRow("Sugar Mix Density", value: batch.calcSugarMixDensity)

                hpSubsection("Mixture Densities — Activation Mix")
                hpWeightRow("Syringe (Clean)", value: batch.densitySyringeCleanActive)
                hpWeightRow("Syringe + Activation Mix", value: batch.densitySyringePlusActiveMass)
                hpVolumeRow("Syringe + Activation Mix Vol", value: batch.densitySyringePlusActiveVol)
                hpDensityRow("Activation Mix Density", value: batch.calcActiveMixDensity)

                hpDensityRow("Gummy Mixture Density", value: batch.calcDensityFinalMix)
            }

            Spacer().frame(height: 8)
            } // end if isExpanded
        }
    }

    // MARK: - Row helpers

    private func hpSubsection(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func hpInfoRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value)
                .cmMono11()
                .foregroundStyle(CMTheme.textSecondary)
        }
        .cmSavedRowPadding()
    }

    private func hpTareRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("g").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func hpCumulativeRow(_ label: String, cumulative: Double?, individual: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            // Cumulative reading
            Text(cumulative.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: cumulative == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            // Individual mass (derived)
            Text(individual.map { String(format: "(%.3f)", $0) } ?? "")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 60, alignment: .trailing)
            Text("g").cmUnitSlot(width: 20)
        }
        .cmSavedRowPadding()
    }

    private func hpTotalRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel().fontWeight(.semibold)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .fontWeight(.semibold)
            Text("g").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func hpCorrectionRow(_ c: SavedCorrectionEntry) -> some View {
        HStack(spacing: 6) {
            Text("  \(c.label)").cmRowLabel()
            Spacer()
            if let diff = c.difference {
                Text(String(format: "%+.3f", diff))
                    .cmValueSlot(color: CMTheme.textSecondary)
            } else {
                Text("—").cmValueSlot(color: CMTheme.textTertiary)
            }
            Text("g").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func hpWeightRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("g").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func hpVolumeRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("mL").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func hpMoldsRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("#").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func hpDensityRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.4f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
            Text("g/mL").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    // MARK: - JSON

    private func hpMeasurementsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        func optStr(_ v: String?) -> Any { v as Any }
        return [
            "gelatinMixture": [
                "beakerID": optStr(batch.hpSubstrateBeakerID),
                "scaleID": optStr(batch.hpSubstrateScaleID),
                "stirBarID": optStr(batch.hpSubstrateStirBarID),
                "beakerTare": opt(batch.frozenSubstrateBeakerTare),
                "hpGelatin": opt(batch.hpGelatin),
                "hpGelatinWater": opt(batch.hpGelatinWater),
                "individualGelatin": opt(batch.hpIndividualGelatin),
                "individualGelatinWater": opt(batch.hpIndividualGelatinWater),
                "mixTotal": opt(batch.hpGelatinMixtureTotal),
            ],
            "sugarMixture": [
                "beakerID": optStr(batch.hpSugarMixBeakerID),
                "scaleID": optStr(batch.hpSugarMixScaleID),
                "stirBarID": optStr(batch.hpSugarMixStirBarID),
                "beakerTare": opt(batch.frozenSugarMixBeakerTare),
                "hpGranulated": opt(batch.hpGranulated),
                "hpGlucoseSyrup": opt(batch.hpGlucoseSyrup),
                "hpSugarWater": opt(batch.hpSugarWater),
                "individualGranulated": opt(batch.hpIndividualGranulated),
                "individualGlucoseSyrup": opt(batch.hpIndividualGlucoseSyrup),
                "individualSugarWater": opt(batch.hpIndividualSugarWater),
                "mixTotal": opt(batch.hpSugarMixtureTotal),
            ],
            "activationMixture": [
                "trayID": optStr(batch.hpActivationTrayID),
                "scaleID": optStr(batch.hpActivationScaleID),
                "trayTare": opt(batch.frozenActivationTrayTare),
                "hpActive": opt(batch.hpActive),
                "hpCitricAcid": opt(batch.hpCitricAcid),
                "hpKSorbate": opt(batch.hpKSorbate),
                "hpActivationWater": opt(batch.hpActivationWater),
                "hpAdditionalActivationWater": opt(batch.hpAdditionalActivationWater),
                "hpFlavorOils": opt(batch.hpFlavorOils),
                "hpColor": opt(batch.hpColor),
                "hpTerps": opt(batch.hpTerps),
                "hpActivationTrayResidue": opt(batch.hpActivationTrayResidue),
                "individualActive": opt(batch.hpIndividualActive),
                "individualCitricAcid": opt(batch.hpIndividualCitricAcid),
                "individualKSorbate": opt(batch.hpIndividualKSorbate),
                "individualActivationWater": opt(batch.hpIndividualActivationWater),
                "individualAdditionalActivationWater": opt(batch.hpIndividualAdditionalActivationWater),
                "individualFlavorOils": opt(batch.hpIndividualFlavorOils),
                "individualColor": opt(batch.hpIndividualColor),
                "individualTerps": opt(batch.hpIndividualTerps),
                "mixTotal": opt(batch.hpActivationMixtureTotal),
            ],
            "transfer": [
                "syringeID": optStr(batch.hpTransferSyringeID),
                "scaleID": optStr(batch.hpTransferScaleID),
                "substrateSugarTransfer": opt(batch.hpSubstrateSugarTransfer),
                "substrateActivationTransfer": opt(batch.hpSubstrateActivationTransfer),
                "syringeClean": opt(batch.weightSyringeEmpty),
                "syringePlusMix": opt(batch.weightSyringeWithMix),
                "syringeMixVol": opt(batch.volumeSyringeGummyMix),
                "syringeResidue": opt(batch.weightSyringeResidue),
            ],
            "molds": [
                "trayID": optStr(batch.hpMoldsTrayID),
                "scaleID": optStr(batch.hpMoldsScaleID),
                "trayClean": opt(batch.weightTrayClean),
                "trayPlusResidue": opt(batch.weightTrayPlusResidue),
                "moldsFilled": opt(batch.weightMoldsFilled),
                "extraGummyMix": opt(batch.extraGummyMixGrams),
            ],
            "densities": [
                "gelatinMix": opt(batch.calcGelatinMixDensity),
                "sugarMix": opt(batch.calcSugarMixDensity),
                "activationMix": opt(batch.calcActiveMixDensity),
                "gummyMixture": opt(batch.calcDensityFinalMix),
            ],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Experiment Data 2 Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchExperimentalData2Section: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    private let colWidth: CGFloat = 58

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var sugarOverage: Double {
        1.0 + batch.sugarMixtureOveragePercent / 100.0
    }

    // MARK: - Theoretical (from saved components)

    private var theoGelatinMass: Double {
        sortedComponents.first { $0.label == "Gelatin" && $0.group == "Gelatin Mix" }?.massGrams ?? 0
    }
    private var theoGelatinWaterMass: Double {
        sortedComponents.first { $0.label == "Water" && $0.group == "Gelatin Mix" }?.massGrams ?? 0
    }
    private var theoGelatinMixTotal: Double {
        sortedComponents.filter { $0.group == "Gelatin Mix" }.reduce(0.0) { $0 + $1.massGrams }
    }

    // Sugar components — stored with overage already applied if batch was saved with overage,
    // but we use the saved components directly since they represent the target amounts
    private var theoGranulatedMass: Double {
        sortedComponents.first { $0.label == "Granulated Sugar" && $0.group == "Sugar Mix" }?.massGrams ?? 0
    }
    private var theoGlucoseSyrupMass: Double {
        sortedComponents.first { $0.label == "Glucose Syrup" && $0.group == "Sugar Mix" }?.massGrams ?? 0
    }
    private var theoSugarWaterMass: Double {
        sortedComponents.first { $0.label == "Water" && $0.group == "Sugar Mix" }?.massGrams ?? 0
    }
    private var theoSugarMixTotal: Double {
        sortedComponents.filter { $0.group == "Sugar Mix" }.reduce(0.0) { $0 + $1.massGrams }
    }

    // Activation components
    private var theoCitricAcidMass: Double {
        sortedComponents.first { $0.label == "Citric Acid" }?.massGrams ?? 0
    }
    private var theoActivationWaterMass: Double {
        sortedComponents.first { $0.label == "Activation Water" }?.massGrams ?? 0
    }
    private var theoKSorbateMass: Double {
        sortedComponents.first { $0.label == "Potassium Sorbate" }?.massGrams ?? 0
    }
    private var theoFlavorOilsMass: Double {
        sortedComponents.filter { $0.group == "Activation Mix" && $0.category == "Flavor Oils" }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoColorMass: Double {
        sortedComponents.filter { $0.group == "Activation Mix" && $0.category == "Colors" }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoTerpsMass: Double {
        sortedComponents.filter { $0.group == "Activation Mix" && $0.category == "Terpenes" }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoActivationMixTotal: Double {
        sortedComponents.filter { $0.group == "Activation Mix" }.reduce(0.0) { $0 + $1.massGrams }
    }
    private var theoTotalMass: Double {
        theoGelatinMixTotal + theoSugarMixTotal + theoActivationMixTotal
    }

    // Theoretical volumes
    private var theoGelatinVol: Double {
        sortedComponents.filter { $0.group == "Gelatin Mix" }.reduce(0.0) { $0 + $1.volumeML }
    }
    private var theoSugarVol: Double {
        sortedComponents.filter { $0.group == "Sugar Mix" }.reduce(0.0) { $0 + $1.volumeML }
    }
    private var theoActivationVol: Double {
        sortedComponents.filter { $0.group == "Activation Mix" }.reduce(0.0) { $0 + $1.volumeML }
    }
    private var theoTotalVol: Double { theoGelatinVol + theoSugarVol + theoActivationVol }

    // Theoretical mixture densities
    private var theoGelatinMixDensity: Double {
        guard theoGelatinVol > 0 else { return 0 }
        return theoGelatinMixTotal / theoGelatinVol
    }
    private var theoSugarMixDensity: Double {
        guard theoSugarVol > 0 else { return 0 }
        return theoSugarMixTotal / theoSugarVol
    }
    private var theoActivationMixDensity: Double {
        guard theoActivationVol > 0 else { return 0 }
        return theoActivationMixTotal / theoActivationVol
    }
    private var theoFinalMixDensity: Double {
        guard theoTotalVol > 0 else { return 0 }
        return theoTotalMass / theoTotalVol
    }

    // MARK: - Experimental (from HP cumulative readings + frozen tares)

    private var expGelatinMass: Double? { batch.hpIndividualGelatin }
    private var expGelatinWaterMass: Double? { batch.hpIndividualGelatinWater }
    private var expGelatinMixTotal: Double? { batch.hpGelatinMixtureTotal }

    private var expGranulatedMass: Double? { batch.hpIndividualGranulated }
    private var expGlucoseSyrupMass: Double? { batch.hpIndividualGlucoseSyrup }
    private var expSugarWaterMass: Double? { batch.hpIndividualSugarWater }
    private var expSugarMixTotal: Double? { batch.hpSugarMixtureTotal }

    private var expActiveMass: Double? { batch.hpIndividualActive }
    private var expCitricAcidMass: Double? { batch.hpIndividualCitricAcid }
    private var expKSorbateMass: Double? { batch.hpIndividualKSorbate }
    private var expActivationWaterMass: Double? { batch.hpIndividualActivationWater }
    private var expAdditionalActivationWaterMass: Double? { batch.hpIndividualAdditionalActivationWater }
    private var expFlavorOilsMass: Double? { batch.hpIndividualFlavorOils }
    private var expColorMass: Double? { batch.hpIndividualColor }
    private var expTerpsMass: Double? { batch.hpIndividualTerps }
    private var expActivationMixTotal: Double? { batch.hpActivationMixtureTotal }

    // MARK: - Losses

    private var calcBeakerResidue: Double? {
        guard let residue = batch.weightBeakerResidue else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return residue - tare
    }

    private var calcActivationTrayResidue: Double? {
        guard let residue = batch.hpActivationTrayResidue else { return nil }
        let tare = batch.frozenActivationTrayTare ?? 0
        return residue - tare
    }

    private var calcSyringeResidue: Double? {
        guard let residue = batch.weightSyringeResidue else { return nil }
        let tare = batch.frozenTransferSyringeTare ?? 0
        return residue - tare
    }

    private var calcTrayResidue: Double? {
        guard let reading = batch.weightTrayPlusResidue else { return nil }
        let tare = batch.frozenMoldsTrayTare ?? 0
        return reading - tare
    }

    private var totalLossMass: Double? {
        let values = [calcBeakerResidue, calcActivationTrayResidue, calcSyringeResidue, calcTrayResidue, batch.extraGummyMixGrams]
        let available = values.compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +)
    }

    private var hpGummyMixtureMass: Double? {
        guard let transfer = batch.hpSubstrateActivationTransfer else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return transfer - tare
    }

    private var totalActiveAmount: Double {
        batch.activeConcentration * Double(batch.wellCount)
    }

    private var activeLostInLosses: Double? {
        guard let loss = totalLossMass,
              let mixMass = hpGummyMixtureMass,
              mixMass > 0 else { return nil }
        return totalActiveAmount * (loss / mixMass)
    }

    private var avgGummyDoseAfterLoss: Double? {
        guard let lost = activeLostInLosses,
              let moldsFilled = batch.weightMoldsFilled,
              moldsFilled > 0 else { return nil }
        return (totalActiveAmount - lost) / moldsFilled
    }

    // MARK: - Gummy Properties

    private var theoGummyMass: Double {
        let gummies = Double(batch.wellCount)
        guard gummies > 0 else { return 0 }
        return theoTotalMass / gummies
    }

    private var theoGummyVolume: Double {
        guard theoTotalVol > 0, batch.wellCount > 0 else { return 0 }
        return theoTotalVol / Double(batch.wellCount)
    }

    private var theoGummyConcentration: Double {
        batch.activeConcentration
    }

    private var expGummyMass: Double? {
        guard let mixMass = hpGummyMixtureMass,
              let losses = totalLossMass,
              let molds = batch.weightMoldsFilled,
              molds > 0 else { return nil }
        return (mixMass - losses) / molds
    }

    private var expGummyVolume: Double? {
        guard let mass = expGummyMass,
              let density = batch.calcDensityFinalMix,
              density > 0 else { return nil }
        return mass / density
    }

    private var expGummyConcentration: Double? {
        avgGummyDoseAfterLoss
    }

    // MARK: - Mass Fractions

    private var theoCitricAcidFraction: Double {
        guard theoTotalMass > 0 else { return 0 }
        return (theoCitricAcidMass / theoTotalMass) * 100.0
    }
    private var expCitricAcidFraction: Double? {
        guard let citric = expCitricAcidMass, let mixMass = hpGummyMixtureMass, mixMass > 0 else { return nil }
        return (citric / mixMass) * 100.0
    }
    private var theoKSorbateFraction: Double {
        guard theoTotalMass > 0 else { return 0 }
        return (theoKSorbateMass / theoTotalMass) * 100.0
    }
    private var expKSorbateFraction: Double? {
        guard let k = expKSorbateMass, let mixMass = hpGummyMixtureMass, mixMass > 0 else { return nil }
        return (k / mixMass) * 100.0
    }
    private var theoGelatinFraction: Double {
        guard theoTotalMass > 0 else { return 0 }
        return (theoGelatinMass / theoTotalMass) * 100.0
    }
    private var expGelatinFraction: Double? {
        guard let gel = expGelatinMass, let mixMass = hpGummyMixtureMass, mixMass > 0 else { return nil }
        return (gel / mixMass) * 100.0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Experiment Data 2",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                copyAction: { BatchDetailCopyUtility.copyJSON(expData2JSON(), label: "Experiment Data 2", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
                ThemedDivider()

                // MARK: Gelatin Mixture
                comparisonSubheader("Gelatin Mixture")
                comparisonRow("Water", theoretical: theoGelatinWaterMass, experimental: expGelatinWaterMass)
                comparisonRow("Gelatin", theoretical: theoGelatinMass, experimental: expGelatinMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Gelatin Mix Total", theoretical: theoGelatinMixTotal, experimental: expGelatinMixTotal, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Sugar Mixture
                comparisonSubheader("Sugar Mixture")
                comparisonRow("Water", theoretical: theoSugarWaterMass, experimental: expSugarWaterMass)
                comparisonRow("Glucose Syrup", theoretical: theoGlucoseSyrupMass, experimental: expGlucoseSyrupMass)
                comparisonRow("Granulated Sugar", theoretical: theoGranulatedMass, experimental: expGranulatedMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Sugar Mix Total", theoretical: theoSugarMixTotal, experimental: expSugarMixTotal, bold: true)
                    .background(CMTheme.totalRowBG)

                if batch.sugarMixtureOveragePercent > 0 {
                    Text(String(format: "Sugar theoretical values include %.0f%% overage.", batch.sugarMixtureOveragePercent))
                        .cmMono10()
                        .foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 20).padding(.top, 4)
                }

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Activation Mixture
                comparisonSubheader("Activation Mixture")
                comparisonRow("Active", theoretical: 0, experimental: expActiveMass)
                comparisonRow("Citric Acid", theoretical: theoCitricAcidMass, experimental: expCitricAcidMass)
                comparisonRow("Potassium Sorbate", theoretical: theoKSorbateMass, experimental: expKSorbateMass)
                comparisonRow("(Base) Activation Water", theoretical: theoActivationWaterMass, experimental: expActivationWaterMass)
                comparisonRow("Additional Activation Water", theoretical: 0, experimental: expAdditionalActivationWaterMass)
                comparisonRow("Flavor Oils", theoretical: theoFlavorOilsMass, experimental: expFlavorOilsMass)
                comparisonRow("Color", theoretical: theoColorMass, experimental: expColorMass)
                comparisonRow("Terps", theoretical: theoTerpsMass, experimental: expTerpsMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                comparisonRow("Activation Mix Total", theoretical: theoActivationMixTotal, experimental: expActivationMixTotal, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Mixture Densities
                densitySubheader("Mixture Densities")
                densityRow("Gelatin Mix", theoretical: theoGelatinMixDensity, experimental: batch.calcGelatinMixDensity)
                densityRow("Sugar Mix", theoretical: theoSugarMixDensity, experimental: batch.calcSugarMixDensity)
                densityRow("Activation Mix", theoretical: theoActivationMixDensity, experimental: batch.calcActiveMixDensity)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                densityRow("Gummy Mixture", theoretical: theoFinalMixDensity, experimental: batch.calcDensityFinalMix, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Losses
                lossesSubheader("Losses")
                lossRow("Beaker Residue", value: calcBeakerResidue)
                lossRow("Activation Tray Residue", value: calcActivationTrayResidue)
                lossRow("Syringe Residue", value: calcSyringeResidue)
                lossRow("Tray Residue", value: calcTrayResidue)
                lossRow("Extra Gummy Mixture", value: batch.extraGummyMixGrams)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                lossRow("Total Losses", value: totalLossMass, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Active Lost
                activeLostSubheader("Active Lost")
                lossRow("Gummy Mixture Mass", value: hpGummyMixtureMass)
                lossRow("Total Active", value: totalActiveAmount, unit: batch.activeUnit)
                lossRow("Total Losses", value: totalLossMass)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                lossRow("Active Lost", value: activeLostInLosses, unit: batch.activeUnit, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Gummies
                gummySubheader("Gummies")
                gummyRow("Volume", theoretical: theoGummyVolume, experimental: expGummyVolume, unit: "mL", format: "%.3f")
                gummyRow("Mass", theoretical: theoGummyMass, experimental: expGummyMass, unit: "g", format: "%.3f")
                gummyRow("Concentration", theoretical: theoGummyConcentration, experimental: expGummyConcentration, unit: batch.activeUnit, format: "%.3f")
                massFractionRow("Citric Acid", theoretical: theoCitricAcidFraction, experimental: expCitricAcidFraction)
                massFractionRow("K Sorbate", theoretical: theoKSorbateFraction, experimental: expKSorbateFraction)
                massFractionRow("Gelatin", theoretical: theoGelatinFraction, experimental: expGelatinFraction)

                if !hasAnyData {
                    Text("Record high-precision weight measurements to populate experimental data.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.top, 8)
                }

                Spacer().frame(height: 12)
            }
        }
    }

    private var hasAnyData: Bool {
        expGelatinMass != nil || expGranulatedMass != nil || expCitricAcidMass != nil
        || batch.calcGelatinMixDensity != nil || batch.calcSugarMixDensity != nil
        || batch.calcActiveMixDensity != nil || batch.calcDensityFinalMix != nil
    }

    // MARK: - Sub-views

    private func comparisonSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("theo (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("exp (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func comparisonRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?,
        bold: Bool = false
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(String(format: "%.3f", theoretical))
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth, alignment: .trailing)
            Text(experimental.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)
            Group {
                if let d = delta {
                    Text(String(format: "%+.3f", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth, alignment: .trailing)
            Group {
                if let p = pctError {
                    Text(String(format: "%+.2f", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func errorColor(pct: Double) -> Color {
        if pct <= 2.0 {
            return CMTheme.success
        } else if pct <= 5.0 {
            return systemConfig.designSecondaryAccent
        } else {
            return systemConfig.designAlert
        }
    }

    // MARK: - Density sub-views

    private func densitySubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("theo (g/mL)")
                .cmFinePrint()
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("exp (g/mL)")
                .cmFinePrint()
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("Δ (g/mL)")
                .cmFinePrint()
                .frame(width: colWidth + 6, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func densityRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?,
        bold: Bool = false
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(String(format: "%.4f", theoretical))
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth + 6, alignment: .trailing)
            Text(experimental.map { String(format: "%.4f", $0) } ?? "—")
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth + 6, alignment: .trailing)
            Group {
                if let d = delta {
                    Text(String(format: "%+.4f", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth + 6, alignment: .trailing)
            Group {
                if let p = pctError {
                    Text(String(format: "%+.2f", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    // MARK: - Losses sub-views

    private func lossesSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("exp (g)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("")
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func lossRow(
        _ label: String,
        value: Double?,
        unit: String = "g",
        bold: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)
            Text(unit)
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmDataRowPadding()
    }

    private func activeLostSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    // MARK: - Gummy sub-views

    private func gummySubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("theo")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("exp")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
            Text("Δ (%)")
                .cmFinePrint()
                .frame(width: colWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func gummyRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?,
        unit: String,
        format: String = "%.3f",
        pctFormat: String = "%.2f"
    ) -> some View {
        let delta: Double? = experimental.map { $0 - theoretical }
        let pctError: Double? = delta.map { theoretical > 0 ? ($0 / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text("\(label) (\(unit))")
                .cmMono12()
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(String(format: format, theoretical))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth, alignment: .trailing)
            Text(experimental.map { String(format: format, $0) } ?? "—")
                .cmMono12()
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)
            Group {
                if let d = delta {
                    Text(String(format: "%+\(format.dropFirst())", d))
                        .foregroundStyle(errorColor(pct: abs(pctError ?? 0)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)
            Group {
                if let p = pctError {
                    Text(String(format: "%+\(pctFormat.dropFirst())", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func massFractionRow(
        _ label: String,
        theoretical: Double,
        experimental: Double?
    ) -> some View {
        let pctError: Double? = experimental.map { theoretical > 0 ? (($0 - theoretical) / theoretical) * 100.0 : 0.0 }

        return HStack(spacing: 4) {
            Text("\(label) (%)")
                .cmMono12()
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(String(format: "%.3f", theoretical))
                .cmMono12()
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: colWidth, alignment: .trailing)
            Text(experimental.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .foregroundStyle(experimental == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: colWidth, alignment: .trailing)
            Text("—")
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: colWidth, alignment: .trailing)
            Group {
                if let p = pctError {
                    Text(String(format: "%+.2f", p))
                        .foregroundStyle(errorColor(pct: abs(p)))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .frame(width: colWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    // MARK: - JSON

    private func expData2JSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "gelatinMixture": [
                "theoGelatin": theoGelatinMass, "expGelatin": opt(expGelatinMass),
                "theoWater": theoGelatinWaterMass, "expWater": opt(expGelatinWaterMass),
                "theoTotal": theoGelatinMixTotal, "expTotal": opt(expGelatinMixTotal),
            ],
            "sugarMixture": [
                "theoGranulated": theoGranulatedMass, "expGranulated": opt(expGranulatedMass),
                "theoGlucoseSyrup": theoGlucoseSyrupMass, "expGlucoseSyrup": opt(expGlucoseSyrupMass),
                "theoWater": theoSugarWaterMass, "expWater": opt(expSugarWaterMass),
                "theoTotal": theoSugarMixTotal, "expTotal": opt(expSugarMixTotal),
            ],
            "activationMixture": [
                "expActive": opt(expActiveMass),
                "theoCitricAcid": theoCitricAcidMass, "expCitricAcid": opt(expCitricAcidMass),
                "theoKSorbate": theoKSorbateMass, "expKSorbate": opt(expKSorbateMass),
                "theoActivationWater": theoActivationWaterMass, "expActivationWater": opt(expActivationWaterMass),
                "expAdditionalActivationWater": opt(expAdditionalActivationWaterMass),
                "theoFlavorOils": theoFlavorOilsMass, "expFlavorOils": opt(expFlavorOilsMass),
                "theoTerps": theoTerpsMass, "expTerps": opt(expTerpsMass),
                "theoTotal": theoActivationMixTotal, "expTotal": opt(expActivationMixTotal),
            ],
            "densities": [
                "gelatinMix": ["theo": theoGelatinMixDensity, "exp": opt(batch.calcGelatinMixDensity)],
                "sugarMix": ["theo": theoSugarMixDensity, "exp": opt(batch.calcSugarMixDensity)],
                "activationMix": ["theo": theoActivationMixDensity, "exp": opt(batch.calcActiveMixDensity)],
                "gummyMixture": ["theo": theoFinalMixDensity, "exp": opt(batch.calcDensityFinalMix)],
            ],
            "losses": [
                "beakerResidue": opt(calcBeakerResidue),
                "activationTrayResidue": opt(calcActivationTrayResidue),
                "syringeResidue": opt(calcSyringeResidue),
                "trayResidue": opt(calcTrayResidue),
                "extraGummyMix": opt(batch.extraGummyMixGrams),
                "totalLosses": opt(totalLossMass),
            ],
            "activeLost": [
                "gummyMixtureMass": opt(hpGummyMixtureMass),
                "totalActive": totalActiveAmount,
                "activeLost": opt(activeLostInLosses),
            ],
            "gummies": [
                "theoVolume": theoGummyVolume, "expVolume": opt(expGummyVolume),
                "theoMass": theoGummyMass, "expMass": opt(expGummyMass),
                "theoConcentration": theoGummyConcentration, "expConcentration": opt(expGummyConcentration),
            ],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Sig Fig Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchSigFigSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    private let valColWidth: CGFloat = 68
    private let unitColWidth: CGFloat = 30
    private let sfColWidth: CGFloat = 38

    // MARK: - Frozen resolutions

    private var substrateRes: MeasurementResolution {
        batch.frozenMeasurementResolution(for: batch.frozenSubstrateScaleResolution)
    }
    private var sugarRes: MeasurementResolution {
        batch.frozenMeasurementResolution(for: batch.frozenSugarMixScaleResolution)
    }
    private var activationRes: MeasurementResolution {
        batch.frozenMeasurementResolution(for: batch.frozenActivationScaleResolution)
    }
    private var transferRes: MeasurementResolution {
        batch.frozenMeasurementResolution(for: batch.frozenTransferScaleResolution)
    }
    private var moldsRes: MeasurementResolution {
        batch.frozenMeasurementResolution(for: batch.frozenMoldsScaleResolution)
    }

    // MARK: - Gelatin Mixture SF (order: Water → Gelatin)

    private var sfExpGelatinWater: SigFigInfo? {
        guard let water = batch.hpGelatinWater else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return SigFigs.sfOfDifference(water, resA: substrateRes, minus: tare, resB: substrateRes)
    }

    private var sfExpGelatin: SigFigInfo? {
        guard let gel = batch.hpGelatin, let water = batch.hpGelatinWater else { return nil }
        return SigFigs.sfOfDifference(gel, resA: substrateRes, minus: water, resB: substrateRes)
    }

    private var sfExpGelatinMixTotal: SigFigInfo? {
        guard let w = sfExpGelatinWater, let g = sfExpGelatin else { return nil }
        let resultDP = SigFigs.addSubtract(w, g)
        let value = (batch.hpIndividualGelatinWater ?? 0) + (batch.hpIndividualGelatin ?? 0)
        let str = SigFigs.formatDP(value, decimalPlaces: resultDP)
        return SigFigs.count(from: str)
    }

    // MARK: - Sugar Mixture SF (order: Water → Glucose Syrup → Granulated)

    private var sfExpSugarWater: SigFigInfo? {
        guard let water = batch.hpSugarWater else { return nil }
        let tare = batch.frozenSugarMixBeakerTare ?? 0
        return SigFigs.sfOfDifference(water, resA: sugarRes, minus: tare, resB: sugarRes)
    }

    private var sfExpGlucoseSyrup: SigFigInfo? {
        guard let gluc = batch.hpGlucoseSyrup, let water = batch.hpSugarWater else { return nil }
        return SigFigs.sfOfDifference(gluc, resA: sugarRes, minus: water, resB: sugarRes)
    }

    private var sfExpGranulated: SigFigInfo? {
        guard let gran = batch.hpGranulated, let gluc = batch.hpGlucoseSyrup else { return nil }
        return SigFigs.sfOfDifference(gran, resA: sugarRes, minus: gluc, resB: sugarRes)
    }

    private var sfExpSugarMixTotal: SigFigInfo? {
        guard let w = sfExpSugarWater, let gl = sfExpGlucoseSyrup, let g = sfExpGranulated else { return nil }
        let resultDP = SigFigs.addSubtract(w, gl, g)
        let value = (batch.hpIndividualSugarWater ?? 0)
            + (batch.hpIndividualGlucoseSyrup ?? 0)
            + (batch.hpIndividualGranulated ?? 0)
        let str = SigFigs.formatDP(value, decimalPlaces: resultDP)
        return SigFigs.count(from: str)
    }

    // MARK: - Activation Mixture SF

    private var sfExpActive: SigFigInfo? {
        guard let active = batch.hpActive else { return nil }
        let tare = batch.frozenActivationTrayTare ?? 0
        return SigFigs.sfOfDifference(active, resA: activationRes, minus: tare, resB: activationRes)
    }

    private var sfExpCitricAcid: SigFigInfo? {
        guard let citric = batch.hpCitricAcid, let active = batch.hpActive else { return nil }
        return SigFigs.sfOfDifference(citric, resA: activationRes, minus: active, resB: activationRes)
    }

    private var sfExpKSorbate: SigFigInfo? {
        guard let k = batch.hpKSorbate, let citric = batch.hpCitricAcid else { return nil }
        return SigFigs.sfOfDifference(k, resA: activationRes, minus: citric, resB: activationRes)
    }

    private var sfExpActivationWater: SigFigInfo? {
        guard let water = batch.hpActivationWater, let k = batch.hpKSorbate else { return nil }
        return SigFigs.sfOfDifference(water, resA: activationRes, minus: k, resB: activationRes)
    }

    private var sfExpAdditionalActivationWater: SigFigInfo? {
        guard let addl = batch.hpAdditionalActivationWater, let water = batch.hpActivationWater else { return nil }
        return SigFigs.sfOfDifference(addl, resA: activationRes, minus: water, resB: activationRes)
    }

    private var sfExpFlavorOils: SigFigInfo? {
        guard let oils = batch.hpFlavorOils, let addl = batch.hpAdditionalActivationWater else { return nil }
        return SigFigs.sfOfDifference(oils, resA: activationRes, minus: addl, resB: activationRes)
    }

    private var sfExpColor: SigFigInfo? {
        guard let color = batch.hpColor, let oils = batch.hpFlavorOils else { return nil }
        return SigFigs.sfOfDifference(color, resA: activationRes, minus: oils, resB: activationRes)
    }

    private var sfExpTerps: SigFigInfo? {
        guard let terps = batch.hpTerps, let color = batch.hpColor else { return nil }
        return SigFigs.sfOfDifference(terps, resA: activationRes, minus: color, resB: activationRes)
    }

    private var sfExpActivationMixTotal: SigFigInfo? {
        guard let a = sfExpActive, let c = sfExpCitricAcid, let k = sfExpKSorbate,
              let w = sfExpActivationWater, let aw = sfExpAdditionalActivationWater,
              let fo = sfExpFlavorOils, let co = sfExpColor, let t = sfExpTerps else { return nil }
        let resultDP = SigFigs.addSubtract(a, c, k, w, aw, fo, co, t)
        let v1: Double = batch.hpIndividualActive ?? 0
        let v2: Double = batch.hpIndividualCitricAcid ?? 0
        let v3: Double = batch.hpIndividualKSorbate ?? 0
        let v4: Double = batch.hpIndividualActivationWater ?? 0
        let v5: Double = batch.hpIndividualAdditionalActivationWater ?? 0
        let v6: Double = batch.hpIndividualFlavorOils ?? 0
        let v6b: Double = batch.hpIndividualColor ?? 0
        let v7: Double = batch.hpIndividualTerps ?? 0
        let value = v1 + v2 + v3 + v4 + v5 + v6 + v6b + v7
        let str = SigFigs.formatDP(value, decimalPlaces: resultDP)
        return SigFigs.count(from: str)
    }

    // MARK: - Mixture Densities SF

    private var sfGelatinMixDensity: Int? {
        guard let clean = batch.densitySyringeCleanGelatin,
              let mass = batch.densitySyringePlusGelatinMass,
              let vol = batch.densitySyringePlusGelatinVol,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(mass, resA: substrateRes, minus: clean, resB: substrateRes)
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    private var sfSugarMixDensity: Int? {
        guard let clean = batch.densitySyringeCleanSugar,
              let mass = batch.densitySyringePlusSugarMass,
              let vol = batch.densitySyringePlusSugarVol,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(mass, resA: sugarRes, minus: clean, resB: sugarRes)
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    private var sfActivationMixDensity: Int? {
        guard let clean = batch.densitySyringeCleanActive,
              let mass = batch.densitySyringePlusActiveMass,
              let vol = batch.densitySyringePlusActiveVol,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(mass, resA: activationRes, minus: clean, resB: activationRes)
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    private var sfFinalMixDensity: Int? {
        guard let syringeMix = batch.weightSyringeWithMix,
              let syringeClean = batch.weightSyringeEmpty,
              let vol = batch.volumeSyringeGummyMix,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(
            syringeMix, resA: transferRes,
            minus: syringeClean, resB: transferRes
        )
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    // MARK: - Losses SF

    private var sfBeakerResidue: SigFigInfo? {
        guard let residue = batch.weightBeakerResidue else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return SigFigs.sfOfDifference(residue, resA: substrateRes, minus: tare, resB: substrateRes)
    }

    private var sfActivationTrayResidue: SigFigInfo? {
        guard let residue = batch.hpActivationTrayResidue else { return nil }
        let tare = batch.frozenActivationTrayTare ?? 0
        return SigFigs.sfOfDifference(residue, resA: activationRes, minus: tare, resB: activationRes)
    }

    private var sfSyringeResidue: SigFigInfo? {
        guard let residue = batch.weightSyringeResidue else { return nil }
        let tare = batch.frozenTransferSyringeTare ?? 0
        return SigFigs.sfOfDifference(residue, resA: transferRes, minus: tare, resB: transferRes)
    }

    private var sfTrayResidue: SigFigInfo? {
        guard let reading = batch.weightTrayPlusResidue else { return nil }
        let tare = batch.frozenMoldsTrayTare ?? 0
        return SigFigs.sfOfDifference(reading, resA: moldsRes, minus: tare, resB: moldsRes)
    }

    private var sfExtraGummyMix: SigFigInfo? {
        guard let v = batch.extraGummyMixGrams else { return nil }
        return SigFigs.quickCount(v)
    }

    private var sfTotalLoss: Int? {
        let infos = [sfBeakerResidue, sfActivationTrayResidue, sfSyringeResidue, sfTrayResidue, sfExtraGummyMix].compactMap { $0 }
        guard !infos.isEmpty else { return nil }
        let minDP = infos.map { $0.decimalPlaces ?? 0 }.min()!
        let beaker = calcBeakerResidue ?? 0
        let actTray = calcActivationTrayResidue ?? 0
        let syringe = calcSyringeResidue ?? 0
        let tray = calcTrayResidue ?? 0
        let extra = batch.extraGummyMixGrams ?? 0
        let sum = beaker + actTray + syringe + tray + extra
        let str = SigFigs.formatDP(sum, decimalPlaces: minDP)
        return SigFigs.count(from: str).sigFigs
    }

    // Loss value helpers
    private var calcBeakerResidue: Double? {
        guard let residue = batch.weightBeakerResidue else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return residue - tare
    }
    private var calcActivationTrayResidue: Double? {
        guard let residue = batch.hpActivationTrayResidue else { return nil }
        let tare = batch.frozenActivationTrayTare ?? 0
        return residue - tare
    }
    private var calcSyringeResidue: Double? {
        guard let residue = batch.weightSyringeResidue else { return nil }
        let tare = batch.frozenTransferSyringeTare ?? 0
        return residue - tare
    }
    private var calcTrayResidue: Double? {
        guard let reading = batch.weightTrayPlusResidue else { return nil }
        let tare = batch.frozenMoldsTrayTare ?? 0
        return reading - tare
    }

    // MARK: - Active Lost SF

    private var sfGummyMixtureMass: SigFigInfo? {
        guard let transfer = batch.hpSubstrateActivationTransfer else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return SigFigs.sfOfDifference(transfer, resA: transferRes, minus: tare, resB: transferRes)
    }

    private var sfTotalActive: SigFigInfo? {
        SigFigs.quickCount(batch.activeConcentration)
    }

    private var sfActiveLost: Int? {
        guard let activeSF = sfTotalActive?.sigFigs,
              let lossSF = sfTotalLoss,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(activeSF, lossSF, mixSF)
    }

    // MARK: - Gummy Properties SF

    private var sfExpGummyMass: Int? {
        guard let mixInfo = sfGummyMixtureMass,
              let lossSF = sfTotalLoss,
              let moldsFilled = batch.weightMoldsFilled else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        let massVal = batch.hpSubstrateActivationTransfer ?? 0
        let netMass = massVal - tare

        let beaker = calcBeakerResidue ?? 0
        let actTray = calcActivationTrayResidue ?? 0
        let syringe = calcSyringeResidue ?? 0
        let trayRes = calcTrayResidue ?? 0
        let extra = batch.extraGummyMixGrams ?? 0
        let totalLoss = beaker + actTray + syringe + trayRes + extra

        let diffDP = min(mixInfo.decimalPlaces ?? 0, lossSF > 0 ? 3 : 0)
        let diff = netMass - totalLoss
        let diffInfo = SigFigs.count(from: SigFigs.formatDP(diff, decimalPlaces: diffDP))

        let moldsInfo = SigFigs.count(moldsFilled, resolution: moldsRes)
        return SigFigs.multiplyDivide(diffInfo, moldsInfo)
    }

    private var sfExpGummyVolume: Int? {
        guard let massSF = sfExpGummyMass,
              let densitySF = sfFinalMixDensity else { return nil }
        return min(massSF, densitySF)
    }

    private var sfExpGummyConcentration: Int? {
        sfActiveLost
    }

    private var sfExpCitricAcidFraction: Int? {
        guard let citricSF = sfExpCitricAcid?.sigFigs,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(citricSF, mixSF)
    }

    private var sfExpKSorbateFraction: Int? {
        guard let kSF = sfExpKSorbate?.sigFigs,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(kSF, mixSF)
    }

    private var sfExpGelatinFraction: Int? {
        guard let gelSF = sfExpGelatin?.sigFigs,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(gelSF, mixSF)
    }

    // MARK: - Computed Values

    private var valGelatinMixDensity: Double? { batch.calcGelatinMixDensity }
    private var valSugarMixDensity: Double? { batch.calcSugarMixDensity }
    private var valActivationMixDensity: Double? { batch.calcActiveMixDensity }
    private var valFinalMixDensity: Double? { batch.calcDensityFinalMix }

    private var valTotalLoss: Double? {
        let vals = [calcBeakerResidue, calcActivationTrayResidue, calcSyringeResidue, calcTrayResidue, batch.extraGummyMixGrams]
        let available = vals.compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +)
    }

    private var valGummyMixtureMass: Double? {
        guard let transfer = batch.hpSubstrateActivationTransfer else { return nil }
        let tare = batch.frozenSubstrateBeakerTare ?? 0
        return transfer - tare
    }

    private var valTotalActive: Double {
        batch.activeConcentration * Double(batch.wellCount)
    }

    private var valActiveLost: Double? {
        guard let loss = valTotalLoss,
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return valTotalActive * (loss / mixMass)
    }

    private var valExpGummyMass: Double? {
        guard let mixMass = valGummyMixtureMass,
              let losses = valTotalLoss,
              let molds = batch.weightMoldsFilled,
              molds > 0 else { return nil }
        return (mixMass - losses) / molds
    }

    private var valExpGummyVolume: Double? {
        guard let mass = valExpGummyMass,
              let density = valFinalMixDensity,
              density > 0 else { return nil }
        return mass / density
    }

    private var valExpGummyConcentration: Double? {
        guard let lost = valActiveLost,
              let moldsFilled = batch.weightMoldsFilled,
              moldsFilled > 0 else { return nil }
        return (valTotalActive - lost) / moldsFilled
    }

    private var valExpCitricAcidFraction: Double? {
        guard let citric = batch.hpIndividualCitricAcid,
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (citric / mixMass) * 100.0
    }

    private var valExpKSorbateFraction: Double? {
        guard let ksorbate = batch.hpIndividualKSorbate,
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (ksorbate / mixMass) * 100.0
    }

    private var valExpGelatinFraction: Double? {
        guard let gelatin = batch.hpIndividualGelatin,
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (gelatin / mixMass) * 100.0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Significant Figures",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                copyAction: { BatchDetailCopyUtility.copyJSON([:], label: "Significant Figures", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
                ThemedDivider()

                Text("Significant figures for each experimental computation.")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                // MARK: Gelatin Mixture
                sfSubheader("Gelatin Mixture")
                sfRow("Water", info: sfExpGelatinWater, unit: "g")
                sfRow("Gelatin", info: sfExpGelatin, unit: "g")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRow("Gelatin Mix Total", info: sfExpGelatinMixTotal, unit: "g", bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Sugar Mixture
                sfSubheader("Sugar Mixture")
                sfRow("Water", info: sfExpSugarWater, unit: "g")
                sfRow("Glucose Syrup", info: sfExpGlucoseSyrup, unit: "g")
                sfRow("Granulated Sugar", info: sfExpGranulated, unit: "g")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRow("Sugar Mix Total", info: sfExpSugarMixTotal, unit: "g", bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Activation Mixture
                sfSubheader("Activation Mixture")
                sfRow("Active", info: sfExpActive, unit: "g")
                sfRow("Citric Acid", info: sfExpCitricAcid, unit: "g")
                sfRow("Potassium Sorbate", info: sfExpKSorbate, unit: "g")
                sfRow("(Base) Activation Water", info: sfExpActivationWater, unit: "g")
                sfRow("Additional Activation Water", info: sfExpAdditionalActivationWater, unit: "g")
                sfRow("Flavor Oils", info: sfExpFlavorOils, unit: "g")
                sfRow("Color", info: sfExpColor, unit: "g")
                sfRow("Terps", info: sfExpTerps, unit: "g")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRow("Activation Mix Total", info: sfExpActivationMixTotal, unit: "g", bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Mixture Densities
                sfSubheader("Mixture Densities")
                sfRowFromInt("Gelatin Mix", value: valGelatinMixDensity, sf: sfGelatinMixDensity, unit: "g/mL")
                sfRowFromInt("Sugar Mix", value: valSugarMixDensity, sf: sfSugarMixDensity, unit: "g/mL")
                sfRowFromInt("Activation Mix", value: valActivationMixDensity, sf: sfActivationMixDensity, unit: "g/mL")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRowFromInt("Gummy Mixture", value: valFinalMixDensity, sf: sfFinalMixDensity, unit: "g/mL", bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Losses
                sfSubheader("Losses")
                sfRow("Beaker Residue", info: sfBeakerResidue, unit: "g")
                sfRow("Activ. Tray Residue", info: sfActivationTrayResidue, unit: "g")
                sfRow("Syringe Residue", info: sfSyringeResidue, unit: "g")
                sfRow("Tray Residue", info: sfTrayResidue, unit: "g")
                sfRow("Extra Gummy Mix", info: sfExtraGummyMix, unit: "g")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRowFromInt("Total Losses", value: valTotalLoss, sf: sfTotalLoss, unit: "g", bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Active Lost
                sfSubheader("Active Lost")
                sfRow("Gummy Mixture Mass", info: sfGummyMixtureMass, unit: "g")
                sfRow("Total Active", info: sfTotalActive, unit: batch.activeUnit)
                sfRowFromInt("Total Losses", value: valTotalLoss, sf: sfTotalLoss, unit: "g")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRowFromInt("Active Lost", value: valActiveLost, sf: sfActiveLost, unit: batch.activeUnit, bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Gummies
                sfSubheader("Gummies")
                sfRowFromInt("Volume", value: valExpGummyVolume, sf: sfExpGummyVolume, unit: "mL")
                sfRowFromInt("Mass", value: valExpGummyMass, sf: sfExpGummyMass, unit: "g")
                sfRowFromInt("Concentration", value: valExpGummyConcentration, sf: sfExpGummyConcentration, unit: batch.activeUnit)
                sfRowFromInt("Citric Acid", value: valExpCitricAcidFraction, sf: sfExpCitricAcidFraction, unit: "%")
                sfRowFromInt("K Sorbate", value: valExpKSorbateFraction, sf: sfExpKSorbateFraction, unit: "%")
                sfRowFromInt("Gelatin", value: valExpGelatinFraction, sf: sfExpGelatinFraction, unit: "%")

                if !hasAnyData {
                    Text("Record high-precision weight measurements to populate sig fig analysis.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.top, 8)
                }

                Spacer().frame(height: 12)
            }
        }
    }

    private var hasAnyData: Bool {
        sfExpGelatin != nil || sfExpGranulated != nil || sfExpCitricAcid != nil
        || sfGelatinMixDensity != nil || sfSugarMixDensity != nil
        || sfActivationMixDensity != nil || sfFinalMixDensity != nil
    }

    // MARK: - Sub-views

    private func sfSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("value")
                .cmFinePrint()
                .frame(width: valColWidth + unitColWidth, alignment: .trailing)
            Text("SF")
                .cmFinePrint()
                .frame(width: sfColWidth, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func sfRow(
        _ label: String,
        info: SigFigInfo?,
        unit: String,
        bold: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Group {
                if let info = info {
                    Text(SigFigs.format(info.value, sigFigs: info.sigFigs))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: valColWidth, alignment: .trailing)
            Text(unit)
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: unitColWidth, alignment: .leading)
            Group {
                if let info = info {
                    Text("\(info.sigFigs)")
                        .foregroundStyle(sfColor(info.sigFigs))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: sfColWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func sfRowFromInt(
        _ label: String,
        value: Double? = nil,
        sf: Int?,
        unit: String,
        bold: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Group {
                if let sf = sf, let value = value {
                    Text(SigFigs.format(value, sigFigs: sf))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: valColWidth, alignment: .trailing)
            Text(unit)
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: unitColWidth, alignment: .leading)
            Group {
                if let sf = sf {
                    Text("\(sf)")
                        .foregroundStyle(sfColor(sf))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: sfColWidth, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func sfColor(_ sf: Int) -> Color {
        if sf >= 4 {
            return CMTheme.success
        } else if sf == 3 {
            return systemConfig.designSecondaryAccent
        } else {
            return systemConfig.designAlert
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Dry Weight / Dehydration Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchDryWeightSection: View {
    @Bindable var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.modelContext) private var modelContext

    private var containerLabels: [String] { systemConfig.containers.map(\.id) }

    @State private var isExpanded = true
    @State private var selectedContainerLabel: String = SystemConfig.beakerContainers.first?.id ?? "Beaker 5ml A"
    @State private var newDryMass: String = ""
    @State private var tareWeightText: String = ""
    @State private var showTareHistory = false

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Returns the selected container, or nil if none exists yet with that label.
    private var selectedContainer: DehydrationContainer? {
        batch.dehydrationContainers.first { $0.label == selectedContainerLabel }
    }

    private var currentReadings: [DryWeightReading] {
        (selectedContainer?.readings ?? []).sorted { $0.timestamp < $1.timestamp }
    }

    private var currentTareWeight: Double {
        selectedContainer?.tareWeightGrams ?? 0
    }

    // MARK: - Dehydration Calculations

    private var wetMass: Double? {
        if let m = batch.wetGummyMassGrams { return m }
        if let m = batch.calcMassMixTransferredToMold { return m }
        let total = sortedComponents.reduce(0.0) { $0 + $1.massGrams }
        return total > 0 ? total : nil
    }

    private var theoreticalTotalMass: Double {
        sortedComponents.reduce(0.0) { $0 + $1.massGrams }
    }

    private var formulationWaterMass: Double? {
        let waterComponents = sortedComponents.filter {
            $0.label == "Water" || $0.label == "Activation Water"
        }
        guard !waterComponents.isEmpty else { return nil }
        return waterComponents.reduce(0.0) { $0 + $1.massGrams }
    }

    private var waterMassFraction: Double? {
        guard let totalWater = formulationWaterMass else { return nil }
        let totalMix = batch.calcMassFinalMixtureInBeaker ?? theoreticalTotalMass
        guard totalMix > 0 else { return nil }
        return totalWater / totalMix
    }

    private var originalWaterInGummies: Double? {
        guard let wet = wetMass, let fraction = waterMassFraction else { return nil }
        return wet * fraction
    }

    private func waterMassPercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        guard waterMass >= 0 else { return nil }
        return (waterMass / wet) * 100.0
    }

    private var estimatedDensity: Double {
        let totalMass = sortedComponents.reduce(0.0) { $0 + $1.massGrams }
        let totalVol = sortedComponents.reduce(0.0) { $0 + $1.volumeML }
        return totalVol > 0 ? totalMass / totalVol : 1.0
    }

    private func waterVolumePercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        guard waterMass >= 0 else { return nil }
        let density = batch.calcDensityFinalMix ?? estimatedDensity
        guard density > 0 else { return nil }
        let totalVol = wet / density
        let waterVol = waterMass / 1.0
        return (waterVol / totalVol) * 100.0
    }

    private func dehydrationPercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, let origWater = originalWaterInGummies, origWater > 0 else { return nil }
        let massRemoved = wet - dryMass
        guard massRemoved >= 0 else { return nil }
        return (massRemoved / origWater) * 100.0
    }

    private var avgDehydrationRate: Double? {
        let entries = currentReadings
        guard entries.count >= 2,
              let wet = wetMass, wet > 0,
              let origWater = originalWaterInGummies, origWater > 0 else { return nil }
        guard let first = entries.first, let last = entries.last else { return nil }
        let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600.0
        guard hours > 0 else { return nil }
        let dehydFirst = ((wet - first.massGrams) / origWater) * 100.0
        let dehydLast  = ((wet - last.massGrams)  / origWater) * 100.0
        return (dehydLast - dehydFirst) / hours
    }

    /// Creates or returns the container for the selected label.
    private func ensureContainer() -> DehydrationContainer {
        if let existing = selectedContainer { return existing }
        let container = DehydrationContainer(label: selectedContainerLabel)
        batch.dehydrationContainers.append(container)
        return container
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Dehydration Tracking",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                lockAction: { withAnimation(.cmSpring) { batch.dehydrationLocked.toggle() } },
                isLocked: batch.dehydrationLocked,
                lockColor: systemConfig.designAlert,
                copyAction: { BatchDetailCopyUtility.copyJSON(dehydrationJSON(), label: "Dehydration Data", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
            // Container picker + tare weight (side by side)
            HStack(spacing: 8) {
                // Left: tare weight input + action buttons
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Tare")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                        KeypadStringField(text: $tareWeightText, placeholder: "0.000")
                            .font(.system(size: 14, design: .monospaced))
                            .padding(10)
                            .background(CMTheme.fieldBG)
                            .cornerRadius(CMTheme.fieldRadius)
                            .onChange(of: tareWeightText) { _, newVal in
                                if let val = Double(newVal) {
                                    let container = ensureContainer()
                                    container.tareWeightGrams = val
                                }
                            }
                        Text("g")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(CMTheme.textTertiary)
                    }

                    // Tare action buttons
                    HStack(spacing: 8) {
                        // Save: persist current tare to SystemConfig + record history
                        Button {
                            CMHaptic.success()
                            if let val = Double(tareWeightText) {
                                systemConfig.setContainerTare(val, for: selectedContainerLabel)
                                // Record to permanent history
                                let record = TareWeightRecord(
                                    containerLabel: selectedContainerLabel,
                                    weightGrams: val
                                )
                                modelContext.insert(record)
                            }
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(systemConfig.designTitle.opacity(0.8))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        // Reset: clear tare to 0
                        Button {
                            CMHaptic.light()
                            tareWeightText = ""
                            let container = ensureContainer()
                            container.tareWeightGrams = 0
                        } label: {
                            Label("Reset", systemImage: "xmark.circle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CMTheme.textSecondary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(CMTheme.totalRowBG)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        // Revert: restore from saved SystemConfig value
                        Button {
                            CMHaptic.light()
                            let saved = systemConfig.containerTare(for: selectedContainerLabel)
                            tareWeightText = saved > 0 ? String(format: "%.3f", saved) : ""
                            let container = ensureContainer()
                            container.tareWeightGrams = saved
                        } label: {
                            Label("Revert", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CMTheme.textSecondary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(CMTheme.totalRowBG)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        // History: show all past tare weights for this container
                        Button {
                            CMHaptic.light()
                            showTareHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CMTheme.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(CMTheme.totalRowBG)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Show saved value hint
                    let savedTare = systemConfig.containerTare(for: selectedContainerLabel)
                    if savedTare > 0 {
                        Text(String(format: "Saved: %.3f g", savedTare))
                            .cmFinePrint()
                    }
                }
                .disabled(batch.dehydrationLocked)
                .opacity(batch.dehydrationLocked ? 0.5 : 1.0)

                // Right: wheel picker
                Picker("Container", selection: $selectedContainerLabel) {
                    ForEach(containerLabels, id: \.self) { label in
                        let hasData = batch.dehydrationContainers.contains { $0.label == label && !$0.readings.isEmpty }
                        Text(label)
                            .fontWeight(hasData ? .bold : .regular)
                            .tag(label)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 150, height: 120)
            }
            .padding(.horizontal, 16).padding(.bottom, 4)

            // Add new reading
            HStack(spacing: 8) {
                KeypadStringField(text: $newDryMass, placeholder: "Total mass on scale (g)")
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(CMTheme.fieldRadius)
                Button("Record") {
                    if let totalMass = Double(newDryMass), totalMass > 0 {
                        let tare = currentTareWeight
                        let netMass = totalMass - tare
                        guard netMass > 0 else { return }
                        CMHaptic.success()
                        withAnimation(.cmSpring) {
                            let container = ensureContainer()
                            container.readings.append(
                                DryWeightReading(massGrams: netMass, timestamp: .now)
                            )
                        }
                        newDryMass = ""
                    }
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(systemConfig.designTitle)
                .cornerRadius(CMTheme.buttonRadius)
                .disabled(Double(newDryMass) == nil)
                .opacity(Double(newDryMass) == nil ? 0.4 : 1.0)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .disabled(batch.dehydrationLocked)
            .opacity(batch.dehydrationLocked ? 0.5 : 1.0)

            // Show tare subtraction hint when tare is set
            if currentTareWeight > 0, let totalMass = Double(newDryMass), totalMass > 0 {
                let net = totalMass - currentTareWeight
                Text(String(format: "%.3f g − %.3f g tare = %.3f g net", totalMass, currentTareWeight, net))
                    .cmFinePrint()
                    .padding(.horizontal, 16).padding(.bottom, 4)
            }

            // Recorded entries table with per-entry water content
            if !currentReadings.isEmpty {
                ThemedDivider(indent: 16)
                HStack(spacing: 4) {
                    Text("Hrs Elapsed").font(.caption2).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    Text("Mass").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 55, alignment: .trailing)
                    Text("Mass %").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 62, alignment: .trailing)
                    Text("Vol %").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 58, alignment: .trailing)
                    Text("Dehyd%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 2)

                ForEach(currentReadings.indices, id: \.self) { i in
                    let entry = currentReadings[i]
                    let hoursElapsed = currentReadings.first.map { entry.timestamp.timeIntervalSince($0.timestamp) / 3600.0 } ?? 0
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f hrs", hoursElapsed))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text(String(format: "%.1f g", entry.massGrams))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                            .frame(width: 55, alignment: .trailing)
                        Text(waterMassPercent(dryMass: entry.massGrams).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 62, alignment: .trailing)
                        Text(waterVolumePercent(dryMass: entry.massGrams).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 58, alignment: .trailing)
                        Text(dehydrationPercent(dryMass: entry.massGrams).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 3)
                }

                // Avg dehydration rate
                if let rate = avgDehydrationRate {
                    ThemedDivider(indent: 16).padding(.top, 4)
                    HStack {
                        Text("Avg dehydration rate")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text(String(format: "%.3f %%/hr", rate))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                }

                // Dehydration chart
                if currentReadings.count >= 2 {
                    dehydrationChart
                }
            }

            Spacer().frame(height: 8)
            } // end if isExpanded
        }
        .onChange(of: selectedContainerLabel) { _, newLabel in
            // Sync tare text field: use per-batch value if set, otherwise fall back to saved SystemConfig value
            let batchTare = selectedContainer?.tareWeightGrams ?? 0
            if batchTare > 0 {
                tareWeightText = String(format: "%.3f", batchTare)
            } else {
                let savedTare = systemConfig.containerTare(for: newLabel)
                if savedTare > 0 {
                    tareWeightText = String(format: "%.3f", savedTare)
                    // Also apply the saved tare to the batch container
                    let container = ensureContainer()
                    container.tareWeightGrams = savedTare
                } else {
                    tareWeightText = ""
                }
            }
            newDryMass = ""
        }
        .onAppear {
            // Select the first container that has data, or default to first beaker
            if let first = batch.dehydrationContainers
                .sorted(by: { $0.label < $1.label })
                .first(where: { !$0.readings.isEmpty }) {
                selectedContainerLabel = first.label
            }
            // Sync tare: per-batch value first, then saved SystemConfig
            let batchTare = selectedContainer?.tareWeightGrams ?? 0
            if batchTare > 0 {
                tareWeightText = String(format: "%.3f", batchTare)
            } else {
                let savedTare = systemConfig.containerTare(for: selectedContainerLabel)
                if savedTare > 0 {
                    tareWeightText = String(format: "%.3f", savedTare)
                    let container = ensureContainer()
                    container.tareWeightGrams = savedTare
                } else {
                    tareWeightText = ""
                }
            }
        }
        .sheet(isPresented: $showTareHistory) {
            TareWeightHistorySheet(containerLabel: selectedContainerLabel)
                .environment(systemConfig)
        }
    }

    // MARK: - Dehydration Chart

    @ViewBuilder
    private var dehydrationChart: some View {
        let entries = currentReadings
        let firstTimestamp = entries.first?.timestamp ?? .now

        let points: [DehydrationChartPoint] = entries.compactMap { entry in
            let hrs = entry.timestamp.timeIntervalSince(firstTimestamp) / 3600.0
            guard let mp = waterMassPercent(dryMass: entry.massGrams),
                  let dp = dehydrationPercent(dryMass: entry.massGrams) else { return nil }
            return DehydrationChartPoint(hours: hrs, massPercent: mp, dehydPercent: dp)
        }

        VStack(spacing: 4) {
            ThemedDivider(indent: 16).padding(.top, 4)
            Chart {
                ForEach(points) { pt in
                    LineMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Mass %", pt.massPercent),
                        series: .value("Series", "Mass %")
                    )
                    .foregroundStyle(systemConfig.designTitle)
                    .symbol(Circle())
                    .symbolSize(20)

                    PointMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Mass %", pt.massPercent)
                    )
                    .foregroundStyle(systemConfig.designTitle)
                    .symbolSize(20)
                }

                ForEach(points) { pt in
                    LineMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Dehyd %", pt.dehydPercent),
                        series: .value("Series", "Dehyd %")
                    )
                    .foregroundStyle(systemConfig.designAlert)
                    .symbol(Circle())
                    .symbolSize(20)

                    PointMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Dehyd %", pt.dehydPercent)
                    )
                    .foregroundStyle(systemConfig.designAlert)
                    .symbolSize(20)
                }
            }
            .chartXAxisLabel("Hours", alignment: .center)
            .chartYAxisLabel("%")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisGridLine().foregroundStyle(CMTheme.divider)
                    AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisGridLine().foregroundStyle(CMTheme.divider)
                    AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                }
            }
            .chartForegroundStyleScale([
                "Mass %": systemConfig.designTitle,
                "Dehyd %": systemConfig.designAlert
            ])
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 160)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - JSON

    private func dehydrationJSON() -> [String: Any] {
        let isoFmt = ISO8601DateFormatter()
        let sortedContainers = batch.dehydrationContainers.sorted { $0.label < $1.label }
        let containersArr: [[String: Any]] = sortedContainers.map { container in
            let entries = container.readings.sorted { $0.timestamp < $1.timestamp }
            var cObj: [String: Any] = [
                "label": container.label,
                "tareWeightGrams": container.tareWeightGrams,
                "readings": entries.map { e in
                    var d: [String: Any] = ["timestamp": isoFmt.string(from: e.timestamp), "massGrams": e.massGrams]
                    if let wm = waterMassPercent(dryMass: e.massGrams) { d["waterMassPct"] = wm }
                    if let wv = waterVolumePercent(dryMass: e.massGrams) { d["waterVolPct"] = wv }
                    if let dp = dehydrationPercent(dryMass: e.massGrams) { d["dehydrationPct"] = dp }
                    return d
                }
            ]
            if entries.count >= 2,
               let wet = wetMass, wet > 0,
               let origWater = originalWaterInGummies, origWater > 0 {
                guard let first = entries.first, let last = entries.last else { return cObj }
                let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600.0
                if hours > 0 {
                    let dehydFirst = ((wet - first.massGrams) / origWater) * 100.0
                    let dehydLast  = ((wet - last.massGrams)  / origWater) * 100.0
                    cObj["avgDehydrationRatePctPerHr"] = (dehydLast - dehydFirst) / hours
                }
            }
            return cObj
        }
        return ["containers": containersArr]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Notes & Ratings Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchNotesAndRatingsSection: View {
    @Bindable var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = true

    private static let flavorTagOptions = ["Too sweet", "Harsh", "Chemical", "Gross", "Unsweet", "Incredible", "Sour", "Bad combo"]
    private static let appearanceTagOptions = ["Bubbles", "Smooth", "Waxy", "Opaque", "Misshapen", "Clear", "Ideal"]
    private static let textureTagOptions = ["Goopy", "Jell-O", "Rubber", "Snappy", "Soft", "Ideal", "Too hard"]

    var body: some View {
        VStack(spacing: 0) {
            CMCollapsibleHeader(
                title: "Notes & Ratings",
                isExpanded: $isExpanded,
                accentColor: systemConfig.designTitle,
                lockAction: { withAnimation(.cmSpring) { batch.notesLocked.toggle() } },
                isLocked: batch.notesLocked,
                lockColor: systemConfig.designAlert,
                copyAction: { BatchDetailCopyUtility.copyJSON(notesAndRatingsJSON(), label: "Notes & Ratings", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            )

            if isExpanded {
            VStack(spacing: 0) {
                notesRatingBlock("Flavor", tagOptions: Self.flavorTagOptions, tags: $batch.flavorTags, notes: $batch.flavorNotes, rating: $batch.flavorRating)
                notesRatingBlock("Appearance", tagOptions: Self.appearanceTagOptions, tags: $batch.colorTags, notes: $batch.colorNotes, rating: $batch.colorRating)
                notesRatingBlock("Texture", tagOptions: Self.textureTagOptions, tags: $batch.textureTags, notes: $batch.textureNotes, rating: $batch.textureRating)

                VStack(spacing: 0) {
                    sectionHeader("Process Notes")
                    TextEditor(text: $batch.processNotes)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(CMTheme.fieldBG)
                        .cornerRadius(8)
                        .padding(.horizontal, 16).padding(.bottom, 10)
                }
            }
            .disabled(batch.notesLocked)
            .opacity(batch.notesLocked ? 0.5 : 1.0)
            } // end if isExpanded
        }
    }

    // MARK: - Helpers

    private func notesRatingBlock(_ category: String, tagOptions: [String], tags: Binding<String>, notes: Binding<String>, rating: Binding<Int>) -> some View {
        VStack(spacing: 0) {
            sectionHeader("\(category) Tags")
            tagRow(options: tagOptions, selection: tags)
            sectionHeader("\(category) Notes")
            TextEditor(text: notes)
                .scrollContentBackground(.hidden)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(minHeight: 80)
                .padding(8)
                .background(CMTheme.fieldBG)
                .cornerRadius(8)
                .padding(.horizontal, 16).padding(.bottom, 10)
            sectionHeader("\(category) Rating")
            ratingField(value: rating)
            ThemedDivider(indent: 16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)
    }

    private func tagRow(options: [String], selection: Binding<String>) -> some View {
        let selected = Set(selection.wrappedValue.split(separator: ",").map { String($0) })
        let columns = [GridItem(.adaptive(minimum: 70))]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { tag in
                let isSelected = selected.contains(tag)
                Button {
                    CMHaptic.light()
                    var tags = selected
                    if isSelected { tags.remove(tag) } else { tags.insert(tag) }
                    withAnimation(.cmSpring) {
                        selection.wrappedValue = tags.sorted().joined(separator: ",")
                    }
                } label: {
                    Text(tag)
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
                        .animation(.cmSpring, value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
    }

    private func ratingField(value: Binding<Int>) -> some View {
        HStack {
            NumericField(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = min(max(Int($0.rounded()), 0), 100) }
            ), decimals: 0)
                .multilineTextAlignment(.leading)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 50)
                .padding(8)
                .background(CMTheme.fieldBG)
                .cornerRadius(CMTheme.fieldRadius)
            Text("/ 100")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    // MARK: - JSON

    private func notesAndRatingsJSON() -> [String: Any] {
        func tagsArr(_ s: String) -> [String] { s.isEmpty ? [] : s.split(separator: ",").map { String($0) } }
        return [
            "flavor": ["rating": batch.flavorRating, "tags": tagsArr(batch.flavorTags), "notes": batch.flavorNotes] as [String: Any],
            "color": ["rating": batch.colorRating, "tags": tagsArr(batch.colorTags), "notes": batch.colorNotes] as [String: Any],
            "texture": ["rating": batch.textureRating, "tags": tagsArr(batch.textureTags), "notes": batch.textureNotes] as [String: Any],
            "processNotes": batch.processNotes,
        ] as [String: Any]
    }
}

// MARK: - Tare Weight History Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TareWeightHistorySheet: View {
    let containerLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TareWeightRecord.date, order: .reverse) private var allRecords: [TareWeightRecord]

    private var records: [TareWeightRecord] {
        allRecords.filter { $0.containerLabel == containerLabel }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("No saved tare weights for \(containerLabel) yet.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.3f g", record.weightGrams))
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundStyle(CMTheme.textPrimary)
                                    Text(record.date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                                        .font(.caption)
                                        .foregroundStyle(CMTheme.textTertiary)
                                }
                                Spacer()
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { records[$0] }
                            for record in toDelete {
                                modelContext.delete(record)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(containerLabel) Tare History")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
