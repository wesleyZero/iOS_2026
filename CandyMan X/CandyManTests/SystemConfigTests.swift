//
//  SystemConfigTests.swift
//  CandyManTests
//
//  Tests for SystemConfig — global configuration, factory defaults,
//  JSON round-tripping, batch ID generation, and scale/beaker recommendations.
//

import Testing
@testable import CandyMan

struct SystemConfigTests {

    // MARK: - Factory Defaults

    @Test func factoryMoldSpecs() {
        let config = TestFixtures.makeDefaultSystemConfig()

        #expect(config.newBear.count == 35)
        #expect(config.newBear.volumeML == 3.946)
        #expect(config.oldBear.count == 24)
        #expect(config.oldBear.volumeML == 4.600)
        #expect(config.circle.count == 35)
        #expect(config.star.count == 28)
        #expect(config.heart.count == 36)
        #expect(config.cloud.count == 36)
        #expect(config.mushroom.count == 15)
    }

    @Test func moldSpecLookup() {
        let config = TestFixtures.makeDefaultSystemConfig()

        for shape in GummyShape.allCases {
            let spec = config.spec(for: shape)
            #expect(spec.shape == shape)
            #expect(spec.count > 0)
            #expect(spec.volumeML > 0)
        }
    }

    @Test func densityDefaults() {
        let config = TestFixtures.makeDefaultSystemConfig()

        #expect(config.densityWater == 0.9982)
        #expect(config.densityGlucoseSyrup == 1.4500)
        #expect(config.densitySucrose == 1.5872)
        #expect(config.densityGelatin == 1.3500)
        #expect(config.densityCitricAcid == 1.6650)
        #expect(config.densityPotassiumSorbate == 1.3630)
        #expect(config.densityFlavorOil == 1.0360)
        #expect(config.densityFoodColoring == 1.2613)
        #expect(config.densityTerpenes == 0.8411)
    }

    @Test func additiveDefaults() {
        let config = TestFixtures.makeDefaultSystemConfig()

        #expect(config.citricAcidPercent == 0.786)
        #expect(config.potassiumSorbatePercent == 0.096)
        #expect(config.additivesAreDefault == true)
    }

    @Test func ratioDefaults() {
        let config = TestFixtures.makeDefaultSystemConfig()

        #expect(config.waterToGelatinMassRatio == 3.000)
        #expect(config.waterMassPercentInSugarMix == 17.34)
        #expect(config.glucoseToSugarMassRatio == 1.000)
    }

    // MARK: - Factory Reset

    @Test func factoryResetRestoresAllValues() {
        let config = TestFixtures.makeDefaultSystemConfig()

        // Mutate several values
        config.densityWater = 999.0
        config.citricAcidPercent = 50.0
        config.waterToGelatinMassRatio = 99.0
        config.newBear = MoldSpec(.newBear, 99, 99.9)

        // Factory reset
        config.factoryReset()

        // Verify restoration
        #expect(config.densityWater == 0.9982)
        #expect(config.citricAcidPercent == 0.786)
        #expect(config.waterToGelatinMassRatio == 3.000)
        #expect(config.newBear.count == 35)
        #expect(config.newBear.volumeML == 3.946)
    }

    // MARK: - Derived Ratios

    @Test func sugarToWaterMassRatio() {
        let config = TestFixtures.makeDefaultSystemConfig()
        // waterMassPercent = 17.34 → ratio = (100/17.34) - 1 = 4.7688...
        let expected = (100.0 / 17.34) - 1.0
        #expect(abs(config.sugarToWaterMassRatio - expected) < 0.001)
    }

    @Test func sugarMixDensityFormula() {
        let config = TestFixtures.makeDefaultSystemConfig()
        let phi = config.sugarToWaterMassRatio
        let expected = (1.0 / (phi + 1.0)) * config.densityWater
            + (phi / (phi + 1.0)) * config.averageSugarDensity
        #expect(abs(config.sugarMixDensity - expected) < 0.0001)
    }

    @Test func averageSugarDensity() {
        let config = TestFixtures.makeDefaultSystemConfig()
        let expected = (config.densityGlucoseSyrup + config.densitySucrose) / 2.0
        #expect(abs(config.averageSugarDensity - expected) < 0.0001)
    }

    // MARK: - Batch ID Generation

    @Test func batchIDSequence() {
        let config = TestFixtures.makeDefaultSystemConfig()
        config.batchIDCounter = 0

        #expect(config.peekNextBatchID() == "AA")
        let first = config.nextBatchID()
        #expect(first == "AA")

        #expect(config.peekNextBatchID() == "AB")
        let second = config.nextBatchID()
        #expect(second == "AB")
    }

    @Test func batchIDWrapsToBA() {
        let config = TestFixtures.makeDefaultSystemConfig()
        config.batchIDCounter = 25  // AZ

        let az = config.nextBatchID()
        #expect(az == "AZ")

        let ba = config.nextBatchID()
        #expect(ba == "BA")
    }

    // MARK: - Settings JSON Round-Trip

    @Test func settingsJSONRoundTrip() {
        let config = TestFixtures.makeDefaultSystemConfig()

        // Mutate some values
        config.densityWater = 1.111
        config.citricAcidPercent = 0.5
        config.newBear = MoldSpec(.newBear, 40, 4.0)

        // Export
        let json = config.settingsToJSON()

        // Create a fresh config and import
        let config2 = TestFixtures.makeDefaultSystemConfig()
        config2.loadSettings(from: json)

        // Verify
        #expect(config2.densityWater == 1.111)
        #expect(config2.citricAcidPercent == 0.5)
        #expect(config2.spec(for: .newBear).count == 40)
        #expect(config2.spec(for: .newBear).volumeML == 4.0)
    }

    // MARK: - Scale Recommendations

    @Test func recommendedScaleForSmallMass() {
        let config = TestFixtures.makeDefaultSystemConfig()
        // 50g should fit on Scale A (0.001g, 100g capacity)
        let scale = config.recommendedScale(forMassGrams: 50)
        #expect(scale != nil)
        #expect(scale!.resolution == 0.001)
    }

    @Test func recommendedScaleForLargeMass() {
        let config = TestFixtures.makeDefaultSystemConfig()
        // 200g won't fit on Scale A (100g max), should get Scale B (500g)
        let scale = config.recommendedScale(forMassGrams: 200)
        #expect(scale != nil)
        #expect(scale!.resolution == 0.01)
    }

    // MARK: - Beaker Recommendations

    @Test func recommendedBeakerForSmallVolume() {
        let config = TestFixtures.makeDefaultSystemConfig()
        let beaker = config.recommendedBeaker(forVolumeML: 3.0)
        #expect(beaker != nil)
        #expect(beaker!.name == "Beaker 5ml")
    }

    @Test func recommendedBeakerForMediumVolume() {
        let config = TestFixtures.makeDefaultSystemConfig()
        let beaker = config.recommendedBeaker(forVolumeML: 120.0)
        #expect(beaker != nil)
        #expect(beaker!.name == "Beaker 150ml")
    }

    // MARK: - Container Tare

    @Test func containerTareOverrides() {
        let config = TestFixtures.makeDefaultSystemConfig()

        let original = config.containerTare(for: "Beaker 50ml")
        #expect(original == 29.312)

        config.setContainerTare(30.0, for: "Beaker 50ml")
        #expect(config.containerTare(for: "Beaker 50ml") == 30.0)
        #expect(config.containerTareIsOverridden(for: "Beaker 50ml") == true)

        config.resetContainerTare(for: "Beaker 50ml")
        #expect(config.containerTare(for: "Beaker 50ml") == 29.312)
    }

    // MARK: - Density Override Detection

    @Test func densityDefaultDetection() {
        let config = TestFixtures.makeDefaultSystemConfig()
        #expect(config.densityIsDefault(\.densityWater) == true)

        config.densityWater = 1.5
        #expect(config.densityIsDefault(\.densityWater) == false)

        config.resetDensity(\.densityWater)
        #expect(config.densityIsDefault(\.densityWater) == true)
    }
}
