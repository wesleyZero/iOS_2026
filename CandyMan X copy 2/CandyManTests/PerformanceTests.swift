//
//  PerformanceTests.swift
//  CandyManTests
//
//  Performance benchmarks for critical computation paths.
//

import Testing
import Foundation
@testable import CandyMan

struct PerformanceTests {

    // MARK: - Batch Calculation Performance

    @Test func batchCalculationPerformance() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        let config = TestFixtures.makeDefaultSystemConfig()

        let iterations = 1000
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            let _ = BatchCalculator.calculate(viewModel: vm, systemConfig: config)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations)

        // Each calculation should complete in under 1ms
        #expect(perIteration < 0.001, "Batch calculation took \(perIteration * 1000)ms per iteration")
    }

    // MARK: - SigFigs Performance

    @Test func sigFigsCountPerformance() {
        let testStrings = [
            "0.078", "1.4500", "3.000", "4600", "5.225",
            "199.0", "-0.078", "0.0012", "1.23e4", "100",
        ]

        let iterations = 10000
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            for str in testStrings {
                let _ = SigFigs.count(from: str)
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // 100,000 total counts should complete in under 1 second
        #expect(elapsed < 1.0, "SigFigs.count took \(elapsed)s for \(iterations * testStrings.count) counts")
    }

    // MARK: - Settings JSON Export Performance

    @Test func settingsJSONExportPerformance() {
        let config = TestFixtures.makeDefaultSystemConfig()

        let iterations = 1000
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            let _ = config.settingsToJSON()
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations)

        // JSON export should complete in under 1ms each
        #expect(perIteration < 0.001, "Settings JSON export took \(perIteration * 1000)ms per iteration")
    }

    // MARK: - All Shapes Calculation Performance

    @Test func allShapesCalculationPerformance() {
        let config = TestFixtures.makeDefaultSystemConfig()

        let iterations = 100
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            for shape in GummyShape.allCases {
                let vm = TestFixtures.makeTropicalPunchViewModel()
                vm.selectedShape = shape
                let _ = BatchCalculator.calculate(viewModel: vm, systemConfig: config)
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // 700 calculations should complete in under 1 second
        #expect(elapsed < 1.0, "All-shapes calculation took \(elapsed)s for \(iterations * 7) calculations")
    }

    // MARK: - Derived Measurements Performance

    @Test func derivedMeasurementsPerformance() {
        let vm = TestFixtures.makeTropicalPunchWithMeasurements()
        let config = TestFixtures.makeDefaultSystemConfig()

        let iterations = 10000
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            let _ = vm.calcMassGelatinAdded
            let _ = vm.calcMassSugarAdded
            let _ = vm.calcMassActiveAdded
            let _ = vm.calcMassFinalMixtureInBeaker
            let _ = vm.calcMassTotalLoss
            let _ = vm.calcMassMixTransferredToMold
            let _ = vm.calcDensityFinalMix(systemConfig: config)
            let _ = vm.calcMassPerGummyMold(systemConfig: config)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // 80,000 derived calculations should complete in under 1 second
        #expect(elapsed < 1.0, "Derived measurements took \(elapsed)s for \(iterations * 8) calculations")
    }
}
