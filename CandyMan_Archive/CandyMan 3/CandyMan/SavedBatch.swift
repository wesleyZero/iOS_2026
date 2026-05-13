import Foundation
import SwiftData

@Model
class SavedBatch {
    var name: String
    var date: Date
    var batchID: String = "—"

    // Shape / size
    var shape: String
    var trayCount: Int
    var wellCount: Int

    // Volumes
    var vBase_mL: Double
    var vMix_mL: Double

    // Active
    var activeName: String
    var activeConcentration: Double
    var activeUnit: String
    var totalActive: Double

    // Gelatin
    var gelatinPercent: Double

    // Flavors — stored as JSON string
    var flavorsJSON: String

    // Snapshot of all ingredient rows for display
    var componentsJSON: String

    // Weight measurements (raw inputs)
    var weightBeakerEmpty: Double?
    var weightBeakerPlusGelatin: Double?
    var weightBeakerPlusSugar: Double?
    var weightBeakerPlusActive: Double?
    var weightBeakerResidue: Double?
    var weightSyringeEmpty: Double?
    var weightSyringeResidue: Double?
    var weightSyringeWithMix: Double?
    var volumeSyringeGummyMix: Double?
    var weightMoldsFilled: Double?

    // Calculated outputs from measurements
    var calcMassGelatinAdded: Double?
    var calcMassSugarAdded: Double?
    var calcMassActiveAdded: Double?
    var calcMassFinalMixtureInBeaker: Double?
    var calcMassBeakerResidue: Double?
    var calcMassSyringeResidue: Double?
    var calcMassTotalLoss: Double?
    var calcActiveLoss: Double?
    var calcMassMixTransferredToMold: Double?
    var calcMassPerGummyMold: Double?
    var calcDensityFinalMix: Double?
    var calcAverageGummyVolume: Double?
    var calcAverageGummyActiveDose: Double?

    // Per-measurement resolutions (stored at save time)
    var resBeakerEmpty: Double = 0.001
    var resBeakerPlusGelatin: Double = 0.001
    var resSubstratePlusSugar: Double = 0.001
    var resSubstratePlusActivation: Double = 0.001
    var resBeakerPlusResidue: Double = 0.001
    var resSyringeClean: Double = 0.001
    var resSyringePlusGummyMix: Double = 0.001
    var resSyringeResidue: Double = 0.001
    var resSyringeVolume: Double = 0.001
    var resMoldsFilled: Double = 0.1

    // Dehydration tracking
    var dehydrationEntriesJSON: String = "[]"

    // Notes & Ratings
    var flavorNotes: String = ""
    var flavorRating: Int?
    var colorNotes: String = ""
    var colorRating: Int?
    var textureNotes: String = ""
    var textureRating: Int?
    var processNotes: String = ""

    // Whether post-save data has been persisted
    var postSaveCompleted: Bool = false

    init(
        name: String,
        batchID: String = "—",
        date: Date = .now,
        shape: String,
        trayCount: Int,
        wellCount: Int,
        vBase_mL: Double,
        vMix_mL: Double,
        activeName: String,
        activeConcentration: Double,
        activeUnit: String,
        totalActive: Double,
        gelatinPercent: Double,
        flavorsJSON: String,
        componentsJSON: String,
        weightBeakerEmpty: Double? = nil,
        weightBeakerPlusGelatin: Double? = nil,
        weightBeakerPlusSugar: Double? = nil,
        weightBeakerPlusActive: Double? = nil,
        weightBeakerResidue: Double? = nil,
        weightSyringeEmpty: Double? = nil,
        weightSyringeWithMix: Double? = nil,
        volumeSyringeGummyMix: Double? = nil,
        weightSyringeResidue: Double? = nil,
        weightMoldsFilled: Double? = nil,
        calcMassGelatinAdded: Double? = nil,
        calcMassSugarAdded: Double? = nil,
        calcMassActiveAdded: Double? = nil,
        calcMassFinalMixtureInBeaker: Double? = nil,
        calcMassBeakerResidue: Double? = nil,
        calcMassSyringeResidue: Double? = nil,
        calcMassTotalLoss: Double? = nil,
        calcActiveLoss: Double? = nil,
        calcMassMixTransferredToMold: Double? = nil,
        calcMassPerGummyMold: Double? = nil,
        calcDensityFinalMix: Double? = nil,
        calcAverageGummyVolume: Double? = nil,
        calcAverageGummyActiveDose: Double? = nil,
        resBeakerEmpty: Double = 0.001,
        resBeakerPlusGelatin: Double = 0.001,
        resSubstratePlusSugar: Double = 0.001,
        resSubstratePlusActivation: Double = 0.001,
        resBeakerPlusResidue: Double = 0.001,
        resSyringeClean: Double = 0.001,
        resSyringePlusGummyMix: Double = 0.001,
        resSyringeResidue: Double = 0.001,
        resSyringeVolume: Double = 0.001,
        resMoldsFilled: Double = 0.1
    ) {
        self.name = name
        self.batchID = batchID
        self.date = date
        self.shape = shape
        self.trayCount = trayCount
        self.wellCount = wellCount
        self.vBase_mL = vBase_mL
        self.vMix_mL = vMix_mL
        self.activeName = activeName
        self.activeConcentration = activeConcentration
        self.activeUnit = activeUnit
        self.totalActive = totalActive
        self.gelatinPercent = gelatinPercent
        self.flavorsJSON = flavorsJSON
        self.componentsJSON = componentsJSON
        self.weightBeakerEmpty = weightBeakerEmpty
        self.weightBeakerPlusGelatin = weightBeakerPlusGelatin
        self.weightBeakerPlusSugar = weightBeakerPlusSugar
        self.weightBeakerPlusActive = weightBeakerPlusActive
        self.weightBeakerResidue = weightBeakerResidue
        self.weightSyringeEmpty = weightSyringeEmpty
        self.weightSyringeWithMix = weightSyringeWithMix
        self.volumeSyringeGummyMix = volumeSyringeGummyMix
        self.weightSyringeResidue = weightSyringeResidue
        self.weightMoldsFilled = weightMoldsFilled
        self.calcMassGelatinAdded = calcMassGelatinAdded
        self.calcMassSugarAdded = calcMassSugarAdded
        self.calcMassActiveAdded = calcMassActiveAdded
        self.calcMassFinalMixtureInBeaker = calcMassFinalMixtureInBeaker
        self.calcMassBeakerResidue = calcMassBeakerResidue
        self.calcMassSyringeResidue = calcMassSyringeResidue
        self.calcMassTotalLoss = calcMassTotalLoss
        self.calcActiveLoss = calcActiveLoss
        self.calcMassMixTransferredToMold = calcMassMixTransferredToMold
        self.calcMassPerGummyMold = calcMassPerGummyMold
        self.calcDensityFinalMix = calcDensityFinalMix
        self.calcAverageGummyVolume = calcAverageGummyVolume
        self.calcAverageGummyActiveDose = calcAverageGummyActiveDose
        self.resBeakerEmpty = resBeakerEmpty
        self.resBeakerPlusGelatin = resBeakerPlusGelatin
        self.resSubstratePlusSugar = resSubstratePlusSugar
        self.resSubstratePlusActivation = resSubstratePlusActivation
        self.resBeakerPlusResidue = resBeakerPlusResidue
        self.resSyringeClean = resSyringeClean
        self.resSyringePlusGummyMix = resSyringePlusGummyMix
        self.resSyringeResidue = resSyringeResidue
        self.resSyringeVolume = resSyringeVolume
        self.resMoldsFilled = resMoldsFilled
    }

    // MARK: - Dehydration Entries

    var dehydrationEntries: [DehydrationEntry] {
        get {
            guard let data = dehydrationEntriesJSON.data(using: .utf8),
                  let entries = try? JSONDecoder().decode([DehydrationEntry].self, from: data)
            else { return [] }
            return entries.sorted { $0.date < $1.date }
        }
        set {
            let sorted = newValue.sorted { $0.date < $1.date }
            let data = (try? JSONEncoder().encode(sorted)) ?? Data()
            dehydrationEntriesJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    func addDehydrationEntry(_ entry: DehydrationEntry) {
        var entries = dehydrationEntries
        entries.append(entry)
        dehydrationEntries = entries
    }

    func removeDehydrationEntry(id: UUID) {
        var entries = dehydrationEntries
        entries.removeAll { $0.id == id }
        dehydrationEntries = entries
    }

    // MARK: - Dehydration Calculations

    /// Average wet mass per gummy (from batch calculations)
    var wetMassPerGummy: Double? { calcMassPerGummyMold }

    /// Water content calculations given a dry mass per gummy
    func waterMassPercent(dryMass: Double) -> Double? {
        guard let wet = wetMassPerGummy, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        return (waterMass / wet) * 100.0
    }

    func waterVolumePercent(dryMass: Double) -> Double? {
        guard let wet = wetMassPerGummy, wet > 0,
              let vol = calcAverageGummyVolume, vol > 0
        else { return nil }
        let waterMass = wet - dryMass
        let waterVol  = waterMass / SubstanceDensity.water.gPerML
        return (waterVol / vol) * 100.0
    }

    /// Percentage dehydration = (wetMass - currentMass) / waterMassOriginal × 100
    func percentDehydration(currentMass: Double) -> Double? {
        guard let wet = wetMassPerGummy else { return nil }
        // Need a "dry mass" reference — use the last dehydration entry or a separate field
        // For generality: waterOriginal = wet - fullyDryMass
        // But we may not have fullyDryMass. Use currentMass relative to wet.
        // Actually: dehydration% = (wet - current) / (wet - 0) is wrong.
        // The user wants: mass_removed / water_originally_in_gummy.
        // Without knowing final dry mass, we can't compute exact water originally.
        // We'll compute it as (wet - current) / wet × 100 as a simple mass loss %
        // unless we have density info to compute water fraction.
        // With density: waterMass = wet - dryMass of solids.
        // Best approach: use the first dehydration entry as the reference "dry" mass
        // if none exist, return nil.
        return nil // Computed in the view with proper context
    }

    /// Average dehydration rate from entries: total mass lost / total time, as %/hr relative to initial water mass.
    func averageDehydrationRate(initialDryMass: Double) -> Double? {
        let entries = dehydrationEntries
        guard entries.count >= 2,
              let wet = wetMassPerGummy, wet > 0
        else { return nil }

        let waterOriginal = wet - initialDryMass
        guard waterOriginal > 0 else { return nil }

        let first = entries.first!
        let last  = entries.last!
        let massLost  = first.mass_g - last.mass_g
        let timeHours = last.date.timeIntervalSince(first.date) / 3600.0

        guard timeHours > 0 else { return nil }

        // Rate as g/hr
        let rateGPerHr = massLost / timeHours
        // As % of original water per hour
        return (rateGPerHr / waterOriginal) * 100.0
    }

    // MARK: - Resolution Helpers

    private func dpFromRaw(_ val: Double) -> Int {
        MeasurementResolution.allCases.first { $0.rawValue == val }?.decimalPlaces ?? 3
    }

    var savedBeakerDP: Int {
        min(dpFromRaw(resBeakerEmpty),
        min(dpFromRaw(resBeakerPlusGelatin),
        min(dpFromRaw(resSubstratePlusSugar),
        min(dpFromRaw(resSubstratePlusActivation),
            dpFromRaw(resBeakerPlusResidue)))))
    }
    var savedSyringeDP: Int {
        min(dpFromRaw(resSyringeClean),
        min(dpFromRaw(resSyringePlusGummyMix),
            dpFromRaw(resSyringeResidue)))
    }
    var savedVolumeDP: Int { dpFromRaw(resSyringeVolume) }
    var savedMoldsDP: Int { dpFromRaw(resMoldsFilled) }
    var savedMixedDP: Int { min(savedBeakerDP, savedSyringeDP) }
    var savedAllDP: Int { min(savedMixedDP, savedVolumeDP) }

    // MARK: - CSV Export

    func generateCSV() -> String {
        var lines: [String] = []

        lines.append("CandyMan Batch Report")
        lines.append("")

        // Batch Info
        lines.append("Batch Info")
        lines.append("Field,Value")
        lines.append("Batch ID,\(batchID)")
        lines.append("Name,\"\(name)\"")
        lines.append("Date,\"\(date.formatted(date: .long, time: .shortened))\"")
        lines.append("Shape,\(shape)")
        lines.append("Tray Count,\(trayCount)")
        lines.append("Well Count,\(wellCount)")
        lines.append("Target Volume (mL),\(String(format: "%.3f", vBase_mL))")
        lines.append("Mix Volume with Overage (mL),\(String(format: "%.3f", vMix_mL))")
        lines.append("Active,\(activeName)")
        lines.append("Active Concentration,\(String(format: "%.6f", activeConcentration)) \(activeUnit)/gummy")
        lines.append("Total Active,\(String(format: "%.6f", totalActive)) \(activeUnit)")
        lines.append("Gelatin %,\(String(format: "%.3f", gelatinPercent))")
        lines.append("")

        // Components
        if let data = componentsJSON.data(using: .utf8),
           let comps = try? JSONDecoder().decode([SavedComponent].self, from: data) {
            lines.append("Components")
            lines.append("Group,Category,Label,Mass (g),Volume (mL)")
            for c in comps {
                lines.append("\(c.group),\(c.category ?? ""),\"\(c.label)\",\(String(format: "%.6f", c.mass_g)),\(String(format: "%.6f", c.volume_mL))")
            }
            lines.append("")
        }

        // Measurements
        lines.append("Measurements")
        lines.append("Label,Value,Unit")
        func addMeas(_ label: String, _ val: Double?, _ unit: String) {
            lines.append("\"\(label)\",\(val.map { String(format: "%.6f", $0) } ?? ""),\(unit)")
        }
        addMeas("Beaker (Empty)", weightBeakerEmpty, "g")
        addMeas("Beaker + Gelatin Mix", weightBeakerPlusGelatin, "g")
        addMeas("Substrate + Sugar Mix", weightBeakerPlusSugar, "g")
        addMeas("Substrate + Activation Mix", weightBeakerPlusActive, "g")
        addMeas("Beaker + Residue", weightBeakerResidue, "g")
        addMeas("Syringe (Clean)", weightSyringeEmpty, "g")
        addMeas("Syringe + Gummy Mix", weightSyringeWithMix, "g")
        addMeas("Syringe Gummy Mix Vol", volumeSyringeGummyMix, "mL")
        addMeas("Syringe + Residue", weightSyringeResidue, "g")
        addMeas("Molds Filled", weightMoldsFilled, "count")
        lines.append("")

        // Calculations
        lines.append("Calculations")
        lines.append("Label,Value,Unit")
        func addCalc(_ label: String, _ val: Double?, _ unit: String) {
            lines.append("\"\(label)\",\(val.map { String(format: "%.6f", $0) } ?? ""),\(unit)")
        }
        addCalc("Gelatin Mix Added", calcMassGelatinAdded, "g")
        addCalc("Sugar Mix Added", calcMassSugarAdded, "g")
        addCalc("Activation Mix Added", calcMassActiveAdded, "g")
        addCalc("Final Mixture in Beaker", calcMassFinalMixtureInBeaker, "g")
        addCalc("Final Mixture in Tray/s", calcMassMixTransferredToMold, "g")
        addCalc("Density of Final Mix", calcDensityFinalMix, "g/mL")
        addCalc("Beaker Residue", calcMassBeakerResidue, "g")
        addCalc("Syringe Residue", calcMassSyringeResidue, "g")
        addCalc("Total Loss", calcMassTotalLoss, "g")
        addCalc("Active Loss", calcActiveLoss, activeUnit)
        addCalc("Average Gummy Mass", calcMassPerGummyMold, "g")
        addCalc("Average Gummy Volume", calcAverageGummyVolume, "mL")
        addCalc("Avg Gummy Active Dose", calcAverageGummyActiveDose, activeUnit)
        lines.append("")

        // Per-Measurement Resolutions
        lines.append("Measurement Resolutions")
        lines.append("Measurement,Resolution,Unit")
        lines.append("Beaker (Empty),\(String(format: "%.3f", resBeakerEmpty)),g")
        lines.append("Beaker + Gelatin Mix,\(String(format: "%.3f", resBeakerPlusGelatin)),g")
        lines.append("Substrate + Sugar Mix,\(String(format: "%.3f", resSubstratePlusSugar)),g")
        lines.append("Substrate + Activation Mix,\(String(format: "%.3f", resSubstratePlusActivation)),g")
        lines.append("Beaker + Residue,\(String(format: "%.3f", resBeakerPlusResidue)),g")
        lines.append("Syringe (Clean),\(String(format: "%.3f", resSyringeClean)),g")
        lines.append("Syringe + Gummy Mix,\(String(format: "%.3f", resSyringePlusGummyMix)),g")
        lines.append("Syringe + Residue,\(String(format: "%.3f", resSyringeResidue)),g")
        lines.append("Syringe Gummy Mixture Vol,\(String(format: "%.3f", resSyringeVolume)),mL")
        lines.append("Molds Filled,\(String(format: "%.3f", resMoldsFilled)),molds")
        lines.append("")

        // Dehydration
        let entries = dehydrationEntries
        if !entries.isEmpty {
            lines.append("Dehydration Log")
            lines.append("Date,Mass (g)")
            for e in entries {
                lines.append("\"\(e.formattedDate)\",\(String(format: "%.3f", e.mass_g))")
            }
            lines.append("")
        }

        // Notes
        lines.append("Notes & Ratings")
        lines.append("Category,Notes,Rating")
        lines.append("Flavor,\"\(flavorNotes)\",\(flavorRating.map { String($0) } ?? "")")
        lines.append("Color,\"\(colorNotes)\",\(colorRating.map { String($0) } ?? "")")
        lines.append("Texture,\"\(textureNotes)\",\(textureRating.map { String($0) } ?? "")")
        lines.append("Process,\"\(processNotes)\",")

        return lines.joined(separator: "\n")
    }
}

// MARK: - Serialisation helpers

struct SavedComponent: Codable {
    let label: String
    let mass_g: Double
    let volume_mL: Double
    let displayUnit: String
    let group: String          // "Activation Mix", "Gelatin Mix", "Sugar Mix"
    let category: String?      // ActivationCategory.rawValue if applicable
}

extension BatchResult {
    func componentsJSON() -> String {
        var rows: [SavedComponent] = []
        for c in activationMix.components {
            rows.append(SavedComponent(label: c.label, mass_g: c.mass_g,
                volume_mL: c.volume_mL, displayUnit: c.displayUnit,
                group: activationMix.name, category: c.activationCategory?.rawValue))
        }
        for c in gelatinMix.components {
            rows.append(SavedComponent(label: c.label, mass_g: c.mass_g,
                volume_mL: c.volume_mL, displayUnit: c.displayUnit,
                group: gelatinMix.name, category: nil))
        }
        for c in sugarMix.components {
            rows.append(SavedComponent(label: c.label, mass_g: c.mass_g,
                volume_mL: c.volume_mL, displayUnit: c.displayUnit,
                group: sugarMix.name, category: nil))
        }
        let data = (try? JSONEncoder().encode(rows)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

extension BatchConfigViewModel {
    func flavorsJSON() -> String {
        let dict = selectedFlavors.reduce(into: [String: Double]()) { $0[$1.key.id] = $1.value }
        let data = (try? JSONEncoder().encode(dict)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func makeSavedBatch(name: String, batchID: String, result: BatchResult, systemConfig: SystemConfig) -> SavedBatch {
        let spec = systemConfig.spec(for: selectedShape)
        let wells = spec.count * trayCount
        return SavedBatch(
            name: name,
            batchID: batchID,
            shape: selectedShape.rawValue,
            trayCount: trayCount,
            wellCount: wells,
            vBase_mL: result.vBase,
            vMix_mL: result.vMix,
            activeName: selectedActive.rawValue,
            activeConcentration: activeConcentration,
            activeUnit: units.rawValue,
            totalActive: activeConcentration * Double(wells),
            gelatinPercent: gelatinPercentage,
            flavorsJSON: flavorsJSON(),
            componentsJSON: result.componentsJSON(),
            weightBeakerEmpty: weightBeakerEmpty,
            weightBeakerPlusGelatin: weightBeakerPlusGelatin,
            weightBeakerPlusSugar: weightBeakerPlusSugar,
            weightBeakerPlusActive: weightBeakerPlusActive,
            weightBeakerResidue: weightBeakerResidue,
            weightSyringeEmpty: weightSyringeEmpty,
            weightSyringeWithMix: weightSyringeWithMix,
            volumeSyringeGummyMix: volumeSyringeGummyMix,
            weightSyringeResidue: weightSyringeResidue,
            weightMoldsFilled: weightMoldsFilled,
            calcMassGelatinAdded: calcMassGelatinAdded,
            calcMassSugarAdded: calcMassSugarAdded,
            calcMassActiveAdded: calcMassActiveAdded,
            calcMassFinalMixtureInBeaker: calcMassFinalMixtureInBeaker,
            calcMassBeakerResidue: calcMassBeakerResidue,
            calcMassSyringeResidue: calcMassSyringeResidue,
            calcMassTotalLoss: calcMassTotalLoss,
            calcActiveLoss: calcActiveLoss(systemConfig: systemConfig),
            calcMassMixTransferredToMold: calcMassMixTransferredToMold,
            calcMassPerGummyMold: calcMassPerGummyMold(systemConfig: systemConfig),
            calcDensityFinalMix: calcDensityFinalMix(systemConfig: systemConfig),
            calcAverageGummyVolume: calcAverageGummyVolume(systemConfig: systemConfig),
            calcAverageGummyActiveDose: calcAverageGummyActiveDose(systemConfig: systemConfig),
            resBeakerEmpty: systemConfig.resBeakerEmpty.rawValue,
            resBeakerPlusGelatin: systemConfig.resBeakerPlusGelatin.rawValue,
            resSubstratePlusSugar: systemConfig.resSubstratePlusSugar.rawValue,
            resSubstratePlusActivation: systemConfig.resSubstratePlusActivation.rawValue,
            resBeakerPlusResidue: systemConfig.resBeakerPlusResidue.rawValue,
            resSyringeClean: systemConfig.resSyringeClean.rawValue,
            resSyringePlusGummyMix: systemConfig.resSyringePlusGummyMix.rawValue,
            resSyringeResidue: systemConfig.resSyringeResidue.rawValue,
            resSyringeVolume: systemConfig.resSyringeVolume.rawValue,
            resMoldsFilled: systemConfig.resMoldsFilled.rawValue
        )
    }
}
