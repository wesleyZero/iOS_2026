//
//  TestFixtures.swift
//  CandyManTests
//
//  Shared test data factories. The "Tropical Punch" fixture mirrors real batch
//  data provided by the user and serves as the ground-truth reference for all
//  calculation, integration, and regression tests.
//

import Foundation
@testable import CandyMan

// MARK: - Test Fixtures

enum TestFixtures {

    // MARK: SystemConfig (factory defaults, no UserDefaults)

    /// Returns a fresh SystemConfig with factory defaults applied.
    /// Calls `factoryReset()` to ensure no UserDefaults bleed in.
    static func makeDefaultSystemConfig() -> SystemConfig {
        let config = SystemConfig()
        config.factoryReset()
        return config
    }

    // MARK: Tropical Punch ViewModel

    /// Configures a BatchConfigViewModel exactly matching the real
    /// "Tropical Punch" batch data provided by the user.
    ///
    /// Inputs:
    ///   - Shape: New Bear (35 wells per tray)
    ///   - Tray count: 1
    ///   - Active: LSD, 10 µg/gummy
    ///   - Gelatin: 5.225%
    ///   - Overage: 3% (factor = 1.03)
    ///   - Oils: Lemonade 75%, Tropical Punch 25%
    ///   - Terpenes: Pineapple 70%, Passionfruit 30%
    ///   - Colors: Coral 10%, Red 30%, Yellow 60%
    ///   - Terpene PPM: 199
    ///   - Flavor oil vol%: 0.451
    ///   - Color vol%: 0.664
    static func makeTropicalPunchViewModel() -> BatchConfigViewModel {
        let vm = BatchConfigViewModel()

        // Shape & trays
        vm.selectedShape = .newBear
        vm.trayCount = 1
        vm.extraGummies = 0

        // Active substance
        vm.selectedActive = .lsd
        vm.units = .ug
        vm.activeConcentration = 10.0
        vm.lsdUgPerTab = 117.0
        vm.additionalActiveWaterML = 0.0

        // Gelatin
        vm.gelatinPercentage = 5.225

        // Overage
        vm.overageFactor = 1.03

        // Flavor oils (locked)
        vm.selectedFlavors = [
            .oil(.lemonade): 75.0,
            .oil(.tropicalPunch): 25.0,
            .terpene(.pineapple): 70.0,
            .terpene(.passionfruit): 30.0,
        ]
        vm.oilsLocked = true
        vm.terpenesLocked = true
        vm.flavorCompositionLocked = true
        vm.flavorOilVolumePercent = 0.451
        vm.terpeneVolumePPM = 199.0

        // Colors (locked)
        vm.selectedColors = [
            .coral: 10.0,
            .red: 30.0,
            .yellow: 60.0,
        ]
        vm.colorsLocked = true
        vm.colorCompositionLocked = true
        vm.colorVolumePercent = 0.664

        return vm
    }

    // MARK: Tropical Punch with Measurements

    /// Same as `makeTropicalPunchViewModel()` but with post-calculate
    /// measurement fields populated from the real batch data.
    static func makeTropicalPunchWithMeasurements() -> BatchConfigViewModel {
        let vm = makeTropicalPunchViewModel()
        vm.batchCalculated = true

        // Standard-mode measurements from user's JSON
        vm.weightBeakerEmpty = 65.358
        vm.weightBeakerPlusGelatin = 75.437
        vm.weightBeakerPlusSugar = 177.113
        vm.weightBeakerPlusActive = 180.893
        vm.weightBeakerResidue = 66.224
        vm.weightSyringeEmpty = 19.253
        vm.weightSyringeResidue = 19.389
        vm.weightSyringeWithMix = 32.497
        vm.volumeSyringeGummyMix = 10.0
        vm.weightMoldsFilled = 35.0

        return vm
    }

    // MARK: Known Derived Values (from user's JSON)

    /// Expected derived calculation values for the Tropical Punch batch
    /// with the measurements above.
    enum TropicalPunchExpected {
        // Batch info
        static let totalGummies = 35
        static let trayCount = 1
        static let wellCount = 35

        // Volume targets
        static let vBase = 138.11    // 35 × 3.946
        static let vMix  = 142.2533  // 138.11 × 1.03

        // Derived measurements
        static let massGelatinAdded = 10.079       // 75.437 - 65.358
        static let massSugarAdded = 101.676        // 177.113 - 75.437
        static let massActiveAdded = 3.780         // 180.893 - 177.113
        static let massFinalMixInBeaker = 115.535  // 180.893 - 65.358
        static let massBeakerResidue = 0.866       // 66.224 - 65.358
        static let massSyringeResidue = 0.136      // 19.389 - 19.253
        static let massTotalLoss = 1.002           // 0.866 + 0.136
        static let massMixTransferred = 114.533    // 115.535 - 1.002
        static let massPerGummy = 3.272            // 114.533 / 35
        static let massOfMixInSyringe = 13.244     // 32.497 - 19.253
        static let densityFinalMix = 1.3244        // 13.244 / 10.0
    }
}
