//
//  Models.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import Foundation
import SwiftUI

// MARK: - Cart Sizes

enum CartSize: String, CaseIterable, Identifiable {
    case half   = "0.5 mL"
    case full   = "1.0 mL"
    case two    = "2.0 mL"

    var id: String { rawValue }

    var volume_mL: Double {
        switch self {
        case .half: return 0.5
        case .full: return 1.0
        case .two:  return 2.0
        }
    }

    var sfSymbol: String {
        switch self {
        case .half: return "battery.25percent"
        case .full: return "battery.75percent"
        case .two:  return "battery.100percent"
        }
    }
}

// MARK: - Cannabis Terpene Strains (from spreadsheet rows 16-30)

enum CannabisTerpene: String, CaseIterable, Identifiable {
    case durbanPoison    = "Durban Poison"
    case lemonHaze       = "Lemon Haze"
    case blueDream       = "Blue Dream"
    case mauiWowie       = "Maui Wowie"
    case platinumCookies = "Platinum Cookies"
    case strawnana       = "Strawnana"
    case watermelonOG    = "Watermelon OG"
    case zkittles        = "Zkittles"
    case forbiddenFruit  = "Forbidden Fruit"
    case grandDaddyPurp  = "Grand Daddy Purp"
    case kingLouisXIII   = "King Louis XIII"
    case cheese          = "Cheese"
    case harleyQuinn     = "Harley Quinn"
    case northernLights  = "Northern Lights"
    case whiteBuffalo    = "White Buffalo"

    var id: String { rawValue }
}

// MARK: - Flavor Terpenes (from spreadsheet rows 31-33)

enum FlavorTerpene: String, CaseIterable, Identifiable {
    case watermelon = "Watermelon Flavor"
    case vanilla    = "Vanilla Flavor"
    case lemonade   = "Lemonade Flavor"

    var id: String { rawValue }
}

// MARK: - Unified Terpene Selection

enum TerpeneSelection: Hashable, Identifiable {
    case cannabis(CannabisTerpene)
    case flavor(FlavorTerpene)

    var id: String {
        switch self {
        case .cannabis(let c): return "cannabis-\(c.rawValue)"
        case .flavor(let f):   return "flavor-\(f.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case .cannabis(let c): return c.rawValue
        case .flavor(let f):   return f.rawValue
        }
    }

    var sourceType: String {
        switch self {
        case .cannabis: return "Cannabis"
        case .flavor:   return "Flavor"
        }
    }
}

extension TerpeneSelection {
    static func fromID(_ id: String) -> TerpeneSelection? {
        if id.hasPrefix("cannabis-") {
            let name = String(id.dropFirst("cannabis-".count))
            if let c = CannabisTerpene(rawValue: name) { return .cannabis(c) }
        } else if id.hasPrefix("flavor-") {
            let name = String(id.dropFirst("flavor-".count))
            if let f = FlavorTerpene(rawValue: name) { return .flavor(f) }
        }
        return nil
    }
}

// MARK: - Terpene Source Tab

enum TerpeneSourceType: String, CaseIterable, Identifiable {
    case cannabis = "Cannabis"
    case flavors  = "Flavors"

    var id: String { rawValue }
}
