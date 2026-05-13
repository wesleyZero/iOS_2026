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
            Text(batch.name).font(.headline)
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
    let batch: SavedBatch

    private var components: [SavedComponent] {
        guard let data = batch.componentsJSON.data(using: .utf8),
              let rows = try? JSONDecoder().decode([SavedComponent].self, from: data)
        else { return [] }
        return rows
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
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

                Divider().padding(.horizontal, 16)

                // Actives
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

                // Ingredient groups
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

                // Weight Measurements
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
                }
            }
        }
        .navigationTitle(batch.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Weight Measurements Section

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
        VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)

            measureSubsection("Input Mixtures")
            savedCalcRow("Gelatin Mix Added",         value: batch.calcMassGelatinAdded,         unit: "g")
            savedCalcRow("Sugar Mix Added",           value: batch.calcMassSugarAdded,           unit: "g")
            savedCalcRow("Activation Mix Added",      value: batch.calcMassActiveAdded,          unit: "g")

            measureSubsection("Final Mixture")
            savedCalcRow("Final Mixture in Beaker",   value: batch.calcMassFinalMixtureInBeaker, unit: "g")
            savedCalcRow("Final Mixture in Tray/s",   value: batch.calcMassMixTransferredToMold, unit: "g")
            savedCalcRow("Density of Final Mix",      value: batch.calcDensityFinalMix,          unit: "g/ml", decimals: 4)

            measureSubsection("Losses")
            savedCalcRow("Beaker Residue",            value: batch.calcMassBeakerResidue,        unit: "g")
            savedCalcRow("Syringe Residue",           value: batch.calcMassSyringeResidue,       unit: "g")
            savedCalcRow("Total Loss",                value: batch.calcMassTotalLoss,            unit: "g")
            savedCalcRow("Active Loss",               value: batch.calcActiveLoss,               unit: batch.activeUnit)

            measureSubsection("Gummies")
            savedCalcRow("Average Gummy Mass",        value: batch.calcMassPerGummyMold,         unit: "g")
            savedCalcRow("Average Gummy Volume",      value: batch.calcAverageGummyVolume,       unit: "mL", decimals: 3)
            savedCalcRow("Avg Gummy Active Dose",     value: batch.calcAverageGummyActiveDose,   unit: batch.activeUnit)

            Spacer().frame(height: 8)
        }
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

    private func savedCalcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.\(decimals)f", $0) } ?? "—")
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
