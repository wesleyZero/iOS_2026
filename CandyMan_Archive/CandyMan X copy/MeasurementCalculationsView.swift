import SwiftUI

struct MeasurementCalculationsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded: Bool = true
    @State private var showDensityUpdatedAlert = false
    @State private var showOverageUpdatedAlert = false

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

    private var massTotalLossWithSurplus: Double? {
        guard let base = massTotalLoss else { return nil }
        return base + (viewModel.extraGummyMix_g ?? 0.0)
    }

    private var massMixTransferredToMold: Double? {
        guard let finalMix = massFinalMixtureInBeaker,
              let totalLoss = massTotalLossWithSurplus else { return nil }
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

    /// Active loss = totalActive × (totalLoss / finalMixtureInBeaker)
    private var activeLoss: Double? {
        guard let totalLoss = massTotalLossWithSurplus,
              let finalMix  = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        let totalActive = viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
        return totalActive * (totalLoss / finalMix)
    }

    /// Average active dose per gummy = (totalActive - activeLoss) / moldsFilled
    private var averageGummyActiveDose: Double? {
        guard let loss  = activeLoss,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        let totalActive = viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
        return (totalActive - loss) / molds
    }

    /// Total mix volume (same formula as BatchCalculator)
    private var vMix: Double {
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        return Double(viewModel.totalGummies(using: systemConfig)) * spec.volume_ml * viewModel.overageFactor
    }

    /// Theoretical mass of potassium sorbate (volume % × vMix × density)
    private var massPotassiumSorbate: Double? {
        let v = (systemConfig.potassiumSorbatePercent / 100.0) * vMix
        return v * systemConfig.densityPotassiumSorbate
    }

    /// Theoretical mass of citric acid (volume % × vMix × density)
    private var massCitricAcid: Double? {
        let v = (systemConfig.citricAcidPercent / 100.0) * vMix
        return v * systemConfig.densityCitricAcid
    }

    /// Mass fraction of potassium sorbate in the final mixture (%)
    private var massFractionPotassiumSorbate: Double? {
        guard let mSorbate = massPotassiumSorbate,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (mSorbate / finalMix) * 100.0
    }

    /// Mass fraction of citric acid in the final mixture (%)
    private var massFractionCitricAcid: Double? {
        guard let mCitric = massCitricAcid,
              let finalMix = massFinalMixtureInBeaker,
              finalMix > 0 else { return nil }
        return (mCitric / finalMix) * 100.0
    }

    /// Overage for next batch = averageGummyVolume / volumePerWell
    private var overageForNextBatch: Double? {
        guard let avgVol = averageGummyVolume else { return nil }
        let spec = systemConfig.spec(for: viewModel.selectedShape)
        guard spec.volume_ml > 0 else { return nil }
        return avgVol / spec.volume_ml
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header — tappable to collapse/expand
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Calculations").font(.headline).foregroundStyle(systemConfig.accent)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                        .animation(.cmExpand, value: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            ThemedDivider()
            VStack(spacing: 0) {
            // MARK: Input Mixtures
            subsectionHeader("Input Mixtures")
            calcRow("Gelatin Mix Added",     value: massGelatinAdded,  unit: "g")
            calcRow("Sugar Mix Added",        value: massSugarAdded,    unit: "g")
            calcRow("Activation Mix Added",   value: massActiveAdded,   unit: "g")

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Final Mixture
            subsectionHeader("Final Mixture")
            calcRow("Final Mixture in Beaker",       value: massFinalMixtureInBeaker,  unit: "g")
            calcRow("Final Mixture in Tray/s",       value: massMixTransferredToMold,  unit: "g")

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Losses
            subsectionHeader("Losses")
            calcRow("Beaker Residue",                value: massBeakerResidue,              unit: "g")
            calcRow("Syringe Residue",               value: massSyringeResidue,             unit: "g")
            calcRow("Gummy Mixture Surplus",         value: viewModel.extraGummyMix_g,      unit: "g")
            calcRow("Total Residue",                 value: massTotalLossWithSurplus,       unit: "g")
            calcRow("Lost \(viewModel.selectedActive.rawValue) in Residue", value: activeLoss, unit: viewModel.units.rawValue)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Preservatives
            subsectionHeader("Preservatives")
            calcRow("Potassium Sorbate Mass Fraction",  value: massFractionPotassiumSorbate,  unit: "w/w%", decimals: 4)
            calcRow("Citric Acid Mass Fraction",        value: massFractionCitricAcid,        unit: "w/w%", decimals: 4)

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Mixture Densities
            subsectionHeader("Mixture Densities")
            calcRow("Sugar Mix Density",      value: viewModel.calcSugarMixDensity,    unit: "g/mL", decimals: 4)
            calcRow("Gelatin Mix Density",    value: viewModel.calcGelatinMixDensity,  unit: "g/mL", decimals: 4)
            calcRow("Activation Mix Density", value: viewModel.calcActiveMixDensity,   unit: "g/mL", decimals: 4)
            calcRow("Gummy Mixture Density",  value: densityFinalMix,                  unit: "g/mL", decimals: 4)

            if let density = densityFinalMix, density > 0 {
                let alreadyApplied = abs(systemConfig.estimatedFinalMixDensity - density) < 0.0001
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { systemConfig.estimatedFinalMixDensity = density }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showDensityUpdatedAlert = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeOut(duration: 0.25)) { showDensityUpdatedAlert = false }
                    }
                } label: {
                    Text("Update final gummy mixture est. density")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            alreadyApplied
                                ? CMTheme.textTertiary
                                : Color(red: 0.929, green: 0.278, blue: 0.290)
                        )
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 4)
            }

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Gummies
            subsectionHeader("Gummies")
            calcRow("Average Gummy Mass",            value: massPerGummyMold,        unit: "g")
            calcRow("Average Gummy Volume",          value: averageGummyVolume,      unit: "mL", decimals: 4)
            calcRow("Average Gummy Active Dose",     value: averageGummyActiveDose,  unit: viewModel.units.rawValue, valueColor: Color(red: 0.929, green: 0.278, blue: 0.290))

            ThemedDivider(indent: 20).padding(.vertical, 8)

            // MARK: Overage
            subsectionHeader("Overage")
            calcRow("Overage for Next Batch",       value: overageForNextBatch,     unit: "", decimals: 4, valueColor: Color(red: 0.929, green: 0.278, blue: 0.290))

            if let overage = overageForNextBatch, overage > 0 {
                let alreadyApplied = abs(viewModel.overageFactor - overage) < 0.0001
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { viewModel.overageFactor = overage }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showOverageUpdatedAlert = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeOut(duration: 0.25)) { showOverageUpdatedAlert = false }
                    }
                } label: {
                    Text("Update overage factor in system settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            alreadyApplied
                                ? CMTheme.textTertiary
                                : Color(red: 0.929, green: 0.278, blue: 0.290)
                        )
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 4)
            }

            Spacer(minLength: 12)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            } // if isExpanded
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

    // MARK: - Helpers

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func calcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3, valueColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Group {
                if let v = value {
                    Text(String(format: "%.\(decimals)f", v))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(valueColor ?? CMTheme.textSecondary)
                } else {
                    Text("—")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            Text(unit)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

}
