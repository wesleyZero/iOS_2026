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
        let oils = batch.flavors.filter { $0.type == "Flavor Oil" }.sorted { $0.percent > $1.percent }
        let sortedColors = batch.colors.sorted { $0.percent > $1.percent }

        return VStack(alignment: .leading, spacing: 3) {
            // Line 1: [ID] [Name]
            HStack(spacing: 6) {
                if !batch.batchID.isEmpty {
                    Text(batch.batchID)
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(CMTheme.accent.opacity(0.15))
                        .foregroundStyle(CMTheme.accent)
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

    @State private var newDryMass: String = ""
    @State private var copiedConfirmation = false

    private var dryWeightEntries: [DryWeightReading] {
        batch.dryWeightReadings.sorted { $0.timestamp < $1.timestamp }
    }

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var decodedFlavors: [SavedBatchFlavor] {
        batch.flavors.sorted { $0.flavorID < $1.flavorID }
    }

    private var decodedColors: [SavedBatchColor] {
        batch.colors.sorted { $0.name < $1.name }
    }

    // MARK: - Dehydration calculations

    /// The wet mass of gummies = mass transferred to molds (measured), or total theoretical mass from components.
    private var wetMass: Double? {
        if let m = batch.wetGummyMass_g { return m }
        if let m = batch.calcMassMixTransferredToMold { return m }
        // Fall back to theoretical total mass from saved components
        let total = sortedComponents.reduce(0.0) { $0 + $1.mass_g }
        return total > 0 ? total : nil
    }

    /// Total theoretical mass of the batch from saved components.
    private var theoreticalTotalMass: Double {
        sortedComponents.reduce(0.0) { $0 + $1.mass_g }
    }

    /// Total water mass in the original formulation, extracted from saved components.
    /// Sums all components named "Water" or "Activation Water" across all mix groups.
    private var formulationWaterMass: Double? {
        let waterComponents = sortedComponents.filter {
            $0.label == "Water" || $0.label == "Activation Water"
        }
        guard !waterComponents.isEmpty else { return nil }
        return waterComponents.reduce(0.0) { $0 + $1.mass_g }
    }

    /// Water fraction in the formulation by mass = totalWater / totalMixMass.
    /// Uses measured final mixture mass if available, otherwise theoretical total.
    private var waterMassFraction: Double? {
        guard let totalWater = formulationWaterMass else { return nil }
        let totalMix = batch.calcMassFinalMixtureInBeaker ?? theoreticalTotalMass
        guard totalMix > 0 else { return nil }
        return totalWater / totalMix
    }

    /// Original water mass in the gummies (scaled by transfer losses).
    private var originalWaterInGummies: Double? {
        guard let wet = wetMass, let fraction = waterMassFraction else { return nil }
        return wet * fraction
    }

    /// % of gummy mass that is water (mass basis).
    private func waterMassPercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        guard waterMass >= 0 else { return nil }
        return (waterMass / wet) * 100.0
    }

    /// Estimated density from theoretical components: totalMass / totalVolume.
    private var estimatedDensity: Double {
        let totalMass = sortedComponents.reduce(0.0) { $0 + $1.mass_g }
        let totalVol = sortedComponents.reduce(0.0) { $0 + $1.volume_mL }
        return totalVol > 0 ? totalMass / totalVol : 1.0
    }

    /// % of gummy volume that is water (volume basis).
    /// Water volume = (wetMass - dryMass) / ρ_water.  Total volume = wetMass / ρ_mix.
    private func waterVolumePercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        guard waterMass >= 0 else { return nil }
        // Use measured density if available, otherwise estimate from theoretical components
        let density = batch.calcDensityFinalMix ?? estimatedDensity
        guard density > 0 else { return nil }
        let totalVol = wet / density          // mL
        let waterVol = waterMass / 1.0        // water density = 1 g/mL
        return (waterVol / totalVol) * 100.0
    }

    /// Percentage dehydration = mass removed / original water mass in gummies.
    private func dehydrationPercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, let origWater = originalWaterInGummies, origWater > 0 else { return nil }
        let massRemoved = wet - dryMass
        guard massRemoved >= 0 else { return nil }
        return (massRemoved / origWater) * 100.0
    }

    /// Average dehydration rate in %/hour across all dry weight entries.
    private var avgDehydrationRate: Double? {
        let entries = dryWeightEntries
        guard entries.count >= 2,
              let wet = wetMass, wet > 0,
              let origWater = originalWaterInGummies, origWater > 0 else { return nil }
        let first = entries.first!
        let last = entries.last!
        let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600.0
        guard hours > 0 else { return nil }
        let dehydFirst = ((wet - first.mass_g) / origWater) * 100.0
        let dehydLast  = ((wet - last.mass_g)  / origWater) * 100.0
        return (dehydLast - dehydFirst) / hours
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
                theoreticalCalculationsSection.cardStyle()

                // Relative Data card
                relativeDataSection.cardStyle()

                // Measurements + Calculations cards (if data exists)
                measurementsAndCalculations

                // Dehydration Tracking card
                dryWeightSection.cardStyle()

                // Notes & Ratings card
                notesAndRatingsSection.cardStyle()

                // Copy Data card
                copyDataSection.cardStyle()
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .navigationTitle(batch.name)
        .navigationBarTitleDisplayMode(.large)
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

    // MARK: - Quantitative Data

    @State private var validationExpanded = false

    private var theoreticalCalculationsSection: some View {
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

        let overageFactor    = batch.vBase_mL > 0 ? batch.vMix_mL / batch.vBase_mL : 1.0
        let targetVol        = batch.vBase_mL
        let volPerMold       = batch.wellCount > 0 ? targetVol / Double(batch.wellCount) : 0
        let volPerTray       = batch.trayCount > 0 ? targetVol / Double(batch.trayCount) : 0

        let finalMixVolNoOverage = overageFactor > 0 ? finalMixVol / overageFactor : finalMixVol
        let quantifiedError      = finalMixVolNoOverage - targetVol
        let relativeError        = targetVol > 0 ? (quantifiedError / targetVol) * 100.0 : 0.0

        return VStack(spacing: 0) {
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmExpand) { validationExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Quantitative Data").font(.headline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                            .rotationEffect(.degrees(validationExpanded ? -180 : 0))
                            .animation(.cmExpand, value: validationExpanded)
                    }
                }
                .buttonStyle(.plain)
                GlassCopyButton { copyJSON(quantitativeDataJSON()) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if validationExpanded {
                ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    validationSubheader("Target Volumes")
                    validationVolOnlyRow("Volume Per Mold", volume: volPerMold)
                    validationVolOnlyRow("Volume Per Tray", volume: volPerTray)
                    validationVolOnlyRow("Total Volume",    volume: targetVol, bold: true)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Active Mix Components")
                    validationComponentRows(activationItems)
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
                    validationCompRow("Final Mix (with overage)",    mass: finalMixMass,                        volume: finalMixVol)
                    validationCompRow("Final Mix (without overage)", mass: finalMixMass / overageFactor,         volume: finalMixVolNoOverage, bold: true)
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

    // MARK: - Validation Helpers

    private func validationSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text("mass (g)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol (mL)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    @ViewBuilder
    private func validationComponentRows(_ items: [SavedBatchComponent]) -> some View {
        ForEach(items.indices, id: \.self) { i in
            HStack {
                Text(items[i].label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", items[i].mass_g))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", items[i].volume_mL))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func validationTotalRow(mass: Double, volume: Double) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.3f", mass))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
        .background(CMTheme.totalRowBG)
    }

    private func validationCompRow(_ label: String, mass: Double, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", mass))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func validationVolOnlyRow(_ label: String, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("—")
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func validationErrorRow(_ label: String, value: String, highlight: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(highlight < 1.0 ? CMTheme.success : CMTheme.danger)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    // MARK: - Relative Data

    @State private var relativeDataExpanded: Bool = false

    private var relativeDataSection: some View {
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

        return VStack(spacing: 0) {
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmExpand) { relativeDataExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Relative Data").font(.headline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                            .rotationEffect(.degrees(relativeDataExpanded ? -180 : 0))
                            .animation(.cmExpand, value: relativeDataExpanded)
                    }
                }
                .buttonStyle(.plain)
                GlassCopyButton { copyJSON(relativeDataJSON()) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if relativeDataExpanded {
                ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    relativeSubheader("Active Mix Components")
                    relativeComponentRows(activationItems, totalMass: finalMixMass, totalVol: finalMixVol)
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
                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Final Mixture")
                    relativeRow("Final Mix", massPct: 100.0, volPct: 100.0, bold: true)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    customMetricsSubheader("Custom Metrics")
                    relativeRow("Goop Ratio",
                                massPct: gelatinTotalMass > 0 ? sugarTotalMass / gelatinTotalMass : 0,
                                volPct: gelatinTotalVol > 0 ? sugarTotalVol / gelatinTotalVol : 0)
                    Text("The goop ratio is defined as the total sugar mixture divided by the total gelatin mixture (water included in each mixture), in mass and volume units.")
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 16).padding(.top, 6)

                    Spacer().frame(height: 12)
                }
            }
        }
    }

    // MARK: - Relative Data Helpers

    private func pct(_ part: Double, of whole: Double) -> Double {
        whole > 0 ? (part / whole) * 100.0 : 0
    }

    private func customMetricsSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text("mass")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func relativeSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text("mass %")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol %")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    @ViewBuilder
    private func relativeComponentRows(_ items: [SavedBatchComponent], totalMass: Double, totalVol: Double) -> some View {
        ForEach(items.indices, id: \.self) { i in
            HStack {
                Text(items[i].label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", pct(items[i].mass_g, of: totalMass)))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", pct(items[i].volume_mL, of: totalVol)))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func relativeTotalRow(mass: Double, volume: Double, totalMass: Double, totalVol: Double) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.3f", pct(mass, of: totalMass)))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", pct(volume, of: totalVol)))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
        .background(CMTheme.totalRowBG)
    }

    private func relativeRow(_ label: String, massPct: Double, volPct: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", massPct))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volPct))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    // MARK: - Measurements + Calculations

    @ViewBuilder
    private var measurementsAndCalculations: some View {
        measurementsSection.cardStyle()
        calculationsSection.cardStyle()
    }

    // MARK: - Weight Measurements Section

    private var measurementsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Measurements").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { copyJSON(measurementsJSON()) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

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
                savedMoldsRow("Molds Filled",             value: batch.weightMoldsFilled)
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

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Calculations Section

    private var calculationsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { copyJSON(calculationsJSON()) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

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
                savedCalcRow("Total Residue",             value: batch.calcMassTotalLoss,            unit: "g")
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
        }
    }

    /// Overage for next batch = averageGummyVolume / volumePerWell
    private var savedOverageForNextBatch: Double? {
        guard let avgVol = batch.calcAverageGummyVolume,
              batch.wellCount > 0,
              batch.vBase_mL > 0 else { return nil }
        let volPerWell = batch.vBase_mL / Double(batch.wellCount)
        return avgVol / volPerWell
    }

    // MARK: - Dry Weight / Dehydration Section

    private var dryWeightSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Dehydration Tracking").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { copyJSON(dehydrationJSON()) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // Add new reading
            HStack(spacing: 8) {
                TextField("Dry mass (g)", text: $newDryMass)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .padding(10)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(CMTheme.fieldRadius)
                Button("Record") {
                    if let mass = Double(newDryMass), mass > 0 {
                        CMHaptic.success()
                        withAnimation(.cmSpring) {
                            batch.dryWeightReadings.append(
                                DryWeightReading(mass_g: mass, timestamp: .now)
                            )
                        }
                        newDryMass = ""
                    }
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(CMTheme.accent)
                .cornerRadius(CMTheme.buttonRadius)
                .disabled(Double(newDryMass) == nil)
                .opacity(Double(newDryMass) == nil ? 0.4 : 1.0)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            // Recorded entries table with per-entry water content
            if !dryWeightEntries.isEmpty {
                ThemedDivider(indent: 16)
                HStack(spacing: 4) {
                    Text("Timestamp").font(.caption2).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    Text("Mass").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 55, alignment: .trailing)
                    Text("H₂O mass%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 62, alignment: .trailing)
                    Text("H₂O vol%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 58, alignment: .trailing)
                    Text("Dehyd%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 2)

                ForEach(dryWeightEntries.indices, id: \.self) { i in
                    let entry = dryWeightEntries[i]
                    HStack(spacing: 4) {
                        Text(entryTimestampString(entry.timestamp))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text(String(format: "%.3f g", entry.mass_g))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                            .frame(width: 55, alignment: .trailing)
                        Text(waterMassPercent(dryMass: entry.mass_g).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 62, alignment: .trailing)
                        Text(waterVolumePercent(dryMass: entry.mass_g).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 58, alignment: .trailing)
                        Text(dehydrationPercent(dryMass: entry.mass_g).map { String(format: "%.1f%%", $0) } ?? "—")
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
            }

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Notes & Ratings Section

    private static let flavorTagOptions = ["Sweet", "Sour", "Bitter", "Fruity", "Earthy", "Floral", "Herbal", "Spicy", "Mild", "Strong"]
    private static let colorTagOptions = ["Vibrant", "Pale", "Opaque", "Translucent", "Even", "Streaky", "Muddy", "Bright"]
    private static let textureTagOptions = ["Chewy", "Hard", "Soft", "Sticky", "Gummy", "Rubbery", "Brittle", "Smooth", "Grainy", "Firm"]

    private var notesAndRatingsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Notes & Ratings").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { copyJSON(notesAndRatingsJSON()) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

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
                sectionHeader("Color Tags")
                tagRow(options: Self.colorTagOptions, selection: $batch.colorTags)
                sectionHeader("Color Notes")
                TextEditor(text: $batch.colorNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(CMTheme.textPrimary)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(8)
                    .padding(.horizontal, 16).padding(.bottom, 10)
                sectionHeader("Color Rating")
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
    }

    // MARK: - Copy Data Section

    private var copyDataSection: some View {
        VStack(spacing: 0) {
            ThemedDivider(indent: 16)
            Button {
                CMHaptic.success()
                UIPasteboard.general.string = buildJSONString()
                copiedConfirmation = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    copiedConfirmation = false
                }
            } label: {
                Label("Copy Data to Clipboard", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CMTheme.accent)
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
            mEntry("Molds Filled", batch.weightMoldsFilled, "molds"),
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
            cEntry("Overage for Next Batch", savedOverageForNextBatch, ""),
        ]

        // DehydrationTracking
        var dehydrationArr: [[String: Any]] = dryWeightEntries.map { e in
            var d: [String: Any] = [
                "timestamp": isoDate(e.timestamp),
                "mass_g": e.mass_g,
            ]
            if let wm = waterMassPercent(dryMass: e.mass_g) { d["waterMassPct"] = wm }
            if let wv = waterVolumePercent(dryMass: e.mass_g) { d["waterVolPct"] = wv }
            if let dp = dehydrationPercent(dryMass: e.mass_g) { d["dehydrationPct"] = dp }
            return d
        }
        var dehydrationObj: [String: Any] = ["readings": dehydrationArr]
        if let rate = avgDehydrationRate {
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
        UIPasteboard.general.string = str
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

    private func quantitativeDataJSON() -> [String: Any] {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }
        let aTM = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let aTV = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gTM = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gTV = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sTM = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sTV = sugarItems.reduce(0.0) { $0 + $1.volume_mL }
        let fMM = aTM + gTM + sTM; let fMV = aTV + gTV + sTV
        let of = batch.vBase_mL > 0 ? batch.vMix_mL / batch.vBase_mL : 1.0
        let tv = batch.vBase_mL
        let fMVno = of > 0 ? fMV / of : fMV
        let qErr = fMVno - tv
        let rErr = tv > 0 ? (qErr / tv) * 100.0 : 0.0
        return [
            "targetVolumes": ["volumePerMold_mL": batch.wellCount > 0 ? tv / Double(batch.wellCount) : 0, "volumePerTray_mL": batch.trayCount > 0 ? tv / Double(batch.trayCount) : 0, "totalTargetVolume_mL": tv],
            "mixTotals": ["activationMix": ["mass_g": aTM, "volume_mL": aTV], "gelatinMix": ["mass_g": gTM, "volume_mL": gTV], "sugarMix": ["mass_g": sTM, "volume_mL": sTV]],
            "finalMix": ["withOverage": ["mass_g": fMM, "volume_mL": fMV], "withoutOverage": ["mass_g": fMM / of, "volume_mL": fMVno]],
            "error": ["quantifiedError_mL": qErr, "relativeErrorPct": rErr],
        ] as [String: Any]
    }

    private func relativeDataJSON() -> [String: Any] {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }
        let aTM = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let aTV = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gTM = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gTV = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sTM = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sTV = sugarItems.reduce(0.0) { $0 + $1.volume_mL }
        let fMM = aTM + gTM + sTM; let fMV = aTV + gTV + sTV
        func p(_ part: Double, _ whole: Double) -> Double { whole > 0 ? (part / whole) * 100.0 : 0 }
        return [
            "components": sortedComponents.map { ["label": $0.label, "group": $0.group, "massPct": p($0.mass_g, fMM), "volumePct": p($0.volume_mL, fMV)] as [String: Any] },
            "mixTotals": ["activationMix": ["massPct": p(aTM, fMM), "volumePct": p(aTV, fMV)], "gelatinMix": ["massPct": p(gTM, fMM), "volumePct": p(gTV, fMV)], "sugarMix": ["massPct": p(sTM, fMM), "volumePct": p(sTV, fMV)]],
            "goopRatio": ["mass": gTM > 0 ? sTM / gTM : 0, "volume": gTV > 0 ? sTV / gTV : 0],
        ] as [String: Any]
    }

    private func measurementsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "initialMass": ["beakerEmpty": opt(batch.weightBeakerEmpty)],
            "gelatinMixture": ["beakerPlusGelatin": opt(batch.weightBeakerPlusGelatin)],
            "sugarMixture": ["substratePlusSugar": opt(batch.weightBeakerPlusSugar)],
            "activationMixture": ["substratePlusActivation": opt(batch.weightBeakerPlusActive)],
            "transferToMold": ["syringeClean": opt(batch.weightSyringeEmpty), "syringePlusMix": opt(batch.weightSyringeWithMix), "syringeMixVol_mL": opt(batch.volumeSyringeGummyMix), "syringeResidue": opt(batch.weightSyringeResidue), "beakerResidue": opt(batch.weightBeakerResidue), "moldsFilled": opt(batch.weightMoldsFilled)],
            "densities": [
                "sugarMix": ["syringeClean": opt(batch.densitySyringeCleanSugar), "syringePlusMass": opt(batch.densitySyringePlusSugarMass), "syringePlusVol": opt(batch.densitySyringePlusSugarVol)],
                "gelatinMix": ["syringeClean": opt(batch.densitySyringeCleanGelatin), "syringePlusMass": opt(batch.densitySyringePlusGelatinMass), "syringePlusVol": opt(batch.densitySyringePlusGelatinVol)],
                "activationMix": ["syringeClean": opt(batch.densitySyringeCleanActive), "syringePlusMass": opt(batch.densitySyringePlusActiveMass), "syringePlusVol": opt(batch.densitySyringePlusActiveVol)],
            ],
        ] as [String: Any]
    }

    private func calculationsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "inputMixtures": ["gelatinMixAdded": opt(batch.calcMassGelatinAdded), "sugarMixAdded": opt(batch.calcMassSugarAdded), "activationMixAdded": opt(batch.calcMassActiveAdded)],
            "finalMixture": ["inBeaker": opt(batch.calcMassFinalMixtureInBeaker), "inTrays": opt(batch.calcMassMixTransferredToMold)],
            "losses": ["beakerResidue": opt(batch.calcMassBeakerResidue), "syringeResidue": opt(batch.calcMassSyringeResidue), "totalResidue": opt(batch.calcMassTotalLoss), "lostActive": opt(batch.calcActiveLoss)],
            "densities": ["sugarMix": opt(batch.calcSugarMixDensity), "gelatinMix": opt(batch.calcGelatinMixDensity), "activationMix": opt(batch.calcActiveMixDensity), "gummyMixture": opt(batch.calcDensityFinalMix)],
            "gummies": ["avgMass_g": opt(batch.calcMassPerGummyMold), "avgVolume_mL": opt(batch.calcAverageGummyVolume), "avgActiveDose": opt(batch.calcAverageGummyActiveDose)],
            "overage": ["overageForNextBatch": opt(savedOverageForNextBatch)],
        ] as [String: Any]
    }

    private func dehydrationJSON() -> [String: Any] {
        let isoFmt = ISO8601DateFormatter()
        var obj: [String: Any] = [
            "readings": dryWeightEntries.map { e in
                var d: [String: Any] = ["timestamp": isoFmt.string(from: e.timestamp), "mass_g": e.mass_g]
                if let wm = waterMassPercent(dryMass: e.mass_g) { d["waterMassPct"] = wm }
                if let wv = waterVolumePercent(dryMass: e.mass_g) { d["waterVolPct"] = wv }
                if let dp = dehydrationPercent(dryMass: e.mass_g) { d["dehydrationPct"] = dp }
                return d
            }
        ]
        if let rate = avgDehydrationRate { obj["avgDehydrationRatePctPerHr"] = rate }
        return obj
    }

    private func notesAndRatingsJSON() -> [String: Any] {
        func tagsArr(_ s: String) -> [String] { s.isEmpty ? [] : s.split(separator: ",").map { String($0) } }
        return [
            "flavor": ["rating": batch.flavorRating, "tags": tagsArr(batch.flavorTags), "notes": batch.flavorNotes] as [String: Any],
            "color": ["rating": batch.colorRating, "tags": tagsArr(batch.colorTags), "notes": batch.colorNotes] as [String: Any],
            "texture": ["rating": batch.textureRating, "tags": tagsArr(batch.textureTags), "notes": batch.textureNotes] as [String: Any],
            "processNotes": batch.processNotes,
        ] as [String: Any]
    }

    private func entryTimestampString(_ date: Date) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let day = cal.component(.day, from: date)
        let year = cal.component(.year, from: date)
        let monthName = date.formatted(.dateTime.month(.wide))
        return String(format: "%02d:%02d, %@ %d, %d", h, m, monthName, day, year)
    }

    // MARK: - Row Helpers

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
                                .fill(isSelected ? CMTheme.accent.opacity(0.25) : CMTheme.chipBG)
                        )
                        .foregroundStyle(isSelected ? CMTheme.accent : CMTheme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                                .stroke(isSelected ? CMTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
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
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.leading)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 50)
                .padding(8)
                .background(CMTheme.fieldBG)
                .cornerRadius(CMTheme.fieldRadius)
                .onChange(of: value.wrappedValue) { _, newVal in
                    value.wrappedValue = min(max(newVal, 0), 100)
                }
            Text("/ 100")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)
    }

    private func measureSubsection(_ title: String) -> some View {
        HStack {
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 2)
    }

    private func savedWeightRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("g").font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedVolumeRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("mL").font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedMoldsRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("molds").font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedCalcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.\(decimals)f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(unit)
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
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

