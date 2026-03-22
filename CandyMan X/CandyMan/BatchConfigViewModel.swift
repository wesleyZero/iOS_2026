//
//  BatchConfigViewModel.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI
import SwiftData

/// Central view model that owns all mutable state for the active batch.
///
/// Injected via `@Environment(BatchConfigViewModel.self)` into every view
/// that reads or writes batch inputs. A single instance lives for the
/// lifetime of the app and is reset between batches via `resetBatch()`.
///
/// ## Key responsibilities
/// - Shape, tray count, active substance selection
/// - Flavor / color blend ratios and lock states
/// - Post-calculate weight measurements and calibration fields
/// - Template save / apply / clear
/// - Corrections and additional measurements tracking
@Observable
final class BatchConfigViewModel {
    var selectedShape: GummyShape = .newBear
    var trayCount: Int = 1
    var extraGummies: Int = 0
    var activeConcentration: Double = 10.0
    var selectedActive: Active = .lsd {
        didSet {
            units = selectedActive.unit
        }
    }
    var units: ConcentrationUnit = .ug
    var gelatinPercentage: Double = 5.225

    /// Total gummy count: full trays + extra individual gummies.
    func totalGummies(using systemConfig: SystemConfig) -> Int {
        let spec = systemConfig.spec(for: selectedShape)
        return spec.count * trayCount + extraGummies
    }

    func totalVolume(using systemConfig: SystemConfig) -> Double {
        let spec = systemConfig.spec(for: selectedShape)
        return Double(totalGummies(using: systemConfig)) * spec.volumeML * overageFactor
    }

    // MARK: - Batch State

    var batchCalculated: Bool = false

    // MARK: - Template Tracking

    var activeTemplateID: PersistentIdentifier? = nil
    var activeTemplateName: String = ""
    private var templateSnapshot: TemplateSnapshot? = nil

    /// A lightweight snapshot of the values a template sets, used to detect user changes.
    struct TemplateSnapshot: Equatable {
        var shape: GummyShape
        var trayCount: Int
        var extraGummies: Int
        var activeConcentration: Double
        var selectedActive: Active
        var units: ConcentrationUnit
        var gelatinPercentage: Double
        var lsdUgPerTab: Double
        var additionalActiveWaterML: Double
        var overageFactor: Double
        var selectedFlavors: [FlavorSelection: Double]
        var flavorSourceTab: FlavorSourceType
        var waterRatioGelatinToSugar: Double
        var terpeneVolumePPM: Double
        var flavorOilVolumePercent: Double
        var selectedColors: [GummyColor: Double]
        var colorVolumePercent: Double
    }

    private func captureSnapshot() -> TemplateSnapshot {
        TemplateSnapshot(
            shape: selectedShape,
            trayCount: trayCount,
            extraGummies: extraGummies,
            activeConcentration: activeConcentration,
            selectedActive: selectedActive,
            units: units,
            gelatinPercentage: gelatinPercentage,
            lsdUgPerTab: lsdUgPerTab,
            additionalActiveWaterML: additionalActiveWaterML,
            overageFactor: overageFactor,
            selectedFlavors: selectedFlavors,
            flavorSourceTab: flavorSourceTab,
            waterRatioGelatinToSugar: waterRatioGelatinToSugar,
            terpeneVolumePPM: terpeneVolumePPM,
            flavorOilVolumePercent: flavorOilVolumePercent,
            selectedColors: selectedColors,
            colorVolumePercent: colorVolumePercent
        )
    }

    /// Lightweight flag toggled when a template is applied or inputs change.
    /// Use this in `onChange(of:)` instead of the expensive `templateInputsChanged`
    /// computed property, which reads every observed field and triggers re-evaluation
    /// on any property change.
    var templateChangeCounter: Int = 0

    /// Returns true if the user has modified any input since the template was applied.
    /// NOTE: Avoid using this in onChange(of:) — it reads every property and causes
    /// excessive observation churn. Use `checkAndClearTemplateIfChanged()` instead.
    var templateInputsChanged: Bool {
        guard let snapshot = templateSnapshot else { return false }
        return captureSnapshot() != snapshot
    }

    /// Call this to check if inputs have drifted from the template snapshot,
    /// and if so, clear the active template link. Designed to be called from
    /// specific user-interaction points rather than on every body evaluation.
    func checkAndClearTemplateIfChanged() {
        guard activeTemplateID != nil else { return }
        if templateInputsChanged {
            activeTemplateID = nil
            activeTemplateName = ""
            templateChangeCounter += 1
        }
    }

    /// Full reset: clears template + recipe inputs + all post-calculate measurements.
    func resetBatch(systemConfig: SystemConfig? = nil) {
        clearTemplate(systemConfig: systemConfig)
        batchCalculated = false
        clearMeasurements()
    }

    /// Clears all post-calculate measurement fields back to nil/defaults.
    private func clearMeasurements() {
        highPrecisionMode       = true
        weightBeakerEmpty       = nil
        hpGelatin               = nil
        hpGelatinWater          = nil
        hpBeakerBEmpty          = nil
        hpGranulated            = nil
        hpSugarWater            = nil
        hpActivationTray        = nil
        hpPotassiumSorbate      = nil
        hpCitricAcid            = nil
        hpColorTerpWater        = nil
        hpGlucoseSyrup          = nil
        hpActivationWater       = nil
        hpKSorbate              = nil
        hpFlavorOilsTerpsActive = nil
        hpActivationTrayResidue = nil
        hpSubstrateBeakerID     = nil
        hpSugarMixBeakerID      = nil
        hpActivationTrayID      = nil
        hpSubstrateScaleID      = nil
        hpSugarMixScaleID       = nil
        hpActivationScaleID     = nil
        hpSubstrateSugarTransfer = nil
        hpSubstrateActivationTransfer = nil
        weightBeakerPlusGelatin = nil
        weightBeakerPlusSugar   = nil
        weightBeakerPlusActive  = nil
        weightBeakerResidue     = nil
        weightTrayClean         = nil
        weightTrayPlusResidue   = nil
        weightSyringeEmpty      = nil
        weightSyringeResidue    = nil
        weightSyringeWithMix    = nil
        volumeSyringeGummyMix   = nil
        weightMoldsFilled       = nil
        extraGummyMixGrams      = nil
        additionalMeasurements  = [
            AdditionalMeasurement(label: "Container 1"),
            AdditionalMeasurement(label: "Container 2"),
            AdditionalMeasurement(label: "Container 3"),
            AdditionalMeasurement(label: "Container 4"),
        ]
        additionalMeasurementsLocked = false
        corrections = [
            CorrectionEntry(label: ""),
            CorrectionEntry(label: ""),
        ]
        correctionsLocked = false
        densitySyringeCleanSugar      = nil
        densitySyringePlusSugarMass   = nil
        densitySyringePlusSugarVol    = nil
        densitySyringeCleanGelatin    = nil
        densitySyringePlusGelatinMass = nil
        densitySyringePlusGelatinVol  = nil
        densitySyringeCleanActive     = nil
        densitySyringePlusActiveMass  = nil
        densitySyringePlusActiveVol   = nil
    }

    // MARK: - LSD Tab Calculator

    var lsdUgPerTab: Double = 117.0

    // MARK: - Additional Measurements

    /// A single before/after mass measurement for tracking material transfer or residue.
    struct AdditionalMeasurement: Identifiable {
        let id: UUID
        var label: String
        var initialMass: Double? = nil
        var finalMass: Double? = nil

        /// The mass change (final − initial), or nil if either value is missing.
        var difference: Double? {
            guard let f = finalMass, let i = initialMass else { return nil }
            return f - i
        }

        init(id: UUID = UUID(), label: String, initialMass: Double? = nil, finalMass: Double? = nil) {
            self.id = id
            self.label = label
            self.initialMass = initialMass
            self.finalMass = finalMass
        }
    }

    var additionalMeasurements: [AdditionalMeasurement] = [
        AdditionalMeasurement(label: "Container 1"),
        AdditionalMeasurement(label: "Container 2"),
        AdditionalMeasurement(label: "Container 3"),
        AdditionalMeasurement(label: "Container 4"),
    ]
    var additionalMeasurementsLocked: Bool = false

    var additionalMeasurementsTotal: Double? {
        let diffs = additionalMeasurements.compactMap { $0.difference }
        guard !diffs.isEmpty else { return nil }
        return diffs.reduce(0, +)
    }

    func addAdditionalMeasurement() {
        let next = additionalMeasurements.count + 1
        additionalMeasurements.append(AdditionalMeasurement(label: "Container \(next)"))
    }

    func removeAdditionalMeasurement(id: UUID) {
        additionalMeasurements.removeAll { $0.id == id }
    }

    // MARK: - Corrections

    /// A correction entry tracking a mass adjustment (same shape as `AdditionalMeasurement`).
    struct CorrectionEntry: Identifiable {
        let id: UUID
        var label: String
        var initialMass: Double? = nil
        var finalMass: Double? = nil

        /// The mass change (final − initial), or nil if either value is missing.
        var difference: Double? {
            guard let f = finalMass, let i = initialMass else { return nil }
            return f - i
        }

        init(id: UUID = UUID(), label: String, initialMass: Double? = nil, finalMass: Double? = nil) {
            self.id = id
            self.label = label
            self.initialMass = initialMass
            self.finalMass = finalMass
        }
    }

    var corrections: [CorrectionEntry] = [
        CorrectionEntry(label: ""),
        CorrectionEntry(label: ""),
    ]
    var correctionsLocked: Bool = false

    var correctionsTotal: Double? {
        let diffs = corrections.compactMap { $0.difference }
        guard !diffs.isEmpty else { return nil }
        return diffs.reduce(0, +)
    }

    func addCorrection() {
        corrections.append(CorrectionEntry(label: ""))
    }

    func removeCorrection(id: UUID) {
        corrections.removeAll { $0.id == id }
    }

    // MARK: - Weight Measurements
    //
    // These fields capture the physical masses recorded during the batch process.
    // The "hp" (high-precision) fields break each mix into sub-components for
    // users who measure individual ingredients separately on a precision scale.

    var measurementsLocked: Bool = false
    var highPrecisionMode: Bool = true
    var weightBeakerEmpty: Double? = nil

    // High-precision sub-fields — Gelatin Mix
    var hpGelatin: Double? = nil
    var hpGelatinWater: Double? = nil
    // High-precision sub-fields — Sugar Mix
    var hpBeakerBEmpty: Double? = nil
    var hpGranulated: Double? = nil
    var hpSugarWater: Double? = nil
    // High-precision sub-fields — Activation Mix
    var hpActivationTray: Double? = nil
    var hpPotassiumSorbate: Double? = nil
    var hpCitricAcid: Double? = nil
    var hpColorTerpWater: Double? = nil

    // High-precision sub-fields — Sugar Mix (expanded)
    var hpGlucoseSyrup: Double? = nil

    // High-precision sub-fields — Activation Mix (expanded)
    var hpActivationWater: Double? = nil
    var hpKSorbate: Double? = nil
    var hpFlavorOilsTerpsActive: Double? = nil
    var hpActivationTrayResidue: Double? = nil

    // High-precision container selections (BeakerContainer.id or nil)
    var hpSubstrateBeakerID: String? = nil
    var hpSugarMixBeakerID: String? = nil
    var hpActivationTrayID: String? = nil

    // High-precision scale selections (ScaleSpec.id or nil)
    var hpSubstrateScaleID: String? = nil
    var hpSugarMixScaleID: String? = nil
    var hpActivationScaleID: String? = nil

    // High-precision transfer measurements
    var hpSubstrateSugarTransfer: Double? = nil
    var hpSubstrateActivationTransfer: Double? = nil

    // MARK: - Section Scale Info (for sig figs / error analysis)

    /// Describes the scale used for a measurement section, providing resolution
    /// and decimal-place information for significant figures and error propagation.
    struct SectionScaleInfo {
        let sectionName: String       // e.g. "Substrate", "Sugar Mix", "Activation"
        let scaleID: String?          // ScaleSpec.id, nil if no scale selected
        let scaleName: String?        // display name
        let resolution: Double?       // grams (e.g. 0.001)
        let maxCapacity: Double?      // grams
        let decimalPlaces: Int        // derived from resolution

        /// The measurement resolution enum matching this scale's resolution.
        var measurementResolution: MeasurementResolution {
            guard let r = resolution else { return .thousandthGram }
            if r >= 1.0 { return .oneGram }
            if r >= 0.1 { return .tenthGram }
            if r >= 0.01 { return .hundredthGram }
            return .thousandthGram
        }
    }

    /// Returns scale info for all three HP sections, for use in error analysis.
    func sectionScaleInfos(systemConfig: SystemConfig) -> [SectionScaleInfo] {
        [
            makeSectionScaleInfo(name: "Substrate", scaleID: hpSubstrateScaleID, systemConfig: systemConfig),
            makeSectionScaleInfo(name: "Sugar Mix", scaleID: hpSugarMixScaleID, systemConfig: systemConfig),
            makeSectionScaleInfo(name: "Activation", scaleID: hpActivationScaleID, systemConfig: systemConfig),
        ]
    }

    private func makeSectionScaleInfo(name: String, scaleID: String?, systemConfig: SystemConfig) -> SectionScaleInfo {
        let scale = scaleID.flatMap { id in systemConfig.scales.first { $0.id == id } }
        let dp: Int
        if let r = scale?.resolution {
            if r >= 1.0 { dp = 0 }
            else if r >= 0.1 { dp = 1 }
            else if r >= 0.01 { dp = 2 }
            else { dp = 3 }
        } else {
            dp = 3
        }
        return SectionScaleInfo(
            sectionName: name,
            scaleID: scale?.id,
            scaleName: scale?.name,
            resolution: scale?.resolution,
            maxCapacity: scale?.maxCapacity,
            decimalPlaces: dp
        )
    }

    /// Resolution for a given section's selected scale, falling back to 0.001 g.
    func hpScaleResolution(for scaleID: String?, systemConfig: SystemConfig) -> MeasurementResolution {
        guard let id = scaleID,
              let scale = systemConfig.scales.first(where: { $0.id == id }) else {
            return .thousandthGram
        }
        if scale.resolution >= 1.0 { return .oneGram }
        if scale.resolution >= 0.1 { return .tenthGram }
        if scale.resolution >= 0.01 { return .hundredthGram }
        return .thousandthGram
    }

    /// Pre-populates HP scale selections based on the same recommendation logic
    /// used by MeasurementEquipmentView. Called when the user taps Calculate so
    /// each section starts with the best-fit scale already selected.
    func prePopulateRecommendedScales(systemConfig: SystemConfig) {
        let result = BatchCalculator.calculate(viewModel: self, systemConfig: systemConfig)
        let sugarOverage = 1.0 + systemConfig.sugarMixtureOveragePercent / 100.0

        let gelatinMass = result.gelatinMix.totalMassGrams
        let gelatinVol  = result.gelatinMix.totalVolumeML
        let sugarMass   = result.sugarMix.totalMassGrams * sugarOverage
        let sugarVol    = result.sugarMix.totalVolumeML * sugarOverage
        let activMass   = result.activationMix.totalMassGrams
        let activVol    = result.activationMix.totalVolumeML

        // Substrate beaker holds gelatin + sugar combined
        let substrateMass = gelatinMass + sugarMass
        let substrateVol  = gelatinVol + sugarVol

        // Helper: recommend scale for a given mix mass + beaker volume
        func recommendScale(mixMass: Double, mixVol: Double) -> String? {
            let beaker = systemConfig.recommendedBeaker(forVolumeML: mixVol)
            let beakerTare = beaker.map { systemConfig.containerTare(for: $0.id) } ?? 0
            let totalOnScale = mixMass + beakerTare
            return systemConfig.recommendedScale(forMassGrams: totalOnScale)?.id
        }

        // Only set if not already user-selected (nil means no selection yet)
        if hpSubstrateScaleID == nil {
            hpSubstrateScaleID = recommendScale(mixMass: substrateMass, mixVol: substrateVol)
        }
        if hpSugarMixScaleID == nil {
            hpSugarMixScaleID = recommendScale(mixMass: sugarMass, mixVol: sugarVol)
        }
        if hpActivationScaleID == nil {
            hpActivationScaleID = recommendScale(mixMass: activMass, mixVol: activVol)
        }
    }

    // MARK: HP Computed Totals

    /// HP Gelatin Mixture total = substrate beaker tare + gelatin + water
    func hpGelatinMixtureTotal(systemConfig: SystemConfig) -> Double? {
        guard let gel = hpGelatin, let water = hpGelatinWater,
              let id = hpSubstrateBeakerID else { return nil }
        let tare = systemConfig.containerTare(for: id)
        return tare + gel + water
    }

    /// HP Sugar Mixture total = sugar beaker tare + granulated + glucose syrup + water
    func hpSugarMixtureTotal(systemConfig: SystemConfig) -> Double? {
        guard let gran = hpGranulated, let water = hpSugarWater,
              let id = hpSugarMixBeakerID else { return nil }
        let tare = systemConfig.containerTare(for: id)
        let glucose = hpGlucoseSyrup ?? 0
        return tare + gran + glucose + water
    }

    /// HP Activation Mixture total = citric + water + kSorbate + flavorEtc - residue (net contents, no tray tare)
    func hpActivationMixtureTotal(systemConfig: SystemConfig) -> Double? {
        guard let citric = hpCitricAcid else { return nil }
        let water = hpActivationWater ?? 0
        let ksorb = hpKSorbate ?? 0
        let flavorEtc = hpFlavorOilsTerpsActive ?? 0
        let residue = hpActivationTrayResidue ?? 0
        return citric + water + ksorb + flavorEtc - residue
    }

    /// HP Grand total = substrate+activation transfer if recorded, otherwise
    /// substrate+sugar transfer + activation mixture total.
    func hpGrandTotal(systemConfig: SystemConfig) -> Double? {
        if let activationTransfer = hpSubstrateActivationTransfer {
            return activationTransfer
        }
        guard let transfer = hpSubstrateSugarTransfer,
              let activation = hpActivationMixtureTotal(systemConfig: systemConfig) else { return nil }
        return transfer + activation
    }

    // MARK: Derived Measurements (computed from raw weight fields)
    /// Mass of gelatin mix added = (beaker + gelatin) − beaker empty.
    var calcMassGelatinAdded: Double? {
        guard let a = weightBeakerPlusGelatin, let b = weightBeakerEmpty else { return nil }
        return a - b
    }
    /// Mass of sugar mix added = (beaker + sugar) − (beaker + gelatin).
    var calcMassSugarAdded: Double? {
        guard let a = weightBeakerPlusSugar, let b = weightBeakerPlusGelatin else { return nil }
        return a - b
    }
    /// Mass of activation mix added = (beaker + active) − (beaker + sugar).
    var calcMassActiveAdded: Double? {
        guard let a = weightBeakerPlusActive, let b = weightBeakerPlusSugar else { return nil }
        return a - b
    }
    var calcMassFinalMixtureInBeaker: Double? {
        guard let a = weightBeakerPlusActive, let b = weightBeakerEmpty else { return nil }
        return a - b
    }
    var calcMassBeakerResidue: Double? {
        guard let a = weightBeakerResidue, let b = weightBeakerEmpty else { return nil }
        return a - b
    }
    var calcMassSyringeResidue: Double? {
        guard let a = weightSyringeResidue, let b = weightSyringeEmpty else { return nil }
        return a - b
    }
    var calcMassTotalLoss: Double? {
        guard let br = calcMassBeakerResidue, let sr = calcMassSyringeResidue else { return nil }
        return br + sr
    }
    var calcMassMixTransferredToMold: Double? {
        guard let fm = calcMassFinalMixtureInBeaker, let tl = calcMassTotalLoss else { return nil }
        return fm - tl
    }
    func calcMassPerGummyMold(systemConfig: SystemConfig) -> Double? {
        guard let transferred = calcMassMixTransferredToMold else { return nil }
        let wells = Double(totalGummies(using: systemConfig))
        guard wells > 0 else { return nil }
        return transferred / wells
    }
    // Mass of gummy mix in syringe = syringe+mix - syringe(clean)
    var calcMassOfMixInSyringe: Double? {
        guard let a = weightSyringeWithMix, let b = weightSyringeEmpty else { return nil }
        return a - b
    }
    func calcDensityFinalMix(systemConfig: SystemConfig) -> Double? {
        guard let mass = calcMassOfMixInSyringe,
              let vol  = volumeSyringeGummyMix,
              vol > 0 else { return nil }
        return mass / vol
    }
    func calcActiveLoss(systemConfig: SystemConfig) -> Double? {
        guard let totalLoss = calcMassTotalLoss,
              let finalMix  = calcMassFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        let totalActive = activeConcentration * Double(totalGummies(using: systemConfig))
        return totalActive * (totalLoss / finalMix)
    }

    func calcAverageGummyActiveDose(systemConfig: SystemConfig) -> Double? {
        guard let loss  = calcActiveLoss(systemConfig: systemConfig),
              let molds = weightMoldsFilled,
              molds > 0 else { return nil }
        let totalActive = activeConcentration * Double(totalGummies(using: systemConfig))
        return (totalActive - loss) / molds
    }

    func calcAverageGummyVolume(systemConfig: SystemConfig) -> Double? {
        guard let density = calcDensityFinalMix(systemConfig: systemConfig),
              density > 0,
              let molds = weightMoldsFilled,
              molds > 0,
              let transferred = calcMassMixTransferredToMold else { return nil }
        let massPerGummy = transferred / molds
        return massPerGummy / density
    }
    var weightBeakerPlusGelatin: Double? = nil
    var weightBeakerPlusSugar: Double? = nil
    var weightBeakerPlusActive: Double? = nil
    var weightBeakerResidue: Double? = nil
    var weightTrayClean: Double? = nil
    var weightTrayPlusResidue: Double? = nil
    var weightSyringeEmpty: Double? = nil
    var weightSyringeResidue: Double? = nil
    var weightSyringeWithMix: Double? = nil      // mass of syringe + gummy mix (g)
    var volumeSyringeGummyMix: Double? = nil     // volume of gummy mix in syringe (mL)
    var weightMoldsFilled: Double? = nil
    var extraGummyMixGrams: Double? = nil

    // MARK: - Mixture Density Measurements

    // Sugar mix density
    var densitySyringeCleanSugar: Double? = nil
    var densitySyringePlusSugarMass: Double? = nil
    var densitySyringePlusSugarVol: Double? = nil

    // Gelatin mix density
    var densitySyringeCleanGelatin: Double? = nil
    var densitySyringePlusGelatinMass: Double? = nil
    var densitySyringePlusGelatinVol: Double? = nil

    // Activation mix density
    var densitySyringeCleanActive: Double? = nil
    var densitySyringePlusActiveMass: Double? = nil
    var densitySyringePlusActiveVol: Double? = nil

    // MARK: Computed Mix Densities (from calibration syringe measurements)

    var calcSugarMixDensity: Double? {
        guard let clean = densitySyringeCleanSugar,
              let mass = densitySyringePlusSugarMass,
              let vol = densitySyringePlusSugarVol,
              vol > 0 else { return nil }
        return (mass - clean) / vol
    }

    var calcGelatinMixDensity: Double? {
        guard let clean = densitySyringeCleanGelatin,
              let mass = densitySyringePlusGelatinMass,
              let vol = densitySyringePlusGelatinVol,
              vol > 0 else { return nil }
        return (mass - clean) / vol
    }

    var calcActiveMixDensity: Double? {
        guard let clean = densitySyringeCleanActive,
              let mass = densitySyringePlusActiveMass,
              let vol = densitySyringePlusActiveVol,
              vol > 0 else { return nil }
        return (mass - clean) / vol
    }

    // MARK: - Overage

    var additionalActiveWaterML: Double = 0.0
    var overageFactor: Double = 1.03
    var overageInputAsGummies: Bool = false

    var overagePercent: Double {
        get { (overageFactor - 1.0) * 100.0 }
        set { overageFactor = 1.0 + (newValue / 100.0) }
    }

    // MARK: - Flavors
    //
    // Flavors are either terpenes (dosed in PPM) or flavor oils (dosed as vol %).
    // Each selected flavor maps to a blend percentage (0–100) that must sum to 100
    // within its category before the user can lock the composition.

    /// Map of selected flavors → blend percentages (0–100).
    var selectedFlavors: [FlavorSelection: Double] = [:]
    var oilsLocked: Bool = false
    var terpenesLocked: Bool = false
    var flavorSourceTab: FlavorSourceType = .terpenes

    /// True when every flavor category that has selections is also locked.
    var flavorsLocked: Bool {
        let hasOils  = selectedOils.isEmpty == false
        let hasTerps = selectedTerpenes.isEmpty == false
        if hasOils && !oilsLocked { return false }
        if hasTerps && !terpenesLocked { return false }
        return hasOils || hasTerps
    }

    var waterRatioGelatinToSugar: Double = 75.0 / 65.0
    var terpeneVolumePPM: Double = 199.0
    var flavorOilVolumePercent: Double = 0.451

    /// Filtered view of only the oil-type selections.
    var selectedOils: [FlavorSelection] {
        selectedFlavors.keys.filter { if case .oil = $0 { return true }; return false }
    }

    /// Filtered view of only the terpene-type selections.
    var selectedTerpenes: [FlavorSelection] {
        selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
    }

    func toggleFlavor(_ flavor: FlavorSelection) {
        switch flavor {
        case .oil:     guard !oilsLocked else { return }
        case .terpene: guard !terpenesLocked else { return }
        }
        if selectedFlavors[flavor] != nil {
            selectedFlavors.removeValue(forKey: flavor)
        } else {
            selectedFlavors[flavor] = 0.0
        }
    }

    func isSelected(_ flavor: FlavorSelection) -> Bool {
        selectedFlavors[flavor] != nil
    }

    func lockOils() {
        guard !selectedOils.isEmpty else { return }
        let values = distributeEvenlyInMultiplesOf5(count: selectedOils.count)
        for (key, value) in zip(selectedOils, values) {
            selectedFlavors[key] = value
        }
        oilsLocked = true
    }

    func unlockOils() {
        oilsLocked = false
    }

    func lockTerpenes() {
        guard !selectedTerpenes.isEmpty else { return }
        let values = distributeEvenlyInMultiplesOf5(count: selectedTerpenes.count)
        for (key, value) in zip(selectedTerpenes, values) {
            selectedFlavors[key] = value
        }
        terpenesLocked = true
    }

    func unlockTerpenes() {
        terpenesLocked = false
    }

    /// Sum of all blend percentages across both flavor categories.
    var blendTotal: Double {
        selectedFlavors.values.reduce(0, +)
    }

    var flavorCompositionLocked: Bool = false

    /// Locks the overall composition if both categories sum to 100%.
    func lockComposition() {
        let terpeneTotal = selectedTerpenes.reduce(0.0) { $0 + (selectedFlavors[$1] ?? 0) }
        let oilTotal     = selectedOils.reduce(0.0) { $0 + (selectedFlavors[$1] ?? 0) }
        let terpenesReady = selectedTerpenes.isEmpty || abs(terpeneTotal - 100) < 0.5
        let oilsReady     = selectedOils.isEmpty || abs(oilTotal - 100) < 0.5
        guard terpenesReady && oilsReady else { return }
        flavorCompositionLocked = true
    }

    func unlockComposition() {
        flavorCompositionLocked = false
    }

    // MARK: - Colors
    //
    // Same lock/unlock/blend pattern as flavors, but simpler (only one category).

    /// Map of selected colors → blend percentages (0–100).
    var selectedColors: [GummyColor: Double] = [:]
    var colorsLocked: Bool = false
    var colorVolumePercent: Double = 0.664
    var colorCompositionLocked: Bool = false

    func toggleColor(_ color: GummyColor) {
        guard !colorsLocked else { return }
        if selectedColors[color] != nil {
            selectedColors.removeValue(forKey: color)
        } else {
            selectedColors[color] = 0.0
        }
    }

    func isColorSelected(_ color: GummyColor) -> Bool {
        selectedColors[color] != nil
    }

    func lockColors() {
        guard !selectedColors.isEmpty else { return }
        let values = distributeEvenlyInMultiplesOf5(count: selectedColors.count)
        for (key, value) in zip(selectedColors.keys, values) {
            selectedColors[key] = value
        }
        colorsLocked = true
    }

    func unlockColors() {
        colorsLocked = false
        colorCompositionLocked = false
    }

    var colorBlendTotal: Double {
        selectedColors.values.reduce(0, +)
    }

    func lockColorComposition() {
        guard abs(colorBlendTotal - 100) < 0.5 else { return }
        colorCompositionLocked = true
    }

    func unlockColorComposition() {
        colorCompositionLocked = false
    }

    /// Distributes 100 % across `count` slots, each rounded to the nearest 5 %.
    /// Example: 3 slots → [35, 35, 30].  Extra 5 % units go to the first slots.
    private func distributeEvenlyInMultiplesOf5(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let baseSlots = Int((100.0 / Double(count)) / 5.0)  // each slot gets this many 5s
        let base = Double(baseSlots * 5)
        let remainder = 100 - baseSlots * 5 * count         // leftover in multiples of 5
        let extraSlots = remainder / 5                       // how many slots get an extra 5
        return (0..<count).map { i in base + (i < extraSlots ? 5.0 : 0.0) }
    }

    // MARK: - Templates

    func saveAsTemplate(name: String, modelContext: ModelContext) {
        let t = BatchTemplate(
            name: name,
            shape: selectedShape.rawValue,
            trayCount: trayCount,
            activeConcentration: activeConcentration,
            activeName: selectedActive.rawValue,
            activeUnit: units.rawValue,
            gelatinPercentage: gelatinPercentage,
            lsdUgPerTab: lsdUgPerTab,
            additionalActiveWaterML: additionalActiveWaterML,
            overageFactor: overageFactor,
            flavorsLocked: oilsLocked || terpenesLocked,
            flavorSourceTab: flavorSourceTab.rawValue,
            waterRatioGelatinToSugar: waterRatioGelatinToSugar,
            terpeneVolumePPM: terpeneVolumePPM,
            flavorOilVolumePercent: flavorOilVolumePercent,
            flavorCompositionLocked: flavorCompositionLocked,
            colorsLocked: colorsLocked,
            colorVolumePercent: colorVolumePercent,
            colorCompositionLocked: colorCompositionLocked
        )
        for (flavor, pct) in selectedFlavors {
            t.flavors.append(TemplateFlavor(flavorID: flavor.id, percent: pct))
        }
        for (color, pct) in selectedColors {
            t.colors.append(TemplateColor(name: color.rawValue, percent: pct))
        }
        modelContext.insert(t)
        activeTemplateID = t.persistentModelID
        activeTemplateName = t.name
        templateSnapshot = captureSnapshot()
    }

    func applyTemplate(_ template: BatchTemplate) {
        selectedShape = GummyShape(rawValue: template.shape) ?? .newBear
        trayCount = template.trayCount
        extraGummies = 0
        activeConcentration = template.activeConcentration
        selectedActive = Active(rawValue: template.activeName) ?? .lsd
        units = ConcentrationUnit(rawValue: template.activeUnit) ?? .ug
        gelatinPercentage = template.gelatinPercentage
        lsdUgPerTab = template.lsdUgPerTab
        additionalActiveWaterML = template.additionalActiveWaterML
        overageFactor = template.overageFactor

        selectedFlavors = [:]
        for tf in template.flavors {
            if let sel = FlavorSelection.fromID(tf.flavorID) {
                selectedFlavors[sel] = tf.percent
            }
        }
        // Set per-type locks based on which flavors exist in the template
        let hasOils = selectedFlavors.keys.contains { if case .oil = $0 { return true }; return false }
        let hasTerps = selectedFlavors.keys.contains { if case .terpene = $0 { return true }; return false }
        oilsLocked = template.flavorsLocked && hasOils
        terpenesLocked = template.flavorsLocked && hasTerps
        flavorSourceTab = FlavorSourceType(rawValue: template.flavorSourceTab) ?? .terpenes
        waterRatioGelatinToSugar = template.waterRatioGelatinToSugar
        terpeneVolumePPM = template.terpeneVolumePPM
        flavorOilVolumePercent = template.flavorOilVolumePercent
        flavorCompositionLocked = template.flavorCompositionLocked

        selectedColors = [:]
        for tc in template.colors {
            if let c = GummyColor(rawValue: tc.name) {
                selectedColors[c] = tc.percent
            }
        }
        colorsLocked = template.colorsLocked
        colorVolumePercent = template.colorVolumePercent
        colorCompositionLocked = template.colorCompositionLocked

        activeTemplateID = template.persistentModelID
        activeTemplateName = template.name
        templateSnapshot = captureSnapshot()
    }

    /// Clears template link and resets all recipe inputs to factory defaults.
    /// Does NOT clear post-calculate measurements — use `resetBatch()` for a full reset.
    func clearTemplate(systemConfig: SystemConfig? = nil) {
        // Template tracking
        activeTemplateID        = nil
        activeTemplateName      = ""
        templateSnapshot        = nil

        // Recipe inputs
        selectedShape           = .newBear
        trayCount               = 1
        extraGummies            = 0
        activeConcentration     = 10.0
        selectedActive          = .lsd
        units                   = .ug
        gelatinPercentage       = 5.225
        lsdUgPerTab             = systemConfig?.defaultLsdUgPerTab ?? 117.0
        additionalActiveWaterML = 0.0
        overageFactor           = 1.03

        // Flavors
        selectedFlavors         = [:]
        oilsLocked              = false
        terpenesLocked          = false
        flavorSourceTab         = .terpenes
        flavorCompositionLocked = false
        waterRatioGelatinToSugar = 75.0 / 65.0
        terpeneVolumePPM        = 199.0
        flavorOilVolumePercent  = 0.451

        // Colors
        selectedColors          = [:]
        colorsLocked            = false
        colorVolumePercent      = 0.664
        colorCompositionLocked  = false
    }
}
