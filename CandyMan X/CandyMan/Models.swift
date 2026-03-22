//
//  Models.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//
//  Domain model types that define the vocabulary of the CandyMan app.
//  Every enum here is a lightweight value type — no state, no side effects.
//
//  Hierarchy:
//    GummyShape        – mold geometry
//    Active            – active substance (drives default concentration unit)
//    ConcentrationUnit – ug / mg / g
//    GummyColor        – food coloring selection
//    TerpeneFlavor     – terpene-based flavor catalog
//    FlavorOil         – oil-based flavor catalog
//    FlavorSelection   – type-erased wrapper for either flavor type
//    FlavorSourceType  – picker tab identity (terpenes vs oils)
//    SubstanceSolubility – solubility data for water-budget calculations
//

import Foundation
import SwiftUI

// MARK: - Substance Solubility

/// Aqueous solubility at ~20 °C expressed as grams per 100 mL water.
/// Used by `BatchCalculator` to determine the minimum activation water
/// volume needed to fully dissolve preservatives.
enum SubstanceSolubility: Double {
    case citricAcid       = 59.0   // g / 100 mL
    case potassiumSorbate = 58.2
    case sucrose          = 200.0

    /// The raw solubility value (grams per 100 mL water).
    var gPer100mL: Double { rawValue }

    /// Minimum water volume (mL) required to dissolve `mass` grams of this substance.
    func minWaterML(toDissolveGrams mass: Double) -> Double {
        (mass / gPer100mL) * 100.0
    }
}

// MARK: - Concentration Unit

/// Unit of measure for an active-substance dose per gummy.
enum ConcentrationUnit: String, CaseIterable, Identifiable {
    case ug = "ug"
    case mg = "mg"
    case g  = "g"

    var id: String { rawValue }
}

// MARK: - Gummy Shape

/// Available mold geometries. Each shape maps to a `MoldSpec` in `SystemConfig`
/// that defines cavity count and per-cavity volume.
enum GummyShape: String, CaseIterable, Identifiable {
    case circle   = "Circle (Gumdrop)"
    case star     = "Star"
    case heart    = "Heart"
    case cloud    = "Cloud"
    case oldBear  = "Old Bear"
    case newBear  = "New Bear"
    case mushroom = "Mushroom"

    var id: String { rawValue }

    /// SF Symbol used in the shape picker grid.
    var sfSymbol: String {
        switch self {
        case .circle:   return "circle.fill"
        case .star:     return "star.fill"
        case .heart:    return "heart.fill"
        case .cloud:    return "cloud.fill"
        case .oldBear:  return "teddybear.fill"
        case .newBear:  return "teddybear"
        case .mushroom: return "umbrella.fill"
        }
    }
}

// MARK: - Active Substance

/// The active substance being dosed into the batch.
/// Each active has a default concentration unit (ug, mg, or g).
enum Active: String, CaseIterable, Identifiable {
    case mdma       = "MDMA"
    case lsd        = "LSD"
    case psilocybin = "Shrooms"
    case mescaline  = "Mesc"
    case ketamine   = "Ket"

    var id: String { rawValue }

    /// Default concentration unit for this substance.
    var unit: ConcentrationUnit {
        switch self {
        case .mdma:       return .mg
        case .lsd:        return .ug
        case .psilocybin: return .g
        case .mescaline:  return .mg
        case .ketamine:   return .mg
        }
    }
}

// MARK: - Gummy Color

/// Food coloring options with their display colors.
enum GummyColor: String, CaseIterable, Identifiable {
    case coral  = "Coral"
    case green  = "Green"
    case red    = "Red"
    case yellow = "Yellow"
    case blue   = "Blue"
    case plum   = "Plum"

    var id: String { rawValue }

    /// The SwiftUI `Color` rendered in the color picker circle.
    var swiftUIColor: Color {
        switch self {
        case .coral:  return Color(red: 1.0,  green: 0.45, blue: 0.35)
        case .green:  return Color(red: 0.2,  green: 0.78, blue: 0.35)
        case .red:    return Color(red: 0.9,  green: 0.15, blue: 0.18)
        case .yellow: return Color(red: 0.95, green: 0.82, blue: 0.2)
        case .blue:   return Color(red: 0.2,  green: 0.5,  blue: 0.95)
        case .plum:   return Color(red: 0.55, green: 0.2,  blue: 0.6)
        }
    }
}

// MARK: - Terpene Flavor Catalog

/// Terpene-based flavor isolates. Dosed in PPM (parts per million by volume).
enum TerpeneFlavor: String, CaseIterable, Identifiable {
    case almondJoy        = "Almond Joy"
    case bananaCream      = "Banana Cream"
    case blueberryCake    = "Blueberry Cake"
    case candyCane        = "Candy Cane"
    case caramelApple     = "Caramel Apple"
    case cherryCobbler    = "Cherry Cobbler"
    case cherryLimeade    = "Cherry Limeade"
    case chocolate        = "Chocolate"
    case churro           = "Churro"
    case cinnamonRoll     = "Cinnamon Roll"
    case coconut          = "Coconut"
    case cola             = "Cola"
    case cottonCandy      = "Cotton Candy"
    case cucumber         = "Cucumber"
    case espresso         = "Espresso"
    case greenApple       = "Green Apple"
    case gummyBear        = "Gummy Bear"
    case hotCocoa         = "Hot Cocoa"
    case kiwi             = "Kiwi"
    case lemonade         = "Lemonade"
    case lime             = "Lime"
    case mango            = "Mango"
    case orange           = "Orange"
    case orangesicle      = "Orangesicle"
    case passionfruit     = "Passionfruit"
    case peachesNCream    = "Peaches N' Cream"
    case peppermintBark   = "Peppermint Bark"
    case pineapple        = "Pineapple"
    case pomegranate      = "Pomegranate"
    case pumpkinSpice     = "Pumpkin Spice"
    case skittlesCandy    = "Skittles Candy"
    case sourGrapes       = "Sour Grapes"
    case sourPatch        = "Sour Patch"
    case spearmint        = "Spearmint"
    case strawberry       = "Strawberry"
    case strawberryBanana = "Strawberry Banana"
    case vanilla          = "Vanilla"
    case watermelon       = "Watermelon"
    case wildBerry        = "Wild Berry"

    var id: String { rawValue }
}

// MARK: - Flavor Oil Catalog

/// Oil-based flavor extracts. Dosed as a volume-percent of the total mix.
enum FlavorOil: String, CaseIterable, Identifiable {
    case apple          = "Apple"
    case apricot        = "Apricot"
    case bananaCreampie = "Banana Creampie"
    case blackCherry    = "Black Cherry"
    case blackberry     = "Blackberry"
    case blueberry      = "Blueberry"
    case cherry         = "Cherry"
    case coconut        = "Coconut"
    case cranberry      = "Cranberry"
    case grape          = "Grape"
    case lemonade       = "Lemonade"
    case melon          = "Melon"
    case orange         = "Orange"
    case orangeCream    = "Orange Cream"
    case pear           = "Pear"
    case pomegranate    = "Pomegranate"
    case raspberry      = "Raspberry"
    case strawberry     = "Strawberry"
    case tropicalPunch  = "Tropical Punch"
    case watermelon     = "Watermelon"

    var id: String { rawValue }
}

// MARK: - Flavor Selection (Type-Erased)

/// A single flavor choice — either a terpene or an oil.
/// Used as a dictionary key in `BatchConfigViewModel.selectedFlavors`.
enum FlavorSelection: Hashable, Identifiable {
    case terpene(TerpeneFlavor)
    case oil(FlavorOil)

    var id: String {
        switch self {
        case .terpene(let t): return "terp-\(t.rawValue)"
        case .oil(let o):     return "oil-\(o.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case .terpene(let t): return t.rawValue
        case .oil(let o):     return o.rawValue
        }
    }

    var sourceType: String {
        switch self {
        case .terpene: return "Terpene"
        case .oil:     return "Flavor Oil"
        }
    }
}

// MARK: - Flavor Source Type

/// Identifies which flavor picker tab is active.
enum FlavorSourceType: String, CaseIterable, Identifiable {
    case terpenes = "Terpenes"
    case oils     = "Flavor Oils"

    var id: String { rawValue }
}
