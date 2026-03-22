//
//  SigFigsTests.swift
//  CandyManTests
//
//  Tests for SigFigs — significant figures counting, propagation, and formatting.
//

import Testing
@testable import CandyMan

struct SigFigsTests {

    // MARK: - Count from String

    @Test func countFromString_leadingZeros() {
        let info = SigFigs.count(from: "0.078")
        #expect(info.sigFigs == 2)
        #expect(info.decimalPlaces == 3)
        #expect(info.isExact == false)
    }

    @Test func countFromString_trailingZeros() {
        let info = SigFigs.count(from: "1.4500")
        #expect(info.sigFigs == 5)
        #expect(info.decimalPlaces == 4)
    }

    @Test func countFromString_allZerosAfterDecimal() {
        let info = SigFigs.count(from: "3.000")
        #expect(info.sigFigs == 4)
        #expect(info.decimalPlaces == 3)
    }

    @Test func countFromString_integerAmbiguous() {
        let info = SigFigs.count(from: "4600")
        #expect(info.sigFigs == 4)
        #expect(info.decimalPlaces == nil)
    }

    @Test func countFromString_gelatinPercentage() {
        let info = SigFigs.count(from: "5.225")
        #expect(info.sigFigs == 4)
        #expect(info.decimalPlaces == 3)
    }

    @Test func countFromString_terpenePPM() {
        let info = SigFigs.count(from: "199.0")
        #expect(info.sigFigs == 4)
        #expect(info.decimalPlaces == 1)
    }

    @Test func countFromString_signIgnored() {
        let info = SigFigs.count(from: "-0.078")
        #expect(info.sigFigs == 2)
    }

    @Test func countFromString_zero() {
        let info = SigFigs.count(from: "0")
        #expect(info.sigFigs == 1)
    }

    @Test func countFromString_smallValue() {
        let info = SigFigs.count(from: "0.0012")
        #expect(info.sigFigs == 2)
    }

    // MARK: - Count with Decimal Places

    @Test func countWithDecimalPlaces() {
        let info = SigFigs.count(0.078, decimalPlaces: 3)
        #expect(info.sigFigs == 2)
        #expect(info.decimalPlaces == 3)
    }

    @Test func countWithDecimalPlaces_trailingZeros() {
        let info = SigFigs.count(1.45, decimalPlaces: 4)
        // "1.4500" → 5 SF
        #expect(info.sigFigs == 5)
    }

    @Test func countWithDecimalPlaces_threePoint000() {
        let info = SigFigs.count(3.0, decimalPlaces: 3)
        // "3.000" → 4 SF
        #expect(info.sigFigs == 4)
    }

    // MARK: - Exact Values

    @Test func exactValues() {
        let info = SigFigs.exact(35.0, label: "35 gummies")
        #expect(info.isExact == true)
        #expect(info.sigFigs == Int.max)
    }

    // MARK: - Propagation: Multiply/Divide

    @Test func multiplyDivideRule() {
        let a = SigFigs.count(from: "5.225")   // 4 SF
        let b = SigFigs.exact(35.0)             // ∞ SF
        let c = SigFigs.count(from: "3.946")   // 4 SF

        let resultSF = SigFigs.multiplyDivide(a, b, c)
        // min of non-exact = min(4, 4) = 4
        #expect(resultSF == 4)
    }

    @Test func multiplyDivideAllExact() {
        let a = SigFigs.exact(100.0)
        let b = SigFigs.exact(1_000_000.0)

        let resultSF = SigFigs.multiplyDivide(a, b)
        #expect(resultSF == Int.max)
    }

    @Test func multiplyDivideMixedPrecision() {
        let a = SigFigs.count(from: "0.078")   // 2 SF
        let b = SigFigs.count(from: "142.253") // 6 SF

        let resultSF = SigFigs.multiplyDivide(a, b)
        #expect(resultSF == 2)
    }

    // MARK: - Propagation: Add/Subtract

    @Test func addSubtractRule() {
        let a = SigFigs.count(from: "65.358")  // 3 DP
        let b = SigFigs.count(from: "75.437")  // 3 DP

        let resultDP = SigFigs.addSubtract(a, b)
        #expect(resultDP == 3)
    }

    @Test func addSubtractMixedDecimalPlaces() {
        let a = SigFigs.count(from: "65.4")    // 1 DP
        let b = SigFigs.count(from: "75.437")  // 3 DP

        let resultDP = SigFigs.addSubtract(a, b)
        #expect(resultDP == 1)
    }

    // MARK: - Formatting

    @Test func formatToSigFigs() {
        #expect(SigFigs.format(0.004567, sigFigs: 3) == "0.00457")
        #expect(SigFigs.format(0.0, sigFigs: 2) == "0.0")
    }

    @Test func formatDecimalPlaces() {
        #expect(SigFigs.formatDP(3.14159, decimalPlaces: 2) == "3.14")
        #expect(SigFigs.formatDP(3.14159, decimalPlaces: 4) == "3.1416")
    }

    // MARK: - Resolution-Aware Counting

    @Test func resolutionAwareCounting() {
        let info = SigFigs.count(123.456, resolution: .thousandthGram)
        // "123.456" at 3 DP → 6 SF
        #expect(info.sigFigs == 6)
        #expect(info.decimalPlaces == 3)
    }

    @Test func resolutionAwareCounting_tenthGram() {
        let info = SigFigs.count(35.0, resolution: .tenthGram)
        // "35.0" at 1 DP → 3 SF
        #expect(info.sigFigs == 3)
        #expect(info.decimalPlaces == 1)
    }

    // MARK: - Difference SF

    @Test func sfOfDifference() {
        let info = SigFigs.sfOfDifference(
            250.123, resA: .thousandthGram,
            minus: 248.456, resB: .thousandthGram
        )
        // difference = 1.667, 3 DP → 4 SF
        #expect(info.sigFigs == 4)
    }

    @Test func sfOfDifference_mixedResolutions() {
        let info = SigFigs.sfOfDifference(
            250.1, resA: .tenthGram,
            minus: 248.5, resB: .tenthGram
        )
        // difference = 1.6, 1 DP → 2 SF
        #expect(info.sigFigs == 2)
    }

    // MARK: - Scientific Notation

    @Test func scientificNotation() {
        let info = SigFigs.count(from: "1.23e4")
        #expect(info.sigFigs == 3)
    }

    // MARK: - Quick Count (Heuristic)

    @Test func quickCount() {
        let info = SigFigs.quickCount(0.078)
        #expect(info.sigFigs == 2)
    }
}
