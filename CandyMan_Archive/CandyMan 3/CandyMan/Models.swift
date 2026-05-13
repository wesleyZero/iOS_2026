//
//  Models.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

// MARK: - Substance Densities (g/mL)

enum SubstanceDensity: Double {
    case water              = 1.000
    case glucoseSyrup       = 1.450
    case sucrose            = 1.587
    case gelatin            = 1.270
    case citricAcid         = 1.665
    case potassiumSorbate   = 1.360
    case flavorOil          = 1.001 //= 0.910
    case foodColoring       = 1.050
    case terpenes           = 1.002

    var gPerML: Double { rawValue }
}

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

// MARK: - Measurement Resolution

enum MeasurementResolution: Double, CaseIterable, Identifiable {
    case one        = 1.0
    case tenth      = 0.1
    case hundredth  = 0.01
    case thousandth = 0.001

    var id: Double { rawValue }

    var displayLabel: String {
        switch self {
        case .one:        return "1.0 g"
        case .tenth:      return "0.1 g"
        case .hundredth:  return "0.01 g"
        case .thousandth: return "0.001 g"
        }
    }

    /// Number of decimal places this resolution supports.
    var decimalPlaces: Int {
        switch self {
        case .one:        return 0
        case .tenth:      return 1
        case .hundredth:  return 2
        case .thousandth: return 3
        }
    }

    /// Measurement uncertainty = ±(resolution / 2)
    var halfResolution: Double { rawValue / 2.0 }
}

// MARK: - Dehydration Entry

struct DehydrationEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var mass_g: Double
    var date: Date

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm, MMMM d, yyyy"
        return f.string(from: date)
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
    case bear = "Bear"
    case star = "Star"
    case cloud = "Cloud"
    case circle = "Circle"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .bear : return "teddybear.fill"
        case .star : return "star.fill"
        case .cloud : return "cloud.fill"
        case .circle : return "circle.fill"
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

// MARK: - Batch ID Helpers

struct BatchIDHelper {
    /// Convert integer counter to base-26 two-letter ID: 0 → "AA", 1 → "AB", ..., 25 → "AZ", 26 → "BA"
    static func string(from value: Int) -> String {
        let clamped = max(0, min(675, value))  // 26*26 - 1
        let first  = clamped / 26
        let second = clamped % 26
        let c1 = Character(UnicodeScalar(65 + first)!)
        let c2 = Character(UnicodeScalar(65 + second)!)
        return String([c1, c2])
    }

    /// Convert two-letter ID back to integer: "AA" → 0, "AB" → 1, etc.
    static func value(from id: String) -> Int {
        let chars = Array(id.uppercased())
        guard chars.count == 2,
              let v1 = chars[0].asciiValue, v1 >= 65, v1 <= 90,
              let v2 = chars[1].asciiValue, v2 >= 65, v2 <= 90
        else { return 0 }
        return Int(v1 - 65) * 26 + Int(v2 - 65)
    }
}
