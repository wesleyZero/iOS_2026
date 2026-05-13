//
//  CartConfigViewModel.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class CartConfigViewModel {

    // MARK: - Core Inputs (mirrors spreadsheet D7-E13)

    var cartSize: CartSize = .full
    var cartCount: Int = 1

    /// Final volume = cartSize.volume_mL × cartCount
    var finalVolume_mL: Double {
        cartSize.volume_mL * Double(cartCount)
    }

    /// Weed distillate composition [%] (E8 in spreadsheet)
    var weedComposition: Double = 0.80

    /// Terpene composition [%] (E9 in spreadsheet)
    var terpComposition: Double = 0.14

    /// Social dosing flag — TRUE when weed < 80% (E12)
    var socialDosing: Bool {
        weedComposition < 0.80
    }

    /// Base composition = 1 - weed - terp (when socialDosing is true) (E10)
    var baseComposition: Double {
        socialDosing ? max(0, 1.0 - weedComposition - terpComposition) : 0.0
    }

    /// Cut composition = 1 - terp - base (when base > 0) (E11)
    var cutComposition: Double {
        baseComposition > 0 ? max(0, 1.0 - terpComposition - baseComposition) : 0.0
    }

    // MARK: - Batch State

    var batchCalculated: Bool = false

    // MARK: - Terpene Blend

    var selectedTerpenes: [TerpeneSelection: Double] = [:]
    var terpenesLocked: Bool = false
    var terpeneSourceTab: TerpeneSourceType = .cannabis
    var terpeneCompositionLocked: Bool = false

    func toggleTerpene(_ terpene: TerpeneSelection) {
        guard !terpenesLocked else { return }
        if selectedTerpenes[terpene] != nil {
            selectedTerpenes.removeValue(forKey: terpene)
        } else {
            selectedTerpenes[terpene] = 0.0
        }
    }

    func isSelected(_ terpene: TerpeneSelection) -> Bool {
        selectedTerpenes[terpene] != nil
    }

    func lockTerpenes() {
        guard !selectedTerpenes.isEmpty else { return }
        let values = distributeEvenlyInMultiplesOf5(count: selectedTerpenes.count)
        for (key, value) in zip(selectedTerpenes.keys, values) {
            selectedTerpenes[key] = value
        }
        terpenesLocked = true
    }

    func unlockTerpenes() {
        terpenesLocked = false
    }

    var blendTotal: Double {
        selectedTerpenes.values.reduce(0, +)
    }

    func lockComposition() {
        let cannabis = selectedTerpenes.keys.filter { if case .cannabis = $0 { return true }; return false }
        let flavors = selectedTerpenes.keys.filter { if case .flavor = $0 { return true }; return false }
        let cannabisTotal = cannabis.reduce(0.0) { $0 + (selectedTerpenes[$1] ?? 0) }
        let flavorTotal = flavors.reduce(0.0) { $0 + (selectedTerpenes[$1] ?? 0) }
        let cannabisReady = cannabis.isEmpty || abs(cannabisTotal - 100) < 0.5
        let flavorsReady = flavors.isEmpty || abs(flavorTotal - 100) < 0.5
        guard cannabisReady && flavorsReady else { return }
        terpeneCompositionLocked = true
    }

    func unlockComposition() {
        terpeneCompositionLocked = false
    }

    // MARK: - Template Tracking

    var activeTemplateID: PersistentIdentifier? = nil
    var activeTemplateName: String = ""
    private var templateSnapshot: TemplateSnapshot? = nil

    struct TemplateSnapshot: Equatable {
        var cartSize: CartSize
        var cartCount: Int
        var weedComposition: Double
        var terpComposition: Double
        var selectedTerpenes: [TerpeneSelection: Double]
        var terpeneSourceTab: TerpeneSourceType
    }

    private func captureSnapshot() -> TemplateSnapshot {
        TemplateSnapshot(
            cartSize: cartSize,
            cartCount: cartCount,
            weedComposition: weedComposition,
            terpComposition: terpComposition,
            selectedTerpenes: selectedTerpenes,
            terpeneSourceTab: terpeneSourceTab
        )
    }

    var templateInputsChanged: Bool {
        guard let snapshot = templateSnapshot else { return false }
        return captureSnapshot() != snapshot
    }

    // MARK: - Reset

    func resetBatch() {
        activeTemplateID = nil
        activeTemplateName = ""
        templateSnapshot = nil
        batchCalculated = false
        cartSize = .full
        cartCount = 1
        weedComposition = 0.80
        terpComposition = 0.14
        selectedTerpenes = [:]
        terpenesLocked = false
        terpeneSourceTab = .cannabis
        terpeneCompositionLocked = false
    }

    // MARK: - Templates

    func saveAsTemplate(name: String, modelContext: ModelContext) {
        let t = CartTemplate(
            name: name,
            cartSizeRaw: cartSize.rawValue,
            cartCount: cartCount,
            weedComposition: weedComposition,
            terpComposition: terpComposition,
            terpenesLocked: terpenesLocked,
            terpeneSourceTab: terpeneSourceTab.rawValue,
            terpeneCompositionLocked: terpeneCompositionLocked
        )
        for (terp, pct) in selectedTerpenes {
            t.terpenes.append(TemplateTerpene(terpeneID: terp.id, percent: pct))
        }
        modelContext.insert(t)
        activeTemplateID = t.persistentModelID
        activeTemplateName = t.name
        templateSnapshot = captureSnapshot()
    }

    func applyTemplate(_ template: CartTemplate) {
        cartSize = CartSize(rawValue: template.cartSizeRaw) ?? .full
        cartCount = template.cartCount
        weedComposition = template.weedComposition
        terpComposition = template.terpComposition

        selectedTerpenes = [:]
        for tt in template.terpenes {
            if let sel = TerpeneSelection.fromID(tt.terpeneID) {
                selectedTerpenes[sel] = tt.percent
            }
        }
        terpenesLocked = template.terpenesLocked
        terpeneSourceTab = TerpeneSourceType(rawValue: template.terpeneSourceTab) ?? .cannabis
        terpeneCompositionLocked = template.terpeneCompositionLocked

        activeTemplateID = template.persistentModelID
        activeTemplateName = template.name
        templateSnapshot = captureSnapshot()
    }

    func clearTemplate() {
        activeTemplateID = nil
        activeTemplateName = ""
        templateSnapshot = nil
        cartSize = .full
        cartCount = 1
        weedComposition = 0.80
        terpComposition = 0.14
        selectedTerpenes = [:]
        terpenesLocked = false
        terpeneSourceTab = .cannabis
        terpeneCompositionLocked = false
    }

    // MARK: - Helpers

    private func distributeEvenlyInMultiplesOf5(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let baseSlots = Int((100.0 / Double(count)) / 5.0)
        let base = Double(baseSlots * 5)
        let remainder = 100 - baseSlots * 5 * count
        let extraSlots = remainder / 5
        return (0..<count).map { i in base + (i < extraSlots ? 5.0 : 0.0) }
    }
}
