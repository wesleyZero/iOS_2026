//
//  ExperimentalDataView.swift
//  CandyMan
//
//  Live "Quantitative Data (Experimental)" card for the main page.
//  Mirrors the structure of BatchValidationView (theoretical) but uses
//  measured masses and experimentally-derived volumes (mass / measured density).
//

import SwiftUI

// MARK: - ExperimentalDataView

struct ExperimentalDataView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isExpanded = false

    private var isRegular: Bool { sizeClass == .regular }

    // MARK: - Experimental Masses (from scale readings)

    private var expGelatinMass: Double? { viewModel.calcMassGelatinAdded }
    private var expSugarMass: Double? { viewModel.calcMassSugarAdded }
    private var expActivationMass: Double? { viewModel.calcMassActiveAdded }
    private var expFinalMixMass: Double? { viewModel.calcMassFinalMixtureInBeaker }

    // MARK: - Experimental Volumes (mass / measured density)

    private var expGelatinVolume: Double? {
        guard let mass = expGelatinMass, let density = viewModel.calcGelatinMixDensity, density > 0 else { return nil }
        return mass / density
    }

    private var expSugarVolume: Double? {
        guard let mass = expSugarMass, let density = viewModel.calcSugarMixDensity, density > 0 else { return nil }
        return mass / density
    }

    private var expActivationVolume: Double? {
        guard let mass = expActivationMass, let density = viewModel.calcActiveMixDensity, density > 0 else { return nil }
        return mass / density
    }

    // MARK: - Experimental Totals

    private var expFinalMixVolume: Double? {
        guard let gv = expGelatinVolume, let sv = expSugarVolume, let av = expActivationVolume else { return nil }
        return gv + sv + av
    }

    private var expFinalMixMassNoOverage: Double? {
        guard let mass = expFinalMixMass, viewModel.overageFactor > 0 else { return nil }
        return mass / viewModel.overageFactor
    }

    private var expFinalMixVolNoOverage: Double? {
        guard let vol = expFinalMixVolume, viewModel.overageFactor > 0 else { return nil }
        return vol / viewModel.overageFactor
    }

    private var expVolPerMold: Double? {
        guard let vol = expFinalMixVolNoOverage else { return nil }
        let totalGummies = viewModel.totalGummies(using: systemConfig)
        guard totalGummies > 0 else { return nil }
        return vol / Double(totalGummies)
    }

    private var expVolPerTray: Double? {
        guard let vol = expFinalMixVolNoOverage, viewModel.trayCount > 0 else { return nil }
        return vol / Double(viewModel.trayCount)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Button {
                guard viewModel.batchActivated else { return }
                CMHaptic.light()
                withAnimation(.cmExpand) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Quantitative Data (Experimental)").cmSectionTitle(accent: systemConfig.designTitle)
                    Spacer()
                    if !viewModel.batchActivated {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(systemConfig.designAlert)
                            Text("Please activate batch")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(systemConfig.designAlert)
                        }
                    } else {
                        CMDisclosureChevron(isExpanded: isExpanded)
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded && viewModel.batchActivated {
                ThemedDivider()

                // MARK: Target Volumes (Experimental)
                expSubheader("Target Volumes (Experimental)")
                expVolOnlyRow("Volume Per Mold", volume: expVolPerMold)
                expVolOnlyRow("Volume Per Tray", volume: expVolPerTray)
                expVolOnlyRow("Total Volume", volume: expFinalMixVolNoOverage, bold: true, valueColor: systemConfig.designSecondaryAccent)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Input Mixtures
                expSubheader("Input Mixtures")
                expCompRow("Gelatin Mix",    mass: expGelatinMass,    volume: expGelatinVolume)
                expCompRow("Sugar Mix",      mass: expSugarMass,      volume: expSugarVolume)
                expCompRow("Activation Mix", mass: expActivationMass, volume: expActivationVolume)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Final Mixture
                expSubheader("Final Mixture")
                expCompRow("Final Mix (+\(String(format: "%.1f", (viewModel.overageFactor - 1) * 100))%)",
                           mass: expFinalMixMass,
                           volume: expFinalMixVolume)
                expCompRow("Final Mix (without overage)",
                           mass: expFinalMixMassNoOverage,
                           volume: expFinalMixVolNoOverage,
                           bold: true)
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Mixture Densities
                expDensitySubheader("Mixture Densities")
                expDensityRow("Gelatin Mix",    density: viewModel.calcGelatinMixDensity)
                expDensityRow("Sugar Mix",      density: viewModel.calcSugarMixDensity)
                expDensityRow("Activation Mix", density: viewModel.calcActiveMixDensity)
                expDensityRow("Gummy Mixture",  density: viewModel.calcDensityFinalMix(systemConfig: systemConfig))

                if !hasAnyData {
                    Text("Record weight measurements and mixture densities to populate experimental data.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.top, 8)
                }

                Spacer().frame(height: 12)
            } // end if isExpanded
        }
        .onChange(of: viewModel.batchActivated) { _, activated in
            if !activated { withAnimation(.cmSpring) { isExpanded = false } }
        }
    }

    private var hasAnyData: Bool {
        expGelatinMass != nil || expSugarMass != nil || expActivationMass != nil
    }

    // MARK: - Sub-views

    private func expSubheader(_ title: String) -> some View {
        CMTwoColumnSubheader(title: title, col1: "mass (g)", col2: "vol (mL)")
    }

    private func expDensitySubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .cmSubsectionPadding()
    }

    private func expCompRow(_ label: String, mass: Double?, volume: Double?, bold: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text(mass.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: mass == nil ? CMTheme.textTertiary : (bold ? CMTheme.textPrimary : CMTheme.textSecondary))
                .fontWeight(bold ? .bold : .regular)
            Text(volume.map { String(format: "%.3f", $0) } ?? "—")
                .cmValueSlot(color: volume == nil ? CMTheme.textTertiary : (bold ? CMTheme.textPrimary : CMTheme.textSecondary))
                .fontWeight(bold ? .bold : .regular)
        }
        .cmDataRowPadding()
    }

    private func expVolOnlyRow(_ label: String, volume: Double?, bold: Bool = false, valueColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            Text("—")
                .cmMono12().foregroundStyle(CMTheme.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text(volume.map { String(format: "%.3f", $0) } ?? "—")
                .cmMono12()
                .foregroundStyle(volume == nil ? CMTheme.textTertiary : (valueColor ?? CMTheme.textSecondary))
                .fontWeight(bold ? .bold : .regular)
                .frame(width: 70, alignment: .trailing)
        }
        .cmDataRowPadding()
    }

    private func expDensityRow(_ label: String, density: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            Text(density.map { String(format: "%.4f", $0) } ?? "—")
                .cmMono12()
                .foregroundStyle(density == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text("g/mL")
                .cmUnitSlot()
        }
        .cmDataRowPadding()
    }
}
