//
//  BatchConfigViewModelTests.swift
//  CandyManTests
//
//  Tests for BatchConfigViewModel — the central mutable state model.
//

import Testing
@testable import CandyMan

struct BatchConfigViewModelTests {

    // MARK: - Total Gummies

    @Test func totalGummies_singleTray() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        // 1 tray × 35 wells + 0 extras = 35
        #expect(vm.totalGummies(using: config) == 35)
    }

    @Test func totalGummies_multipleTrays() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        vm.trayCount = 3
        vm.extraGummies = 5
        // 3 × 35 + 5 = 110
        #expect(vm.totalGummies(using: config) == 110)
    }

    @Test func totalGummies_zeroTraysWithExtras() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        vm.trayCount = 0
        vm.extraGummies = 10
        #expect(vm.totalGummies(using: config) == 10)
    }

    // MARK: - Total Volume

    @Test func totalVolume() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()
        let expected = 35.0 * 3.946 * 1.03
        #expect(abs(vm.totalVolume(using: config) - expected) < 0.001)
    }

    // MARK: - Overage Conversion

    @Test func overagePercentConversion() {
        let vm = BatchConfigViewModel()
        vm.overageFactor = 1.03
        #expect(abs(vm.overagePercent - 3.0) < 0.001)

        vm.overagePercent = 5.0
        #expect(abs(vm.overageFactor - 1.05) < 0.001)

        vm.overagePercent = 0.0
        #expect(abs(vm.overageFactor - 1.0) < 0.001)
    }

    // MARK: - Flavor Toggle

    @Test func flavorToggleAddRemove() {
        let vm = BatchConfigViewModel()
        let flavor = FlavorSelection.oil(.lemonade)

        #expect(vm.isSelected(flavor) == false)

        vm.toggleFlavor(flavor)
        #expect(vm.isSelected(flavor) == true)
        #expect(vm.selectedFlavors[flavor] == 0.0)

        vm.toggleFlavor(flavor)
        #expect(vm.isSelected(flavor) == false)
    }

    @Test func flavorToggleLockedPreventsRemoval() {
        let vm = BatchConfigViewModel()
        let oil = FlavorSelection.oil(.lemonade)
        vm.selectedFlavors[oil] = 100.0
        vm.oilsLocked = true

        vm.toggleFlavor(oil)
        // Should still be selected because oils are locked
        #expect(vm.isSelected(oil) == true)
    }

    // MARK: - Lock Distribution

    @Test func lockOilsDistribution_twoOils() {
        let vm = BatchConfigViewModel()
        vm.selectedFlavors[.oil(.lemonade)] = 0.0
        vm.selectedFlavors[.oil(.tropicalPunch)] = 0.0

        vm.lockOils()

        #expect(vm.oilsLocked == true)
        let lemonade = vm.selectedFlavors[.oil(.lemonade)] ?? 0
        let tropical = vm.selectedFlavors[.oil(.tropicalPunch)] ?? 0
        #expect(lemonade + tropical == 100.0)
        // Even distribution in multiples of 5: 50/50
        #expect(lemonade == 50.0)
        #expect(tropical == 50.0)
    }

    @Test func lockTerpenesDistribution_threeItems() {
        let vm = BatchConfigViewModel()
        vm.selectedFlavors[.terpene(.pineapple)] = 0.0
        vm.selectedFlavors[.terpene(.passionfruit)] = 0.0
        vm.selectedFlavors[.terpene(.mango)] = 0.0

        vm.lockTerpenes()

        #expect(vm.terpenesLocked == true)
        let total = vm.selectedTerpenes.reduce(0.0) { $0 + (vm.selectedFlavors[$1] ?? 0) }
        #expect(total == 100.0)
        // 3 items: 35 + 35 + 30 = 100
    }

    // MARK: - Color Toggle & Lock

    @Test func colorToggleAddRemove() {
        let vm = BatchConfigViewModel()
        #expect(vm.isColorSelected(.coral) == false)

        vm.toggleColor(.coral)
        #expect(vm.isColorSelected(.coral) == true)

        vm.toggleColor(.coral)
        #expect(vm.isColorSelected(.coral) == false)
    }

    @Test func lockColorsDistribution() {
        let vm = BatchConfigViewModel()
        vm.selectedColors[.coral] = 0.0
        vm.selectedColors[.red] = 0.0

        vm.lockColors()
        #expect(vm.colorsLocked == true)

        let total = vm.selectedColors.values.reduce(0, +)
        #expect(total == 100.0)
    }

    @Test func lockColorComposition() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        // Already locked in fixture
        #expect(vm.colorCompositionLocked == true)
        #expect(abs(vm.colorBlendTotal - 100.0) < 0.5)
    }

    // MARK: - Clear Template / Reset Batch

    @Test func clearTemplateResetsInputs() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        vm.clearTemplate()

        #expect(vm.selectedShape == .newBear)
        #expect(vm.trayCount == 1)
        #expect(vm.activeConcentration == 10.0)
        #expect(vm.selectedActive == .lsd)
        #expect(vm.gelatinPercentage == 5.225)
        #expect(vm.selectedFlavors.isEmpty)
        #expect(vm.selectedColors.isEmpty)
        #expect(vm.oilsLocked == false)
        #expect(vm.terpenesLocked == false)
        #expect(vm.colorsLocked == false)
    }

    @Test func resetBatchClearsMeasurements() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        #expect(vm.weightBeakerEmpty != nil)

        vm.resetBatch()

        #expect(vm.weightBeakerEmpty == nil)
        #expect(vm.weightBeakerPlusGelatin == nil)
        #expect(vm.batchCalculated == false)
        #expect(vm.selectedFlavors.isEmpty)
    }

    // MARK: - Derived Measurements

    @Test func calcMassGelatinAdded() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let expected = TestFixtures.TropicalPunchExpected.massGelatinAdded
        #expect(vm.calcMassGelatinAdded != nil)
        #expect(abs(vm.calcMassGelatinAdded! - expected) < 0.001)
    }

    @Test func calcMassSugarAdded() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let expected = TestFixtures.TropicalPunchExpected.massSugarAdded
        #expect(vm.calcMassSugarAdded != nil)
        #expect(abs(vm.calcMassSugarAdded! - expected) < 0.001)
    }

    @Test func calcMassActiveAdded() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let expected = TestFixtures.TropicalPunchExpected.massActiveAdded
        #expect(vm.calcMassActiveAdded != nil)
        #expect(abs(vm.calcMassActiveAdded! - expected) < 0.001)
    }

    @Test func calcMassFinalMixInBeaker() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let expected = TestFixtures.TropicalPunchExpected.massFinalMixInBeaker
        #expect(vm.calcMassFinalMixtureInBeaker != nil)
        #expect(abs(vm.calcMassFinalMixtureInBeaker! - expected) < 0.001)
    }

    @Test func calcMassTotalLoss() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let expected = TestFixtures.TropicalPunchExpected.massTotalLoss
        #expect(vm.calcMassTotalLoss != nil)
        #expect(abs(vm.calcMassTotalLoss! - expected) < 0.001)
    }

    @Test func calcMassMixTransferred() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let expected = TestFixtures.TropicalPunchExpected.massMixTransferred
        #expect(vm.calcMassMixTransferredToMold != nil)
        #expect(abs(vm.calcMassMixTransferredToMold! - expected) < 0.001)
    }

    @Test func calcDensityFinalMix() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let config = TestFixtures.makeDefaultSystemConfig()
        let expected = TestFixtures.TropicalPunchExpected.densityFinalMix
        let density = vm.calcDensityFinalMix(systemConfig: config)
        #expect(density != nil)
        #expect(abs(density! - expected) < 0.001)
    }

    @Test func calcMassPerGummy() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let config = TestFixtures.makeDefaultSystemConfig()
        let expected = TestFixtures.TropicalPunchExpected.massPerGummy
        let massPerGummy = vm.calcMassPerGummyMold(systemConfig: config)
        #expect(massPerGummy != nil)
        #expect(abs(massPerGummy! - expected) < 0.01)
    }

    // MARK: - Nil Safety on Missing Measurements

    @Test func derivedMeasurementsNilWhenIncomplete() {
        let vm = BatchConfigViewModel()
        // No measurements set — all derived values should be nil
        #expect(vm.calcMassGelatinAdded == nil)
        #expect(vm.calcMassSugarAdded == nil)
        #expect(vm.calcMassActiveAdded == nil)
        #expect(vm.calcMassFinalMixtureInBeaker == nil)
        #expect(vm.calcMassBeakerResidue == nil)
        #expect(vm.calcMassSyringeResidue == nil)
        #expect(vm.calcMassTotalLoss == nil)
        #expect(vm.calcMassMixTransferredToMold == nil)
    }

    // MARK: - Flavors Locked Property

    @Test func flavorsLockedComposite() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        // Both oils and terpenes are locked in the fixture
        #expect(vm.flavorsLocked == true)

        vm.oilsLocked = false
        #expect(vm.flavorsLocked == false)
    }
}
