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

    // MARK: - Per-Measurement Resolutions

    // Beaker-scale measurements (g)
    var resBeakerEmpty: MeasurementResolution              = .thousandth
    var resBeakerPlusGelatin: MeasurementResolution        = .thousandth
    var resSubstratePlusSugar: MeasurementResolution       = .thousandth
    var resSubstratePlusActivation: MeasurementResolution  = .thousandth
    var resBeakerPlusResidue: MeasurementResolution        = .thousandth

    // Syringe-scale measurements (g)
    var resSyringeClean: MeasurementResolution             = .thousandth
    var resSyringePlusGummyMix: MeasurementResolution      = .thousandth
    var resSyringeResidue: MeasurementResolution           = .thousandth

    // Volume measurement (mL)
    var resSyringeVolume: MeasurementResolution            = .thousandth

    // Mold count measurement
    var resMoldsFilled: MeasurementResolution              = .tenth

    // MARK: - Derived Decimal Places (error propagation)

    /// Coarsest beaker-scale resolution (across all beaker inputs)
    private var coarsestBeakerDP: Int {
        min(resBeakerEmpty.decimalPlaces,
        min(resBeakerPlusGelatin.decimalPlaces,
        min(resSubstratePlusSugar.decimalPlaces,
        min(resSubstratePlusActivation.decimalPlaces,
            resBeakerPlusResidue.decimalPlaces))))
    }

    /// Coarsest syringe-scale resolution (across all syringe inputs)
    private var coarsestSyringeDP: Int {
        min(resSyringeClean.decimalPlaces,
        min(resSyringePlusGummyMix.decimalPlaces,
            resSyringeResidue.decimalPlaces))
    }

    /// Decimal places for a subtraction of two specific measurements
    func dpFor(_ a: MeasurementResolution, _ b: MeasurementResolution) -> Int {
        min(a.decimalPlaces, b.decimalPlaces)
    }

    /// Decimal places for calculations using only beaker measurements
    var beakerDP: Int { coarsestBeakerDP }

    /// Decimal places for calculations using only syringe measurements
    var syringeDP: Int { coarsestSyringeDP }

    /// Decimal places for calculations mixing beaker + syringe
    var mixedDP: Int { min(beakerDP, syringeDP) }

    /// Decimal places for calculations involving all instrument types
    var allDP: Int { min(mixedDP, resSyringeVolume.decimalPlaces) }

    /// Decimal places for mold-count–related calculations
    var moldsDP: Int { resMoldsFilled.decimalPlaces }

    // MARK: - Batch ID Counter (persisted via UserDefaults)

    var nextBatchIDValue: Int = UserDefaults.standard.integer(forKey: "CandyMan_nextBatchIDValue") {
        didSet { UserDefaults.standard.set(nextBatchIDValue, forKey: "CandyMan_nextBatchIDValue") }
    }

    /// Returns the next batch ID string and increments the counter.
    func consumeNextBatchID() -> String {
        let id = BatchIDHelper.string(from: nextBatchIDValue)
        nextBatchIDValue += 1
        return id
    }

    /// Returns the next batch ID string WITHOUT incrementing (for pre-fill).
    func peekNextBatchID() -> String {
        BatchIDHelper.string(from: nextBatchIDValue)
    }

    // MARK: - Spec Accessors

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
