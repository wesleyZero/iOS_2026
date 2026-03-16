//
//  SigFigs.swift
//  CandyMan
//
//  Significant figures analysis and propagation utility.
//
//  Sig fig rules (for the ChemE in us all):
//    • Multiplication / Division → result SF = min(SF of all operands)
//    • Addition / Subtraction    → result decimal places = min(DP of all operands)
//    • Exact numbers (counts, defined conversions like 100, 1e6) → infinite SF
//    • Leading zeros are never significant
//    • Trailing zeros after the decimal ARE significant (0.078 = 2 SF, 3.000 = 4 SF)
//    • Trailing zeros before the decimal with no decimal point are ambiguous
//      (we treat them as significant when explicitly provided, e.g. "4600" → 4 SF)
//

import Foundation

// MARK: - SigFigInfo

/// Result of a significant figures analysis on a single numeric value.
struct SigFigInfo: CustomStringConvertible {
    /// The original string representation of the number.
    let representation: String
    /// The numeric value.
    let value: Double
    /// Number of significant figures.
    let sigFigs: Int
    /// Number of decimal places (nil if no decimal point present).
    let decimalPlaces: Int?
    /// Whether this value is considered exact (infinite sig figs).
    let isExact: Bool

    var description: String {
        if isExact {
            return "\(representation) → exact (∞ SF)"
        }
        let dpStr = decimalPlaces.map { ", \($0) DP" } ?? ""
        return "\(representation) → \(sigFigs) SF\(dpStr)"
    }
}

// MARK: - SigFigs

enum SigFigs {

    // ────────────────────────────────────────────────────────────────────
    // MARK: Core: Count sig figs from a string
    // ────────────────────────────────────────────────────────────────────

    /// Counts significant figures from a string representation of a number.
    ///
    /// Examples:
    ///   "0.078"    → 2 SF   (leading zeros not significant)
    ///   "1.4500"   → 5 SF   (trailing zeros after decimal are significant)
    ///   "3.000"    → 4 SF
    ///   "4600"     → 4 SF   (ambiguous — we assume all digits are significant)
    ///   "100"      → 3 SF   (ambiguous — use `exact()` if it's a conversion factor)
    ///   "5.225"    → 4 SF
    ///   "199.0"    → 4 SF
    ///   "-0.078"   → 2 SF   (sign ignored)
    ///
    static func count(from string: String) -> SigFigInfo {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        let unsigned = trimmed.hasPrefix("-") || trimmed.hasPrefix("+")
            ? String(trimmed.dropFirst())
            : trimmed

        // Handle scientific notation: "1.23e4", "5.0E-3"
        let parts = unsigned.lowercased().split(separator: "e", maxSplits: 1)
        let mantissa = String(parts[0])

        let value = Double(trimmed) ?? 0.0
        let hasDecimal = mantissa.contains(".")

        // Strip the decimal point for digit analysis
        let stripped = mantissa.replacingOccurrences(of: ".", with: "")

        // Find first non-zero digit
        guard let firstNonZero = stripped.firstIndex(where: { $0 != "0" }) else {
            // All zeros → "0" or "0.0" or "0.000" etc.
            // "0" has 1 SF; "0.0" has 1 SF; "0.00" has 1 SF
            return SigFigInfo(
                representation: trimmed, value: value, sigFigs: 1,
                decimalPlaces: hasDecimal ? mantissa.count - mantissa.firstIndex(of: ".")!.utf16Offset(in: mantissa) - 1 : nil,
                isExact: false
            )
        }

        // Count significant digits: from first non-zero to end of mantissa digits
        let significantDigits = stripped[firstNonZero...]
        let sf = significantDigits.count

        // Decimal places
        let dp: Int? = hasDecimal
            ? mantissa.count - mantissa.firstIndex(of: ".")!.utf16Offset(in: mantissa) - 1
            : nil

        return SigFigInfo(
            representation: trimmed, value: value, sigFigs: sf,
            decimalPlaces: dp, isExact: false
        )
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Count sig figs from a Double + known decimal places
    // ────────────────────────────────────────────────────────────────────

    /// When you have a `Double` and know how many decimal places it was specified to,
    /// this converts it to a string at that precision and counts sig figs.
    ///
    /// Use this for values from SystemConfig where you know the literal form.
    ///
    ///   count(0.078, decimalPlaces: 3)  → "0.078" → 2 SF
    ///   count(1.45, decimalPlaces: 4)   → "1.4500" → 5 SF
    ///   count(3.0, decimalPlaces: 3)    → "3.000" → 4 SF
    ///
    static func count(_ value: Double, decimalPlaces: Int) -> SigFigInfo {
        let str = String(format: "%.\(decimalPlaces)f", value)
        return count(from: str)
    }

    /// Marks a value as exact (infinite significant figures).
    /// Use for counts (35 molds), defined conversion factors (100, 1e6), etc.
    static func exact(_ value: Double, label: String = "") -> SigFigInfo {
        SigFigInfo(
            representation: label.isEmpty ? "\(value)" : label,
            value: value, sigFigs: Int.max,
            decimalPlaces: nil, isExact: true
        )
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Propagation rules
    // ────────────────────────────────────────────────────────────────────

    /// Propagates sig figs through multiplication or division.
    /// Result SF = min(SF of all operands).
    static func multiplyDivide(_ operands: SigFigInfo...) -> Int {
        let nonExact = operands.filter { !$0.isExact }
        guard !nonExact.isEmpty else { return Int.max }
        return nonExact.map(\.sigFigs).min()!
    }

    /// Propagates sig figs through addition or subtraction.
    /// Result decimal places = min(DP of all operands).
    /// Returns the limiting number of decimal places.
    static func addSubtract(_ operands: SigFigInfo...) -> Int {
        let nonExact = operands.filter { !$0.isExact }
        guard !nonExact.isEmpty else { return Int.max }
        // For operands without a decimal point, DP = 0
        return nonExact.map { $0.decimalPlaces ?? 0 }.min()!
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Formatting to correct sig figs
    // ────────────────────────────────────────────────────────────────────

    /// Rounds a Double to `n` significant figures and returns the formatted string.
    ///
    ///   format(0.004567, sigFigs: 3) → "0.00457"
    ///   format(1234.5, sigFigs: 3)   → "1230"     (or "1.23e3")
    ///   format(0.0, sigFigs: 2)      → "0.0"
    ///
    static func format(_ value: Double, sigFigs n: Int) -> String {
        guard n > 0 else { return "0" }
        guard value != 0 else {
            // For zero, show n-1 decimal places: SF=2 → "0.0", SF=3 → "0.00"
            return String(format: "%.\(max(n - 1, 0))f", 0.0)
        }

        let absVal = abs(value)
        let magnitude = floor(log10(absVal))
        let shift = pow(10.0, Double(n - 1) - magnitude)
        let rounded = (absVal * shift).rounded() / shift

        let result = value < 0 ? -rounded : rounded

        // Determine decimal places to display
        let dp = max(0, n - 1 - Int(magnitude))
        return String(format: "%.\(dp)f", result)
    }

    /// Rounds a Double to `n` decimal places.
    static func formatDP(_ value: Double, decimalPlaces n: Int) -> String {
        String(format: "%.\(n)f", value)
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: Quick analysis of a Double (heuristic)
    // ────────────────────────────────────────────────────────────────────

    /// Heuristic sig fig count from a raw Double.
    ///
    /// ⚠️ This is inherently lossy — a Double doesn't carry sig fig info.
    /// It uses Swift's default string interpolation, which drops trailing zeros.
    /// Prefer `count(from:)` or `count(_:decimalPlaces:)` when you know the
    /// original representation.
    ///
    ///   quickCount(0.078)  → 2  (Swift prints "0.078")
    ///   quickCount(1.45)   → 3  (Swift prints "1.45", NOT "1.4500")
    ///   quickCount(3.0)    → 1  (Swift prints "3.0" → but only 1 trailing zero)
    ///
    /// For constants where trailing zeros matter, always use count(_:decimalPlaces:).
    static func quickCount(_ value: Double) -> SigFigInfo {
        count(from: "\(value)")
    }
}

// MARK: - Resolution-Aware Sig Fig Analysis

/// Computes the significant figures of a measurement given its reading
/// and the `MeasurementResolution` set in Settings.
///
/// The resolution determines the number of decimal places (DP).
/// The sig figs depend on both DP and the magnitude of the reading:
///
///     reading = 123.456 at resolution .thousandthGram (3 DP) → 6 SF
///     reading = 1.234   at resolution .thousandthGram (3 DP) → 4 SF
///     reading = 0.012   at resolution .thousandthGram (3 DP) → 2 SF
///     reading = 35.0    at resolution .tenthGram      (1 DP) → 3 SF
///
/// This means: YES, changing resolution in Settings changes the SF of your
/// measurements, which propagates through every derived calculation.
///
extension SigFigs {

    /// Counts sig figs of a measurement value at a given resolution.
    ///
    ///     let info = SigFigs.count(123.456, resolution: .thousandthGram)
    ///     print(info)  // "123.456 → 6 SF, 3 DP"
    ///
    static func count(_ value: Double, resolution: MeasurementResolution) -> SigFigInfo {
        let dp = resolution.decimalPlaces
        let str = String(format: "%.\(dp)f", value)
        return count(from: str)
    }

    /// Returns the SF that would result from subtracting two measurements
    /// at the given resolutions.
    ///
    /// Subtraction rule: result DP = min(DP_a, DP_b).
    /// Result SF = digits in the difference at that DP.
    ///
    ///     sfOfDifference(250.123, res: .thousandthGram,
    ///                    minus: 248.456, res: .thousandthGram)
    ///     // difference = 1.667, 3 DP → 4 SF
    ///
    ///     sfOfDifference(250.1, res: .tenthGram,
    ///                    minus: 248.5, res: .tenthGram)
    ///     // difference = 1.6, 1 DP → 2 SF
    ///
    static func sfOfDifference(
        _ a: Double, resA: MeasurementResolution,
        minus b: Double, resB: MeasurementResolution
    ) -> SigFigInfo {
        let resultDP = min(resA.decimalPlaces, resB.decimalPlaces)
        let diff = a - b
        let str = String(format: "%.\(resultDP)f", diff)
        return count(from: str)
    }

    /// Returns the SF that would result from dividing two values
    /// at the given resolutions.
    ///
    /// Division rule: result SF = min(SF_a, SF_b).
    ///
    static func sfOfDivision(
        _ a: Double, resA: MeasurementResolution,
        dividedBy b: Double, resB: MeasurementResolution
    ) -> SigFigInfo {
        let sfA = count(a, resolution: resA).sigFigs
        let sfB = count(b, resolution: resB).sigFigs
        let resultSF = min(sfA, sfB)
        let result = b != 0 ? a / b : 0
        return SigFigInfo(
            representation: format(result, sigFigs: resultSF),
            value: result,
            sigFigs: resultSF,
            decimalPlaces: nil,
            isExact: false
        )
    }
}

// MARK: - Live Audit from SystemConfig + ViewModel

/// Computes the propagated sig figs for every post-batch calculation
/// using the CURRENT resolution settings from SystemConfig and
/// actual measurement values from the ViewModel.
///
/// This is the function that changes when you change resolution in Settings.
///
/// Usage:
///     let audit = SigFigLiveAudit(viewModel: viewModel, systemConfig: systemConfig)
///     print(audit.report())
///     print(audit.densityFinalMixSF)  // e.g. 4
///
struct SigFigLiveAudit {
    let viewModel: BatchConfigViewModel
    let systemConfig: SystemConfig

    // MARK: - Measurement SF (resolution-aware)

    /// SF of the raw beaker-empty reading at its current resolution.
    var sfBeakerEmpty: SigFigInfo? {
        guard let v = viewModel.weightBeakerEmpty else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionBeakerEmpty)
    }

    var sfBeakerPlusGelatin: SigFigInfo? {
        guard let v = viewModel.weightBeakerPlusGelatin else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionBeakerPlusGelatin)
    }

    var sfBeakerPlusSugar: SigFigInfo? {
        guard let v = viewModel.weightBeakerPlusSugar else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionBeakerPlusSugar)
    }

    var sfBeakerPlusActive: SigFigInfo? {
        guard let v = viewModel.weightBeakerPlusActive else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionBeakerPlusActive)
    }

    var sfBeakerResidue: SigFigInfo? {
        guard let v = viewModel.weightBeakerResidue else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionBeakerResidue)
    }

    var sfSyringeEmpty: SigFigInfo? {
        guard let v = viewModel.weightSyringeEmpty else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionSyringeEmpty)
    }

    var sfSyringeWithMix: SigFigInfo? {
        guard let v = viewModel.weightSyringeWithMix else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionSyringeWithMix)
    }

    var sfSyringeResidue: SigFigInfo? {
        guard let v = viewModel.weightSyringeResidue else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionSyringeResidue)
    }

    var sfMoldsFilled: SigFigInfo? {
        guard let v = viewModel.weightMoldsFilled else { return nil }
        return SigFigs.count(v, resolution: systemConfig.resolutionMoldsFilled)
    }

    // MARK: - Derived Calculation SF (propagated)

    /// Gelatin added = beaker+gel - beaker.
    /// Subtraction: result DP = min(DP_gel, DP_empty).
    var sfGelatinAdded: SigFigInfo? {
        guard let a = viewModel.weightBeakerPlusGelatin,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return SigFigs.sfOfDifference(
            a, resA: systemConfig.resolutionBeakerPlusGelatin,
            minus: b, resB: systemConfig.resolutionBeakerEmpty
        )
    }

    /// Sugar added = beaker+sugar - beaker+gelatin.
    var sfSugarAdded: SigFigInfo? {
        guard let a = viewModel.weightBeakerPlusSugar,
              let b = viewModel.weightBeakerPlusGelatin else { return nil }
        return SigFigs.sfOfDifference(
            a, resA: systemConfig.resolutionBeakerPlusSugar,
            minus: b, resB: systemConfig.resolutionBeakerPlusGelatin
        )
    }

    /// Active added = beaker+active - beaker+sugar.
    var sfActiveAdded: SigFigInfo? {
        guard let a = viewModel.weightBeakerPlusActive,
              let b = viewModel.weightBeakerPlusSugar else { return nil }
        return SigFigs.sfOfDifference(
            a, resA: systemConfig.resolutionBeakerPlusActive,
            minus: b, resB: systemConfig.resolutionBeakerPlusSugar
        )
    }

    /// Final mixture = beaker+active - beaker(empty).
    var sfFinalMixture: SigFigInfo? {
        guard let a = viewModel.weightBeakerPlusActive,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return SigFigs.sfOfDifference(
            a, resA: systemConfig.resolutionBeakerPlusActive,
            minus: b, resB: systemConfig.resolutionBeakerEmpty
        )
    }

    /// Beaker residue = beaker+residue - beaker(empty).
    var sfBeakerResidueCalc: SigFigInfo? {
        guard let a = viewModel.weightBeakerResidue,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return SigFigs.sfOfDifference(
            a, resA: systemConfig.resolutionBeakerResidue,
            minus: b, resB: systemConfig.resolutionBeakerEmpty
        )
    }

    /// Syringe residue = syringe+residue - syringe(clean).
    var sfSyringeResidueCalc: SigFigInfo? {
        guard let a = viewModel.weightSyringeResidue,
              let b = viewModel.weightSyringeEmpty else { return nil }
        return SigFigs.sfOfDifference(
            a, resA: systemConfig.resolutionSyringeResidue,
            minus: b, resB: systemConfig.resolutionSyringeEmpty
        )
    }

    /// Total loss = beaker residue + syringe residue.
    /// Addition: result DP = min(DP of both).
    var sfTotalLoss: Int? {
        guard let br = sfBeakerResidueCalc, let sr = sfSyringeResidueCalc else { return nil }
        return SigFigs.addSubtract(br, sr)
    }

    /// Density of final mix = mass / volume (both from syringe).
    var sfDensityFinalMix: Int? {
        guard let massInfo = sfSyringeWithMix,
              let emptyInfo = sfSyringeEmpty else { return nil }
        // mass of mix = syringe+mix - syringe(clean) → subtraction
        let massDiffSF = SigFigs.sfOfDifference(
            viewModel.weightSyringeWithMix!, resA: systemConfig.resolutionSyringeWithMix,
            minus: viewModel.weightSyringeEmpty!, resB: systemConfig.resolutionSyringeEmpty
        ).sigFigs
        // volume is entered directly at 3 DP
        let volSF = viewModel.volumeSyringeGummyMix.map {
            SigFigs.count(from: String(format: "%.3f", $0)).sigFigs
        } ?? 0
        return min(massDiffSF, volSF)
    }

    /// Avg gummy mass = transferred / molds.
    /// Division: min(SF_transferred, SF_molds).
    var sfAvgGummyMass: Int? {
        guard let transferredSF = sfFinalMixture?.sigFigs,
              let moldsSF = sfMoldsFilled?.sigFigs else { return nil }
        // transferred is itself a subtraction result, so use its SF
        // then we also subtract totalLoss, but let's use the simpler model
        return min(transferredSF, moldsSF)
    }

    // MARK: - Report

    struct ReportLine {
        let label: String
        let sigFigs: String     // "4 SF" or "—"
        let dp: String          // "3 DP" or "—"
        let resolution: String  // "0.001 g" or "—"
    }

    func report() -> [ReportLine] {
        var lines: [ReportLine] = []

        func add(_ label: String, _ info: SigFigInfo?, res: MeasurementResolution? = nil) {
            let sf = info.map { "\($0.sigFigs) SF" } ?? "—"
            let dp = info?.decimalPlaces.map { "\($0) DP" } ?? "—"
            let r = res.map { $0.label } ?? "—"
            lines.append(ReportLine(label: label, sigFigs: sf, dp: dp, resolution: r))
        }

        func addCalc(_ label: String, sf: Int?) {
            let s = sf.map { "\($0) SF" } ?? "—"
            lines.append(ReportLine(label: label, sigFigs: s, dp: "—", resolution: "derived"))
        }

        // Raw measurements
        add("Beaker (Empty)",          sfBeakerEmpty,       res: systemConfig.resolutionBeakerEmpty)
        add("Beaker + Gelatin",        sfBeakerPlusGelatin, res: systemConfig.resolutionBeakerPlusGelatin)
        add("Beaker + Sugar",          sfBeakerPlusSugar,   res: systemConfig.resolutionBeakerPlusSugar)
        add("Beaker + Active",         sfBeakerPlusActive,  res: systemConfig.resolutionBeakerPlusActive)
        add("Beaker + Residue",        sfBeakerResidue,     res: systemConfig.resolutionBeakerResidue)
        add("Syringe (Clean)",         sfSyringeEmpty,      res: systemConfig.resolutionSyringeEmpty)
        add("Syringe + Mix",           sfSyringeWithMix,    res: systemConfig.resolutionSyringeWithMix)
        add("Syringe + Residue",       sfSyringeResidue,    res: systemConfig.resolutionSyringeResidue)
        add("Molds Filled",            sfMoldsFilled,       res: systemConfig.resolutionMoldsFilled)

        // Derived
        add("Gelatin Added (calc)",    sfGelatinAdded)
        add("Sugar Added (calc)",      sfSugarAdded)
        add("Active Added (calc)",     sfActiveAdded)
        add("Final Mixture (calc)",    sfFinalMixture)
        add("Beaker Residue (calc)",   sfBeakerResidueCalc)
        add("Syringe Residue (calc)",  sfSyringeResidueCalc)
        addCalc("Density Final Mix",   sf: sfDensityFinalMix)
        addCalc("Avg Gummy Mass",      sf: sfAvgGummyMass)

        return lines
    }
}

// MARK: - Batch-Specific Analysis

/// Catalogs the sig fig counts of every constant, input, measurement, and
/// derived calculation in CandyMan's batch system.
///
/// Call `SigFigAudit.fullReport()` to get a printable summary.
enum SigFigAudit {

    struct Entry {
        let label: String
        let group: String
        let value: String
        let sigFigs: Int
        let isExact: Bool
        let notes: String

        var sfLabel: String { isExact ? "∞" : "\(sigFigs)" }
    }

    // MARK: System Config Constants

    static func systemConfigEntries() -> [Entry] {
        [
            // Densities
            Entry(label: "ρ Water",              group: "Densities",   value: "0.9982",  sigFigs: 4, isExact: false, notes: "4 DP"),
            Entry(label: "ρ Glucose Syrup",      group: "Densities",   value: "1.4500",  sigFigs: 5, isExact: false, notes: "4 DP, trailing zeros significant"),
            Entry(label: "ρ Sucrose",            group: "Densities",   value: "1.5872",  sigFigs: 5, isExact: false, notes: "4 DP"),
            Entry(label: "ρ Gelatin",            group: "Densities",   value: "1.3500",  sigFigs: 5, isExact: false, notes: "4 DP, trailing zeros significant"),
            Entry(label: "ρ Citric Acid",        group: "Densities",   value: "1.6650",  sigFigs: 5, isExact: false, notes: "4 DP, trailing zero significant"),
            Entry(label: "ρ Potassium Sorbate",  group: "Densities",   value: "1.3630",  sigFigs: 5, isExact: false, notes: "4 DP"),
            Entry(label: "ρ Flavor Oil",         group: "Densities",   value: "1.0360",  sigFigs: 5, isExact: false, notes: "4 DP"),
            Entry(label: "ρ Food Coloring",      group: "Densities",   value: "1.2613",  sigFigs: 5, isExact: false, notes: "4 DP"),
            Entry(label: "ρ Terpenes",           group: "Densities",   value: "0.8411",  sigFigs: 4, isExact: false, notes: "4 DP"),

            // Ratios & Percents
            Entry(label: "Glucose:Sugar ratio",       group: "Ratios",  value: "1.000",   sigFigs: 4, isExact: false, notes: "3 DP"),
            Entry(label: "Water:Gelatin ratio",       group: "Ratios",  value: "3.000",   sigFigs: 4, isExact: false, notes: "3 DP"),
            Entry(label: "Sugar:Water ratio",         group: "Ratios",  value: "4.769",   sigFigs: 4, isExact: false, notes: "3 DP"),
            Entry(label: "Citric Acid %vol",          group: "Ratios",  value: "0.638",   sigFigs: 3, isExact: false, notes: "3 DP"),
            Entry(label: "Potassium Sorbate %vol",    group: "Ratios",  value: "0.078",   sigFigs: 2, isExact: false, notes: "⚠️ LOWEST in system — 3 DP but only 2 SF"),

            // Solubility
            Entry(label: "Citric Acid solubility",    group: "Solubility", value: "59.0",  sigFigs: 3, isExact: false, notes: "g/100mL @ 20°C"),
            Entry(label: "K-Sorbate solubility",      group: "Solubility", value: "58.2",  sigFigs: 3, isExact: false, notes: "g/100mL @ 20°C"),

            // Mold Volumes (examples)
            Entry(label: "Circle volume_ml",     group: "Mold Specs",  value: "2.292",   sigFigs: 4, isExact: false, notes: "3 DP"),
            Entry(label: "New Bear volume_ml",   group: "Mold Specs",  value: "4.600",   sigFigs: 4, isExact: false, notes: "3 DP, trailing zeros significant"),

            // Exact values
            Entry(label: "Mold count (e.g. 35)", group: "Exact",       value: "35",      sigFigs: Int.max, isExact: true, notes: "Integer count → exact"),
            Entry(label: "Tray count",           group: "Exact",       value: "1",       sigFigs: Int.max, isExact: true, notes: "Integer count → exact"),
            Entry(label: "100.0 (% divisor)",    group: "Exact",       value: "100.0",   sigFigs: Int.max, isExact: true, notes: "Defined conversion → exact"),
            Entry(label: "1,000,000 (PPM)",      group: "Exact",       value: "1000000", sigFigs: Int.max, isExact: true, notes: "Defined conversion → exact"),
        ]
    }

    // MARK: User Inputs

    static func userInputEntries() -> [Entry] {
        [
            Entry(label: "Overage factor",         group: "User Inputs", value: "1.03",    sigFigs: 3, isExact: false, notes: "Default; 2 DP"),
            Entry(label: "Gelatin %",              group: "User Inputs", value: "5.225",   sigFigs: 4, isExact: false, notes: "3 DP"),
            Entry(label: "Terpene PPM",            group: "User Inputs", value: "199.0",   sigFigs: 4, isExact: false, notes: "1 DP"),
            Entry(label: "Flavor Oil %vol",        group: "User Inputs", value: "0.451",   sigFigs: 3, isExact: false, notes: "3 DP"),
            Entry(label: "Color %vol",             group: "User Inputs", value: "0.664",   sigFigs: 3, isExact: false, notes: "3 DP"),
            Entry(label: "Active concentration",   group: "User Inputs", value: "10.0",    sigFigs: 3, isExact: false, notes: "User-entered"),
            Entry(label: "LSD µg/tab",             group: "User Inputs", value: "117.0",   sigFigs: 4, isExact: false, notes: "1 DP"),
            Entry(label: "Blend % (each flavor)",  group: "User Inputs", value: "25",      sigFigs: 2, isExact: false, notes: "Slider in 5% steps; 2 SF for 25, 1 SF for 5"),
        ]
    }

    // MARK: Measurement Fields

    static func measurementEntries() -> [Entry] {
        [
            Entry(label: "Beaker (Empty)",               group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "Resolution-dependent; typ. 5-6 SF for ~100g reading"),
            Entry(label: "Beaker + Gelatin Mix",         group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP; SF depends on magnitude"),
            Entry(label: "Beaker + Sugar Mix",           group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Beaker + Active Mix",          group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Beaker + Residue",             group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Syringe (Clean)",              group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Syringe + Mix",                group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Syringe + Residue",            group: "Measurements", value: "±0.001g",  sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Syringe volume (mL)",          group: "Measurements", value: "±0.001mL", sigFigs: 0, isExact: false, notes: "3 DP"),
            Entry(label: "Molds Filled",                 group: "Measurements", value: "±0.1",     sigFigs: 0, isExact: false, notes: "1 DP; resolution = 0.1"),
        ]
    }

    // MARK: Derived Calculations — Propagated SF

    static func calculationEntries() -> [Entry] {
        [
            // Volume chain
            Entry(label: "vBase = count × trays × vol_ml",
                  group: "Volume Chain", value: "—", sigFigs: 4, isExact: false,
                  notes: "count/trays exact; vol_ml = 4 SF → 4 SF"),
            Entry(label: "vMix = vBase × overageFactor",
                  group: "Volume Chain", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(4, 3) = 3 SF ← overage is the bottleneck"),

            // Activation mix
            Entry(label: "vCitric = (0.638/100) × vMix",
                  group: "Activation Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, ∞, 3) = 3 SF"),
            Entry(label: "mCitric = vCitric × ρ_citric",
                  group: "Activation Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, 5) = 3 SF"),
            Entry(label: "vSorbate = (0.078/100) × vMix",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "⚠️ min(2, ∞, 3) = 2 SF — 0.078 limits!"),
            Entry(label: "mSorbate = vSorbate × ρ_sorbate",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "⚠️ min(2, 5) = 2 SF"),
            Entry(label: "vColor = (0.664/100) × vMix × blend%",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "min(3, ∞, 3, 2) = 2 SF ← blend% at 25 = 2 SF"),
            Entry(label: "mColor = vColor × ρ_coloring",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "min(2, 5) = 2 SF"),
            Entry(label: "vOil = (0.451/100) × vMix × blend%",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "min(3, ∞, 3, 2) = 2 SF ← blend%"),
            Entry(label: "vTerp = (199/1e6) × vMix × blend%",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "min(4, ∞, 3, 2) = 2 SF ← blend%"),
            Entry(label: "waterForCitric = (mCitric/59.0)×100",
                  group: "Activation Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, 3, ∞) = 3 SF"),
            Entry(label: "waterForSorbate = (mSorbate/58.2)×100",
                  group: "Activation Mix", value: "—", sigFigs: 2, isExact: false,
                  notes: "⚠️ min(2, 3, ∞) = 2 SF"),

            // Gelatin mix
            Entry(label: "vGelatin = (5.225/100) × vMix",
                  group: "Gelatin Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(4, ∞, 3) = 3 SF ← vMix limits"),
            Entry(label: "mGelatin = vGelatin × ρ_gelatin",
                  group: "Gelatin Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, 5) = 3 SF"),
            Entry(label: "mGelatinWater = mGelatin × φ_gel",
                  group: "Gelatin Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, 4) = 3 SF"),
            Entry(label: "vGelatinWater = mGelatinWater / ρ_water",
                  group: "Gelatin Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, 4) = 3 SF"),

            // Sugar mix
            Entry(label: "vRemaining = vMix − vActivation − vGelatinMix",
                  group: "Sugar Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "Subtraction: limited by DP alignment; ~3 SF"),
            Entry(label: "sugarMixDensity (computed)",
                  group: "Sugar Mix", value: "—", sigFigs: 4, isExact: false,
                  notes: "min(4, 4, 5, 5) = 4 SF (from ratios + densities)"),
            Entry(label: "mSugarMix = vRemaining × ρ_mix",
                  group: "Sugar Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "min(3, 4) = 3 SF"),
            Entry(label: "mGlucoseSyrup",
                  group: "Sugar Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "Derived from mSugarMix × ratio → 3 SF"),
            Entry(label: "mGranulated",
                  group: "Sugar Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "Derived from mSugarMix × ratio → 3 SF"),
            Entry(label: "vSugarWater (residual closure)",
                  group: "Sugar Mix", value: "—", sigFigs: 3, isExact: false,
                  notes: "Subtraction residual → ~3 SF"),

            // Post-batch measured calculations
            Entry(label: "Gelatin Mix Added = beaker+gel − beaker",
                  group: "Post-Batch Calcs", value: "—", sigFigs: 0, isExact: false,
                  notes: "Subtraction: 3 DP − 3 DP = 3 DP; SF depends on magnitude"),
            Entry(label: "Total Residue = beakerRes + syringeRes",
                  group: "Post-Batch Calcs", value: "—", sigFigs: 0, isExact: false,
                  notes: "Addition: 3 DP + 3 DP = 3 DP"),
            Entry(label: "Density = mass / volume",
                  group: "Post-Batch Calcs", value: "—", sigFigs: 0, isExact: false,
                  notes: "Division: min(SF_mass, SF_vol); typ. 4-5 SF"),
            Entry(label: "Active Loss = totalActive × (loss/finalMix)",
                  group: "Post-Batch Calcs", value: "—", sigFigs: 0, isExact: false,
                  notes: "Chain of mult/div; typically limited by input SF"),
            Entry(label: "Avg Gummy Mass = transferred / molds",
                  group: "Post-Batch Calcs", value: "—", sigFigs: 0, isExact: false,
                  notes: "Molds at 1 DP (0.1 resolution) limits this"),
        ]
    }

    // MARK: Full Report

    static func fullReport() -> String {
        var lines: [String] = []
        lines.append("═══════════════════════════════════════════════════════════════")
        lines.append("  CandyMan — Significant Figures Audit")
        lines.append("═══════════════════════════════════════════════════════════════")

        let allEntries: [(String, [Entry])] = [
            ("System Config Constants", systemConfigEntries()),
            ("User Inputs (Defaults)",  userInputEntries()),
            ("Raw Measurements",        measurementEntries()),
            ("Derived Calculations",    calculationEntries()),
        ]

        for (section, entries) in allEntries {
            lines.append("")
            lines.append("┌─ \(section)")
            lines.append("│")
            for e in entries {
                let sf = e.isExact ? "  ∞ SF" : String(format: "%3d SF", e.sigFigs)
                let val = e.value.padding(toLength: 12, withPad: " ", startingAt: 0)
                lines.append("│  \(sf)  \(val)  \(e.label)")
                if !e.notes.isEmpty {
                    lines.append("│         \("".padding(toLength: 12, withPad: " ", startingAt: 0))  └─ \(e.notes)")
                }
            }
            lines.append("│")
            lines.append("└────────────────────────────────────────────────────────────")
        }

        lines.append("")
        lines.append("⚠️  BOTTLENECKS (values limiting downstream precision):")
        lines.append("   1. Potassium Sorbate %vol = 0.078  →  2 SF")
        lines.append("   2. Overage Factor = 1.03            →  3 SF (limits vMix)")
        lines.append("   3. Blend percentages at 5% steps    →  1 SF (for 5%), 2 SF (for 25%)")
        lines.append("   4. Molds Filled resolution = 0.1    →  limits gummy-level calcs")

        return lines.joined(separator: "\n")
    }
}
