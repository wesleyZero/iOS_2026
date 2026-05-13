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
    var bear = MoldSpec(.bear, 35, 4.600)
    var star = MoldSpec(.star, 67, 2.211)
    var cloud = MoldSpec(.cloud, 420, 2.182)
    var circle = MoldSpec(.circle, 88, 2.292)

    // Sugar
    var glucoseToSugarMassRatio: Double = 1.000

    var glucoseToSugarVolumeRatio: Double {
        glucoseToSugarMassRatio * (SubstanceDensity.sucrose.gPerML / SubstanceDensity.glucoseSyrup.gPerML)
    }

    // Additives
    var potassiumSorbatePercent: Double = 0.078
    var citricAcidPercent: Double = 0.638

    // Ratios
    var gelatinToWaterMassRatio: Double = 3.000
    var sugarToWaterMassRatio: Double = 4.769

    // Computed: average sugar density (50/50 glucose syrup + granulated)
    var averageSugarDensity: Double {
        (SubstanceDensity.glucoseSyrup.gPerML + SubstanceDensity.sucrose.gPerML) / 2.0
    }

    // Sugar mix density from equation (4): rho_mix = (1/(phi+1)) * rho_water + (phi/(phi+1)) * rho_sugar
    var sugarMixDensity: Double {
        let phi = sugarToWaterMassRatio
        return (1.0 / (phi + 1.0)) * SubstanceDensity.water.gPerML
             + (phi / (phi + 1.0)) * averageSugarDensity
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
