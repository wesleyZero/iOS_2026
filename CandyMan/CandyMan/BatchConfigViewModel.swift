//
//  BatchConfigViewModel.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

enum ConcentrationUnit: String, CaseIterable, Identifiable {
    case mg = "mg"
    case ml = "ml"
    case g = "g"

    var id: String { self.rawValue }
}

@Observable
class BatchConfigViewModel {
    var selectedShape: GummyShape = .bear
    var trayCount: Int = 1
    var activeConcentration: Double = 10.0
    let units: ConcentrationUnit = .mg
}

//create a class for the tray sizes? because I will want to have a way for the user to modify the volume?



