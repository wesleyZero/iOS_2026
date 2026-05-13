//
//  CartTemplate.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import Foundation
import SwiftData

@Model
class TemplateTerpene {
    var terpeneID: String
    var percent: Double

    var template: CartTemplate?

    init(terpeneID: String, percent: Double) {
        self.terpeneID = terpeneID
        self.percent = percent
    }
}

@Model
class CartTemplate {
    var name: String
    var createdDate: Date
    var cartSizeRaw: String
    var cartCount: Int
    var weedComposition: Double
    var terpComposition: Double
    var terpenesLocked: Bool
    var terpeneSourceTab: String
    var terpeneCompositionLocked: Bool

    @Relationship(deleteRule: .cascade, inverse: \TemplateTerpene.template)
    var terpenes: [TemplateTerpene] = []

    init(
        name: String,
        cartSizeRaw: String,
        cartCount: Int,
        weedComposition: Double,
        terpComposition: Double,
        terpenesLocked: Bool,
        terpeneSourceTab: String,
        terpeneCompositionLocked: Bool
    ) {
        self.name = name
        self.createdDate = .now
        self.cartSizeRaw = cartSizeRaw
        self.cartCount = cartCount
        self.weedComposition = weedComposition
        self.terpComposition = terpComposition
        self.terpenesLocked = terpenesLocked
        self.terpeneSourceTab = terpeneSourceTab
        self.terpeneCompositionLocked = terpeneCompositionLocked
    }
}
