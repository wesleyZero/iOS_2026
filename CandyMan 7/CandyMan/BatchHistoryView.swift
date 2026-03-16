import SwiftUI
import SwiftData

struct BatchHistoryView: View {
    @Query(sort: \SavedBatch.date, order: .reverse) private var batches: [SavedBatch]
    @Environment(\.modelContext) private var modelContext
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        NavigationStack {
            Group {
                if batches.isEmpty {
                    ContentUnavailableView(
                        "No Saved Batches",
                        systemImage: "tray",
                        description: Text("Save a batch from the batch output screen.")
                    )
                } else {
                    List {
                        ForEach(batches) { batch in
                            NavigationLink(destination: BatchDetailView(batch: batch)) {
                                batchRow(batch)
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet { modelContext.delete(batches[i]) }
                        }
                    }
                }
            }
            .navigationTitle("Batch History")
            .keyboardDismissToolbar()
            #if os(iOS) || os(visionOS)
            .toolbar { EditButton() }
            #endif
        }
    }

    private func batchRow(_ batch: SavedBatch) -> some View {
        let oils = batch.flavors.filter { $0.type == "Flavor Oil" }.sorted { $0.percent > $1.percent }
        let sortedColors = batch.colors.sorted { $0.percent > $1.percent }

        return VStack(alignment: .leading, spacing: 3) {
            // Line 1: [ID] [Name]
            HStack(spacing: 6) {
                if !batch.batchID.isEmpty {
                    Text(batch.batchID)
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(systemConfig.accent.opacity(0.15))
                        .foregroundStyle(systemConfig.accent)
                        .cornerRadius(4)
                }
                Text(batch.name).font(.headline).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
                Spacer()
            }
            // Line 2: [Shape] · [Active] · [Concentration] · [Gummies]
            HStack(spacing: 6) {
                Text(batch.shape).font(.caption).foregroundStyle(CMTheme.textTertiary)
                Text("·").font(.caption).foregroundStyle(CMTheme.textTertiary)
                Text(batch.activeName).font(.caption).foregroundStyle(CMTheme.textTertiary)
                Text("·").font(.caption).foregroundStyle(CMTheme.textTertiary)
                Text(batch.calcAverageGummyActiveDose.map { String(format: "%.2f %@", $0, batch.activeUnit) } ?? String(format: "%.2f %@", batch.activeConcentration, batch.activeUnit))
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
                Text("·").font(.caption).foregroundStyle(CMTheme.textTertiary)
                Text("\(batch.wellCount) gummies")
                    .font(.caption).foregroundStyle(CMTheme.textTertiary)
            }
            // Line 3: [Colors] · [Oils]
            let segments: [String] = [
                sortedColors.map { $0.name }.joined(separator: ", "),
                oils.map { $0.name }.joined(separator: ", "),
            ].filter { !$0.isEmpty }
            if !segments.isEmpty {
                Text(segments.joined(separator: " · "))
                    .font(.caption2).foregroundStyle(CMTheme.textTertiary)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 4)
    }

}

// MARK: - Detail View

struct BatchDetailView: View {
    @Bindable var batch: SavedBatch
    @Environment(\.modelContext) private var modelContext
    @Environment(SystemConfig.self) private var systemConfig

    @State private var copiedConfirmation = false

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
            LazyVStack(spacing: 12) {
                // Header card
                headerSection.cardStyle()

                // User Inputs card
                userInputsSection.cardStyle()

                // Batch Output card (actives + ingredient groups)
                batchOutputCard.cardStyle()

                // Theoretical Calculations card
                BatchQuantitativeDataSection(batch: batch, copiedConfirmation: $copiedConfirmation).cardStyle()

                // Relative Data card
                BatchRelativeDataSection(batch: batch, copiedConfirmation: $copiedConfirmation).cardStyle()

                // Measurements + Calculations cards
                BatchMeasurementsSection(batch: batch, copiedConfirmation: $copiedConfirmation).cardStyle()
                BatchCalculationsSection(batch: batch, copiedConfirmation: $copiedConfirmation).cardStyle()

                // Dehydration Tracking card
                BatchDryWeightSection(batch: batch, copiedConfirmation: $copiedConfirmation).cardStyle()

                // Notes & Ratings card
                BatchNotesAndRatingsSection(batch: batch, copiedConfirmation: $copiedConfirmation).cardStyle()

                // Copy Data card
                copyDataSection.cardStyle()
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .navigationTitle(batch.name)
        .keyboardDismissToolbar()
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            if copiedConfirmation {
                Text("Copied to clipboard!")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                            .fill(CMTheme.success)
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: copiedConfirmation)
    }

    // MARK: - Batch Output Card

    private var batchOutputCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Batch Output").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f mL (+ overage)", batch.vMix_mL))
                        .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    Text(String(format: "%.1f mL", batch.vBase_mL))
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                }
                GlassCopyButton { copyJSON(batchOutputJSON()) }
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            ThemedDivider(indent: 16)
            ingredientGroupsSection
            activesSection
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                GlassCopyButton { copyJSON(headerJSON()) }
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 0)
            inputRow("Batch ID", value: batch.batchID.isEmpty ? "—" : batch.batchID)
            inputRow("Batch Name", value: batch.name)
            inputRow("Date", value: batch.date.formatted(.dateTime.month(.wide).day().year()))
            inputRow("Time", value: batch.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
        }
        .padding(.vertical, 8)
    }

    // MARK: - User Inputs

    private var userInputsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("User Inputs").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { copyJSON(userInputsJSON()) }
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            // Shape & Trays
            inputRow("Shape", value: batch.shape)
            inputRow("Trays", value: "\(batch.trayCount)")

            // Active
            inputRow("Active", value: batch.activeName)
            inputRow("Concentration", value: String(format: "%.2f %@ / gummy", batch.activeConcentration, batch.activeUnit))

            // Gelatin %
            inputRow("Gelatin %", value: String(format: "%.3f%%", batch.gelatinPercent))

            // Terpenes
            terpenesInputSection
            // Flavor Oils
            flavorOilsInputSection
            // Colors
            colorsInputSection

            Spacer().frame(height: 8)
        }
    }

    @ViewBuilder
    private var terpenesInputSection: some View {
        let terpenes = decodedFlavors.filter { $0.type == "Terpene" }
        if !terpenes.isEmpty {
            inputSubheader("Terpenes")
            inputRow("PPM", value: String(format: "%.1f", batch.terpenePPM))
            ForEach(terpenes.indices, id: \.self) { i in
                inputRow(terpenes[i].name, value: String(format: "%.0f%%", terpenes[i].percent))
            }
        }
    }

    @ViewBuilder
    private var flavorOilsInputSection: some View {
        let oils = decodedFlavors.filter { $0.type == "Flavor Oil" }
        if !oils.isEmpty {
            inputSubheader("Flavor Oils")
            inputRow("Volume %", value: String(format: "%.3f%%", batch.flavorOilVolumePercent))
            ForEach(oils.indices, id: \.self) { i in
                inputRow(oils[i].name, value: String(format: "%.0f%%", oils[i].percent))
            }
        }
    }

    @ViewBuilder
    private var colorsInputSection: some View {
        if !decodedColors.isEmpty {
            inputSubheader("Colors")
            inputRow("Volume %", value: String(format: "%.3f%%", batch.colorVolumePercent))
            ForEach(decodedColors.indices, id: \.self) { i in
                inputRow(decodedColors[i].name, value: String(format: "%.0f%%", decodedColors[i].percent))
            }
        }
    }

    private func inputRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func inputSubheader(_ title: String) -> some View {
        HStack {
            Text(title).font(.subheadline).fontWeight(.bold).foregroundStyle(CMTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
    }

    // MARK: - Actives

    private var activesSection: some View {
        groupSection(title: "Actives") {
            AnyView(
                HStack {
                    Text(batch.activeName).font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.2f %@", batch.totalActive, batch.activeUnit))
                        .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                }
                .padding(.horizontal, 20).padding(.vertical, 3)
            )
        }
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
            ThemedDivider(indent: 16)
            Button {
                CMHaptic.success()
                CMClipboard.copy(buildJSONString())
                copiedConfirmation = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    copiedConfirmation = false
                }
            } label: {
                Label("Copy Data to Clipboard", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(systemConfig.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(CMTheme.buttonRadius)
                    .font(.headline)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.vertical, 16)
        }
    }

    // MARK: - JSON Builder

    private func buildJSONString() -> String {
        let isoFmt = ISO8601DateFormatter()
        let isoDate: (Date) -> String = { isoFmt.string(from: $0) }

        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }

        let activeTotalMass   = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let activeTotalVol    = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gelatinTotalMass  = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gelatinTotalVol   = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sugarTotalMass    = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sugarTotalVol     = sugarItems.reduce(0.0) { $0 + $1.volume_mL }

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        let overageFactor        = batch.vBase_mL > 0 ? batch.vMix_mL / batch.vBase_mL : 1.0
        let targetVol            = batch.vBase_mL
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

        // Dehydration entries
        let dryWeightEntries = batch.dryWeightReadings.sorted { $0.timestamp < $1.timestamp }
        let wetMass: Double? = batch.wetGummyMass_g ?? batch.calcMassMixTransferredToMold ?? {
            let t = sortedComponents.reduce(0.0) { $0 + $1.mass_g }; return t > 0 ? t : nil
        }()
        let waterComponents = sortedComponents.filter { $0.label == "Water" || $0.label == "Activation Water" }
        let formulationWaterMass: Double? = waterComponents.isEmpty ? nil : waterComponents.reduce(0.0) { $0 + $1.mass_g }
        let theoreticalTotalMass = sortedComponents.reduce(0.0) { $0 + $1.mass_g }
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
        let totalVol = sortedComponents.reduce(0.0) { $0 + $1.volume_mL }
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
        let avgDehydRate: Double? = {
            guard dryWeightEntries.count >= 2, let w = wetMass, w > 0, let ow = originalWaterInGummies, ow > 0 else { return nil }
            let first = dryWeightEntries.first!; let last = dryWeightEntries.last!
            let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600.0
            guard hours > 0 else { return nil }
            let df = ((w - first.mass_g) / ow) * 100.0; let dl = ((w - last.mass_g) / ow) * 100.0
            return (dl - df) / hours
        }()

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
            "vBase_mL": batch.vBase_mL,
            "vMix_mL": batch.vMix_mL,
        ] as [String: Any]

        // UserInputs
        root["userInputs"] = [
            "activeName": batch.activeName,
            "activeConcentration": batch.activeConcentration,
            "activeUnit": batch.activeUnit,
            "totalActive": batch.totalActive,
            "gelatinPercent": batch.gelatinPercent,
            "terpenePPM": batch.terpenePPM,
            "flavorOilVolumePercent": batch.flavorOilVolumePercent,
            "colorVolumePercent": batch.colorVolumePercent,
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
        ] as [String: Any]

        // BatchOutput
        root["batchOutput"] = sortedComponents.map { [
            "sortOrder": $0.sortOrder,
            "label": $0.label,
            "mass_g": $0.mass_g,
            "volume_mL": $0.volume_mL,
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
                "activationMix": ["mass_g": activeTotalMass, "volume_mL": activeTotalVol],
                "gelatinMix": ["mass_g": gelatinTotalMass, "volume_mL": gelatinTotalVol],
                "sugarMix": ["mass_g": sugarTotalMass, "volume_mL": sugarTotalVol],
            ],
            "finalMix": [
                "withOverage": ["mass_g": finalMixMass, "volume_mL": finalMixVol],
                "withoutOverage": ["mass_g": finalMixMass / overageFactor, "volume_mL": finalMixVolNoOverage],
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
                "massPct": pctOf(c.mass_g, finalMixMass),
                "volumePct": pctOf(c.volume_mL, finalMixVol),
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
            mEntry("Molds Filled", batch.weightMoldsFilled, "#"),
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
            guard let av = batch.calcAverageGummyVolume, batch.wellCount > 0, batch.vBase_mL > 0 else { return nil }
            return av / (batch.vBase_mL / Double(batch.wellCount))
        }()
        root["calculations"] = [
            cEntry("Gelatin Mix Added", batch.calcMassGelatinAdded, "g"),
            cEntry("Sugar Mix Added", batch.calcMassSugarAdded, "g"),
            cEntry("Activation Mix Added", batch.calcMassActiveAdded, "g"),
            cEntry("Final Mixture in Beaker", batch.calcMassFinalMixtureInBeaker, "g"),
            cEntry("Final Mixture in Tray/s", batch.calcMassMixTransferredToMold, "g"),
            cEntry("Beaker Residue", batch.calcMassBeakerResidue, "g"),
            cEntry("Syringe Residue", batch.calcMassSyringeResidue, "g"),
            cEntry("Total Residue", batch.calcMassTotalLoss, "g"),
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

        // DehydrationTracking
        var dehydrationArr: [[String: Any]] = dryWeightEntries.map { e in
            var d: [String: Any] = [
                "timestamp": isoDate(e.timestamp),
                "mass_g": e.mass_g,
            ]
            if let wm = waterMassPct(e.mass_g) { d["waterMassPct"] = wm }
            if let wv = waterVolPct(e.mass_g) { d["waterVolPct"] = wv }
            if let dp = dehydPct(e.mass_g) { d["dehydrationPct"] = dp }
            return d
        }
        var dehydrationObj: [String: Any] = ["readings": dehydrationArr]
        if let rate = avgDehydRate {
            dehydrationObj["avgDehydrationRatePctPerHr"] = rate
        }
        root["dehydrationTracking"] = dehydrationObj

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

    private func copyJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return }
        CMClipboard.copy(str)
        CMHaptic.success()
        copiedConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copiedConfirmation = false
        }
    }

    private func headerJSON() -> [String: Any] {
        let isoFmt = ISO8601DateFormatter()
        return [
            "batchID": batch.batchID,
            "name": batch.name,
            "date": isoFmt.string(from: batch.date),
            "shape": batch.shape,
            "trayCount": batch.trayCount,
            "wellCount": batch.wellCount,
            "vBase_mL": batch.vBase_mL,
            "vMix_mL": batch.vMix_mL,
        ]
    }

    private func userInputsJSON() -> [String: Any] {
        [
            "activeName": batch.activeName,
            "activeConcentration": batch.activeConcentration,
            "activeUnit": batch.activeUnit,
            "totalActive": batch.totalActive,
            "gelatinPercent": batch.gelatinPercent,
            "terpenePPM": batch.terpenePPM,
            "flavorOilVolumePercent": batch.flavorOilVolumePercent,
            "colorVolumePercent": batch.colorVolumePercent,
            "flavors": decodedFlavors.map { [
                "flavorID": $0.flavorID, "name": $0.name, "type": $0.type, "percent": $0.percent,
            ] as [String: Any] },
            "colors": decodedColors.map { [
                "name": $0.name, "percent": $0.percent,
            ] as [String: Any] },
        ] as [String: Any]
    }

    private func batchOutputJSON() -> [String: Any] {
        [
            "vMix_mL": batch.vMix_mL,
            "vBase_mL": batch.vBase_mL,
            "activeName": batch.activeName,
            "totalActive": batch.totalActive,
            "activeUnit": batch.activeUnit,
            "components": sortedComponents.map { [
                "sortOrder": $0.sortOrder, "label": $0.label,
                "mass_g": $0.mass_g, "volume_mL": $0.volume_mL,
                "displayUnit": $0.displayUnit, "group": $0.group,
                "category": $0.category as Any,
            ] as [String: Any] },
        ] as [String: Any]
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
            Text(String(format: "%.3f", c.mass_g))
                .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("g")
                .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 20, alignment: .leading)
            if c.displayUnit == "µL" {
                Text(String(format: "%.0f", c.volume_mL * 1000.0))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 60, alignment: .trailing)
                Text("µL")
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 28, alignment: .leading)
            } else {
                Text(String(format: "%.3f", c.volume_mL))
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
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
            content()
            Spacer().frame(height: 8)
        }
    }
}
