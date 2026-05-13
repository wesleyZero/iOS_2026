//
//  SavedCart.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import Foundation
import SwiftData

// MARK: - Child: Saved Terpene

@Model
class SavedCartTerpene {
    var terpeneID: String
    var name: String
    var type: String          // "Cannabis" or "Flavor"
    var percent: Double
    var volume_mL: Double

    var cart: SavedCart?

    init(terpeneID: String, name: String, type: String, percent: Double, volume_mL: Double) {
        self.terpeneID = terpeneID
        self.name = name
        self.type = type
        self.percent = percent
        self.volume_mL = volume_mL
    }
}

// MARK: - Parent: Saved Cart Batch

@Model
class SavedCart {
    var name: String
    var batchID: String
    var date: Date
    var isTrashed: Bool = false
    var trashedDate: Date? = nil

    // Cart config
    var cartSizeRaw: String
    var cartCount: Int

    // Compositions
    var weedComposition: Double
    var terpComposition: Double
    var baseComposition: Double
    var cutComposition: Double

    // Calculated volumes (total batch)
    var finalVolume_mL: Double
    var weedDistillate_mL: Double
    var base_mL: Double
    var cut_mL: Double
    var totalTerpenes_mL: Double
    var totalOutput_mL: Double

    // Per-cart volumes
    var perCartWeed_mL: Double
    var perCartBase_mL: Double
    var perCartCut_mL: Double
    var perCartTerp_mL: Double
    var perCartTotal_mL: Double

    // Terpene breakdown
    @Relationship(deleteRule: .cascade, inverse: \SavedCartTerpene.cart)
    var terpenes: [SavedCartTerpene] = []

    // Notes
    var flavorNotes: String = ""
    var flavorRating: Int = 0
    var processNotes: String = ""
    var notesLocked: Bool = false

    init(
        name: String,
        batchID: String = "",
        date: Date = .now,
        cartSizeRaw: String,
        cartCount: Int,
        weedComposition: Double,
        terpComposition: Double,
        baseComposition: Double,
        cutComposition: Double,
        finalVolume_mL: Double,
        weedDistillate_mL: Double,
        base_mL: Double,
        cut_mL: Double,
        totalTerpenes_mL: Double,
        totalOutput_mL: Double,
        perCartWeed_mL: Double,
        perCartBase_mL: Double,
        perCartCut_mL: Double,
        perCartTerp_mL: Double,
        perCartTotal_mL: Double
    ) {
        self.name = name
        self.batchID = batchID
        self.date = date
        self.cartSizeRaw = cartSizeRaw
        self.cartCount = cartCount
        self.weedComposition = weedComposition
        self.terpComposition = terpComposition
        self.baseComposition = baseComposition
        self.cutComposition = cutComposition
        self.finalVolume_mL = finalVolume_mL
        self.weedDistillate_mL = weedDistillate_mL
        self.base_mL = base_mL
        self.cut_mL = cut_mL
        self.totalTerpenes_mL = totalTerpenes_mL
        self.totalOutput_mL = totalOutput_mL
        self.perCartWeed_mL = perCartWeed_mL
        self.perCartBase_mL = perCartBase_mL
        self.perCartCut_mL = perCartCut_mL
        self.perCartTerp_mL = perCartTerp_mL
        self.perCartTotal_mL = perCartTotal_mL
    }
}

// MARK: - Batch Creation Extension

extension CartConfigViewModel {
    func makeSavedCart(name: String, batchID: String, result: CartResult) -> SavedCart {
        let cart = SavedCart(
            name: name,
            batchID: batchID,
            cartSizeRaw: cartSize.rawValue,
            cartCount: cartCount,
            weedComposition: weedComposition,
            terpComposition: terpComposition,
            baseComposition: baseComposition,
            cutComposition: cutComposition,
            finalVolume_mL: result.finalVolume_mL,
            weedDistillate_mL: result.weedDistillate_mL,
            base_mL: result.base_mL,
            cut_mL: result.cut_mL,
            totalTerpenes_mL: result.totalTerpenes_mL,
            totalOutput_mL: result.totalOutput_mL,
            perCartWeed_mL: result.perCartWeed_mL,
            perCartBase_mL: result.perCartBase_mL,
            perCartCut_mL: result.perCartCut_mL,
            perCartTerp_mL: result.perCartTerp_mL,
            perCartTotal_mL: result.perCartTotal_mL
        )

        for component in result.terpeneBreakdown {
            let terpName: String
            let terpType: String
            if let match = selectedTerpenes.first(where: { $0.key.displayName == component.label }) {
                terpName = match.key.displayName
                terpType = match.key.sourceType
            } else {
                terpName = component.label
                terpType = "Unknown"
            }
            cart.terpenes.append(SavedCartTerpene(
                terpeneID: terpName,
                name: terpName,
                type: terpType,
                percent: selectedTerpenes.first(where: { $0.key.displayName == component.label })?.value ?? 0,
                volume_mL: component.volume_mL
            ))
        }

        return cart
    }
}
