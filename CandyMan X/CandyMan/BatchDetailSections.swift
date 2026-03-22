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
//    BatchMeasurementsSection      — recorded weights (gelatin/sugar/active/final)
//    BatchCalculationsSection      — density, overage, error analysis summary
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
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Quantitative Data (Theoretical)").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { BatchDetailCopyUtility.copyJSON(quantitativeDataJSON(), label: "Quantitative Data (Theoretical)", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

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
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("mass (g)").cmColumnHeader()
            Text("vol (mL)").cmColumnHeader()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
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
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Composition Data (Theoretical)").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { BatchDetailCopyUtility.copyJSON(relativeDataJSON(), label: "Composition Data (Theoretical)", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

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
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("mass").cmColumnHeader()
            Text("vol").cmColumnHeader()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func relativeSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("mass %").cmColumnHeader()
            Text("vol %").cmColumnHeader()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
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
// MARK: - Measurements Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchMeasurementsSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Measurements").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { BatchDetailCopyUtility.copyJSON(measurementsJSON(), label: "Measurements", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if isExpanded {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    measureSubsection("Initial mass of container")
                    savedWeightRow("Beaker (Empty)",          value: batch.weightBeakerEmpty)

                    measureSubsection("Add gelatin mixture")
                    savedWeightRow("Beaker + Gelatin Mix",    value: batch.weightBeakerPlusGelatin)

                    measureSubsection("Add sugar mixture")
                    savedWeightRow("Substrate + Sugar Mix",   value: batch.weightBeakerPlusSugar)

                    measureSubsection("Add activation mixture")
                    savedWeightRow("Substrate + Activation Mix", value: batch.weightBeakerPlusActive)
                }

                VStack(spacing: 0) {
                    measureSubsection("Transfer to mold")
                    savedWeightRow("Syringe (Clean)",         value: batch.weightSyringeEmpty)
                    savedWeightRow("Syringe + Gummy Mix",     value: batch.weightSyringeWithMix)
                    savedVolumeRow("Syringe Gummy Mix Vol",   value: batch.volumeSyringeGummyMix)
                    savedWeightRow("Syringe + Residue",       value: batch.weightSyringeResidue)
                    savedWeightRow("Beaker + Residue",        value: batch.weightBeakerResidue)

                    savedWeightRow("Tray (Clean)",            value: batch.weightTrayClean)
                    savedWeightRow("Tray + Residue",          value: batch.weightTrayPlusResidue)

                    savedMoldsRow("Molds Filled",             value: batch.weightMoldsFilled)
                    savedWeightRow("Extra Gummy Mix",         value: batch.extraGummyMixGrams)
                }

                VStack(spacing: 0) {
                    measureSubsection("Mixture Densities — Sugar Mix")
                    savedWeightRow("Syringe (Clean)",         value: batch.densitySyringeCleanSugar)
                    savedWeightRow("Syringe + Sugar Mix",     value: batch.densitySyringePlusSugarMass)
                    savedVolumeRow("Syringe + Sugar Mix Vol",  value: batch.densitySyringePlusSugarVol)

                    measureSubsection("Mixture Densities — Gelatin Mix")
                    savedWeightRow("Syringe (Clean)",         value: batch.densitySyringeCleanGelatin)
                    savedWeightRow("Syringe + Gelatin Mix",   value: batch.densitySyringePlusGelatinMass)
                    savedVolumeRow("Syringe + Gelatin Mix Vol", value: batch.densitySyringePlusGelatinVol)
                }

                VStack(spacing: 0) {
                    measureSubsection("Mixture Densities — Activation Mix")
                    savedWeightRow("Syringe (Clean)",         value: batch.densitySyringeCleanActive)
                    savedWeightRow("Syringe + Activation Mix", value: batch.densitySyringePlusActiveMass)
                    savedVolumeRow("Syringe + Activation Mix Vol", value: batch.densitySyringePlusActiveVol)
                }
            }

            Spacer().frame(height: 8)
            } // end if isExpanded
        }
    }

    // MARK: - Helpers

    private func measureSubsection(_ title: String) -> some View {
        HStack {
            Text(title).cmFootnote().fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 2)
    }

    private func savedWeightRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("g").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func savedVolumeRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("mL").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    private func savedMoldsRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
            Text("#").cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    // MARK: - JSON

    private func measurementsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "initialMass": ["beakerEmpty": opt(batch.weightBeakerEmpty)],
            "gelatinMixture": ["beakerPlusGelatin": opt(batch.weightBeakerPlusGelatin)],
            "sugarMixture": ["substratePlusSugar": opt(batch.weightBeakerPlusSugar)],
            "activationMixture": ["substratePlusActivation": opt(batch.weightBeakerPlusActive)],
            "transferToMold": ["syringeClean": opt(batch.weightSyringeEmpty), "syringePlusMix": opt(batch.weightSyringeWithMix), "syringeMixVolML": opt(batch.volumeSyringeGummyMix), "syringeResidue": opt(batch.weightSyringeResidue), "beakerResidue": opt(batch.weightBeakerResidue), "trayClean": opt(batch.weightTrayClean), "trayPlusResidue": opt(batch.weightTrayPlusResidue), "moldsFilled": opt(batch.weightMoldsFilled), "extraGummyMixGrams": opt(batch.extraGummyMixGrams)],
            "densities": [
                "sugarMix": ["syringeClean": opt(batch.densitySyringeCleanSugar), "syringePlusMass": opt(batch.densitySyringePlusSugarMass), "syringePlusVol": opt(batch.densitySyringePlusSugarVol)],
                "gelatinMix": ["syringeClean": opt(batch.densitySyringeCleanGelatin), "syringePlusMass": opt(batch.densitySyringePlusGelatinMass), "syringePlusVol": opt(batch.densitySyringePlusGelatinVol)],
                "activationMix": ["syringeClean": opt(batch.densitySyringeCleanActive), "syringePlusMass": opt(batch.densitySyringePlusActiveMass), "syringePlusVol": opt(batch.densitySyringePlusActiveVol)],
            ],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Calculations Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchCalculationsSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Binding var copiedLabel: String
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    private var savedOverageForNextBatch: Double? {
        guard let avgVol = batch.calcAverageGummyVolume,
              batch.wellCount > 0,
              batch.vBaseML > 0 else { return nil }
        let volPerWell = batch.vBaseML / Double(batch.wellCount)
        return avgVol / volPerWell
    }

    private var massTrayResidue: Double? {
        guard let a = batch.weightTrayPlusResidue,
              let b = batch.weightTrayClean else { return nil }
        return a - b
    }

    private var massTotalLossWithSurplus: Double? {
        guard let base = batch.calcMassTotalLoss else { return nil }
        return base + (batch.extraGummyMixGrams ?? 0.0) + (massTrayResidue ?? 0.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Experiment Data").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { BatchDetailCopyUtility.copyJSON(calculationsJSON(), label: "Experiment Data", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if isExpanded {
            VStack(spacing: 0) {
                measureSubsection("Input Mixtures")
                savedCalcRow("Gelatin Mix Added",         value: batch.calcMassGelatinAdded,         unit: "g")
                savedCalcRow("Sugar Mix Added",           value: batch.calcMassSugarAdded,           unit: "g")
                savedCalcRow("Activation Mix Added",      value: batch.calcMassActiveAdded,          unit: "g")

                measureSubsection("Final Mixture")
                savedCalcRow("Final Mixture in Beaker",   value: batch.calcMassFinalMixtureInBeaker, unit: "g")
                savedCalcRow("Final Mixture in Tray/s",   value: batch.calcMassMixTransferredToMold, unit: "g")

                measureSubsection("Losses")
                savedCalcRow("Beaker Residue",            value: batch.calcMassBeakerResidue,        unit: "g")
            }

            VStack(spacing: 0) {
                savedCalcRow("Syringe Residue",           value: batch.calcMassSyringeResidue,       unit: "g")
                savedCalcRow("Gummy Mixture Surplus",     value: batch.extraGummyMixGrams,              unit: "g")
                savedCalcRow("Tray Residue",              value: massTrayResidue,                    unit: "g")
                savedCalcRow("Total Residue",             value: massTotalLossWithSurplus ?? batch.calcMassTotalLoss, unit: "g")
                    .background(CMTheme.rowHighlight)
                savedCalcRow("Lost \(batch.activeName) in Residue", value: batch.calcActiveLoss, unit: batch.activeUnit)

                measureSubsection("Mixture Densities")
                savedCalcRow("Sugar Mix Density",         value: batch.calcSugarMixDensity,          unit: "g/mL", decimals: 4)
                savedCalcRow("Gelatin Mix Density",       value: batch.calcGelatinMixDensity,        unit: "g/mL", decimals: 4)
                savedCalcRow("Activation Mix Density",    value: batch.calcActiveMixDensity,         unit: "g/mL", decimals: 4)
                savedCalcRow("Gummy Mixture Density",     value: batch.calcDensityFinalMix,          unit: "g/mL", decimals: 4)
            }

            VStack(spacing: 0) {
                measureSubsection("Gummies")
                savedCalcRow("Average Gummy Mass",        value: batch.calcMassPerGummyMold,         unit: "g")
                savedCalcRow("Average Gummy Volume",      value: batch.calcAverageGummyVolume,       unit: "mL", decimals: 3)
                savedCalcRow("Avg Gummy Active Dose",     value: batch.calcAverageGummyActiveDose,   unit: batch.activeUnit)

                measureSubsection("Overage")
                savedCalcRow("Overage for Next Batch",     value: savedOverageForNextBatch, unit: "", decimals: 4)
            }

            Spacer().frame(height: 8)
            } // end if isExpanded
        }
    }

    // MARK: - Helpers

    private func measureSubsection(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func savedCalcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(value.map { String(format: "%.\(decimals)f", $0) } ?? "—")
                .cmValueSlot(color: value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
            Text(unit).cmUnitSlot(width: 38)
        }
        .cmSavedRowPadding()
    }

    // MARK: - JSON

    private func calculationsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "inputMixtures": ["gelatinMixAdded": opt(batch.calcMassGelatinAdded), "sugarMixAdded": opt(batch.calcMassSugarAdded), "activationMixAdded": opt(batch.calcMassActiveAdded)],
            "finalMixture": ["inBeaker": opt(batch.calcMassFinalMixtureInBeaker), "inTrays": opt(batch.calcMassMixTransferredToMold)],
            "losses": ["beakerResidue": opt(batch.calcMassBeakerResidue), "syringeResidue": opt(batch.calcMassSyringeResidue), "gummyMixtureSurplus": opt(batch.extraGummyMixGrams), "trayResidue": opt(massTrayResidue), "totalResidue": opt(massTotalLossWithSurplus ?? batch.calcMassTotalLoss), "lostActive": opt(batch.calcActiveLoss)],
            "densities": ["sugarMix": opt(batch.calcSugarMixDensity), "gelatinMix": opt(batch.calcGelatinMixDensity), "activationMix": opt(batch.calcActiveMixDensity), "gummyMixture": opt(batch.calcDensityFinalMix)],
            "gummies": ["avgMass_g": opt(batch.calcMassPerGummyMold), "avgVolume_mL": opt(batch.calcAverageGummyVolume), "avgActiveDose": opt(batch.calcAverageGummyActiveDose)],
            "overage": ["overageForNextBatch": opt(savedOverageForNextBatch)],
        ] as [String: Any]
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
    @State private var selectedContainerLabel: String = SystemConfig.beakerContainers.first?.id ?? "Beaker 5ml"
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
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Dehydration Tracking").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { batch.dehydrationLocked.toggle() }
                        } label: {
                            Image(systemName: batch.dehydrationLocked ? "lock.fill" : "lock.open.fill")
                                .cmLockIcon(isLocked: batch.dehydrationLocked, color: systemConfig.designAlert)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { BatchDetailCopyUtility.copyJSON(dehydrationJSON(), label: "Dehydration Data", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

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
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Notes & Ratings").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Button {
                            CMHaptic.light()
                            withAnimation(.cmSpring) { batch.notesLocked.toggle() }
                        } label: {
                            Image(systemName: batch.notesLocked ? "lock.fill" : "lock.open.fill")
                                .cmLockIcon(isLocked: batch.notesLocked, color: systemConfig.designAlert)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { BatchDetailCopyUtility.copyJSON(notesAndRatingsJSON(), label: "Notes & Ratings", copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if isExpanded {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    sectionHeader("Flavor Tags")
                    tagRow(options: Self.flavorTagOptions, selection: $batch.flavorTags)
                    sectionHeader("Flavor Notes")
                    TextEditor(text: $batch.flavorNotes)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(CMTheme.fieldBG)
                        .cornerRadius(8)
                        .padding(.horizontal, 16).padding(.bottom, 10)
                    sectionHeader("Flavor Rating")
                    ratingField(value: $batch.flavorRating)
                    ThemedDivider(indent: 16)
                }

                VStack(spacing: 0) {
                    sectionHeader("Appearance Tags")
                    tagRow(options: Self.appearanceTagOptions, selection: $batch.colorTags)
                    sectionHeader("Appearance Notes")
                    TextEditor(text: $batch.colorNotes)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(CMTheme.fieldBG)
                        .cornerRadius(8)
                        .padding(.horizontal, 16).padding(.bottom, 10)
                    sectionHeader("Appearance Rating")
                    ratingField(value: $batch.colorRating)
                    ThemedDivider(indent: 16)
                }

                VStack(spacing: 0) {
                    sectionHeader("Texture Tags")
                    tagRow(options: Self.textureTagOptions, selection: $batch.textureTags)
                    sectionHeader("Texture Notes")
                    TextEditor(text: $batch.textureNotes)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(CMTheme.fieldBG)
                        .cornerRadius(8)
                        .padding(.horizontal, 16).padding(.bottom, 10)
                    sectionHeader("Texture Rating")
                    ratingField(value: $batch.textureRating)
                    ThemedDivider(indent: 16)
                }

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
