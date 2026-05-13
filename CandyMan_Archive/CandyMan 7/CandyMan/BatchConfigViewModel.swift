//
//  BatchConfigViewModel.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class BatchConfigViewModel {
    var selectedShape: GummyShape = .newBear
    var trayCount: Int = 1
    var activeConcentration: Double = 10.0
    var selectedActive: Active = .LSD {
        didSet {
            units = selectedActive.unit
        }
    }
    var units: ConcentrationUnit = .ug
    var gelatinPercentage: Double = 5.225

    func totalVolume(using systemConfig: SystemConfig) -> Double {
        let spec = systemConfig.spec(for: selectedShape)
        return Double(spec.count * trayCount) * spec.volume_ml * overageFactor
    }

    // MARK: - Batch State

    var batchCalculated: Bool = false

    var areFlavorsReadyForCalculation: Bool {
        let terpeneTotal = selectedFlavors.terpeneBlendTotal
        let oilTotal = selectedFlavors.oilBlendTotal
        let hasTerpenes = !selectedFlavors.terpeneEntries.isEmpty
        let hasOils = !selectedFlavors.oilEntries.isEmpty
        let terpenesValid = !hasTerpenes || abs(terpeneTotal - 100) < CMTheme.blendSumTolerance
        let oilsValid = !hasOils || abs(oilTotal - 100) < CMTheme.blendSumTolerance
        return terpenesValid && oilsValid && (selectedFlavors.isEmpty || flavorsLocked)
    }

    var areColorsReadyForCalculation: Bool {
        selectedColors.isEmpty || (colorsLocked && abs(colorBlendTotal - 100) < CMTheme.blendSumTolerance)
    }

    var canCalculateBatch: Bool {
        areFlavorsReadyForCalculation && areColorsReadyForCalculation
    }

    // MARK: - Template Tracking

    var activeTemplateID: PersistentIdentifier? = nil
    var activeTemplateName: String = ""
    private var templateSnapshot: TemplateSnapshot? = nil

    /// Allows auto-deselecting the active template when the user modifies any input.
    struct TemplateSnapshot: Equatable {
        var shape: GummyShape
        var trayCount: Int
        var activeConcentration: Double
        var selectedActive: Active
        var units: ConcentrationUnit
        var gelatinPercentage: Double
        var lsdUgPerTab: Double
        var additionalActiveWater_mL: Double
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
            activeConcentration: activeConcentration,
            selectedActive: selectedActive,
            units: units,
            gelatinPercentage: gelatinPercentage,
            lsdUgPerTab: lsdUgPerTab,
            additionalActiveWater_mL: additionalActiveWater_mL,
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

    /// Returns true if the user has modified any input since the template was applied.
    var templateInputsChanged: Bool {
        guard let snapshot = templateSnapshot else { return false }
        return captureSnapshot() != snapshot
    }

    func resetBatch() {
        clearTemplateTracking()
        resetInputsToDefaults()
        resetMeasurements()
        batchCalculated = false
    }

    private func clearTemplateTracking() {
        activeTemplateID = nil
        activeTemplateName = ""
        templateSnapshot = nil
    }

    private func resetInputsToDefaults() {
        selectedShape = .newBear
        trayCount = 1
        activeConcentration = 10.0
        selectedActive = .LSD
        units = .ug
        gelatinPercentage = 5.225
        lsdUgPerTab = 117.0
        additionalActiveWater_mL = 0.0
        overageFactor = 1.03
        selectedFlavors = [:]
        flavorsLocked = false
        flavorSourceTab = .terpenes
        flavorCompositionLocked = false
        waterRatioGelatinToSugar = 75.0 / 65.0
        terpeneVolumePPM = 199.0
        flavorOilVolumePercent = 0.451
        selectedColors = [:]
        colorsLocked = false
        colorVolumePercent = 0.664
        colorCompositionLocked = false
    }

    private func resetMeasurements() {
        weightBeakerEmpty = nil
        weightBeakerPlusGelatin = nil
        weightBeakerPlusSugar = nil
        weightBeakerPlusActive = nil
        weightBeakerResidue = nil
        weightSyringeEmpty = nil
        weightSyringeResidue = nil
        weightSyringeWithMix = nil
        volumeSyringeGummyMix = nil
        weightMoldsFilled = nil
        densitySyringeCleanSugar = nil
        densitySyringePlusSugarMass = nil
        densitySyringePlusSugarVol = nil
        densitySyringeCleanGelatin = nil
        densitySyringePlusGelatinMass = nil
        densitySyringePlusGelatinVol = nil
        densitySyringeCleanActive = nil
        densitySyringePlusActiveMass = nil
        densitySyringePlusActiveVol = nil
    }

    // MARK: - LSD Tab Calculator

    var lsdUgPerTab: Double = 117.0

    // MARK: - Weight Measurements

    var measurementsLocked: Bool = false
    var weightBeakerEmpty: Double? = nil
    var calcMassGelatinAdded: Double? {
        guard let afterGelatin = weightBeakerPlusGelatin, let empty = weightBeakerEmpty else { return nil }
        return afterGelatin - empty
    }

    var calcMassSugarAdded: Double? {
        guard let afterSugar = weightBeakerPlusSugar, let afterGelatin = weightBeakerPlusGelatin else { return nil }
        return afterSugar - afterGelatin
    }

    var calcMassActiveAdded: Double? {
        guard let afterActive = weightBeakerPlusActive, let afterSugar = weightBeakerPlusSugar else { return nil }
        return afterActive - afterSugar
    }

    var calcMassFinalMixtureInBeaker: Double? {
        guard let afterActive = weightBeakerPlusActive, let empty = weightBeakerEmpty else { return nil }
        return afterActive - empty
    }

    var calcMassBeakerResidue: Double? {
        guard let residue = weightBeakerResidue, let empty = weightBeakerEmpty else { return nil }
        return residue - empty
    }

    var calcMassSyringeResidue: Double? {
        guard let residue = weightSyringeResidue, let empty = weightSyringeEmpty else { return nil }
        return residue - empty
    }

    var calcMassTotalLoss: Double? {
        guard let beakerLoss = calcMassBeakerResidue, let syringeLoss = calcMassSyringeResidue else { return nil }
        return beakerLoss + syringeLoss
    }

    var calcMassMixTransferredToMold: Double? {
        guard let finalMix = calcMassFinalMixtureInBeaker, let totalLoss = calcMassTotalLoss else { return nil }
        return finalMix - totalLoss
    }
    func calcMassPerGummyMold(systemConfig: SystemConfig) -> Double? {
        guard let transferred = calcMassMixTransferredToMold else { return nil }
        let spec = systemConfig.spec(for: selectedShape)
        let wells = Double(spec.count * trayCount)
        guard wells > 0 else { return nil }
        return transferred / wells
    }
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
        let spec = systemConfig.spec(for: selectedShape)
        let totalActive = activeConcentration * Double(spec.count * trayCount)
        return totalActive * (totalLoss / finalMix)
    }

    func calcAverageGummyActiveDose(systemConfig: SystemConfig) -> Double? {
        guard let loss  = calcActiveLoss(systemConfig: systemConfig),
              let molds = weightMoldsFilled,
              molds > 0 else { return nil }
        let spec = systemConfig.spec(for: selectedShape)
        let totalActive = activeConcentration * Double(spec.count * trayCount)
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
    var weightSyringeEmpty: Double? = nil
    var weightSyringeResidue: Double? = nil
    var weightSyringeWithMix: Double? = nil
    var volumeSyringeGummyMix: Double? = nil
    var weightMoldsFilled: Double? = nil

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

    /// Density = (syringePlusMixMass - syringeCleanMass) / volume
    private func syringeDensity(cleanMass: Double?, mixMass: Double?, volume: Double?) -> Double? {
        guard let clean = cleanMass, let mass = mixMass, let vol = volume, vol > 0 else { return nil }
        return (mass - clean) / vol
    }

    var calcSugarMixDensity: Double? {
        syringeDensity(cleanMass: densitySyringeCleanSugar, mixMass: densitySyringePlusSugarMass, volume: densitySyringePlusSugarVol)
    }

    var calcGelatinMixDensity: Double? {
        syringeDensity(cleanMass: densitySyringeCleanGelatin, mixMass: densitySyringePlusGelatinMass, volume: densitySyringePlusGelatinVol)
    }

    var calcActiveMixDensity: Double? {
        syringeDensity(cleanMass: densitySyringeCleanActive, mixMass: densitySyringePlusActiveMass, volume: densitySyringePlusActiveVol)
    }

    // MARK: - Overage

    var additionalActiveWater_mL: Double = 0.0
    var overageFactor: Double = 1.03

    var overagePercent: Double {
        get { (overageFactor - 1.0) * 100.0 }
        set { overageFactor = 1.0 + (newValue / 100.0) }
    }

    // MARK: - Flavors

    var selectedFlavors: [FlavorSelection: Double] = [:]
    var flavorsLocked: Bool = false
    var flavorSourceTab: FlavorSourceType = .terpenes
    var waterRatioGelatinToSugar: Double = 75/65

    var terpeneVolumePPM: Double = 199.0
    var flavorOilVolumePercent: Double = 0.451

    func toggleFlavor(_ flavor: FlavorSelection) {
        guard !flavorsLocked else { return }
        if selectedFlavors[flavor] != nil {
            selectedFlavors.removeValue(forKey: flavor)
        } else {
            selectedFlavors[flavor] = 0.0
        }
    }

    func isSelected(_ flavor: FlavorSelection) -> Bool {
        selectedFlavors[flavor] != nil
    }

    func lockFlavors() {
        guard !selectedFlavors.isEmpty else { return }
        let values = distributeEvenlyInMultiplesOf5(count: selectedFlavors.count)
        for (key, value) in zip(selectedFlavors.keys, values) {
            selectedFlavors[key] = value
        }
        flavorsLocked = true
    }

    func unlockFlavors() {
        flavorsLocked = false
    }

    var blendTotal: Double {
        selectedFlavors.values.reduce(0, +)
    }

    var flavorCompositionLocked: Bool = false

    func lockComposition() {
        let terpenesReady = selectedFlavors.terpeneEntries.isEmpty
            || abs(selectedFlavors.terpeneBlendTotal - 100) < CMTheme.blendSumTolerance
        let oilsReady = selectedFlavors.oilEntries.isEmpty
            || abs(selectedFlavors.oilBlendTotal - 100) < CMTheme.blendSumTolerance
        guard terpenesReady && oilsReady else { return }
        flavorCompositionLocked = true
    }

    func unlockComposition() {
        flavorCompositionLocked = false
    }

    // MARK: - Colors

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
        guard abs(colorBlendTotal - 100) < CMTheme.blendSumTolerance else { return }
        colorCompositionLocked = true
    }

    func unlockColorComposition() {
        colorCompositionLocked = false
    }

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
            additionalActiveWater_mL: additionalActiveWater_mL,
            overageFactor: overageFactor,
            flavorsLocked: flavorsLocked,
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
        activeConcentration = template.activeConcentration
        selectedActive = Active(rawValue: template.activeName) ?? .LSD
        units = ConcentrationUnit(rawValue: template.activeUnit) ?? .ug
        gelatinPercentage = template.gelatinPercentage
        lsdUgPerTab = template.lsdUgPerTab
        additionalActiveWater_mL = template.additionalActiveWater_mL
        overageFactor = template.overageFactor

        selectedFlavors = [:]
        for tf in template.flavors {
            if let sel = FlavorSelection.fromID(tf.flavorID) {
                selectedFlavors[sel] = tf.percent
            }
        }
        flavorsLocked = template.flavorsLocked
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

    func clearTemplate() {
        clearTemplateTracking()
        resetInputsToDefaults()
    }
}
