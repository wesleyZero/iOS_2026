//
//  CartCalculator.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//
//  Implements the spreadsheet formulas from "Cannabis Cart Calculator":
//
//  INPUTS:
//    E7  = Final Volume [ml]       → viewModel.finalVolume_mL
//    E8  = Weed Composition [%]    → viewModel.weedComposition
//    E9  = Terp Composition [%]    → viewModel.terpComposition
//    E10 = Base Composition        → 1 - E8 - E9  (when social dosing)
//    E11 = Cut Composition         → 1 - E9 - E10 (when base > 0)
//    E12 = Social Dosing           → E8 < 80%
//
//  OUTPUTS:
//    J8  = Weed Distillate [ml]    → E8 × E7
//    J9  = Base [ml]               → E10 × E7
//    J10 = Cut [ml]                → E7 × (1 - E8 - E9 - E10)
//    J11 = Total Flavor Terps [ml] → E7 × E9
//    J7  = Total [ml]              → SUM(J8:J11)
//
//  TERPENE BREAKDOWN (rows 16-33):
//    J[n] = E[n] × E7 × E9        → relative% × finalVol × terpComp
//

import Foundation

// MARK: - Cart Component (a single ingredient line)

struct CartComponent: Identifiable {
    let id = UUID()
    let label: String
    let volume_mL: Double
    let displayUnit: String   // "ml" or "µL"
}

// MARK: - Cart Result

struct CartResult {
    let finalVolume_mL: Double
    let weedDistillate_mL: Double
    let base_mL: Double
    let cut_mL: Double
    let totalTerpenes_mL: Double
    let totalOutput_mL: Double
    let terpeneBreakdown: [CartComponent]

    /// Per-cart volumes (divide by cart count)
    let perCartWeed_mL: Double
    let perCartBase_mL: Double
    let perCartCut_mL: Double
    let perCartTerp_mL: Double
    let perCartTotal_mL: Double

    // Composition percentages for the pie chart
    var weedPercent: Double { finalVolume_mL > 0 ? (weedDistillate_mL / finalVolume_mL) * 100 : 0 }
    var basePercent: Double { finalVolume_mL > 0 ? (base_mL / finalVolume_mL) * 100 : 0 }
    var cutPercent: Double  { finalVolume_mL > 0 ? (cut_mL / finalVolume_mL) * 100 : 0 }
    var terpPercent: Double { finalVolume_mL > 0 ? (totalTerpenes_mL / finalVolume_mL) * 100 : 0 }
}

// MARK: - Calculator

struct CartCalculator {

    static func calculate(viewModel: CartConfigViewModel) -> CartResult {
        let V = viewModel.finalVolume_mL
        let weed = viewModel.weedComposition
        let terp = viewModel.terpComposition
        let base = viewModel.baseComposition

        // Core volumes (spreadsheet J8:J11)
        let vWeed = weed * V                          // J8 = E8 × E7
        let vBase = base * V                          // J9 = E10 × E7
        let vCut  = V * (1.0 - weed - terp - base)   // J10
        let vTerp = V * terp                          // J11 = E7 × E9
        let vTotal = vWeed + vBase + max(0, vCut) + vTerp   // J7

        // Terpene breakdown (spreadsheet rows 16-33)
        // Each: volume = relative% × finalVol × terpComp
        var breakdown: [CartComponent] = []

        let sortedTerps = viewModel.selectedTerpenes.sorted { $0.key.id < $1.key.id }
        for (selection, relativePct) in sortedTerps {
            let fraction = relativePct / 100.0
            let vol = fraction * V * terp   // J[n] = E[n] × E7 × E9
            breakdown.append(CartComponent(
                label: selection.displayName,
                volume_mL: vol,
                displayUnit: vol < 0.01 ? "µL" : "ml"
            ))
        }

        let count = Double(max(1, viewModel.cartCount))

        return CartResult(
            finalVolume_mL: V,
            weedDistillate_mL: vWeed,
            base_mL: vBase,
            cut_mL: max(0, vCut),
            totalTerpenes_mL: vTerp,
            totalOutput_mL: vTotal,
            terpeneBreakdown: breakdown,
            perCartWeed_mL: vWeed / count,
            perCartBase_mL: vBase / count,
            perCartCut_mL: max(0, vCut) / count,
            perCartTerp_mL: vTerp / count,
            perCartTotal_mL: vTotal / count
        )
    }
}
