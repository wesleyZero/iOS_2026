//
//  MetaAnalysisView.swift
//  CandyMan
//
//  Cross-batch statistical analysis using linear regression. Pulls all saved
//  batches that have measured data and runs OLS regression on overage factor
//  vs actual overage, displaying scatter plots with trend lines, R², 95%
//  prediction intervals, and residual diagnostics. Uses Swift Charts.
//
//  Contents:
//    RegressionResult      — OLS output (slope, intercept, R², std errors, prediction CI)
//    linearRegression()    — standalone OLS function
//    tValue95()            — t-distribution lookup for 95% confidence
//    MetaAnalysisView      — main analysis view with chart + stats
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Linear Regression Engine

struct RegressionResult {
    let slope: Double
    let intercept: Double
    let rSquared: Double
    let standardError: Double       // standard error of the estimate
    let slopeStdError: Double       // standard error of slope
    let interceptStdError: Double   // standard error of intercept
    let n: Int

    /// Predicted y for a given x
    func predict(_ x: Double) -> Double { slope * x + intercept }

    /// 95% prediction interval half-width at x
    func predictionInterval95(at x: Double, xMean: Double, sumXXDeviation: Double) -> Double {
        let tCrit = tValue95(df: n - 2)
        let xDev = x - xMean
        let factor = 1.0 + 1.0 / Double(n) + (xDev * xDev) / sumXXDeviation
        return tCrit * standardError * sqrt(factor)
    }

    /// Approximate t-value for 95% two-tailed CI
    private func tValue95(df: Int) -> Double {
        // Lookup for small df; approximate for larger
        let table: [Int: Double] = [
            1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571,
            6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262, 10: 2.228,
            15: 2.131, 20: 2.086, 25: 2.060, 30: 2.042, 40: 2.021,
            60: 2.000, 120: 1.980
        ]
        if let v = table[df] { return v }
        if df > 120 { return 1.960 }
        // Linear interpolate between nearest keys
        let keys = table.keys.sorted()
        guard let upper = keys.first(where: { $0 >= df }),
              let lowerIdx = keys.lastIndex(where: { $0 < df }) else { return 1.960 }
        let lower = keys[lowerIdx]
        let frac = Double(df - lower) / Double(upper - lower)
        return table[lower]! + frac * (table[upper]! - table[lower]!)
    }
}

extension RegressionResult {
    /// Performs ordinary least-squares linear regression on paired (x, y) data.
    static func linearRegression(xs: [Double], ys: [Double]) -> RegressionResult? {
    let n = min(xs.count, ys.count)
    guard n >= 3 else { return nil } // need at least 3 points

    let xMean = xs.reduce(0, +) / Double(n)
    let yMean = ys.reduce(0, +) / Double(n)

    var ssXX = 0.0, ssXY = 0.0, ssYY = 0.0
    for i in 0..<n {
        let dx = xs[i] - xMean
        let dy = ys[i] - yMean
        ssXX += dx * dx
        ssXY += dx * dy
        ssYY += dy * dy
    }

    guard ssXX > 0 else { return nil }

    let slope = ssXY / ssXX
    let intercept = yMean - slope * xMean
    let ssRes = ssYY - slope * ssXY
    let rSquared = ssYY > 0 ? 1.0 - ssRes / ssYY : 0
    let mse = ssRes / Double(n - 2)
    let se = sqrt(max(mse, 0))
    let slopeSE = se / sqrt(ssXX)
    let interceptSE = se * sqrt(1.0 / Double(n) + xMean * xMean / ssXX)

    return RegressionResult(
        slope: slope,
        intercept: intercept,
        rSquared: max(rSquared, 0),
        standardError: se,
        slopeStdError: slopeSE,
        interceptStdError: interceptSE,
        n: n
    )
    }
}

// MARK: - Data Point

struct DensityDataPoint: Identifiable {
    let id = UUID()
    let batchID: String
    let batchName: String
    let batchLabel: String
    let mixVolume: Double      // x — measured syringe volume of gummy mixture (mL)
    let mixMass: Double        // y — measured final gummy mixture mass (g)
    let date: Date
    let shape: String
    let wellCount: Int

    /// Derived density from the two measured values
    var density: Double { mixVolume > 0 ? mixMass / mixVolume : 0 }
}

// MARK: - Meta-Analysis View

struct MetaAnalysisView: View {
    @Query(sort: \SavedBatch.date, order: .reverse) private var batches: [SavedBatch]
    @Environment(SystemConfig.self) private var systemConfig
    @State private var showBatchDataSheet = false

    /// Synthetic data generated once and cached.
    @State private var syntheticPoints: [DensityDataPoint] = []

    private var realDataPoints: [DensityDataPoint] {
        batches
            .filter { !$0.isTrashed }
            .compactMap { batch in
                guard let mass = batch.calcMassFinalMixtureInBeaker,
                      let volume = batch.volumeSyringeGummyMix,
                      mass > 0, volume > 0 else { return nil }
                return DensityDataPoint(
                    batchID: batch.batchID,
                    batchName: batch.name,
                    batchLabel: batch.batchID.isEmpty ? batch.name : batch.batchID,
                    mixVolume: volume,
                    mixMass: mass,
                    date: batch.date,
                    shape: batch.shape,
                    wellCount: batch.wellCount
                )
            }
            .sorted { $0.date < $1.date }
    }

    private var dataPoints: [DensityDataPoint] {
        if systemConfig.syntheticDataSet1Enabled {
            return realDataPoints + syntheticPoints
        }
        return realDataPoints
    }

    private var regression: RegressionResult? {
        let pts = dataPoints
        guard pts.count >= 3 else { return nil }
        return RegressionResult.linearRegression(
            xs: pts.map(\.mixVolume),
            ys: pts.map(\.mixMass)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                summaryCard
                    .cardStyle()

                if dataPoints.count >= 3 {
                    regressionChart
                        .cardStyle()
                    regressionStatsCard
                        .cardStyle()
                    residualsCard
                        .cardStyle()
                }

                dataTableCard
                    .cardStyle()
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .navigationTitle("Density Analysis")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showBatchDataSheet) {
            BatchDensityDataSheet(dataPoints: dataPoints, regression: regression)
                .environment(systemConfig)
        }
        .onAppear {
            if syntheticPoints.isEmpty && systemConfig.syntheticDataSet1Enabled {
                syntheticPoints = Self.generateSyntheticDataSet1()
            }
        }
        .onChange(of: systemConfig.syntheticDataSet1Enabled) { _, enabled in
            if enabled && syntheticPoints.isEmpty {
                syntheticPoints = Self.generateSyntheticDataSet1()
            } else if !enabled {
                syntheticPoints = []
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let pts = dataPoints
        let densities = pts.map(\.density)
        let n = densities.count
        let mean = n > 0 ? densities.reduce(0, +) / Double(n) : 0
        let variance = n > 1 ? densities.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(n - 1) : 0
        let stdDev = sqrt(variance)
        let minD = densities.min() ?? 0
        let maxD = densities.max() ?? 0
        let tCrit = n > 2 ? 2.0 : 12.706  // rough 95% t
        let ciHalf = n > 1 ? tCrit * stdDev / sqrt(Double(n)) : 0

        return VStack(spacing: 0) {
            HStack {
                Text("Final Mixture Mass vs Volume").cmSectionTitle(accent: systemConfig.designTitle)
                Spacer()
                Button {
                    CMHaptic.light()
                    showBatchDataSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("\(n) batch\(n == 1 ? "" : "es")")
                            .font(.caption).foregroundStyle(CMTheme.textTertiary)
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(systemConfig.designTitle)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ThemedDivider(indent: 16)

            if n == 0 {
                Text("No batches with measured mass and volume data.")
                    .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                    .padding(16)
            } else {
                VStack(spacing: 0) {
                    statRow("Mean Density (m/V)", value: String(format: "%.4f g/mL", mean))
                    statRow("Std Deviation", value: String(format: "%.4f g/mL", stdDev))
                    statRow("95% CI", value: String(format: "%.4f ± %.4f g/mL", mean, ciHalf))
                    statRow("Range", value: String(format: "%.4f – %.4f g/mL", minD, maxD))
                }
                .padding(.bottom, 8)

                if n < 3 {
                    Text("At least 3 batches with measurement data are needed for regression analysis.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.bottom, 10)
                }
            }
        }
    }

    // MARK: - Regression Chart

    private var regressionChart: some View {
        let pts = dataPoints
        guard let reg = regression else { return AnyView(EmptyView()) }

        let xs = pts.map(\.mixVolume)
        let xMin = (xs.min() ?? 0) * 0.90
        let xMax = (xs.max() ?? 1) * 1.10
        let xMean = xs.reduce(0, +) / Double(xs.count)
        let ssXX = xs.map { ($0 - xMean) * ($0 - xMean) }.reduce(0, +)

        // Generate regression line + prediction band points
        let lineSteps = 50
        let lineXs = (0...lineSteps).map { i in xMin + (xMax - xMin) * Double(i) / Double(lineSteps) }

        struct BandPoint: Identifiable {
            let id = UUID()
            let x: Double
            let yLow: Double
            let yHigh: Double
        }
        let bandPoints = lineXs.map { x in
            let yHat = reg.predict(x)
            let hw = reg.predictionInterval95(at: x, xMean: xMean, sumXXDeviation: ssXX)
            return BandPoint(x: x, yLow: yHat - hw, yHigh: yHat + hw)
        }

        return AnyView(
            VStack(spacing: 0) {
                HStack {
                    Text("Mass vs Volume — Final Gummy Mixture").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                Chart {
                    // 95% prediction band
                    ForEach(bandPoints) { bp in
                        AreaMark(
                            x: .value("Volume (mL)", bp.x),
                            yStart: .value("Low", bp.yLow),
                            yEnd: .value("High", bp.yHigh)
                        )
                        .foregroundStyle(systemConfig.designTitle.opacity(0.1))
                    }

                    // Regression line
                    ForEach(Array(lineXs.enumerated()), id: \.offset) { _, x in
                        LineMark(
                            x: .value("Volume (mL)", x),
                            y: .value("Mass (g)", reg.predict(x))
                        )
                        .foregroundStyle(systemConfig.designTitle.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    // Data points
                    ForEach(pts) { pt in
                        PointMark(
                            x: .value("Volume (mL)", pt.mixVolume),
                            y: .value("Mass (g)", pt.mixMass)
                        )
                        .foregroundStyle(systemConfig.designTitle)
                        .symbolSize(40)
                    }
                }
                .chartXAxisLabel("Syringe Volume (mL)", alignment: .center)
                .chartYAxisLabel("Mass (g)")
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) {
                        AxisGridLine().foregroundStyle(CMTheme.divider)
                        AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) {
                        AxisGridLine().foregroundStyle(CMTheme.divider)
                        AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Text("Slope = density (g/mL). Shaded region: 95% prediction interval.")
                    .cmFootnote()
                    .padding(.horizontal, 16).padding(.bottom, 10)
            }
        )
    }

    // MARK: - Regression Statistics

    private var regressionStatsCard: some View {
        guard let reg = regression else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: 0) {
                HStack {
                    Text("Regression Statistics").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    statRow("Equation", value: String(format: "m = %.4f × V %+.4f", reg.slope, reg.intercept))
                    statRow("Slope (ρ estimate)", value: String(format: "%.6f ± %.6f g/mL", reg.slope, reg.slopeStdError), highlight: true)
                    statRow("R²", value: String(format: "%.6f", reg.rSquared), highlight: reg.rSquared >= 0.95)
                    statRow("Std Error of Estimate", value: String(format: "%.4f g", reg.standardError))
                    statRow("Intercept", value: String(format: "%.4f ± %.4f g", reg.intercept, reg.interceptStdError))
                    statRow("n", value: "\(reg.n)")

                    // Interpretation
                    let interceptSignificant = abs(reg.intercept) > 2.0 * reg.interceptStdError
                    Text(interceptSignificant
                         ? "Intercept is significantly non-zero — consider systematic offset in measurements."
                         : "Intercept consistent with zero. Slope is a reliable density estimate (g/mL).")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .padding(.bottom, 4)
            }
        )
    }

    // MARK: - Residuals

    private var residualsCard: some View {
        guard let reg = regression else { return AnyView(EmptyView()) }
        let pts = dataPoints

        struct ResidualPoint: Identifiable {
            let id = UUID()
            let x: Double
            let residual: Double
        }
        let residuals = pts.map { pt in
            ResidualPoint(x: pt.mixVolume, residual: pt.mixMass - reg.predict(pt.mixVolume))
        }

        return AnyView(
            VStack(spacing: 0) {
                HStack {
                    Text("Residuals").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                Chart {
                    // Zero line
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(CMTheme.textTertiary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    ForEach(residuals) { r in
                        BarMark(
                            x: .value("Volume (mL)", r.x),
                            y: .value("Residual (g)", r.residual)
                        )
                        .foregroundStyle(r.residual >= 0 ? systemConfig.designTitle : systemConfig.designAlert)
                        .cornerRadius(2)
                    }
                }
                .chartXAxisLabel("Syringe Volume (mL)", alignment: .center)
                .chartYAxisLabel("Residual (g)")
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) {
                        AxisGridLine().foregroundStyle(CMTheme.divider)
                        AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine().foregroundStyle(CMTheme.divider)
                        AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                    }
                }
                .frame(height: 140)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                Text("Residuals should scatter randomly around zero. Patterns suggest non-linear behavior.")
                    .cmFootnote()
                    .padding(.horizontal, 16).padding(.bottom, 10)
            }
        )
    }

    // MARK: - Data Table

    private var dataTableCard: some View {
        let pts = dataPoints

        return VStack(spacing: 0) {
            HStack {
                Text("Batch Data").cmSectionTitle(accent: systemConfig.designTitle)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ThemedDivider(indent: 16)

            // Header
            HStack(spacing: 4) {
                Text("Batch").font(.caption2).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("Vol (mL)").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 60, alignment: .trailing)
                Text("Mass (g)").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 65, alignment: .trailing)
                Text("ρ (g/mL)").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                    .frame(width: 60, alignment: .trailing)
                if regression != nil {
                    Text("Resid (g)").font(.caption2).foregroundStyle(CMTheme.textTertiary)
                        .frame(width: 60, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 2)

            if pts.isEmpty {
                Text("No measurement data available.")
                    .cmFootnote()
                    .padding(16)
            } else {
                ForEach(pts) { pt in
                    let residual = regression.map { pt.mixMass - $0.predict(pt.mixVolume) }
                    HStack(spacing: 4) {
                        Text(pt.batchLabel)
                            .cmMono11()
                            .foregroundStyle(CMTheme.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(width: 50, alignment: .leading)
                        Spacer()
                        Text(String(format: "%.2f", pt.mixVolume))
                            .cmMono11()
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 60, alignment: .trailing)
                        Text(String(format: "%.3f", pt.mixMass))
                            .cmMono11()
                            .foregroundStyle(CMTheme.textPrimary)
                            .frame(width: 65, alignment: .trailing)
                        Text(String(format: "%.4f", pt.density))
                            .cmMono11()
                            .foregroundStyle(CMTheme.textTertiary)
                            .frame(width: 60, alignment: .trailing)
                        if let r = residual {
                            Text(String(format: "%+.3f", r))
                                .cmMono11()
                                .foregroundStyle(abs(r) < 0.5 ? CMTheme.success : (abs(r) < 1.5 ? systemConfig.designSecondaryAccent : systemConfig.designAlert))
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 3)
                }
            }

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Helpers

    private func statRow(_ label: String, value: String, highlight: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmRowLabel()
            Spacer()
            Text(value)
                .cmMono12()
                .foregroundStyle(highlight ? systemConfig.designTitle : CMTheme.textSecondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 3)
    }

    // MARK: - Synthetic Data Generator

    /// Generates 100 synthetic batches with realistic variation based on default system settings.
    static func generateSyntheticDataSet1() -> [DensityDataPoint] {
        let baseDensity = 1.3085         // estimatedFinalMixDensity default

        // Seeded random for reproducibility
        var rng = SeededRNG(seed: 42)

        var points: [DensityDataPoint] = []
        let baseDate = Calendar.current.date(byAdding: .month, value: -6, to: .now)!

        for i in 0..<100 {
            // Synthetic syringe volume: 20–120 mL range
            let syringeVol = Double.random(in: 20.0...120.0, using: &rng)

            // Density: normal-ish distribution around baseDensity
            // Use Box-Muller transform for Gaussian noise
            let u1 = Double.random(in: 0.0001...0.9999, using: &rng)
            let u2 = Double.random(in: 0.0001...0.9999, using: &rng)
            let gaussian = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
            let density = baseDensity + gaussian * 0.025  // std dev ~0.025 g/mL
            let finalDensity = max(density, 1.0)

            // Mass = density × volume, plus small independent measurement noise
            let massNoise = Double.random(in: -0.3...0.3, using: &rng)
            let mixMass = finalDensity * syringeVol + massNoise

            // Generate date spread over past 6 months
            let dayOffset = Int.random(in: 0...180, using: &rng)
            let hourOffset = Int.random(in: 0...23, using: &rng)
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: baseDate)!
                .addingTimeInterval(Double(hourOffset) * 3600)

            let batchID = String(format: "SYN-%03d", i + 1)

            points.append(DensityDataPoint(
                batchID: batchID,
                batchName: "Synthetic #\(i + 1)",
                batchLabel: batchID,
                mixVolume: syringeVol,
                mixMass: max(mixMass, 0),
                date: date,
                shape: "—",
                wellCount: 0
            ))
        }

        return points.sorted { $0.date < $1.date }
    }
}

/// Simple seeded PRNG for reproducible synthetic data.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Batch Density Data Sheet

struct BatchDensityDataSheet: View {
    let dataPoints: [DensityDataPoint]
    let regression: RegressionResult?
    @Environment(\.dismiss) private var dismiss
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        Text("Batch ID")
                            .frame(width: 70, alignment: .leading)
                        Text("Shape")
                            .frame(width: 55, alignment: .leading)
                        Spacer()
                        Text("Vol (mL)")
                            .frame(width: 58, alignment: .trailing)
                        Text("Mass (g)")
                            .frame(width: 60, alignment: .trailing)
                        Text("ρ (g/mL)")
                            .frame(width: 62, alignment: .trailing)
                        if regression != nil {
                            Text("Resid (g)")
                                .frame(width: 58, alignment: .trailing)
                        }
                    }
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(CMTheme.textSecondary)
                    .padding(.horizontal, 16).padding(.vertical, 8)

                    ThemedDivider(indent: 16)

                    if dataPoints.isEmpty {
                        Text("No measurement data available.")
                            .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                            .padding(20)
                    } else {
                        ForEach(dataPoints) { pt in
                            let residual = regression.map { pt.mixMass - $0.predict(pt.mixVolume) }
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(pt.batchID.isEmpty ? "—" : pt.batchID)
                                        .cmMono11()
                                        .foregroundStyle(systemConfig.designTitle)
                                        .lineLimit(1).minimumScaleFactor(0.6)
                                        .frame(width: 70, alignment: .leading)
                                    Text(pt.shape)
                                        .font(.system(size: 10))
                                        .foregroundStyle(CMTheme.textTertiary)
                                        .lineLimit(1)
                                        .frame(width: 55, alignment: .leading)
                                    Spacer()
                                    Text(String(format: "%.2f", pt.mixVolume))
                                        .cmMono11()
                                        .foregroundStyle(CMTheme.textSecondary)
                                        .frame(width: 58, alignment: .trailing)
                                    Text(String(format: "%.3f", pt.mixMass))
                                        .cmMono11()
                                        .foregroundStyle(CMTheme.textPrimary)
                                        .frame(width: 60, alignment: .trailing)
                                    Text(String(format: "%.4f", pt.density))
                                        .cmMono10()
                                        .foregroundStyle(CMTheme.textTertiary)
                                        .frame(width: 62, alignment: .trailing)
                                    if let r = residual {
                                        Text(String(format: "%+.3f", r))
                                            .cmMono10()
                                            .foregroundStyle(
                                                abs(r) < 0.5 ? CMTheme.success
                                                : abs(r) < 1.5 ? systemConfig.designSecondaryAccent
                                                : systemConfig.designAlert
                                            )
                                            .frame(width: 58, alignment: .trailing)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 5)

                                // Second line: name + date + gummies
                                HStack(spacing: 4) {
                                    Text(pt.batchName)
                                        .font(.system(size: 9))
                                        .foregroundStyle(CMTheme.textTertiary)
                                        .lineLimit(1)
                                    Text("·")
                                        .font(.system(size: 9))
                                        .foregroundStyle(CMTheme.textTertiary)
                                    Text(pt.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                        .font(.system(size: 9))
                                        .foregroundStyle(CMTheme.textTertiary)
                                    Text("·")
                                        .font(.system(size: 9))
                                        .foregroundStyle(CMTheme.textTertiary)
                                    Text("\(pt.wellCount) gummies")
                                        .font(.system(size: 9))
                                        .foregroundStyle(CMTheme.textTertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16).padding(.bottom, 4)
                            }
                        }
                    }

                    Spacer().frame(height: 20)
                }
            }
            .background(CMTheme.pageBG)
            .navigationTitle("Batch Density Data")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
