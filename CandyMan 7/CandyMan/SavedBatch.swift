import Foundation
import SwiftData

// MARK: - Child Models

@Model
class SavedBatchComponent {
    var label: String
    var mass_g: Double
    var volume_mL: Double
    var displayUnit: String
    var group: String           // "Activation Mix", "Gelatin Mix", "Sugar Mix"
    var category: String?       // ActivationCategory.rawValue if applicable
    var sortOrder: Int

    var batch: SavedBatch?

    init(label: String, mass_g: Double, volume_mL: Double, displayUnit: String,
         group: String, category: String?, sortOrder: Int) {
        self.label = label
        self.mass_g = mass_g
        self.volume_mL = volume_mL
        self.displayUnit = displayUnit
        self.group = group
        self.category = category
        self.sortOrder = sortOrder
    }
}

@Model
class SavedBatchFlavor {
    var flavorID: String        // e.g. "terp-Linalool", "oil-Cherry"
    var name: String            // parsed display name
    var type: String            // "Terpene" or "Flavor Oil"
    var percent: Double

    var batch: SavedBatch?

    init(flavorID: String, name: String, type: String, percent: Double) {
        self.flavorID = flavorID
        self.name = name
        self.type = type
        self.percent = percent
    }
}

@Model
class SavedBatchColor {
    var name: String
    var percent: Double

    var batch: SavedBatch?

    init(name: String, percent: Double) {
        self.name = name
        self.percent = percent
    }
}

@Model
class DryWeightReading {
    var mass_g: Double
    var timestamp: Date

    var batch: SavedBatch?

    init(mass_g: Double, timestamp: Date) {
        self.mass_g = mass_g
        self.timestamp = timestamp
    }
}

// MARK: - Parent Model

@Model
class SavedBatch {
    var name: String
    var batchID: String
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

    // Relationships (replace JSON blobs)
    @Relationship(deleteRule: .cascade, inverse: \SavedBatchComponent.batch)
    var components: [SavedBatchComponent] = []

    @Relationship(deleteRule: .cascade, inverse: \SavedBatchFlavor.batch)
    var flavors: [SavedBatchFlavor] = []

    @Relationship(deleteRule: .cascade, inverse: \SavedBatchColor.batch)
    var colors: [SavedBatchColor] = []

    @Relationship(deleteRule: .cascade, inverse: \DryWeightReading.batch)
    var dryWeightReadings: [DryWeightReading] = []

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

    // The "initial" wet gummy mass used for dehydration % calculations.
    var wetGummyMass_g: Double?

    // User input parameters (for review)
    var terpenePPM: Double = 0
    var flavorOilVolumePercent: Double = 0
    var colorVolumePercent: Double = 0

    // Post-batch notes, ratings, and tags
    var flavorNotes: String = ""
    var flavorRating: Int = 0
    var flavorTags: String = ""      // comma-separated tag labels
    var colorNotes: String = ""
    var colorRating: Int = 0
    var colorTags: String = ""
    var textureNotes: String = ""
    var textureRating: Int = 0
    var textureTags: String = ""
    var processNotes: String = ""

    // Mixture density measurements (raw inputs)
    var densitySyringeCleanSugar: Double?
    var densitySyringePlusSugarMass: Double?
    var densitySyringePlusSugarVol: Double?
    var densitySyringeCleanGelatin: Double?
    var densitySyringePlusGelatinMass: Double?
    var densitySyringePlusGelatinVol: Double?
    var densitySyringeCleanActive: Double?
    var densitySyringePlusActiveMass: Double?
    var densitySyringePlusActiveVol: Double?

    // Calculated mixture densities
    var calcSugarMixDensity: Double?
    var calcGelatinMixDensity: Double?
    var calcActiveMixDensity: Double?

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
        batchID: String = "",
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
        densitySyringeCleanSugar: Double? = nil,
        densitySyringePlusSugarMass: Double? = nil,
        densitySyringePlusSugarVol: Double? = nil,
        densitySyringeCleanGelatin: Double? = nil,
        densitySyringePlusGelatinMass: Double? = nil,
        densitySyringePlusGelatinVol: Double? = nil,
        densitySyringeCleanActive: Double? = nil,
        densitySyringePlusActiveMass: Double? = nil,
        densitySyringePlusActiveVol: Double? = nil,
        calcSugarMixDensity: Double? = nil,
        calcGelatinMixDensity: Double? = nil,
        calcActiveMixDensity: Double? = nil,
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
        self.densitySyringeCleanSugar = densitySyringeCleanSugar
        self.densitySyringePlusSugarMass = densitySyringePlusSugarMass
        self.densitySyringePlusSugarVol = densitySyringePlusSugarVol
        self.densitySyringeCleanGelatin = densitySyringeCleanGelatin
        self.densitySyringePlusGelatinMass = densitySyringePlusGelatinMass
        self.densitySyringePlusGelatinVol = densitySyringePlusGelatinVol
        self.densitySyringeCleanActive = densitySyringeCleanActive
        self.densitySyringePlusActiveMass = densitySyringePlusActiveMass
        self.densitySyringePlusActiveVol = densitySyringePlusActiveVol
        self.calcSugarMixDensity = calcSugarMixDensity
        self.calcGelatinMixDensity = calcGelatinMixDensity
        self.calcActiveMixDensity = calcActiveMixDensity
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

// MARK: - Batch Creation

extension BatchConfigViewModel {
    func makeSavedBatch(name: String, batchID: String, result: BatchResult, systemConfig: SystemConfig) -> SavedBatch {
        let spec = systemConfig.spec(for: selectedShape)
        let wells = spec.count * trayCount
        let batch = SavedBatch(
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
            densitySyringeCleanSugar: densitySyringeCleanSugar,
            densitySyringePlusSugarMass: densitySyringePlusSugarMass,
            densitySyringePlusSugarVol: densitySyringePlusSugarVol,
            densitySyringeCleanGelatin: densitySyringeCleanGelatin,
            densitySyringePlusGelatinMass: densitySyringePlusGelatinMass,
            densitySyringePlusGelatinVol: densitySyringePlusGelatinVol,
            densitySyringeCleanActive: densitySyringeCleanActive,
            densitySyringePlusActiveMass: densitySyringePlusActiveMass,
            densitySyringePlusActiveVol: densitySyringePlusActiveVol,
            calcSugarMixDensity: calcSugarMixDensity,
            calcGelatinMixDensity: calcGelatinMixDensity,
            calcActiveMixDensity: calcActiveMixDensity,
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
        batch.wetGummyMass_g = calcMassMixTransferredToMold
        batch.terpenePPM = terpeneVolumePPM
        batch.flavorOilVolumePercent = flavorOilVolumePercent
        batch.colorVolumePercent = colorVolumePercent

        // Create child components
        var sortOrder = 0
        for c in result.activationMix.components {
            batch.components.append(SavedBatchComponent(
                label: c.label, mass_g: c.mass_g, volume_mL: c.volume_mL,
                displayUnit: c.displayUnit, group: result.activationMix.name,
                category: c.activationCategory?.rawValue, sortOrder: sortOrder
            ))
            sortOrder += 1
        }
        for c in result.gelatinMix.components {
            batch.components.append(SavedBatchComponent(
                label: c.label, mass_g: c.mass_g, volume_mL: c.volume_mL,
                displayUnit: c.displayUnit, group: result.gelatinMix.name,
                category: nil, sortOrder: sortOrder
            ))
            sortOrder += 1
        }
        for c in result.sugarMix.components {
            batch.components.append(SavedBatchComponent(
                label: c.label, mass_g: c.mass_g, volume_mL: c.volume_mL,
                displayUnit: c.displayUnit, group: result.sugarMix.name,
                category: nil, sortOrder: sortOrder
            ))
            sortOrder += 1
        }

        // Create child flavors
        for (flavor, pct) in selectedFlavors {
            let flavorName: String
            let flavorType: String
            switch flavor {
            case .terpene(let t): flavorName = t.rawValue; flavorType = "Terpene"
            case .oil(let o):     flavorName = o.rawValue; flavorType = "Flavor Oil"
            }
            batch.flavors.append(SavedBatchFlavor(
                flavorID: flavor.id, name: flavorName, type: flavorType, percent: pct
            ))
        }

        // Create child colors
        for (color, pct) in selectedColors {
            batch.colors.append(SavedBatchColor(
                name: color.rawValue, percent: pct
            ))
        }

        return batch
    }
}
