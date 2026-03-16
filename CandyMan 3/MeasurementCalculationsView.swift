import SwiftUI

struct MeasurementCalculationsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var showErrorHelp = false

    // MARK: - Resolution-aware decimal places

    /// Beaker-only subtractions (gelatin added, sugar added, active added, final mix, beaker residue)
    private var beakerDP: Int { systemConfig.beakerDP }
    /// Syringe-only subtractions (syringe residue, mass in syringe)
    private var syringeDP: Int { systemConfig.syringeDP }
    /// Mixed beaker+syringe (total loss, transferred to mold, avg gummy mass, active loss, active dose)
    private var mixedDP: Int { systemConfig.mixedDP }
    /// All instruments (density, avg gummy volume)
    private var allDP: Int { systemConfig.allDP }

    // MARK: - Derived Measurements

    private var massGelatinAdded: Double? {
        guard let a = viewModel.weightBeakerPlusGelatin,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return a - b
    }

    private var massSugarAdded: Double? {
        guard let a = viewModel.weightBeakerPlusSugar,
              let b = viewModel.weightBeakerPlusGelatin else { return nil }
        return a - b
    }

    private var massActiveAdded: Double? {
        guard let a = viewModel.weightBeakerPlusActive,
              let b = viewModel.weightBeakerPlusSugar else { return nil }
        return a - b
    }

    private var massFinalMixtureInBeaker: Double? {
        guard let a = viewModel.weightBeakerPlusActive,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return a - b
    }

    private var massBeakerResidue: Double? {
        guard let a = viewModel.weightBeakerResidue,
              let b = viewModel.weightBeakerEmpty else { return nil }
        return a - b
    }

    private var massSyringeResidue: Double? {
        guard let a = viewModel.weightSyringeResidue,
              let b = viewModel.weightSyringeEmpty else { return nil }
        return a - b
    }

    private var massTotalLoss: Double? {
        guard let br = massBeakerResidue,
              let sr = massSyringeResidue else { return nil }
        return br + sr
    }

    private var massMixTransferredToMold: Double? {
        guard let finalMix = massFinalMixtureInBeaker,
              let totalLoss = massTotalLoss else { return nil }
        return finalMix - totalLoss
    }

    private var massPerGummyMold: Double? {
        guard let transferred = massMixTransferredToMold,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        return transferred / molds
    }

    private var densityFinalMix: Double? {
        guard let mass = viewModel.calcMassOfMixInSyringe,
              let vol  = viewModel.volumeSyringeGummyMix,
              vol > 0 else { return nil }
        return mass / vol
    }

    private var averageGummyVolume: Double? {
        guard let density = densityFinalMix, density > 0,
              let massPerGummy = massPerGummyMold else { return nil }
        return massPerGummy / density
    }

    private var activeLoss: Double? {
        guard let totalLoss = massTotalLoss,
              let finalMix  = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let totalActive = viewModel.activeConcentration * Double(spec.count * viewModel.trayCount)
        return totalActive * (totalLoss / finalMix)
    }

    private var averageGummyActiveDose: Double? {
        guard let loss  = activeLoss,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        let totalActive = viewModel.activeConcentration * Double(spec.count * viewModel.trayCount)
        return (totalActive - loss) / molds
    }

    // MARK: - Per-subtraction decimal places

    /// Gelatin added = (Beaker+Gelatin) - (Beaker Empty)
    private var dpGelatinAdded: Int {
        systemConfig.dpFor(systemConfig.resBeakerPlusGelatin, systemConfig.resBeakerEmpty)
    }
    /// Sugar added = (Substrate+Sugar) - (Beaker+Gelatin)
    private var dpSugarAdded: Int {
        systemConfig.dpFor(systemConfig.resSubstratePlusSugar, systemConfig.resBeakerPlusGelatin)
    }
    /// Activation added = (Substrate+Activation) - (Substrate+Sugar)
    private var dpActiveAdded: Int {
        systemConfig.dpFor(systemConfig.resSubstratePlusActivation, systemConfig.resSubstratePlusSugar)
    }
    /// Final mixture = (Substrate+Activation) - (Beaker Empty)
    private var dpFinalMixture: Int {
        systemConfig.dpFor(systemConfig.resSubstratePlusActivation, systemConfig.resBeakerEmpty)
    }
    /// Beaker residue = (Beaker+Residue) - (Beaker Empty)
    private var dpBeakerResidue: Int {
        systemConfig.dpFor(systemConfig.resBeakerPlusResidue, systemConfig.resBeakerEmpty)
    }
    /// Syringe residue = (Syringe+Residue) - (Syringe Clean)
    private var dpSyringeResidue: Int {
        systemConfig.dpFor(systemConfig.resSyringeResidue, systemConfig.resSyringeClean)
    }
    /// Total loss = beaker residue + syringe residue (mixed instruments)
    private var dpTotalLoss: Int { mixedDP }
    /// Transferred to mold = final mix - total loss (mixed instruments)
    private var dpTransferred: Int { mixedDP }
    /// Density = mass / volume (all instruments)
    private var dpDensity: Int { allDP + 1 }
    /// Avg gummy mass = transferred / molds (mixed + molds)
    private var dpAvgGummyMass: Int { min(mixedDP, systemConfig.moldsDP) }
    /// Avg gummy volume = mass / density (all instruments + molds)
    private var dpAvgGummyVol: Int { min(allDP, systemConfig.moldsDP) + 1 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.headline)
                Spacer()
                Button {
                    showErrorHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            // MARK: Input Mixtures
            subsectionHeader("Input Mixtures")
            calcRow("Gelatin Mix Added",     value: massGelatinAdded,  unit: "g",  dp: dpGelatinAdded)
            calcRow("Sugar Mix Added",        value: massSugarAdded,    unit: "g",  dp: dpSugarAdded)
            calcRow("Activation Mix Added",   value: massActiveAdded,   unit: "g",  dp: dpActiveAdded)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Final Mixture
            subsectionHeader("Final Mixture")
            calcRow("Final Mixture in Beaker",       value: massFinalMixtureInBeaker,  unit: "g",    dp: dpFinalMixture)
            calcRow("Final Mixture in Tray/s",       value: massMixTransferredToMold,  unit: "g",    dp: dpTransferred)
            calcRow("Density of Final Mix",          value: densityFinalMix,           unit: "g/ml", dp: dpDensity)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Losses
            subsectionHeader("Losses")
            calcRow("Beaker Residue",                value: massBeakerResidue,         unit: "g",  dp: dpBeakerResidue)
            calcRow("Syringe Residue",               value: massSyringeResidue,        unit: "g",  dp: dpSyringeResidue)
            calcRow("Total Loss",                    value: massTotalLoss,             unit: "g",  dp: dpTotalLoss)
            calcRow("Active Loss",                   value: activeLoss,                unit: viewModel.units.rawValue, dp: dpTotalLoss)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Gummies
            subsectionHeader("Gummies")
            calcRow("Average Gummy Mass",            value: massPerGummyMold,        unit: "g",  dp: dpAvgGummyMass)
            calcRow("Average Gummy Volume",          value: averageGummyVolume,      unit: "mL", dp: dpAvgGummyVol)
            calcRow("Average Gummy Active Dose",     value: averageGummyActiveDose,  unit: viewModel.units.rawValue, dp: dpAvgGummyMass)

            Spacer(minLength: 12)
        }
        .sheet(isPresented: $showErrorHelp) {
            errorPropagationHelp
        }
    }

    // MARK: - Error Propagation Help Sheet

    private var errorPropagationHelp: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    Text("Why do some values show fewer decimal places?")
                        .font(.headline)

                    Text("Every measurement has an inherent uncertainty determined by your instrument's resolution. When you combine measurements through arithmetic, those uncertainties propagate — and the result can never be more precise than its inputs.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    Divider()

                    Group {
                        Text("Current Instrument Resolutions").font(.subheadline).fontWeight(.semibold)

                        Text("Beaker scale").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                        resolutionRow("Beaker (Empty)",             res: systemConfig.resBeakerEmpty)
                        resolutionRow("Beaker + Gelatin Mix",       res: systemConfig.resBeakerPlusGelatin)
                        resolutionRow("Substrate + Sugar Mix",      res: systemConfig.resSubstratePlusSugar)
                        resolutionRow("Substrate + Activation Mix", res: systemConfig.resSubstratePlusActivation)
                        resolutionRow("Beaker + Residue",           res: systemConfig.resBeakerPlusResidue)
                    }

                    Group {
                        Text("Syringe scale").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                        resolutionRow("Syringe (Clean)",            res: systemConfig.resSyringeClean)
                        resolutionRow("Syringe + Gummy Mix",        res: systemConfig.resSyringePlusGummyMix)
                        resolutionRow("Syringe + Residue",          res: systemConfig.resSyringeResidue)

                        Text("Volume & count").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                        resolutionRow("Syringe Gummy Mixture Vol",  res: systemConfig.resSyringeVolume, unit: "mL")
                        resolutionRow("Molds Filled",               res: systemConfig.resMoldsFilled, unit: "molds")
                    }

                    Divider()

                    Group {
                        Text("Propagation Rules").font(.subheadline).fontWeight(.semibold)

                        ruleRow(
                            title: "Subtraction / Addition",
                            formula: "c = a ± b",
                            explanation: "δc = √(δa² + δb²). The result keeps the same number of decimal places as the coarsest input."
                        )

                        ruleRow(
                            title: "Division / Multiplication",
                            formula: "c = a / b",
                            explanation: "δc/c = √((δa/a)² + (δb/b)²). Relative uncertainties add in quadrature. Result gets one extra decimal place beyond the coarsest input."
                        )

                        ruleRow(
                            title: "Scalar Multiplication",
                            formula: "c = k × a (k exact)",
                            explanation: "δc = k × δa. Exact constants don't add uncertainty."
                        )
                    }

                    Divider()

                    Group {
                        Text("How It Applies").font(.subheadline).fontWeight(.semibold)

                        Text("Each calculation uses the resolutions of its specific input measurements. For example, "Gelatin Mix Added" = (Beaker + Gelatin Mix) − (Beaker Empty), so its decimal places = min(\(systemConfig.resBeakerPlusGelatin.decimalPlaces), \(systemConfig.resBeakerEmpty.decimalPlaces)) = \(dpGelatinAdded).")
                            .font(.caption)

                        Text("Calculations that combine beaker and syringe measurements use the coarsest resolution across both instruments → \(mixedDP) decimal places.")
                            .font(.caption)

                        Text("Division results (density, volume) use min(all inputs) + 1 → \(allDP + 1) decimal places.")
                            .font(.caption)

                        Text("Gummy averages that divide by mold count also factor in the mold count resolution → \(systemConfig.moldsDP) dp.")
                            .font(.caption)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Error Propagation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showErrorHelp = false }.fontWeight(.semibold)
                }
            }
        }
    }

    private func resolutionRow(_ label: String, res: MeasurementResolution, unit: String = "g") -> some View {
        HStack {
            Text(label).font(.system(size: 13, design: .monospaced))
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text("± \(String(format: "%g", res.halfResolution)) \(unit)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("→ \(res.decimalPlaces) dp")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }

    private func ruleRow(title: String, formula: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).fontWeight(.semibold)
                Spacer()
                Text(formula).font(.system(size: 12, design: .monospaced)).foregroundStyle(.blue)
            }
            Text(explanation).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func calcRow(_ label: String, value: Double?, unit: String, dp: Int) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.primary)
            Spacer()
            Group {
                if let v = value {
                    Text(String(format: "%.\(dp)f", v))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.primary)
                } else {
                    Text("—")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            Text(unit)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 5)
    }
}
