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
    var selectedShape: GummyShape = .bear
    var trayCount: Int = 1
    var activeConcentration: Double = 10.0
    var selectedActive: Active = .LSD {
        didSet {
            units = selectedActive.unit
        }
    }
    var units: ConcentrationUnit = .ug
    var gelatinPercentage: Double = 8.0
    func totalVolume(using systemConfig: SystemConfig) -> Double {
        systemConfig.spec(for: selectedShape).volume_ml * Double(trayCount)
    }

    var selectedFlavors: [FlavorSelection: Double] = [:]
    // value = proportion 0-100, all selected flavors should sum to 100
    var flavorsLocked: Bool = false
    var flavorSourceTab: FlavorSourceType = .terpenes
    var waterRatioGelatinToSugar: Double = 75/65
    var overageFactor: Double = 1.03

    var terpeneVolumePPM: Double = 1000.0
    var flavorOilVolumePercent: Double = 1.0

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
        let even = 100.0 / Double(selectedFlavors.count)
        for key in selectedFlavors.keys {
            selectedFlavors[key] = even
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
}

//create a class for the tray sizes? because I will want to have a way for the user to modify the volume?

