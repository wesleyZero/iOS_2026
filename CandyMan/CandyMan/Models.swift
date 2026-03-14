//
//  Models.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation

enum ConcentrationUnit: String, CaseIterable, Identifiable {
    case ug = "ug"
    case mg = "mg"
    case g = "g"

    var id: String { self.rawValue }
}

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
