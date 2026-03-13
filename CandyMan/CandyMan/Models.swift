//
//  Models.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation

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


