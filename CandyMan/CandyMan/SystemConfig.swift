//
//  SystemConfig.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

struct MoldSpec {
    var shape: GummyShape
    var count: Int
    var volume_ml: Double

    init(_ shape: GummyShape, _ count: Int, _ volume_ml: Double) {
        self.shape = shape
        self.count = count
        self.volume_ml = volume_ml
    }
}

@Observable
class SystemConfig {
    var bear = MoldSpec(.bear, 69, 2.339)
    var star = MoldSpec(.star, 67, 2.211)
    var cloud = MoldSpec(.cloud, 420, 2.182)
    var circle = MoldSpec(.circle, 88, 2.292)

    // Sugar
    var glucoseToSugarMassRatio: Double = 1.0

    var glucoseToSugarVolumeRatio: Double {
        glucoseToSugarMassRatio * (SubstanceDensity.sucrose.gPerML / SubstanceDensity.glucoseSyrup.gPerML)
    }

    // Additives
    var potassiumSorbatePercent: Double = 0.1
    var citricAcidPercent: Double = 1.0

    // Water
    var gelatinWaterPercent: Double = 22.0

    // Pre-Active Gel to Water Mass Ratio
    var gelToWaterMassRatio: Double = 1.0

    var gelToWaterVolumeRatio: Double {
        gelToWaterMassRatio * (SubstanceDensity.water.gPerML / SubstanceDensity.gelatin.gPerML)
    }

    func setSpec(_ spec: MoldSpec, for shape: GummyShape) {
        switch shape {
        case .bear:   bear = spec
        case .star:   star = spec
        case .cloud:  cloud = spec
        case .circle: circle = spec
        }
    }

    func spec(for shape: GummyShape) -> MoldSpec {
        switch shape {
        case .bear:   return bear
        case .star:   return star
        case .cloud:  return cloud
        case .circle: return circle
        }
    }
}
