//
//  SystemConfig.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import Foundation
import SwiftUI

@Observable
class SystemConfig {

    init() {
        if let saved = UserDefaults.standard.string(forKey: "cartAccentTheme"),
           let theme = AccentTheme(rawValue: saved) {
            self.accentTheme = theme
        }
        self.batchIDCounter = UserDefaults.standard.integer(forKey: "cartBatchIDCounter")
    }

    // MARK: - Batch ID Counter (base-26: AA, AB, ..., AZ, BA, ...)

    var batchIDCounter: Int = 0 {
        didSet { UserDefaults.standard.set(batchIDCounter, forKey: "cartBatchIDCounter") }
    }

    func nextBatchID() -> String {
        let id = batchIDString(for: batchIDCounter)
        batchIDCounter += 1
        return id
    }

    func peekNextBatchID() -> String {
        batchIDString(for: batchIDCounter)
    }

    func batchIDString(for index: Int) -> String {
        let first = Character(UnicodeScalar(65 + (index / 26) % 26)!)
        let second = Character(UnicodeScalar(65 + index % 26)!)
        return String(first) + String(second)
    }

    func batchIDIndex(for id: String) -> Int? {
        let upper = id.uppercased()
        guard upper.count == 2,
              let first = upper.first?.asciiValue,
              let second = upper.last?.asciiValue,
              first >= 65, first <= 90, second >= 65, second <= 90
        else { return nil }
        return Int(first - 65) * 26 + Int(second - 65)
    }

    func syncBatchIDCounter(from carts: [SavedCart]) {
        var maxIndex = batchIDCounter - 1
        for cart in carts {
            if let idx = batchIDIndex(for: cart.batchID) {
                maxIndex = max(maxIndex, idx)
            }
        }
        let newCounter = maxIndex + 1
        if newCounter > batchIDCounter {
            batchIDCounter = newCounter
        }
    }

    // MARK: - Accent Theme

    var accentTheme: AccentTheme = .forest {
        didSet { UserDefaults.standard.set(accentTheme.rawValue, forKey: "cartAccentTheme") }
    }

    var accent: Color { accentTheme.color }

    // MARK: - Haptic Feedback
    var sliderVibrationsEnabled: Bool = true

    // MARK: - Developer Mode
    var developerMode: Bool = false
}
