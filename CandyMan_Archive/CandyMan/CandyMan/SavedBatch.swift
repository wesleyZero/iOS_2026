import Foundation
import SwiftData

@Model
class SavedBatch {
    var name: String
    var date: Date

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

    init(
        name: String,
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
        calcAverageGummyActiveDose: Double? = nil
    ) {
        self.name = name
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

    func makeSavedBatch(name: String, result: BatchResult, systemConfig: SystemConfig) -> SavedBatch {
        let spec = systemConfig.spec(for: selectedShape)
        let wells = spec.count * trayCount
        return SavedBatch(
            name: name,
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
            calcAverageGummyActiveDose: calcAverageGummyActiveDose(systemConfig: systemConfig)
        )
    }
}
