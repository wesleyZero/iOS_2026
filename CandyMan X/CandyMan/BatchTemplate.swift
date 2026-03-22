//
//  BatchTemplate.swift
//  CandyMan
//
//  SwiftData models for saving and restoring batch configurations as reusable
//  templates. A template captures the full set of user-chosen parameters —
//  shape, tray count, active concentration, flavors, colors, overage, etc. —
//  so that common recipes can be loaded with one tap from TemplateListView.
//
//  Contents:
//    TemplateFlavor              — child model linking a FlavorSelection ID + percent
//    TemplateColor               — child model linking a GummyColor name + percent
//    BatchTemplate               — parent model with cascade-delete relationships
//    FlavorSelection.fromID(_:)  — reconstruct a FlavorSelection from its canonical ID
//

import Foundation
import SwiftData

// MARK: - Child Models

@Model
class TemplateFlavor {
    var flavorID: String      // FlavorSelection.id (e.g. "terp-Strawberry", "oil-Cherry")
    var percent: Double

    var template: BatchTemplate?

    init(flavorID: String, percent: Double) {
        self.flavorID = flavorID
        self.percent = percent
    }
}

@Model
class TemplateColor {
    var name: String          // GummyColor.rawValue
    var percent: Double

    var template: BatchTemplate?

    init(name: String, percent: Double) {
        self.name = name
        self.percent = percent
    }
}

// MARK: - Parent Model

@Model
class BatchTemplate {
    var name: String
    var createdDate: Date

    // Core settings
    var shape: String                    // GummyShape.rawValue
    var trayCount: Int
    var activeConcentration: Double
    var activeName: String               // Active.rawValue
    var activeUnit: String               // ConcentrationUnit.rawValue
    var gelatinPercentage: Double

    // LSD
    var lsdUgPerTab: Double

    // Overage
    var additionalActiveWaterML: Double
    var overageFactor: Double

    // Flavor settings
    var flavorsLocked: Bool
    var flavorSourceTab: String          // FlavorSourceType.rawValue
    var waterRatioGelatinToSugar: Double
    var terpeneVolumePPM: Double
    var flavorOilVolumePercent: Double
    var flavorCompositionLocked: Bool

    // Color settings
    var colorsLocked: Bool
    var colorVolumePercent: Double
    var colorCompositionLocked: Bool

    // Child relationships
    @Relationship(deleteRule: .cascade, inverse: \TemplateFlavor.template)
    var flavors: [TemplateFlavor] = []

    @Relationship(deleteRule: .cascade, inverse: \TemplateColor.template)
    var colors: [TemplateColor] = []

    init(
        name: String,
        createdDate: Date = .now,
        shape: String,
        trayCount: Int,
        activeConcentration: Double,
        activeName: String,
        activeUnit: String,
        gelatinPercentage: Double,
        lsdUgPerTab: Double,
        additionalActiveWaterML: Double,
        overageFactor: Double,
        flavorsLocked: Bool,
        flavorSourceTab: String,
        waterRatioGelatinToSugar: Double,
        terpeneVolumePPM: Double,
        flavorOilVolumePercent: Double,
        flavorCompositionLocked: Bool,
        colorsLocked: Bool,
        colorVolumePercent: Double,
        colorCompositionLocked: Bool
    ) {
        self.name = name
        self.createdDate = createdDate
        self.shape = shape
        self.trayCount = trayCount
        self.activeConcentration = activeConcentration
        self.activeName = activeName
        self.activeUnit = activeUnit
        self.gelatinPercentage = gelatinPercentage
        self.lsdUgPerTab = lsdUgPerTab
        self.additionalActiveWaterML = additionalActiveWaterML
        self.overageFactor = overageFactor
        self.flavorsLocked = flavorsLocked
        self.flavorSourceTab = flavorSourceTab
        self.waterRatioGelatinToSugar = waterRatioGelatinToSugar
        self.terpeneVolumePPM = terpeneVolumePPM
        self.flavorOilVolumePercent = flavorOilVolumePercent
        self.flavorCompositionLocked = flavorCompositionLocked
        self.colorsLocked = colorsLocked
        self.colorVolumePercent = colorVolumePercent
        self.colorCompositionLocked = colorCompositionLocked
    }
}

// MARK: - FlavorSelection Reconstruction

extension FlavorSelection {
    /// Reconstruct from the canonical ID string (e.g. "terp-Strawberry", "oil-Cherry")
    static func fromID(_ id: String) -> FlavorSelection? {
        if id.hasPrefix("terp-") {
            let raw = String(id.dropFirst(5))
            guard let t = TerpeneFlavor(rawValue: raw) else { return nil }
            return .terpene(t)
        } else if id.hasPrefix("oil-") {
            let raw = String(id.dropFirst(4))
            guard let o = FlavorOil(rawValue: raw) else { return nil }
            return .oil(o)
        }
        return nil
    }
}
