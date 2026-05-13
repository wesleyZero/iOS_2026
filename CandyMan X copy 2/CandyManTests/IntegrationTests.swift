//
//  IntegrationTests.swift
//  CandyManTests
//
//  End-to-end pipeline tests: configure inputs → calculate → verify outputs
//  match the real "Tropical Punch" batch data.
//

import Testing
@testable import CandyMan

struct IntegrationTests {

    // MARK: - Full Pipeline

    @Test func tropicalPunchFullPipeline() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()

        // Step 1: Verify inputs
        #expect(vm.totalGummies(using: config) == 35)
        #expect(vm.selectedShape == .newBear)

        // Step 2: Calculate
        let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)

        // Step 3: Verify volume targets
        #expect(abs(result.vBase - 138.11) < 0.01)
        #expect(abs(result.vMix - 142.2533) < 0.01)

        // Step 4: Verify volume budget closes
        let totalVol = result.activationMix.totalVolumeML
            + result.gelatinMix.totalVolumeML
            + result.sugarMix.totalVolumeML
        #expect(abs(totalVol - result.vMix) < 0.001)

        // Step 5: Verify all 3 mix groups present
        #expect(result.activationMix.components.count >= 3)
        #expect(result.gelatinMix.components.count == 2)
        #expect(result.sugarMix.components.count == 3)

        // Step 6: Verify component count matches expectation
        // Activation: citric + sorbate + 3 colors + 2 oils + 2 terpenes + water = 10
        #expect(result.activationMix.components.count == 10)
    }

    // MARK: - Measurement Derivation Pipeline

    @Test func tropicalPunchMeasurementDerivations() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let config = TestFixtures.makeDefaultSystemConfig()

        // Chain of derivations must all succeed
        let gelatinAdded = vm.calcMassGelatinAdded
        let sugarAdded = vm.calcMassSugarAdded
        let activeAdded = vm.calcMassActiveAdded
        let finalMix = vm.calcMassFinalMixtureInBeaker
        let beakerResidue = vm.calcMassBeakerResidue
        let syringeResidue = vm.calcMassSyringeResidue
        let totalLoss = vm.calcMassTotalLoss
        let transferred = vm.calcMassMixTransferredToMold
        let density = vm.calcDensityFinalMix(systemConfig: config)

        // None should be nil
        #expect(gelatinAdded != nil)
        #expect(sugarAdded != nil)
        #expect(activeAdded != nil)
        #expect(finalMix != nil)
        #expect(beakerResidue != nil)
        #expect(syringeResidue != nil)
        #expect(totalLoss != nil)
        #expect(transferred != nil)
        #expect(density != nil)

        // Verify chain: finalMix = gelatin + sugar + active
        let sumAdded = gelatinAdded! + sugarAdded! + activeAdded!
        #expect(abs(finalMix! - sumAdded) < 0.001)

        // Verify: transferred = finalMix - totalLoss
        #expect(abs(transferred! - (finalMix! - totalLoss!)) < 0.001)

        // Verify: totalLoss = beakerResidue + syringeResidue
        #expect(abs(totalLoss! - (beakerResidue! + syringeResidue!)) < 0.001)

        // Density should be reasonable (> 1.0 for gummy mix)
        #expect(density! > 1.0)
        #expect(density! < 2.0)
    }

    // MARK: - Relative Data (mass %, vol %)

    @Test func tropicalPunchRelativeData() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)

        // All component volumes should sum to vMix
        var allComponents: [BatchComponent] = []
        allComponents.append(contentsOf: result.activationMix.components)
        allComponents.append(contentsOf: result.gelatinMix.components)
        allComponents.append(contentsOf: result.sugarMix.components)

        // Volume percentages should sum to ~100%
        let totalVol = allComponents.reduce(0.0) { $0 + $1.volumeML }
        let volPercents = allComponents.map { ($0.volumeML / totalVol) * 100.0 }
        let sumPercents = volPercents.reduce(0, +)
        #expect(abs(sumPercents - 100.0) < 0.01)

        // Mass percentages should sum to ~100%
        let totalMass = allComponents.reduce(0.0) { $0 + $1.massGrams }
        let massPercents = allComponents.map { ($0.massGrams / totalMass) * 100.0 }
        let sumMassPercents = massPercents.reduce(0, +)
        #expect(abs(sumMassPercents - 100.0) < 0.01)
    }

    // MARK: - Mix Group Totals

    @Test func tropicalPunchMixTotals() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)

        // Each mix group's totals should be consistent
        for mix in [result.activationMix, result.gelatinMix, result.sugarMix] {
            let componentVolSum = mix.components.reduce(0.0) { $0 + $1.volumeML }
            let componentMassSum = mix.components.reduce(0.0) { $0 + $1.massGrams }

            #expect(abs(mix.totalVolumeML - componentVolSum) < 0.001,
                    "\(mix.name) volume sum mismatch")
            #expect(abs(mix.totalMassGrams - componentMassSum) < 0.001,
                    "\(mix.name) mass sum mismatch")
        }
    }

    // MARK: - Active Loss & Dose Calculation

    @Test func tropicalPunchActiveLossAndDose() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let config = TestFixtures.makeDefaultSystemConfig()

        let activeLoss = vm.calcActiveLoss(systemConfig: config)
        #expect(activeLoss != nil)
        #expect(activeLoss! > 0)  // Some loss expected
        #expect(activeLoss! < 350.0)  // Total active = 10 × 35 = 350 µg

        let avgDose = vm.calcAverageGummyActiveDose(systemConfig: config)
        #expect(avgDose != nil)
        #expect(avgDose! > 0)
        #expect(avgDose! < 10.0)  // Should be slightly less than 10 µg due to loss
    }

    // MARK: - Changing Shapes Produces Different Results

    @Test func differentShapesDifferentVolumes() {
        let config = TestFixtures.makeDefaultSystemConfig()
        var volumes: [String: Double] = [:]

        for shape in GummyShape.allCases {
            let vm = TestFixtures.makeTropicalPunchViewModel()
            vm.selectedShape = shape
            let result = BatchCalculator.calculate(viewModel: vm, systemConfig: config)
            volumes[shape.rawValue] = result.vBase
        }

        // Different shapes have different cavity volumes → different vBase
        // At minimum, old bear (4.6mL × 24) vs new bear (3.946 × 35) should differ
        #expect(volumes["Old Bear"] != volumes["New Bear"])
        #expect(volumes["Mushroom"] != volumes["Circle (Gumdrop)"])
    }

    // MARK: - Overage Affects All Mix Groups

    @Test func overageScalesAllMixes() {
        let config = TestFixtures.makeDefaultSystemConfig()

        let vm1 = TestFixtures.makeTropicalPunchViewModel()
        vm1.overageFactor = 1.0
        let result1 = BatchCalculator.calculate(viewModel: vm1, systemConfig: config)

        let vm2 = TestFixtures.makeTropicalPunchViewModel()
        vm2.overageFactor = 1.10
        let result2 = BatchCalculator.calculate(viewModel: vm2, systemConfig: config)

        // 10% overage should produce ~10% more volume
        let ratio = result2.vMix / result1.vMix
        #expect(abs(ratio - 1.10) < 0.001)

        // All mix totals should be larger
        #expect(result2.activationMix.totalVolumeML > result1.activationMix.totalVolumeML)
        #expect(result2.gelatinMix.totalVolumeML > result1.gelatinMix.totalVolumeML)
        #expect(result2.sugarMix.totalVolumeML > result1.sugarMix.totalVolumeML)
    }
}
