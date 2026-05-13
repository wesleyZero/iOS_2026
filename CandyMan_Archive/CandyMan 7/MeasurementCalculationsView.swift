import SwiftUI

struct MeasurementCalculationsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var showDensityUpdatedAlert = false
    @State private var showOverageUpdatedAlert = false

    // MARK: - Derived Measurements

    private var massGelatinAdded: Double? {
        guard let afterGelatin = viewModel.weightBeakerPlusGelatin,
              let empty = viewModel.weightBeakerEmpty else { return nil }
        return afterGelatin - empty
    }

    private var massSugarAdded: Double? {
        guard let afterSugar = viewModel.weightBeakerPlusSugar,
              let afterGelatin = viewModel.weightBeakerPlusGelatin else { return nil }
        return afterSugar - afterGelatin
    }

    private var massActiveAdded: Double? {
        guard let afterActive = viewModel.weightBeakerPlusActive,
              let afterSugar = viewModel.weightBeakerPlusSugar else { return nil }
        return afterActive - afterSugar
    }

    private var massFinalMixtureInBeaker: Double? {
        guard let afterActive = viewModel.weightBeakerPlusActive,
              let empty = viewModel.weightBeakerEmpty else { return nil }
        return afterActive - empty
    }

    private var massBeakerResidue: Double? {
        guard let residue = viewModel.weightBeakerResidue,
              let empty = viewModel.weightBeakerEmpty else { return nil }
        return residue - empty
    }

    private var massSyringeResidue: Double? {
        guard let residue = viewModel.weightSyringeResidue,
              let empty = viewModel.weightSyringeEmpty else { return nil }
        return residue - empty
    }

    private var massTotalLoss: Double? {
        guard let beakerLoss = massBeakerResidue,
              let syringeLoss = massSyringeResidue else { return nil }
        return beakerLoss + syringeLoss
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

    /// Proportional share of active substance lost in beaker/syringe residue.
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

    private var massPotassiumSorbate: Double? {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        return result.activationMix.components.first(where: { $0.label == "Potassium Sorbate" })?.mass_g
    }

    private var massCitricAcid: Double? {
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
        return result.activationMix.components.first(where: { $0.label == "Citric Acid" })?.mass_g
    }

    private var massFractionPotassiumSorbate: Double? {
        guard let mSorbate = massPotassiumSorbate,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (mSorbate / finalMix) * 100.0
    }

    private var massFractionCitricAcid: Double? {
        guard let mCitric = massCitricAcid,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (mCitric / finalMix) * 100.0
    }

    /// Ratio of actual gummy volume to mold volume; use as next batch's overage factor.
    private var overageForNextBatch: Double? {
        guard let avgVol = averageGummyVolume else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        guard spec.volume_ml > 0 else { return nil }
        return avgVol / spec.volume_ml
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ThemedDivider()

            // MARK: Input Mixtures
            subsectionHeader("Input Mixtures")
            calcRow("Gelatin Mix Added",     value: massGelatinAdded,  unit: "g")
            calcRow("Sugar Mix Added",        value: massSugarAdded,    unit: "g")
            calcRow("Activation Mix Added",   value: massActiveAdded,   unit: "g")

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Final Mixture
            subsectionHeader("Final Mixture")
            calcRow("Final Mixture in Beaker",       value: massFinalMixtureInBeaker,  unit: "g")
            calcRow("Final Mixture in Tray/s",       value: massMixTransferredToMold,  unit: "g")

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Losses
            subsectionHeader("Losses")
            calcRow("Beaker Residue",                value: massBeakerResidue,         unit: "g")
            calcRow("Syringe Residue",               value: massSyringeResidue,        unit: "g")
            calcRow("Total Residue",                 value: massTotalLoss,             unit: "g")
            calcRow("Lost \(viewModel.selectedActive.rawValue) in Residue", value: activeLoss, unit: viewModel.units.rawValue)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Preservatives
            subsectionHeader("Preservatives")
            calcRow("Potassium Sorbate Mass Fraction",  value: massFractionPotassiumSorbate,  unit: "%", decimals: 4)
            calcRow("Citric Acid Mass Fraction",        value: massFractionCitricAcid,        unit: "%", decimals: 4)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Mixture Densities
            subsectionHeader("Mixture Densities")
            calcRow("Sugar Mix Density",      value: viewModel.calcSugarMixDensity,    unit: "g/mL", decimals: 4)
            calcRow("Gelatin Mix Density",    value: viewModel.calcGelatinMixDensity,  unit: "g/mL", decimals: 4)
            calcRow("Activation Mix Density", value: viewModel.calcActiveMixDensity,   unit: "g/mL", decimals: 4)
            calcRow("Gummy Mixture Density",  value: densityFinalMix,                  unit: "g/mL", decimals: 4)

            if let density = densityFinalMix, density > 0 {
                updateSettingButton(
                    title: "Update final gummy mixture est. density",
                    alreadyApplied: abs(systemConfig.estimatedFinalMixDensity - density) < CMTheme.densityComparisonTolerance,
                    action: { systemConfig.estimatedFinalMixDensity = density },
                    toastBinding: $showDensityUpdatedAlert
                )
            }

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Gummies
            subsectionHeader("Gummies")
            calcRow("Average Gummy Mass",            value: massPerGummyMold,        unit: "g")
            calcRow("Average Gummy Volume",          value: averageGummyVolume,      unit: "mL", decimals: 4)
            calcRow("Average Gummy Active Dose",     value: averageGummyActiveDose,  unit: viewModel.units.rawValue)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Overage
            subsectionHeader("Overage")
            calcRow("Overage for Next Batch",       value: overageForNextBatch,     unit: "", decimals: 4)

            if let overage = overageForNextBatch, overage > 0 {
                updateSettingButton(
                    title: "Update overage factor in system settings",
                    alreadyApplied: abs(viewModel.overageFactor - overage) < CMTheme.densityComparisonTolerance,
                    action: { viewModel.overageFactor = overage },
                    toastBinding: $showOverageUpdatedAlert
                )
            }

            Spacer(minLength: 12)
        }
        .overlay(alignment: .top) {
            if showDensityUpdatedAlert {
                toastView(
                    icon: "checkmark.seal.fill",
                    title: "ρ estimate updated!",
                    subtitle: "Smoke crack erry day mon'"
                )
            }
            if showOverageUpdatedAlert {
                toastView(
                    icon: "checkmark.seal.fill",
                    title: "Overage factor updated!",
                    subtitle: "Smoke crack erry day mon'"
                )
            }
        }
    }

    private func toastView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(systemConfig.accent)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(subtitle)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(CMTheme.cardBG)
                .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
        )
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Update Setting Button

    private func updateSettingButton(
        title: String,
        alreadyApplied: Bool,
        action: @escaping () -> Void,
        toastBinding: Binding<Bool>
    ) -> some View {
        Button {
            CMHaptic.light()
            withAnimation(.cmSpring) { action() }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                toastBinding.wrappedValue = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + CMTheme.toastDismissDelay) {
                withAnimation(.easeOut(duration: 0.25)) { toastBinding.wrappedValue = false }
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(alreadyApplied ? CMTheme.textTertiary : CMTheme.strawberryRed)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.top, 4)
    }

    // MARK: - Helpers

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func calcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Group {
                if let measured = value {
                    Text(String(format: "%.\(decimals)f", measured))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("—")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            Text(unit)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 5)
    }

}
