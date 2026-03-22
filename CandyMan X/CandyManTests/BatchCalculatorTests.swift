//
//  BatchCalculatorTests.swift
//  CandyManTests
//
//  Tests for BatchCalculator — the pure, stateless calculation engine.
//  Uses the "Tropical Punch" batch as ground truth.
//

import Testing
@testable import CandyMan

struct BatchCalculatorTests {

    // MARK: - Helpers

    private func tropicalPunchResult() -> BatchResult {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        return BatchCalculator.calculate(viewModel: vm, systemConfig: config)
    }

    // MARK: - Volume Targets

    @Test func tropicalPunchVBase() {
        let result = tropicalPunchResult()
        // vBase = 35 gummies × 3.946 mL = 138.11 mL
        #expect(abs(result.vBase - 138.11) < 0.01)
    }

    @Test func tropicalPunchVMix() {
        let result = tropicalPunchResult()
        // vMix = 138.11 × 1.03 = 142.2533 mL
        #expect(abs(result.vMix - 142.2533) < 0.01)
    }

    // MARK: - Volume Budget (total == vMix)

    @Test func tropicalPunchVolumeBudgetCloses() {
        let result = tropicalPunchResult()
        let totalVol = result.activationMix.totalVolumeML
            + result.gelatinMix.totalVolumeML
            + result.sugarMix.totalVolumeML
        // All three mixes must sum exactly to vMix (within floating-point tolerance)
        #expect(abs(totalVol - result.vMix) < 0.001)
    }

    // MARK: - Activation Mix Components

    @Test func tropicalPunchCitricAcid() {
        let result = tropicalPunchResult()
        let config = TestFixtures.makeDefaultSystemConfig()
        let citric = result.activationMix.components.first { $0.label == "Citric Acid" }
        #expect(citric != nil)

        // vCitric = (0.786 / 100) × vMix
        let expectedVol = (config.citricAcidPercent / 100.0) * result.vMix
        #expect(abs(citric!.volumeML - expectedVol) < 0.001)

        // mass = vol × density
        let expectedMass = expectedVol * config.densityCitricAcid
        #expect(abs(citric!.massGrams - expectedMass) < 0.001)
    }

    @Test func tropicalPunchPotassiumSorbate() {
        let result = tropicalPunchResult()
        let config = TestFixtures.makeDefaultSystemConfig()
        let sorbate = result.activationMix.components.first { $0.label == "Potassium Sorbate" }
        #expect(sorbate != nil)

        let expectedVol = (config.potassiumSorbatePercent / 100.0) * result.vMix
        #expect(abs(sorbate!.volumeML - expectedVol) < 0.001)
    }

    @Test func tropicalPunchColors() {
        let result = tropicalPunchResult()
        let config = TestFixtures.makeDefaultSystemConfig()
        let vm = TestFixtures.makeTropicalPunchViewModel()

        let vColorTotal = (vm.colorVolumePercent / 100.0) * result.vMix

        let coral = result.activationMix.components.first { $0.label == "Coral Color" }
        let red = result.activationMix.components.first { $0.label == "Red Color" }
        let yellow = result.activationMix.components.first { $0.label == "Yellow Color" }

        #expect(coral != nil)
        #expect(red != nil)
        #expect(yellow != nil)

        // Coral = 10% of color volume
        #expect(abs(coral!.volumeML - vColorTotal * 0.10) < 0.001)
        // Red = 30%
        #expect(abs(red!.volumeML - vColorTotal * 0.30) < 0.001)
        // Yellow = 60%
        #expect(abs(yellow!.volumeML - vColorTotal * 0.60) < 0.001)

        // Mass = vol × density
        #expect(abs(coral!.massGrams - coral!.volumeML * config.densityFoodColoring) < 0.001)
    }

    @Test func tropicalPunchFlavorOils() {
        let result = tropicalPunchResult()
        let vm = TestFixtures.makeTropicalPunchViewModel()

        let vOilTotal = (vm.flavorOilVolumePercent / 100.0) * result.vMix

        let lemonade = result.activationMix.components.first { $0.label == "Lemonade Oil" }
        let tropical = result.activationMix.components.first { $0.label == "Tropical Punch Oil" }

        #expect(lemonade != nil)
        #expect(tropical != nil)

        // Lemonade = 75% of oil volume
        #expect(abs(lemonade!.volumeML - vOilTotal * 0.75) < 0.001)
        // Tropical Punch = 25%
        #expect(abs(tropical!.volumeML - vOilTotal * 0.25) < 0.001)
    }

    @Test func tropicalPunchTerpenes() {
        let result = tropicalPunchResult()
        let vm = TestFixtures.makeTropicalPunchViewModel()

        let vTerpTotal = (vm.terpeneVolumePPM / 1_000_000.0) * result.vMix

        let pineapple = result.activationMix.components.first { $0.label == "Pineapple Terpene" }
        let passionfruit = result.activationMix.components.first { $0.label == "Passionfruit Terpene" }

        #expect(pineapple != nil)
        #expect(passionfruit != nil)

        // Pineapple = 70%
        #expect(abs(pineapple!.volumeML - vTerpTotal * 0.70) < 0.0001)
        // Passionfruit = 30%
        #expect(abs(passionfruit!.volumeML - vTerpTotal * 0.30) < 0.0001)
    }

    @Test func tropicalPunchActivationWater() {
        let result = tropicalPunchResult()
        let config = TestFixtures.makeDefaultSystemConfig()

        let water = result.activationMix.components.first { $0.label == "Activation Water" }
        #expect(water != nil)

        // Activation water = solubility water for citric + sorbate + additional (0)
        let vCitric = (config.citricAcidPercent / 100.0) * result.vMix
        let mCitric = vCitric * config.densityCitricAcid
        let vSorbate = (config.potassiumSorbatePercent / 100.0) * result.vMix
        let mSorbate = vSorbate * config.densityPotassiumSorbate

        let waterForCitric = SubstanceSolubility.citricAcid.minWaterML(toDissolveGrams: mCitric)
        let waterForSorbate = SubstanceSolubility.potassiumSorbate.minWaterML(toDissolveGrams: mSorbate)
        let expectedWater = waterForCitric + waterForSorbate + 0.0

        #expect(abs(water!.volumeML - expectedWater) < 0.001)
    }

    // MARK: - Gelatin Mix

    @Test func tropicalPunchGelatinMix() {
        let result = tropicalPunchResult()
        let config = TestFixtures.makeDefaultSystemConfig()
        let vm = TestFixtures.makeTropicalPunchViewModel()

        let gelatin = result.gelatinMix.components.first { $0.label == "Gelatin" }
        let water = result.gelatinMix.components.first { $0.label == "Water" }

        #expect(gelatin != nil)
        #expect(water != nil)

        // Gelatin volume = 5.225% of vMix
        let expectedGelatinVol = (vm.gelatinPercentage / 100.0) * result.vMix
        #expect(abs(gelatin!.volumeML - expectedGelatinVol) < 0.001)

        // Gelatin mass = vol × density
        let expectedGelatinMass = expectedGelatinVol * config.densityGelatin
        #expect(abs(gelatin!.massGrams - expectedGelatinMass) < 0.001)

        // Water mass = gelatin mass × water:gelatin ratio
        let expectedWaterMass = expectedGelatinMass * config.waterToGelatinMassRatio
        #expect(abs(water!.massGrams - expectedWaterMass) < 0.001)

        // Water volume = mass / density
        let expectedWaterVol = expectedWaterMass / config.densityWater
        #expect(abs(water!.volumeML - expectedWaterVol) < 0.001)
    }

    // MARK: - Sugar Mix (Residual Closure)

    @Test func tropicalPunchSugarMixClosure() {
        let result = tropicalPunchResult()

        // Sugar mix must fill the remaining volume exactly
        let vActivation = result.activationMix.totalVolumeML
        let vGelatin = result.gelatinMix.totalVolumeML
        let expectedSugarVol = result.vMix - vActivation - vGelatin

        #expect(abs(result.sugarMix.totalVolumeML - expectedSugarVol) < 0.001)

        // Sugar mix has 3 components
        #expect(result.sugarMix.components.count == 3)

        let glucose = result.sugarMix.components.first { $0.label == "Glucose Syrup" }
        let granulated = result.sugarMix.components.first { $0.label == "Granulated Sugar" }
        let water = result.sugarMix.components.first { $0.label == "Water" }

        #expect(glucose != nil)
        #expect(granulated != nil)
        #expect(water != nil)

        // All volumes must be positive
        #expect(glucose!.volumeML > 0)
        #expect(granulated!.volumeML > 0)
        #expect(water!.volumeML > 0)
    }

    // MARK: - Mass Budget

    @Test func tropicalPunchMassBudget() {
        let result = tropicalPunchResult()
        let totalMass = result.totalMassGrams
        // Total mass should be reasonable (not zero, not negative)
        #expect(totalMass > 100)  // ~180g expected for 142mL batch
        #expect(totalMass < 300)
    }

    // MARK: - All Shapes Calculate

    @Test func allShapesProduceValidResults() {
        let config = TestFixtures.makeDefaultSystemConfig()

        for shape in GummyShape.allCases {
            let vm = TestFixtures.makeTropicalPunchViewModel()
            vm.selectedShape = shape

            let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)

            #expect(result.vBase > 0, "vBase should be positive for \(shape.rawValue)")
            #expect(result.vMix > 0, "vMix should be positive for \(shape.rawValue)")
            #expect(result.activationMix.components.count > 0, "Activation mix empty for \(shape.rawValue)")
            #expect(result.gelatinMix.components.count == 2, "Gelatin mix should have 2 components for \(shape.rawValue)")
            #expect(result.sugarMix.components.count == 3, "Sugar mix should have 3 components for \(shape.rawValue)")

            // Volume budget closes
            let totalVol = result.activationMix.totalVolumeML
                + result.gelatinMix.totalVolumeML
                + result.sugarMix.totalVolumeML
            #expect(abs(totalVol - result.vMix) < 0.001, "Volume budget doesn't close for \(shape.rawValue)")
        }
    }

    // MARK: - Edge Cases

    @Test func zeroOverageCalculation() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        vm.overageFactor = 1.0  // No overage
        let config = TestFixtures.makeDefaultSystemConfig()

        let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)
        #expect(abs(result.vMix - result.vBase) < 0.001)
    }

    @Test func noFlavorsNoColors() {
        let vm = BatchConfigViewModel()
        vm.selectedShape = .newBear
        vm.trayCount = 1
        vm.selectedActive = .lsd
        vm.activeConcentration = 10.0
        vm.gelatinPercentage = 5.225
        vm.overageFactor = 1.03
        vm.selectedFlavors = [:]
        vm.selectedColors = [:]
        vm.colorVolumePercent = 0.664
        vm.flavorOilVolumePercent = 0.451
        vm.terpeneVolumePPM = 199.0

        let config = TestFixtures.makeDefaultSystemConfig()
        let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)

        // Should still calculate with just preservatives + water
        #expect(result.vMix > 0)
        // Activation mix: citric acid + potassium sorbate + activation water = 3 components
        #expect(result.activationMix.components.count == 3)
    }

    @Test func edgeCaseExtraGummiesOnly() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        vm.trayCount = 0
        vm.extraGummies = 5
        let config = TestFixtures.makeDefaultSystemConfig()

        let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)
        let spec = config.spec(for: .newBear)
        let expectedVBase = 5.0 * spec.volumeML
        #expect(abs(result.vBase - expectedVBase) < 0.001)
    }

    @Test func preservativeWaterCalculation() {
        let config = TestFixtures.makeDefaultSystemConfig()

        // Verify SubstanceSolubility formula
        let mass = 1.0 // 1 gram
        let water = SubstanceSolubility.citricAcid.minWaterML(toDissolveGrams: mass)
        // 59 g / 100 mL → 1g needs (1/59)*100 = 1.6949 mL
        #expect(abs(water - (1.0 / 59.0) * 100.0) < 0.001)
    }
}
