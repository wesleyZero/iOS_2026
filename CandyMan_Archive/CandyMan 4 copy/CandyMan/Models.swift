//
//  Models.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

// MARK: - Substance Solubility (g per 100 mL water at ~20C)

enum SubstanceSolubility: Double {
    case citricAcid         = 59.0
    case potassiumSorbate   = 58.2
    case sucrose            = 200.0

    var gPer100mL: Double { rawValue }

    func minWaterML(toDissolveGrams mass: Double) -> Double {
        (mass / gPer100mL) * 100.0
    }
}

// MARK: - Units

enum ConcentrationUnit: String, CaseIterable, Identifiable {
    case ug = "ug"
    case mg = "mg"
    case g = "g"

    var id: String { self.rawValue }
}

// MARK: - Shapes

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
        case .mushroom: return "leaf.fill"
        }
    }
}

// MARK: - Actives

enum Active: String, CaseIterable, Identifiable {
    case MDMA = "MDMA"
    case LSD = "LSD"
    case psilocybin = "Shrooms"
    case Mescaline = "Mesc"
    case Ketamine = "Ket"

    var id: String { rawValue }

    var unit: ConcentrationUnit {
        switch self {
        case .MDMA : return .mg
        case .LSD : return .ug
        case .psilocybin : return .g
        case .Mescaline : return .mg
        case .Ketamine : return .mg
        }
    }
}

// MARK: - Colors

enum GummyColor: String, CaseIterable, Identifiable {
    case coral = "Coral"
    case green = "Green"
    case red = "Red"
    case yellow = "Yellow"
    case blue = "Blue"
    case plum = "Plum"

    var id: String { rawValue }

    var swiftUIColor: Color {
        switch self {
        case .coral:  return Color(red: 1.0, green: 0.45, blue: 0.35)
        case .green:  return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .red:    return Color(red: 0.9, green: 0.15, blue: 0.18)
        case .yellow: return Color(red: 0.95, green: 0.82, blue: 0.2)
        case .blue:   return Color(red: 0.2, green: 0.5, blue: 0.95)
        case .plum:   return Color(red: 0.55, green: 0.2, blue: 0.6)
        }
    }
}

// MARK: - Terpene Flavors

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

enum FlavorSourceType: String, CaseIterable, Identifiable {
    case terpenes  = "Terpenes"
    case oils      = "Flavor Oils"

    var id: String { rawValue }
}
