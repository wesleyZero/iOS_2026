//
//  Models.swift
//  CandyMan XI
//
//  Created by Wesley James on 5/3/26.
//

import Foundation
import SwiftUI

enum ConcentrationUnit: String, Codable, CaseIterable, Identifiable {
    case ug = "ug"
    case mg = "mg"
    case g = "g"

    var id: String { rawValue }
}

enum GummyShape: String, CaseIterable, Identifiable {
    case circle   = "Circle (Gumdrop)"
    case star     = "Star"
    case heart    = "Heart"
    case cloud    = "Cloud"
    case oldBear  = "Old Bear"
    case newBear  = "New Bear"
    case mushroom = "Mushroom"

    var id: String { rawValue }

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

/// The active ingredient being dosed into the batch.
/// Built-in cases cover common supplements and functional ingredients.
/// Users may define unlimited custom actives via `CustomActive`.
enum Active: String, CaseIterable, Identifiable {
    case vitaminC    = "Vitamin C"
    case vitaminD3   = "Vitamin D3"
    case zinc        = "Zinc"
    case magnesium   = "Magnesium"
    case melatonin   = "Melatonin"
    case b12         = "B12"
    case curcumin    = "Curcumin"
    case ashwagandha = "Ashwagandha"
    case lionsMane   = "Lion's Mane"
    case cbd         = "CBD"
    case caffeine    = "Caffeine"
    case lTheanine   = "L-Theanine"
    case custom      = "Custom"

    var id: String { rawValue }

    /// Default concentration unit for this substance.
    /// Chosen to match standard supplement dosing conventions.
    var defaultUnit: ConcentrationUnit {
        switch self {
        case .vitaminC:    return .mg
        case .vitaminD3:   return .ug
        case .zinc:        return .mg
        case .magnesium:   return .mg
        case .melatonin:   return .mg
        case .b12:         return .ug
        case .curcumin:    return .mg
        case .ashwagandha: return .mg
        case .lionsMane:   return .mg
        case .cbd:         return .mg
        case .caffeine:    return .mg
        case .lTheanine:   return .mg
        case .custom:      return .mg  // overridden by CustomActive.defaultUnit
        }
    }
}

// MARK: - Custom Active

/// A user-defined active ingredient. Used when `Active == .custom`.
/// Stored and persisted separately from the enum — the enum case `.custom`
/// is just a signal that the real data lives here.
struct CustomActive: Codable, Hashable {
    /// Display name shown throughout the UI (e.g. "MDMA", "Psilocybin", "Iron").
    var name: String
    /// The unit this substance is typically measured in.
    var defaultUnit: ConcentrationUnit
}


// MARK: - Gummy Color

enum GummyColor: String, CaseIterable, Identifiable {
    case coral  = "Coral"
    case green  = "Green"
    case red    = "Red"
    case yellow = "Yellow"
    case blue   = "Blue"
    case plum   = "Plum"

    var id: String { rawValue }

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

