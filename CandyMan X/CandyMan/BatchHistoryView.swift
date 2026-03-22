//
//  BatchHistoryView.swift
//  CandyMan
//
//  Full-screen batch history view (presented from the main screen).
//  Lists all saved batches stored in SwiftData, sorted by date.
//  Tapping a batch opens its detail view with full recipe data,
//  measurements, calibration data, and dehydration charts.
//

import SwiftUI
import SwiftData

struct BatchHistoryView: View {
    @Query(sort: \SavedBatch.date, order: .reverse) private var batches: [SavedBatch]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SystemConfig.self) private var systemConfig
    @State private var syntheticPoints: [DensityDataPoint] = []

    @State private var showCopiedConfirm  = false
    @State private var showImportConfirm  = false
    @State private var showImportError    = false
    @State private var importErrorMessage = ""
    @State private var importPreviewCount = 0

    private var activeBatches: [SavedBatch] {
        batches.filter { !$0.isTrashed }
    }

    private var trashedBatches: [SavedBatch] {
        batches.filter { $0.isTrashed }
    }

    var body: some View {
        NavigationStack {
            batchListContent
            .navigationTitle("Batch History")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .keyboardDismissToolbar()
            #if os(iOS) || os(visionOS)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Import from clipboard
                        Button {
                            importFromClipboard()
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(systemConfig.designTitle)
                        }

                        // Copy all to clipboard
                        Button {
                            let dtos = activeBatches.map { $0.toDTO() }
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                            encoder.dateEncodingStrategy = .iso8601
                            if let data = try? encoder.encode(dtos),
                               let jsonString = String(data: data, encoding: .utf8) {
                                CMClipboard.copy(jsonString)
                                CMHaptic.success()
                                showCopiedConfirm = true
                            }
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(activeBatches.isEmpty ? CMTheme.textTertiary : systemConfig.designTitle)
                        }
                        .disabled(activeBatches.isEmpty)

                        NavigationLink(destination: TrashView()) {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(trashedBatches.isEmpty ? CMTheme.textTertiary : systemConfig.designAlert)
                        }
                    }
                }
            }
            .alert("Copied to Clipboard", isPresented: $showCopiedConfirm) {
                Button("OK") { }
            } message: {
                Text("All \(activeBatches.count) batch\(activeBatches.count == 1 ? "" : "es") exported as JSON to your clipboard.")
            }
            #endif
            .alert("Import \(importPreviewCount) Batch\(importPreviewCount == 1 ? "" : "es")?", isPresented: $showImportConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Import") { executeImport() }
            } message: {
                Text("This will import \(importPreviewCount) batch\(importPreviewCount == 1 ? "" : "es") from the JSON on your clipboard. Existing batches with matching IDs will be skipped.")
            }
            .alert("Import Failed", isPresented: $showImportError) {
                Button("OK") { }
            } message: {
                Text(importErrorMessage)
            }

        }
    }

    // MARK: - Batch List Content

    private var batchListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Meta-Analysis button
                NavigationLink(destination: MetaAnalysisView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(systemConfig.designTitle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Meta-Analysis")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(CMTheme.textPrimary)
                            Text("Density regression across batches")
                                .cmFootnote()
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .cardStyle()

                if activeBatches.isEmpty && syntheticPoints.isEmpty {
                    ContentUnavailableView(
                        "No Saved Batches",
                        systemImage: "tray",
                        description: Text("Save a batch from the batch output screen.")
                    )
                    .frame(minHeight: 300)
                } else {
                    ForEach(activeBatches) { batch in
                        NavigationLink(destination: BatchDetailView(batch: batch)) {
                            batchCard(batch)
                        }
                        .buttonStyle(.plain)
                        .cardStyle()
                    }

                    if !syntheticPoints.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Synthetic Dataset 1")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(CMTheme.textTertiary)
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            ThemedDivider()
                            ForEach(syntheticPoints) { point in
                                syntheticBatchRow(point)
                                if point.id != syntheticPoints.last?.id {
                                    ThemedDivider(indent: 20)
                                }
                            }
                            Spacer().frame(height: 8)
                        }
                        .cardStyle()
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .onAppear {
            if systemConfig.syntheticDataSet1Enabled && syntheticPoints.isEmpty {
                syntheticPoints = MetaAnalysisView.generateSyntheticDataSet1()
            }
        }
        .onChange(of: systemConfig.syntheticDataSet1Enabled) { _, enabled in
            if enabled && syntheticPoints.isEmpty {
                syntheticPoints = MetaAnalysisView.generateSyntheticDataSet1()
            } else if !enabled {
                syntheticPoints = []
            }
        }
    }

    private func batchCard(_ batch: SavedBatch) -> some View {
        let oils = batch.flavors.filter { $0.type == "Flavor Oil" }.sorted { $0.percent > $1.percent }
        let sortedColors = batch.colors.sorted { $0.percent > $1.percent }

        return VStack(spacing: 0) {
            // Header row: ID badge + name + chevron
            HStack(spacing: 8) {
                if !batch.batchID.isEmpty {
                    Text(batch.batchID)
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(systemConfig.designTitle.opacity(0.15))
                        .foregroundStyle(systemConfig.designTitle)
                        .cornerRadius(4)
                }
                Text(batch.name)
                    .font(.headline).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CMTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 6)

            ThemedDivider()

            // Detail rows
            VStack(spacing: 4) {
                // Date
                HStack(spacing: 6) {
                    Text("Date")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(batch.date.formatted(.dateTime.month(.abbreviated).day().year().hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits)))
                        .cmMono12()
                        .foregroundStyle(CMTheme.textSecondary)
                }
                // Shape + Gummies
                HStack(spacing: 6) {
                    Text("Shape")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text("\(batch.shape) · \(batch.wellCount) gummies")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textSecondary)
                }
                // Active + dose
                HStack(spacing: 6) {
                    Text("Active")
                        .cmMono12()
                        .foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(batch.calcAverageGummyActiveDose.map { String(format: "%.2f %@ / gummy", $0, batch.activeUnit) } ?? String(format: "%.2f %@ / gummy", batch.activeConcentration, batch.activeUnit))
                        .cmMono12()
                        .foregroundStyle(systemConfig.designAlert)
                }
                // Colors + Oils summary
                let colorNames = sortedColors.map { $0.name }.joined(separator: ", ")
                let oilNames = oils.map { $0.name }.joined(separator: ", ")
                let segments = [colorNames, oilNames].filter { !$0.isEmpty }
                if !segments.isEmpty {
                    HStack(spacing: 6) {
                        Text("Profile")
                            .cmMono12()
                            .foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text(segments.joined(separator: " · "))
                            .cmMono12()
                            .foregroundStyle(CMTheme.textTertiary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .contentShape(Rectangle())
    }

    private func syntheticBatchRow(_ point: DensityDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(point.batchID)
                    .font(.caption).fontWeight(.bold)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(CMTheme.textTertiary.opacity(0.15))
                    .foregroundStyle(CMTheme.textTertiary)
                    .cornerRadius(4)
                Text(point.batchName).font(.headline).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                Spacer()
            }
            HStack(spacing: 6) {
                Text(point.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .cmFootnote()
                Text("·").cmFootnote()
                Text(String(format: "%.2f g/mL", point.density))
                    .cmFootnote()
                Text("·").cmFootnote()
                Text(String(format: "%.1f mL", point.mixVolume))
                    .cmFootnote()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Import from Clipboard

    private func importFromClipboard() {
        guard let jsonString = CMClipboard.paste(), !jsonString.isEmpty else {
            importErrorMessage = "Your clipboard is empty. Copy a batch history JSON to your clipboard first."
            showImportError = true
            return
        }
        guard let data = jsonString.data(using: .utf8) else {
            importErrorMessage = "Could not read clipboard contents as text."
            showImportError = true
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let dtos = try decoder.decode([SavedBatchDTO].self, from: data)
            guard !dtos.isEmpty else {
                importErrorMessage = "The JSON array is empty — no batches to import."
                showImportError = true
                return
            }
            importPreviewCount = dtos.count
            showImportConfirm = true
        } catch {
            importErrorMessage = "Could not parse the clipboard JSON as batch history.\n\n\(error.localizedDescription)"
            showImportError = true
        }
    }

    private func executeImport() {
        guard let jsonString = CMClipboard.paste(),
              let data = jsonString.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let dtos = try? decoder.decode([SavedBatchDTO].self, from: data) else { return }

        let existingIDs = Set(batches.map { $0.batchID })
        var imported = 0
        for dto in dtos {
            // Skip duplicates by batchID (if it exists and matches)
            if !dto.batchID.isEmpty && existingIDs.contains(dto.batchID) { continue }
            SavedBatch.from(dto: dto, context: modelContext)
            imported += 1
        }
        CMHaptic.success()
    }

}

// MARK: - Detail View

struct BatchDetailView: View {
    @Bindable var batch: SavedBatch
    @Environment(\.modelContext) private var modelContext
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var copiedConfirmation = false
    @State private var copiedLabel = ""
    @State private var batchInfoExpanded = true
    @State private var batchOutputExpanded = false
    @State private var copyDataExpanded = true

    private var isRegular: Bool { sizeClass == .regular }

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var decodedFlavors: [SavedBatchFlavor] {
        batch.flavors.sorted { $0.flavorID < $1.flavorID }
    }

    private var decodedColors: [SavedBatchColor] {
        batch.colors.sorted { $0.name < $1.name }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if isRegular {
                HStack(alignment: .top, spacing: 0) {
                    LazyVStack(spacing: 12) {
                        headerSection.cardStyle()
                        batchOutputCard.cardStyle()
                        BatchQuantitativeDataSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                        BatchRelativeDataSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)

                    LazyVStack(spacing: 12) {
                        BatchMeasurementsSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                        BatchCalculationsSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                        BatchDryWeightSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                        BatchNotesAndRatingsSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                        copyDataSection.cardStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
            } else {
                LazyVStack(spacing: 12) {
                    headerSection.cardStyle()
                    batchOutputCard.cardStyle()
                    BatchQuantitativeDataSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    BatchRelativeDataSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    BatchMeasurementsSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    BatchCalculationsSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    BatchDryWeightSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    BatchNotesAndRatingsSection(batch: batch, copiedConfirmation: $copiedConfirmation, copiedLabel: $copiedLabel).cardStyle()
                    copyDataSection.cardStyle()
                }
                .padding(.vertical, 12)
            }
        }
        .background(CMTheme.pageBG)
        .navigationTitle(batch.name)
        .keyboardDismissToolbar()
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .copyAlert(isShowing: $copiedConfirmation, label: copiedLabel)
    }

    // MARK: - Batch Output Card

    private var batchOutputCard: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { batchOutputExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Batch Output").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: batchOutputExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f mL (+ overage)", batch.vMixML))
                                .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                            Text(String(format: "%.1f mL", batch.vBaseML))
                                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { copyJSON(batchOutputJSON(), label: "Batch Output") }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if batchOutputExpanded {
                ThemedDivider(indent: 16)
                ingredientGroupsSection
                activesSection
            }
        }
    }

    // MARK: - Batch Configuration (merged header + user inputs)

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { batchInfoExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Batch Configuration").font(.headline).foregroundStyle(systemConfig.designTitle)
                        Image(systemName: batchInfoExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GlassCopyButton { copyJSON(batchConfigJSON(), label: "Batch Config") }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if batchInfoExpanded {
                // Batch identity
                summaryRow("Batch ID", value: batch.batchID.isEmpty ? "—" : batch.batchID)
                summaryRow("Batch Name", value: batch.name)
                summaryRow("Date", value: batch.date.formatted(.dateTime.month(.wide).day().year()))
                summaryRow("Time", value: batch.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))

                ThemedDivider(indent: 20).padding(.vertical, 6)

                // Core configuration — matches InputSummaryView
                summaryRow("Shape", value: batch.shape)
                summaryRow("Trays", value: "\(batch.trayCount)")
                summaryRow("Gummies", value: "\(batch.wellCount)")
                summaryRow("Active", value: batch.activeName)
                summaryRow("Concentration", value: String(format: "%.2f %@ / gummy", batch.activeConcentration, batch.activeUnit))
                summaryRow("Gelatin %", value: String(format: "%.3f%%", batch.gelatinPercent))
                summaryRow("Overage", value: String(format: "%.1f%%", (batch.overageFactor - 1.0) * 100.0))
                if batch.extraGummies > 0 {
                    summaryRow("Extra Gummies", value: "\(batch.extraGummies)")
                }

                // LSD-specific inputs
                if batch.activeName == "LSD" && batch.lsdUgPerTab > 0 {
                    summaryRow("µg / Tab", value: String(format: "%.0f", batch.lsdUgPerTab))
                    summaryRow("Transfer Water", value: String(format: "%.3f mL", batch.lsdTransferWaterML))
                }

                // Additional water
                if batch.additionalActiveWaterML > 0 {
                    summaryRow("Additional Water", value: String(format: "%.1f mL", batch.additionalActiveWaterML))
                }

                // Terpenes
                let terpenes = decodedFlavors.filter { $0.type == "Terpene" }
                if !terpenes.isEmpty {
                    summarySubheader("Terpenes")
                    summaryRow("PPM", value: String(format: "%.1f", batch.terpenePPM))
                    ForEach(terpenes.indices, id: \.self) { i in
                        summaryRow(terpenes[i].name, value: String(format: "%.0f%%", terpenes[i].percent))
                    }
                }

                // Flavor Oils
                let oils = decodedFlavors.filter { $0.type == "Flavor Oil" }
                if !oils.isEmpty {
                    summarySubheader("Flavor Oils")
                    summaryRow("Volume %", value: String(format: "%.3f%%", batch.flavorOilVolumePercent))
                    ForEach(oils.indices, id: \.self) { i in
                        summaryRow(oils[i].name, value: String(format: "%.0f%%", oils[i].percent))
                    }
                }

                // Colors
                if !decodedColors.isEmpty {
                    summarySubheader("Colors")
                    summaryRow("Volume %", value: String(format: "%.3f%%", batch.colorVolumePercent))
                    ForEach(decodedColors.indices, id: \.self) { i in
                        summaryRow(decodedColors[i].name, value: String(format: "%.0f%%", decodedColors[i].percent))
                    }
                }

                Spacer().frame(height: 8)
            }
        }
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).cmMono12().foregroundStyle(CMTheme.textPrimary).lineLimit(1)
            Spacer()
            Text(value)
                .cmMono12().foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func summarySubheader(_ title: String) -> some View {
        HStack {
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
    }

    // MARK: - Actives

    private var activesSection: some View {
        let gold = systemConfig.designSecondaryAccent
        return groupSection(title: "Actives") {
            AnyView(
                VStack(spacing: 0) {
                    if batch.activeName == "LSD" && batch.lsdUgPerTab > 0 {
                        // LSD header: total active
                        activeRow(String(format: "LSD (%.0f µg / tab)", batch.lsdUgPerTab),
                                  value: String(format: "%.1f", batch.totalActive),
                                  unit: batch.activeUnit)

                        ThemedDivider(indent: 20).padding(.vertical, 4)

                        // Tabs + LSD in liquid
                        let tabsNeeded = Int(batch.totalActive / batch.lsdUgPerTab)
                        let lsdInLiquid = batch.totalActive - (Double(tabsNeeded) * batch.lsdUgPerTab)
                        let transferWater = batch.lsdTransferWaterML
                        let keptVolume = batch.lsdUgPerTab > 0 ? (lsdInLiquid / batch.lsdUgPerTab) * transferWater : 0.0
                        let discardedVolume = transferWater - keptVolume

                        activeRow("Tabs", value: "\(tabsNeeded)", unit: "#")
                        activeRow("LSD in Liquid", value: String(format: "%.1f", lsdInLiquid), unit: "µg", valueColor: gold)

                        ThemedDivider(indent: 20).padding(.vertical, 4)

                        activeRow("Total Transfer Water", value: String(format: "%.3f", transferWater), unit: "mL")
                        activeRow("Kept", value: String(format: "%.3f", keptVolume), unit: "mL", valueColor: gold)
                        activeRow("Discarded", value: String(format: "%.3f", discardedVolume), unit: "mL")
                    } else {
                        // Non-LSD: simple total row
                        activeRow(batch.activeName,
                                  value: String(format: "%.2f", batch.totalActive),
                                  unit: batch.activeUnit)
                    }
                }
            )
        }
    }

    private func activeRow(_ label: String, value: String, unit: String, valueColor: Color = CMTheme.textSecondary) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(valueColor)
                .frame(width: 70, alignment: .trailing)
            Text(unit)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    // MARK: - Ingredient Groups

    @ViewBuilder
    private var ingredientGroupsSection: some View {
        let groups = ["Activation Mix", "Gelatin Mix", "Sugar Mix"]
        ForEach(groups, id: \.self) { group in
            let items = sortedComponents.filter { $0.group == group }
            if !items.isEmpty {
                groupSection(title: group) {
                    AnyView(
                        VStack(spacing: 0) {
                            if group == "Activation Mix" {
                                activationSubsections(items: items)
                            } else {
                                ForEach(items, id: \.label) { c in componentRow(c) }
                            }
                        }
                    )
                }
                ThemedDivider(indent: 16)
            }
        }
    }

    // MARK: - Copy Data Section

    private var copyDataSection: some View {
        VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { copyDataExpanded.toggle() }
            } label: {
                HStack {
                    Text("Copy Data").font(.headline).foregroundStyle(systemConfig.designTitle)
                    Image(systemName: copyDataExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if copyDataExpanded {
                ThemedDivider(indent: 16)
                Button {
                    CMHaptic.success()
                    CMClipboard.copy(buildJSONString())
                    copiedLabel = "All Batch Data"
                    copiedConfirmation = true
                    Task {
                        try? await Task.sleep(for: .seconds(2.5))
                        copiedConfirmation = false
                    }
                } label: {
                    Label("Copy Data to Clipboard", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(systemConfig.designTitle)
                        .foregroundStyle(.white)
                        .cornerRadius(CMTheme.buttonRadius)
                        .font(.headline)
                }
                .buttonStyle(CMPressStyle())
                .padding(.horizontal, 16).padding(.vertical, 16)
            }
        }
    }

    // MARK: - JSON Builder

    private func buildJSONString() -> String {
        let isoFmt = ISO8601DateFormatter()
        let isoDate: (Date) -> String = { isoFmt.string(from: $0) }

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

        let overageFactor        = batch.vBaseML > 0 ? batch.vMixML / batch.vBaseML : 1.0
        let targetVol            = batch.vBaseML
        let finalMixVolNoOverage = overageFactor > 0 ? finalMixVol / overageFactor : finalMixVol
        let quantifiedError      = finalMixVolNoOverage - targetVol
        let relativeError        = targetVol > 0 ? (quantifiedError / targetVol) * 100.0 : 0.0

        func pctOf(_ part: Double, _ whole: Double) -> Double { whole > 0 ? (part / whole) * 100.0 : 0 }
        func optNum(_ v: Double?) -> Any { v as Any }

        let volPerMold = batch.wellCount > 0 ? targetVol / Double(batch.wellCount) : 0.0
        let volPerTray = batch.trayCount > 0 ? targetVol / Double(batch.trayCount) : 0.0
        let goopMass = gelatinTotalMass > 0 ? sugarTotalMass / gelatinTotalMass : 0.0
        let goopVol  = gelatinTotalVol  > 0 ? sugarTotalVol  / gelatinTotalVol  : 0.0

        // Tags as arrays
        let flavorTagsArr = batch.flavorTags.isEmpty ? [] : batch.flavorTags.split(separator: ",").map { String($0) }
        let colorTagsArr  = batch.colorTags.isEmpty  ? [] : batch.colorTags.split(separator: ",").map { String($0) }
        let textureTagsArr = batch.textureTags.isEmpty ? [] : batch.textureTags.split(separator: ",").map { String($0) }

        // Dehydration helper values
        let wetMass: Double? = batch.wetGummyMassGrams ?? batch.calcMassMixTransferredToMold ?? {
            let t = sortedComponents.reduce(0.0) { $0 + $1.massGrams }; return t > 0 ? t : nil
        }()
        let waterComponents = sortedComponents.filter { $0.label == "Water" || $0.label == "Activation Water" }
        let formulationWaterMass: Double? = waterComponents.isEmpty ? nil : waterComponents.reduce(0.0) { $0 + $1.massGrams }
        let theoreticalTotalMass = sortedComponents.reduce(0.0) { $0 + $1.massGrams }
        let waterMassFraction: Double? = {
            guard let tw = formulationWaterMass else { return nil }
            let tm = batch.calcMassFinalMixtureInBeaker ?? theoreticalTotalMass
            return tm > 0 ? tw / tm : nil
        }()
        let originalWaterInGummies: Double? = {
            guard let w = wetMass, let f = waterMassFraction else { return nil }; return w * f
        }()
        func waterMassPct(_ dryMass: Double) -> Double? {
            guard let w = wetMass, w > 0 else { return nil }
            let wm = w - dryMass; return wm >= 0 ? (wm / w) * 100.0 : nil
        }
        let totalVol = sortedComponents.reduce(0.0) { $0 + $1.volumeML }
        let estDensity = totalVol > 0 ? theoreticalTotalMass / totalVol : 1.0
        func waterVolPct(_ dryMass: Double) -> Double? {
            guard let w = wetMass, w > 0 else { return nil }
            let wm = w - dryMass; guard wm >= 0 else { return nil }
            let d = batch.calcDensityFinalMix ?? estDensity; guard d > 0 else { return nil }
            return (wm / 1.0) / (w / d) * 100.0
        }
        func dehydPct(_ dryMass: Double) -> Double? {
            guard let w = wetMass, let ow = originalWaterInGummies, ow > 0 else { return nil }
            let mr = w - dryMass; return mr >= 0 ? (mr / ow) * 100.0 : nil
        }

        // Build the root dictionary
        var root: [String: Any] = [:]

        // BatchInfo
        root["batchInfo"] = [
            "batchID": batch.batchID,
            "name": batch.name,
            "date": isoDate(batch.date),
            "shape": batch.shape,
            "trayCount": batch.trayCount,
            "wellCount": batch.wellCount,
            "vBaseML": batch.vBaseML,
            "vMixML": batch.vMixML,
        ] as [String: Any]

        // UserInputs
        var userInputs: [String: Any] = [
            "activeName": batch.activeName,
            "activeConcentration": batch.activeConcentration,
            "activeUnit": batch.activeUnit,
            "totalActive": batch.totalActive,
            "gelatinPercent": batch.gelatinPercent,
            "terpenePPM": batch.terpenePPM,
            "flavorOilVolumePercent": batch.flavorOilVolumePercent,
            "colorVolumePercent": batch.colorVolumePercent,
            "additionalActiveWaterML": batch.additionalActiveWaterML,
            "flavors": decodedFlavors.map { [
                "flavorID": $0.flavorID,
                "name": $0.name,
                "type": $0.type,
                "percent": $0.percent,
            ] as [String: Any] },
            "colors": decodedColors.map { [
                "name": $0.name,
                "percent": $0.percent,
            ] as [String: Any] },
        ]
        if batch.lsdUgPerTab > 0 {
            userInputs["lsdUgPerTab"] = batch.lsdUgPerTab
            userInputs["lsdTransferWaterML"] = batch.lsdTransferWaterML
        }
        root["userInputs"] = userInputs

        // BatchOutput
        root["batchOutput"] = sortedComponents.map { [
            "sortOrder": $0.sortOrder,
            "label": $0.label,
            "massGrams": $0.massGrams,
            "volumeML": $0.volumeML,
            "displayUnit": $0.displayUnit,
            "group": $0.group,
            "category": $0.category as Any,
        ] as [String: Any] }

        // QuantitativeData
        root["quantitativeData"] = [
            "targetVolumes": [
                "volumePerMold_mL": volPerMold,
                "volumePerTray_mL": volPerTray,
                "totalTargetVolume_mL": targetVol,
            ],
            "mixTotals": [
                "activationMix": ["massGrams": activeTotalMass, "volumeML": activeTotalVol],
                "gelatinMix": ["massGrams": gelatinTotalMass, "volumeML": gelatinTotalVol],
                "sugarMix": ["massGrams": sugarTotalMass, "volumeML": sugarTotalVol],
            ],
            "finalMix": [
                "withOverage": ["massGrams": finalMixMass, "volumeML": finalMixVol],
                "withoutOverage": ["massGrams": finalMixMass / overageFactor, "volumeML": finalMixVolNoOverage],
            ],
            "error": [
                "quantifiedError_mL": quantifiedError,
                "relativeErrorPct": relativeError,
            ],
        ] as [String: Any]

        // RelativeData
        var relComponents: [[String: Any]] = []
        for c in sortedComponents {
            relComponents.append([
                "label": c.label,
                "group": c.group,
                "massPct": pctOf(c.massGrams, finalMixMass),
                "volumePct": pctOf(c.volumeML, finalMixVol),
            ])
        }
        root["relativeData"] = [
            "components": relComponents,
            "mixTotals": [
                "activationMix": ["massPct": pctOf(activeTotalMass, finalMixMass), "volumePct": pctOf(activeTotalVol, finalMixVol)],
                "gelatinMix": ["massPct": pctOf(gelatinTotalMass, finalMixMass), "volumePct": pctOf(gelatinTotalVol, finalMixVol)],
                "sugarMix": ["massPct": pctOf(sugarTotalMass, finalMixMass), "volumePct": pctOf(sugarTotalVol, finalMixVol)],
            ],
            "goopRatio": ["mass": goopMass, "volume": goopVol],
        ] as [String: Any]

        // Measurements
        func mEntry(_ label: String, _ value: Double?, _ unit: String) -> [String: Any] {
            ["label": label, "value": optNum(value), "unit": unit]
        }
        root["measurements"] = [
            mEntry("Beaker (Empty)", batch.weightBeakerEmpty, "g"),
            mEntry("Beaker + Gelatin Mix", batch.weightBeakerPlusGelatin, "g"),
            mEntry("Substrate + Sugar Mix", batch.weightBeakerPlusSugar, "g"),
            mEntry("Substrate + Activation Mix", batch.weightBeakerPlusActive, "g"),
            mEntry("Syringe (Clean)", batch.weightSyringeEmpty, "g"),
            mEntry("Syringe + Gummy Mix", batch.weightSyringeWithMix, "g"),
            mEntry("Syringe Gummy Mix Vol", batch.volumeSyringeGummyMix, "mL"),
            mEntry("Syringe + Residue", batch.weightSyringeResidue, "g"),
            mEntry("Beaker + Residue", batch.weightBeakerResidue, "g"),
            mEntry("Tray (Clean)", batch.weightTrayClean, "g"),
            mEntry("Tray + Residue", batch.weightTrayPlusResidue, "g"),
            mEntry("Molds Filled", batch.weightMoldsFilled, "#"),
            mEntry("Extra Gummy Mix", batch.extraGummyMixGrams, "g"),
            mEntry("Density Sugar Syringe Clean", batch.densitySyringeCleanSugar, "g"),
            mEntry("Density Sugar Syringe + Mix", batch.densitySyringePlusSugarMass, "g"),
            mEntry("Density Sugar Syringe + Mix Vol", batch.densitySyringePlusSugarVol, "mL"),
            mEntry("Density Gelatin Syringe Clean", batch.densitySyringeCleanGelatin, "g"),
            mEntry("Density Gelatin Syringe + Mix", batch.densitySyringePlusGelatinMass, "g"),
            mEntry("Density Gelatin Syringe + Mix Vol", batch.densitySyringePlusGelatinVol, "mL"),
            mEntry("Density Active Syringe Clean", batch.densitySyringeCleanActive, "g"),
            mEntry("Density Active Syringe + Mix", batch.densitySyringePlusActiveMass, "g"),
            mEntry("Density Active Syringe + Mix Vol", batch.densitySyringePlusActiveVol, "mL"),
        ]

        // Calculations
        func cEntry(_ label: String, _ value: Double?, _ unit: String) -> [String: Any] {
            ["label": label, "value": optNum(value), "unit": unit]
        }
        let savedOverage: Double? = {
            guard let av = batch.calcAverageGummyVolume, batch.wellCount > 0, batch.vBaseML > 0 else { return nil }
            return av / (batch.vBaseML / Double(batch.wellCount))
        }()
        root["calculations"] = [
            cEntry("Gelatin Mix Added", batch.calcMassGelatinAdded, "g"),
            cEntry("Sugar Mix Added", batch.calcMassSugarAdded, "g"),
            cEntry("Activation Mix Added", batch.calcMassActiveAdded, "g"),
            cEntry("Final Mixture in Beaker", batch.calcMassFinalMixtureInBeaker, "g"),
            cEntry("Final Mixture in Tray/s", batch.calcMassMixTransferredToMold, "g"),
            cEntry("Beaker Residue", batch.calcMassBeakerResidue, "g"),
            cEntry("Syringe Residue", batch.calcMassSyringeResidue, "g"),
            cEntry("Gummy Mixture Surplus", batch.extraGummyMixGrams, "g"),
            cEntry("Tray Residue", {
                guard let a = batch.weightTrayPlusResidue, let b = batch.weightTrayClean else { return nil }
                return a - b
            }(), "g"),
            cEntry("Total Residue", {
                guard let base = batch.calcMassTotalLoss else { return nil }
                let trayRes: Double = {
                    guard let a = batch.weightTrayPlusResidue, let b = batch.weightTrayClean else { return 0 }
                    return a - b
                }()
                return base + (batch.extraGummyMixGrams ?? 0) + trayRes
            }(), "g"),
            cEntry("Lost \(batch.activeName) in Residue", batch.calcActiveLoss, batch.activeUnit),
            cEntry("Sugar Mix Density", batch.calcSugarMixDensity, "g/mL"),
            cEntry("Gelatin Mix Density", batch.calcGelatinMixDensity, "g/mL"),
            cEntry("Activation Mix Density", batch.calcActiveMixDensity, "g/mL"),
            cEntry("Gummy Mixture Density", batch.calcDensityFinalMix, "g/mL"),
            cEntry("Average Gummy Mass", batch.calcMassPerGummyMold, "g"),
            cEntry("Average Gummy Volume", batch.calcAverageGummyVolume, "mL"),
            cEntry("Avg Gummy Active Dose", batch.calcAverageGummyActiveDose, batch.activeUnit),
            cEntry("Overage for Next Batch", savedOverage, ""),
        ]

        // DehydrationTracking (per container)
        let sortedContainers = batch.dehydrationContainers.sorted { $0.label < $1.label }
        let containersJSON: [[String: Any]] = sortedContainers.map { container in
            let entries = container.readings.sorted { $0.timestamp < $1.timestamp }
            let readingsArr: [[String: Any]] = entries.map { e in
                var d: [String: Any] = [
                    "timestamp": isoDate(e.timestamp),
                    "massGrams": e.massGrams,
                ]
                if let wm = waterMassPct(e.massGrams) { d["waterMassPct"] = wm }
                if let wv = waterVolPct(e.massGrams) { d["waterVolPct"] = wv }
                if let dp = dehydPct(e.massGrams) { d["dehydrationPct"] = dp }
                return d
            }
            var cObj: [String: Any] = [
                "label": container.label,
                "tareWeightGrams": container.tareWeightGrams,
                "readings": readingsArr,
            ]
            if entries.count >= 2, let w = wetMass, w > 0, let ow = originalWaterInGummies, ow > 0 {
                guard let first = entries.first, let last = entries.last else { return cObj }
                let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600.0
                if hours > 0 {
                    let df = ((w - first.massGrams) / ow) * 100.0
                    let dl = ((w - last.massGrams) / ow) * 100.0
                    cObj["avgDehydrationRatePctPerHr"] = (dl - df) / hours
                }
            }
            return cObj
        }
        root["dehydrationTracking"] = ["containers": containersJSON] as [String: Any]

        // FlavorReview
        root["flavorReview"] = [
            "rating": batch.flavorRating,
            "tags": flavorTagsArr,
            "notes": batch.flavorNotes,
        ] as [String: Any]

        // ColorReview
        root["colorReview"] = [
            "rating": batch.colorRating,
            "tags": colorTagsArr,
            "notes": batch.colorNotes,
        ] as [String: Any]

        // TextureReview
        root["textureReview"] = [
            "rating": batch.textureRating,
            "tags": textureTagsArr,
            "notes": batch.textureNotes,
        ] as [String: Any]

        // ProcessNotes
        root["processNotes"] = batch.processNotes

        // Serialize
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - Per-Section JSON Builders

    private func copyJSON(_ dict: [String: Any], label: String = "JSON") {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return }
        CMClipboard.copy(str)
        CMHaptic.success()
        copiedLabel = label
        copiedConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            copiedConfirmation = false
        }
    }

    private func batchConfigJSON() -> [String: Any] {
        let isoFmt = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "batchID": batch.batchID,
            "name": batch.name,
            "date": isoFmt.string(from: batch.date),
            "shape": batch.shape,
            "trayCount": batch.trayCount,
            "wellCount": batch.wellCount,
            "vBaseML": batch.vBaseML,
            "vMixML": batch.vMixML,
            "activeName": batch.activeName,
            "activeConcentration": batch.activeConcentration,
            "activeUnit": batch.activeUnit,
            "totalActive": batch.totalActive,
            "gelatinPercent": batch.gelatinPercent,
            "overageFactor": batch.overageFactor,
            "terpenePPM": batch.terpenePPM,
            "flavorOilVolumePercent": batch.flavorOilVolumePercent,
            "colorVolumePercent": batch.colorVolumePercent,
            "additionalActiveWaterML": batch.additionalActiveWaterML,
            "flavors": decodedFlavors.map { [
                "flavorID": $0.flavorID, "name": $0.name, "type": $0.type, "percent": $0.percent,
            ] as [String: Any] },
            "colors": decodedColors.map { [
                "name": $0.name, "percent": $0.percent,
            ] as [String: Any] },
        ]
        if batch.extraGummies > 0 {
            dict["extraGummies"] = batch.extraGummies
        }
        if batch.lsdUgPerTab > 0 {
            dict["lsdUgPerTab"] = batch.lsdUgPerTab
            dict["lsdTransferWaterML"] = batch.lsdTransferWaterML
        }
        return dict
    }

    private func batchOutputJSON() -> [String: Any] {
        var dict: [String: Any] = [
            "vMixML": batch.vMixML,
            "vBaseML": batch.vBaseML,
            "activeName": batch.activeName,
            "totalActive": batch.totalActive,
            "activeUnit": batch.activeUnit,
            "additionalActiveWaterML": batch.additionalActiveWaterML,
            "components": sortedComponents.map { [
                "sortOrder": $0.sortOrder, "label": $0.label,
                "massGrams": $0.massGrams, "volumeML": $0.volumeML,
                "displayUnit": $0.displayUnit, "group": $0.group,
                "category": $0.category as Any,
            ] as [String: Any] },
        ]
        if batch.activeName == "LSD" && batch.lsdUgPerTab > 0 {
            let tabsNeeded = Int(batch.totalActive / batch.lsdUgPerTab)
            let lsdInLiquid = batch.totalActive - (Double(tabsNeeded) * batch.lsdUgPerTab)
            let transferWater = batch.lsdTransferWaterML
            let keptVolume = batch.lsdUgPerTab > 0 ? (lsdInLiquid / batch.lsdUgPerTab) * transferWater : 0.0
            dict["lsd"] = [
                "ugPerTab": batch.lsdUgPerTab,
                "tabs": tabsNeeded,
                "lsdInLiquid_ug": lsdInLiquid,
                "totalTransferWater_mL": transferWater,
                "keptVolume_mL": keptVolume,
                "discardedVolume_mL": transferWater - keptVolume,
            ] as [String: Any]
        }
        return dict
    }

    // MARK: - Existing Helpers

    @ViewBuilder
    private func activationSubsections(items: [SavedBatchComponent]) -> some View {
        let order = ["Preservatives", "Colors", "Flavor Oils", "Terpenes"]
        ForEach(order, id: \.self) { cat in
            let catItems = items.filter { $0.category == cat }
            if !catItems.isEmpty {
                if cat != "Preservatives" {
                    HStack {
                        Text(cat).font(.subheadline).fontWeight(.bold).foregroundStyle(CMTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                }
                ForEach(catItems, id: \.label) { c in componentRow(c) }
            }
        }
        let uncategorised = items.filter { $0.category == nil }
        ForEach(uncategorised, id: \.label) { c in componentRow(c) }
    }

    private func componentRow(_ c: SavedBatchComponent) -> some View {
        HStack(spacing: 6) {
            Text(c.label).font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(String(format: "%.3f", c.massGrams))
                .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("g")
                .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 20, alignment: .leading)
            if c.displayUnit == "µL" {
                Text(String(format: "%.0f", c.volumeML * 1000.0))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 60, alignment: .trailing)
                Text("µL")
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 28, alignment: .leading)
            } else {
                Text(String(format: "%.3f", c.volumeML))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 60, alignment: .trailing)
                Text("mL")
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 28, alignment: .leading)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func groupSection(title: String, @ViewBuilder content: () -> AnyView) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).cmSubsectionTitle()
                Spacer()
            }
            .cmSubsectionPadding()
            content()
            Spacer().frame(height: 8)
        }
    }
}
// MARK: - Trash View

struct TrashView: View {
    @Query(sort: \SavedBatch.date, order: .reverse) private var allBatches: [SavedBatch]
    @Environment(\.modelContext) private var modelContext
    @Environment(SystemConfig.self) private var systemConfig
    @State private var showEmptyTrashAlert = false

    private var trashedBatches: [SavedBatch] {
        allBatches.filter { $0.isTrashed }
    }

    var body: some View {
        Group {
            if trashedBatches.isEmpty {
                ContentUnavailableView(
                    "Trash is Empty",
                    systemImage: "trash",
                    description: Text("Deleted batches will appear here.")
                )
            } else {
                List {
                    ForEach(trashedBatches) { batch in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                if !batch.batchID.isEmpty {
                                    Text(batch.batchID)
                                        .font(.caption).fontWeight(.bold)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(systemConfig.designAlert.opacity(0.15))
                                        .foregroundStyle(systemConfig.designAlert)
                                        .cornerRadius(4)
                                }
                                Text(batch.name).font(.headline).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                                Spacer()
                            }
                            HStack(spacing: 6) {
                                Text(batch.shape).font(.caption).foregroundStyle(CMTheme.textTertiary)
                                Text("·").font(.caption).foregroundStyle(CMTheme.textTertiary)
                                Text(batch.date, format: .dateTime.month(.abbreviated).day().year())
                                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                            }
                            if let trashed = batch.trashedDate {
                                Text("Trashed \(trashed, format: .dateTime.month(.abbreviated).day().hour().minute())")
                                    .font(.caption2).foregroundStyle(CMTheme.textTertiary)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                CMHaptic.medium()
                                withAnimation { modelContext.delete(batch) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                CMHaptic.light()
                                withAnimation {
                                    batch.isTrashed = false
                                    batch.trashedDate = nil
                                }
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(systemConfig.designTitle)
                        }
                    }
                }
            }
        }
        .navigationTitle("Trash")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !trashedBatches.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEmptyTrashAlert = true
                    } label: {
                        Text("Empty Trash")
                            .font(.subheadline)
                            .foregroundStyle(systemConfig.designAlert)
                    }
                }
            }
        }
        #endif
        .alert("Empty Trash?", isPresented: $showEmptyTrashAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                CMHaptic.medium()
                withAnimation {
                    for batch in trashedBatches {
                        modelContext.delete(batch)
                    }
                }
            }
        } message: {
            Text("This will permanently delete all \(trashedBatches.count) trashed batch\(trashedBatches.count == 1 ? "" : "es"). This cannot be undone.")
        }
    }
}

