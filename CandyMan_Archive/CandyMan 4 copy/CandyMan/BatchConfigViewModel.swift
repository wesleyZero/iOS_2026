//
//  BatchConfigViewModel.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

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

    func resetBatch() {
        batchCalculated        = false
        selectedShape          = .newBear
        trayCount              = 1
        activeConcentration    = 10.0
        selectedActive         = .LSD
        units                  = .ug
        gelatinPercentage      = 5.225
        lsdUgPerTab            = 117.0
        overageFactor          = 1.03
        selectedFlavors        = [:]
        flavorsLocked          = false
        flavorSourceTab        = .terpenes
        flavorCompositionLocked = false
        selectedColors         = [:]
        colorsLocked           = false
        colorCompositionLocked = false
        weightBeakerEmpty      = nil
        weightBeakerPlusGelatin = nil
        weightBeakerPlusSugar  = nil
        weightBeakerPlusActive = nil
        weightBeakerResidue    = nil
        weightSyringeEmpty     = nil
        weightSyringeResidue   = nil
        weightSyringeWithMix   = nil
        volumeSyringeGummyMix  = nil
        weightMoldsFilled      = nil
        densitySyringeCleanSugar     = nil
        densitySyringePlusSugarMass  = nil
        densitySyringePlusSugarVol   = nil
        densitySyringeCleanGelatin   = nil
        densitySyringePlusGelatinMass = nil
        densitySyringePlusGelatinVol = nil
        densitySyringeCleanActive    = nil
        densitySyringePlusActiveMass = nil
        densitySyringePlusActiveVol  = nil
    }

    // MARK: - LSD Tab Calculator

    var lsdUgPerTab: Double = 117.0

    // MARK: - Weight Measurements

    var weightBeakerEmpty: Double? = nil
    // Computed derived measurements (mirrors MeasurementCalculationsView logic)
    var calcMassGelatinAdded: Double? {
        guard let a = weightBeakerPlusGelatin, let b = weightBeakerEmpty else { return nil }
        return a - b
    }
    var calcMassSugarAdded: Double? {
        guard let a = weightBeakerPlusSugar, let b = weightBeakerPlusGelatin else { return nil }
        return a - b
    }
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
        let spec = systemConfig.spec(for: selectedShape)
        let wells = Double(spec.count * trayCount)
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
    var weightSyringeWithMix: Double? = nil      // mass of syringe + gummy mix (g)
    var volumeSyringeGummyMix: Double? = nil     // volume of gummy mix in syringe (mL)
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

    // Computed densities
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
        let terpenes = selectedFlavors.keys.filter { if case .terpene = $0 { return true }; return false }
        let oils = selectedFlavors.keys.filter { if case .oil = $0 { return true }; return false }
        let terpeneTotal = terpenes.reduce(0.0) { $0 + (selectedFlavors[$1] ?? 0) }
        let oilTotal = oils.reduce(0.0) { $0 + (selectedFlavors[$1] ?? 0) }
        let terpenesReady = terpenes.isEmpty || abs(terpeneTotal - 100) < 0.5
        let oilsReady = oils.isEmpty || abs(oilTotal - 100) < 0.5
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
        guard abs(colorBlendTotal - 100) < 0.5 else { return }
        colorCompositionLocked = true
    }

    func unlockColorComposition() {
        colorCompositionLocked = false
    }

    // Distributes 100% across `count` slots as equal multiples of 5.
    // Floors each slot to nearest 5, then adds remaining 5s to first slots.
    private func distributeEvenlyInMultiplesOf5(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let baseSlots = Int((100.0 / Double(count)) / 5.0)  // each slot gets this many 5s
        let base = Double(baseSlots * 5)
        let remainder = 100 - baseSlots * 5 * count         // leftover in multiples of 5
        let extraSlots = remainder / 5                       // how many slots get an extra 5
        return (0..<count).map { i in base + (i < extraSlots ? 5.0 : 0.0) }
    }
}
