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
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Theoretical Calculation Validation").font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline).foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
            Spacer()
            Text("mass (g)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
                .frame(width: 70, alignment: .trailing)
            Text("vol (mL)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
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
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", c.mass_g))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", c.volume_mL))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func totalRow(mass: Double, volume: Double) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
            Spacer()
            Text(String(format: "%.3f", mass))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 11, design: .monospaced)).fontWeight(.semibold)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
        .background(Color(.systemGray5).opacity(0.6))
    }

    private func compRow(_ label: String, mass: Double, volume: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(bold ? .bold : .regular)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(String(format: "%.3f", mass))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? .primary : .secondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? .primary : .secondary)
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
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("—")
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(.tertiary)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.3f", volume))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bold ? .primary : .secondary)
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func errorRow(_ label: String, value: String, highlight: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(highlight < 1.0 ? Color.green : Color.red)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }
}
