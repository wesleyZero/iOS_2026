import SwiftUI
import SwiftData

struct BatchHistoryView: View {
    @Query(sort: \SavedBatch.date, order: .reverse) private var batches: [SavedBatch]
    @Environment(\.modelContext) private var modelContext

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
            .toolbar { EditButton() }
        }
    }

    private func batchRow(_ batch: SavedBatch) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(batch.batchID)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Text(batch.name).font(.headline)
            }
            HStack(spacing: 12) {
                Label("\(batch.trayCount) tray\(batch.trayCount == 1 ? "" : "s") · \(batch.shape)", systemImage: "square.grid.2x2")
                    .font(.caption).foregroundStyle(.secondary)
                Label(String(format: "%.1f mL", batch.vMix_mL), systemImage: "drop")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(batch.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct BatchDetailView: View {
    @Bindable var batch: SavedBatch
    @Environment(\.modelContext) private var modelContext

    // Dehydration input state
    @State private var newDehydrationMass: Double?
    @State private var showAddDehydration = false

    // Post-save confirmation
    @State private var showSaveConfirmation = false

    // CSV sharing
    @State private var csvURL: URL?

    private var components: [SavedComponent] {
        guard let data = batch.componentsJSON.data(using: .utf8),
              let rows = try? JSONDecoder().decode([SavedComponent].self, from: data)
        else { return [] }
        return rows
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────
                headerSection

                Divider().padding(.horizontal, 16)

                // ── Actives ───────────────────────────────────
                groupSection(title: "Actives") {
                    AnyView(
                        HStack {
                            Text(batch.activeName).font(.system(size: 13, design: .monospaced))
                            Spacer()
                            Text(String(format: "%.2f %@", batch.totalActive, batch.activeUnit))
                                .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 3)
                    )
                }

                Divider().padding(.horizontal, 16)

                // ── Ingredient groups ─────────────────────────
                let groups = ["Activation Mix", "Gelatin Mix", "Sugar Mix"]
                ForEach(groups, id: \.self) { group in
                    let items = components.filter { $0.group == group }
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
                        Divider().padding(.horizontal, 16)
                    }
                }

                // ── Measurements ──────────────────────────────
                let hasAnyMeasurement = batch.weightBeakerEmpty != nil
                    || batch.weightBeakerPlusGelatin != nil
                    || batch.weightBeakerPlusSugar != nil
                    || batch.weightBeakerPlusActive != nil
                    || batch.weightBeakerResidue != nil
                    || batch.weightSyringeEmpty != nil
                    || batch.weightSyringeWithMix != nil
                    || batch.volumeSyringeGummyMix != nil
                    || batch.weightSyringeResidue != nil
                    || batch.weightMoldsFilled != nil
                if hasAnyMeasurement {
                    measurementsSection
                    Divider().padding(.horizontal, 16)
                    calculationsSection
                    Divider().padding(.horizontal, 16)
                }

                // ── Dehydration ───────────────────────────────
                dehydrationSection
                Divider().padding(.horizontal, 16)

                // ── Notes & Ratings ───────────────────────────
                flavorNotesSection
                Divider().padding(.horizontal, 16)
                colorNotesSection
                Divider().padding(.horizontal, 16)
                textureNotesSection
                Divider().padding(.horizontal, 16)
                processNotesSection
                Divider().padding(.horizontal, 16)

                // ── Save & Share ──────────────────────────────
                saveAndShareSection
            }
        }
        .navigationTitle("[\(batch.batchID)] \(batch.name)")
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(batch.batchID)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                Text(batch.date.formatted(date: .long, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(batch.trayCount) tray\(batch.trayCount == 1 ? "" : "s") · \(batch.shape) · \(batch.wellCount) wells")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f mL (with overage)", batch.vMix_mL))
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(String(format: "%.1f mL (target)", batch.vBase_mL))
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Measurements Section

    private var measurementsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Measurements").font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("g").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            measureSubsection("Initial mass of container")
            savedWeightRow("Beaker (Empty)",          value: batch.weightBeakerEmpty)

            measureSubsection("Add gelatin mixture")
            savedWeightRow("Beaker + Gelatin Mix",    value: batch.weightBeakerPlusGelatin)

            measureSubsection("Add sugar mixture")
            savedWeightRow("Substrate + Sugar Mix",   value: batch.weightBeakerPlusSugar)

            measureSubsection("Add activation mixture")
            savedWeightRow("Substrate + Activation Mix", value: batch.weightBeakerPlusActive)

            measureSubsection("Transfer to mold")
            savedWeightRow("Beaker + Residue",        value: batch.weightBeakerResidue)
            savedWeightRow("Syringe (Clean)",         value: batch.weightSyringeEmpty)
            savedWeightRow("Syringe + Gummy Mix",     value: batch.weightSyringeWithMix)
            savedVolumeRow("Syringe Gummy Mix Vol",   value: batch.volumeSyringeGummyMix)
            savedWeightRow("Syringe + Residue",       value: batch.weightSyringeResidue)
            savedMoldsRow("Molds Filled",             value: batch.weightMoldsFilled)

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Calculations Section

    private var calculationsSection: some View {
        let bDP = batch.savedBeakerDP
        let sDP = batch.savedSyringeDP
        let mDP = batch.savedMixedDP
        let aDP = batch.savedAllDP

        return VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            measureSubsection("Input Mixtures")
            savedCalcRow("Gelatin Mix Added",         value: batch.calcMassGelatinAdded,         unit: "g",    dp: bDP)
            savedCalcRow("Sugar Mix Added",           value: batch.calcMassSugarAdded,           unit: "g",    dp: bDP)
            savedCalcRow("Activation Mix Added",      value: batch.calcMassActiveAdded,          unit: "g",    dp: bDP)

            measureSubsection("Final Mixture")
            savedCalcRow("Final Mixture in Beaker",   value: batch.calcMassFinalMixtureInBeaker, unit: "g",    dp: bDP)
            savedCalcRow("Final Mixture in Tray/s",   value: batch.calcMassMixTransferredToMold, unit: "g",    dp: mDP)
            savedCalcRow("Density of Final Mix",      value: batch.calcDensityFinalMix,          unit: "g/ml", dp: aDP + 1)

            measureSubsection("Losses")
            savedCalcRow("Beaker Residue",            value: batch.calcMassBeakerResidue,        unit: "g",    dp: bDP)
            savedCalcRow("Syringe Residue",           value: batch.calcMassSyringeResidue,       unit: "g",    dp: sDP)
            savedCalcRow("Total Loss",                value: batch.calcMassTotalLoss,            unit: "g",    dp: mDP)
            savedCalcRow("Active Loss",               value: batch.calcActiveLoss,               unit: batch.activeUnit, dp: mDP)

            measureSubsection("Gummies")
            savedCalcRow("Average Gummy Mass",        value: batch.calcMassPerGummyMold,         unit: "g",    dp: mDP)
            savedCalcRow("Average Gummy Volume",      value: batch.calcAverageGummyVolume,       unit: "mL",   dp: aDP + 1)
            savedCalcRow("Avg Gummy Active Dose",     value: batch.calcAverageGummyActiveDose,   unit: batch.activeUnit, dp: mDP)

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Dehydration Section

    private var dehydrationSection: some View {
        let entries = batch.dehydrationEntries
        let wetMass = batch.wetMassPerGummy
        // First entry is the reference "initial dry" weight for water calculations
        let firstEntry = entries.first

        return VStack(spacing: 0) {
            HStack {
                Text("Dehydration").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            // Water content info (if we have wet mass and at least one dry weight)
            if let wet = wetMass, let first = firstEntry {
                let waterMass = wet - first.mass_g
                let waterMassPct = (waterMass / wet) * 100.0
                let waterVol = waterMass / SubstanceDensity.water.gPerML
                let gummyVol = batch.calcAverageGummyVolume ?? 0
                let waterVolPct = gummyVol > 0 ? (waterVol / gummyVol) * 100.0 : 0

                measureSubsection("Water Content (from first dry weight)")
                savedCalcRow("Wet Mass / Gummy",     value: wet,          unit: "g",  dp: batch.savedMixedDP)
                savedCalcRow("Dry Mass / Gummy",     value: first.mass_g, unit: "g",  dp: batch.savedMixedDP)
                savedCalcRow("Water Mass %",         value: waterMassPct, unit: "%",  dp: 1)
                if gummyVol > 0 {
                    savedCalcRow("Water Volume %",   value: waterVolPct,  unit: "%",  dp: 1)
                }
            }

            // Dehydration entries table
            if !entries.isEmpty {
                measureSubsection("Dehydration Log")

                // Column headers
                HStack(spacing: 8) {
                    Text("Date").font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Mass (g)").font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                    if let wet = wetMass, let first = entries.first {
                        let waterOrig = wet - first.mass_g
                        if waterOrig > 0 {
                            Text("Dehyd %").font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    Text("").frame(width: 24) // delete button space
                }
                .padding(.horizontal, 20).padding(.vertical, 4)

                ForEach(entries) { entry in
                    HStack(spacing: 8) {
                        Text(entry.formattedDate)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.3f", entry.mass_g))
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 70, alignment: .trailing)
                        if let wet = wetMass, let first = entries.first {
                            let waterOrig = wet - first.mass_g
                            if waterOrig > 0 {
                                let massLost = first.mass_g - entry.mass_g
                                let pct = (massLost / waterOrig) * 100.0
                                Text(String(format: "%.1f%%", pct))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(pct > 0 ? .blue : .secondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                        Button {
                            batch.removeDehydrationEntry(id: entry.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 24)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 3)
                }

                // Average dehydration rate
                if entries.count >= 2, let wet = wetMass, let first = entries.first {
                    let waterOrig = wet - first.mass_g
                    if waterOrig > 0 {
                        let rate = batch.averageDehydrationRate(initialDryMass: first.mass_g)
                        if let r = rate {
                            Divider().padding(.horizontal, 20).padding(.vertical, 4)
                            HStack {
                                Text("Avg Dehydration Rate")
                                    .font(.system(size: 12, design: .monospaced)).fontWeight(.semibold)
                                Spacer()
                                Text(String(format: "%.3f %%/hr", r))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.horizontal, 20).padding(.vertical, 4)
                        }
                    }
                }
            }

            // Add dehydration entry
            Divider().padding(.horizontal, 16).padding(.top, 4)

            HStack(spacing: 8) {
                Text("Add dry weight")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                Spacer()
                TextField("0.000", value: $newDehydrationMass, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: 80)
                Text("g").font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
                Button {
                    guard let mass = newDehydrationMass, mass > 0 else { return }
                    batch.addDehydrationEntry(DehydrationEntry(mass_g: mass, date: .now))
                    newDehydrationMass = nil
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }
    }

    // MARK: - Notes & Ratings Sections

    private var flavorNotesSection: some View {
        notesAndRatingSection(
            title: "Flavor Notes",
            notes: $batch.flavorNotes,
            rating: Binding(
                get: { batch.flavorRating ?? 50 },
                set: { batch.flavorRating = $0 }
            ),
            hasRating: batch.flavorRating != nil,
            onEnableRating: { if batch.flavorRating == nil { batch.flavorRating = 50 } }
        )
    }

    private var colorNotesSection: some View {
        notesAndRatingSection(
            title: "Color Notes",
            notes: $batch.colorNotes,
            rating: Binding(
                get: { batch.colorRating ?? 50 },
                set: { batch.colorRating = $0 }
            ),
            hasRating: batch.colorRating != nil,
            onEnableRating: { if batch.colorRating == nil { batch.colorRating = 50 } }
        )
    }

    private var textureNotesSection: some View {
        notesAndRatingSection(
            title: "Texture Notes",
            notes: $batch.textureNotes,
            rating: Binding(
                get: { batch.textureRating ?? 50 },
                set: { batch.textureRating = $0 }
            ),
            hasRating: batch.textureRating != nil,
            onEnableRating: { if batch.textureRating == nil { batch.textureRating = 50 } }
        )
    }

    private func notesAndRatingSection(
        title: String,
        notes: Binding<String>,
        rating: Binding<Int>,
        hasRating: Bool,
        onEnableRating: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            TextEditor(text: notes)
                .font(.system(size: 13))
                .frame(minHeight: 60, maxHeight: 120)
                .padding(.horizontal, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal, 16).padding(.vertical, 4)

            // Rating
            let ratingTitle = title.replacingOccurrences(of: " Notes", with: " Rating")
            HStack {
                Text(ratingTitle).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                if !hasRating {
                    Button("Tap to rate") {
                        onEnableRating()
                    }
                    .font(.caption).foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16).padding(.top, 6)

            if hasRating {
                HStack(spacing: 8) {
                    TextField(
                        "0–100",
                        text: Binding(
                            get: { "\(rating.wrappedValue)" },
                            set: { newValue in
                                if let val = Int(newValue) {
                                    rating.wrappedValue = min(max(val, 0), 100)
                                } else if newValue.isEmpty {
                                    rating.wrappedValue = 0
                                }
                            }
                        )
                    )
                    .keyboardType(.numberPad)
                    .font(.system(size: 15, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)

                    Text("/ 100")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
            }

            Spacer().frame(height: 6)
        }
    }

    private var processNotesSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Process Notes").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            TextEditor(text: $batch.processNotes)
                .font(.system(size: 13))
                .frame(minHeight: 80, maxHeight: 150)
                .padding(.horizontal, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal, 16).padding(.vertical, 4)

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Save & Share

    private var saveAndShareSection: some View {
        VStack(spacing: 10) {
            // Save button
            Button {
                batch.postSaveCompleted = true
                // Force SwiftData to persist by triggering a dummy mutation
                try? modelContext.save()
                showSaveConfirmation = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showSaveConfirmation = false
                }
            } label: {
                Label("Save Batch Data", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
            .padding(.horizontal, 16)

            if showSaveConfirmation {
                Text("Saved!")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            // Share CSV button (always available once batch exists)
            if batch.postSaveCompleted {
                ShareLink(item: generateCSVFile(), preview: SharePreview("Batch \(batch.batchID) Data", image: Image(systemName: "doc.text"))) {
                    Label("Share Data (CSV)", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .cornerRadius(12)
                        .font(.headline)
                }
                .padding(.horizontal, 16)
            }

            Spacer().frame(height: 20)
        }
        .padding(.top, 8)
    }

    private func generateCSVFile() -> URL {
        let csv = batch.generateCSV()
        let filename = "CandyMan_\(batch.batchID)_\(batch.name.replacingOccurrences(of: " ", with: "_")).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Row Helpers

    private func measureSubsection(_ title: String) -> some View {
        HStack {
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 2)
    }

    private func savedWeightRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? .tertiary : .secondary)
            Text("g").font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedVolumeRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? .tertiary : .secondary)
            Text("mL").font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedMoldsRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? .tertiary : .secondary)
            Text("molds").font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedCalcRow(_ label: String, value: Double?, unit: String, dp: Int) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.\(dp)f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? .tertiary : .primary)
            Text(unit)
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    // MARK: - Existing Helpers

    @ViewBuilder
    private func activationSubsections(items: [SavedComponent]) -> some View {
        let order = ["Preservatives", "Colors", "Flavor Oils", "Terpenes"]
        ForEach(order, id: \.self) { cat in
            let catItems = items.filter { $0.category == cat }
            if !catItems.isEmpty {
                HStack {
                    Text(cat).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
                ForEach(catItems, id: \.label) { c in componentRow(c) }
            }
        }
        let uncategorised = items.filter { $0.category == nil }
        ForEach(uncategorised, id: \.label) { c in componentRow(c) }
    }

    private func componentRow(_ c: SavedComponent) -> some View {
        HStack(spacing: 6) {
            Text(c.label).font(.system(size: 13, design: .monospaced)).lineLimit(1)
            Spacer()
            if c.displayUnit == "µL" {
                Text(String(format: "%.0f µL", c.volume_mL * 1000.0))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            } else if c.displayUnit == "g" {
                Text(String(format: "%.3f g", c.mass_g))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            } else {
                Text(String(format: "%.3f mL", c.volume_mL))
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func groupSection(title: String, @ViewBuilder content: () -> AnyView) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
            content()
            Spacer().frame(height: 8)
        }
    }
}
