import SwiftUI

struct BatchValidationView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        let spec = systemConfig.spec(for: viewModel.selectedShape)

        // Pre-compute totals for reuse
        let activeTotalMass   = result.activationMix.totalMass_g
        let activeTotalVol    = result.activationMix.totalVolume_mL
        let gelatinTotalMass  = result.gelatinMix.totalMass_g
        let gelatinTotalVol   = result.gelatinMix.totalVolume_mL
        let sugarTotalMass    = result.sugarMix.totalMass_g
        let sugarTotalVol     = result.sugarMix.totalVolume_mL

        let finalMixMass      = activeTotalMass  + gelatinTotalMass  + sugarTotalMass
        let finalMixVol       = activeTotalVol   + gelatinTotalVol   + sugarTotalVol
        let finalOverageMass  = finalMixMass * viewModel.overageFactor
        let finalOverageVol   = finalMixVol  * viewModel.overageFactor

        let targetVol           = spec.volume_ml * Double(spec.count) * Double(viewModel.trayCount)
        let finalMixVolNoOverage = finalMixVol / viewModel.overageFactor
        let quantifiedError     = finalMixVolNoOverage - targetVol
        let relativeError       = (targetVol > 0) ? (quantifiedError / targetVol) * 100.0 : 0.0

        VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Quantitative Data").font(.headline).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                        .animation(.cmExpand, value: isExpanded)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            Divider().padding(.horizontal, 16)

            // MARK: Target Volumes
            subsectionHeader("Target Volumes")
            volOnlyRow("Volume Per Mold",  volume: spec.volume_ml)
            volOnlyRow("Volume Per Tray",  volume: spec.volume_ml * Double(spec.count))
            volOnlyRow("Total Volume",     volume: targetVol, bold: true)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Active Mix Components
            subsectionHeader("Active Mix Components")
            componentRows(result.activationMix.components)
            totalRow(mass: activeTotalMass, volume: activeTotalVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Gelatin Mix Components
            subsectionHeader("Gelatin Mix Components")
            componentRows(result.gelatinMix.components)
            totalRow(mass: gelatinTotalMass, volume: gelatinTotalVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Sugar Mix Components
            subsectionHeader("Sugar Mix Components")
            componentRows(result.sugarMix.components)
            totalRow(mass: sugarTotalMass, volume: sugarTotalVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Input Mixtures
            subsectionHeader("Input Mixtures")
            compRow("Active Mix",  mass: activeTotalMass,  volume: activeTotalVol)
            compRow("Gelatin Mix", mass: gelatinTotalMass, volume: gelatinTotalVol)
            compRow("Sugar Mix",   mass: sugarTotalMass,   volume: sugarTotalVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Final Mixture
            subsectionHeader("Final Mixture")
            compRow("Final Mix (with overage)",    mass: finalMixMass,                          volume: finalMixVol)
            compRow("Final Mix (without overage)", mass: finalMixMass / viewModel.overageFactor, volume: finalMixVol / viewModel.overageFactor, bold: true)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Error
            subsectionHeader("Error")
            errorRow("Quantified Error",
                     value: String(format: "%+.3f mL", quantifiedError),
                     highlight: abs(quantifiedError))
            errorRow("Relative Error",
                     value: String(format: "%+.3f%%", relativeError),
                     highlight: abs(relativeError))

            Spacer().frame(height: 12)
            } // end if isExpanded
        }
    }

    // MARK: - Sub-views

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text("mass (g)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol (mL)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    @ViewBuilder
    private func componentRows(_ components: [BatchComponent]) -> some View {
        ForEach(components) { c in
            HStack {
                Text(c.label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", c.mass_g))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", c.volume_mL))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func totalRow(mass: Double, volume: Double) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.3f", mass))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
        .background(CMTheme.totalRowBG)
    }

    private func compRow(_ label: String, mass: Double, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", mass))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func volOnlyRow(_ label: String, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("—")
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func errorRow(_ label: String, value: String, highlight: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(highlight < 1.0 ? CMTheme.success : CMTheme.danger)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }
}

// MARK: - Relative Fractions View

struct RelativeFractionsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false

    var body: some View {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)

        let activeTotalMass   = result.activationMix.totalMass_g
        let activeTotalVol    = result.activationMix.totalVolume_mL
        let gelatinTotalMass  = result.gelatinMix.totalMass_g
        let gelatinTotalVol   = result.gelatinMix.totalVolume_mL
        let sugarTotalMass    = result.sugarMix.totalMass_g
        let sugarTotalVol     = result.sugarMix.totalVolume_mL

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        VStack(spacing: 0) {
            Button {
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Relative Data").font(.headline).foregroundStyle(CMTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline).foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                        .animation(.cmExpand, value: isExpanded)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            Divider().padding(.horizontal, 16)

            // MARK: Active Mix Components
            fracSubheader("Active Mix Components")
            fracComponentRows(result.activationMix.components, totalMass: finalMixMass, totalVol: finalMixVol)
            fracTotalRow(mass: activeTotalMass, volume: activeTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Gelatin Mix Components
            fracSubheader("Gelatin Mix Components")
            fracComponentRows(result.gelatinMix.components, totalMass: finalMixMass, totalVol: finalMixVol)
            fracTotalRow(mass: gelatinTotalMass, volume: gelatinTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Sugar Mix Components
            fracSubheader("Sugar Mix Components")
            fracComponentRows(result.sugarMix.components, totalMass: finalMixMass, totalVol: finalMixVol)
            fracTotalRow(mass: sugarTotalMass, volume: sugarTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Input Mixtures
            fracSubheader("Input Mixtures")
            fracRow("Active Mix",  massPct: pct(activeTotalMass, of: finalMixMass),  volPct: pct(activeTotalVol, of: finalMixVol))
            fracRow("Gelatin Mix", massPct: pct(gelatinTotalMass, of: finalMixMass), volPct: pct(gelatinTotalVol, of: finalMixVol))
            fracRow("Sugar Mix",   massPct: pct(sugarTotalMass, of: finalMixMass),   volPct: pct(sugarTotalVol, of: finalMixVol))

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Final Mixture
            fracSubheader("Final Mixture")
            fracRow("Final Mix", massPct: 100.0, volPct: 100.0, bold: true)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Custom Metrics
            customMetricsSubheader("Custom Metrics")
            fracRow("Goop Ratio",
                    massPct: gelatinTotalMass > 0 ? sugarTotalMass / gelatinTotalMass : 0,
                    volPct: gelatinTotalVol > 0 ? sugarTotalVol / gelatinTotalVol : 0)
            Text("The goop ratio is defined as the total sugar mixture divided by the total gelatin mixture (water included in each mixture), in mass and volume units.")
                .font(.caption).foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16).padding(.top, 6)

            Spacer().frame(height: 12)
            } // end if isExpanded
        }
    }

    // MARK: - Helpers

    private func pct(_ part: Double, of whole: Double) -> Double {
        whole > 0 ? (part / whole) * 100.0 : 0
    }

    private func customMetricsSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text("mass")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func fracSubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text("mass %")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol %")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    @ViewBuilder
    private func fracComponentRows(_ components: [BatchComponent], totalMass: Double, totalVol: Double) -> some View {
        ForEach(components) { c in
            HStack {
                Text(c.label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", pct(c.mass_g, of: totalMass)))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", pct(c.volume_mL, of: totalVol)))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func fracTotalRow(mass: Double, volume: Double, totalMass: Double, totalVol: Double) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(String(format: "%.3f", pct(mass, of: totalMass)))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", pct(volume, of: totalVol)))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
        .background(CMTheme.totalRowBG)
    }

    private func fracRow(_ label: String, massPct: Double, volPct: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", massPct))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volPct))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? CMTheme.textPrimary : CMTheme.textSecondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }
}
