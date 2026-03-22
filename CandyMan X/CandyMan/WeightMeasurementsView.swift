//
//  WeightMeasurementsView.swift
//  CandyMan
//
//  Post-calculation batch measurement entry card. Collapsible section where the
//  user records actual masses for each mix group (gelatin, sugar, activation),
//  the final mixture in the beaker, syringe residue, beaker residue, and the
//  mix transferred into the mold. Also hosts popups for Additional Measurements
//  and Corrections via overlay sheets.
//
//  Contents:
//    WeightMeasurementsView    — main collapsible card with lockable numeric fields
//    measurementRow            — reusable labeled numeric-field row
//    quickActionBar            — Additional Measurements / Corrections buttons
//

import SwiftUI
import SwiftData

struct WeightMeasurementsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded: Bool = true
    @State private var showAdditionalMeasurements = false
    @State private var showCorrections = false
    @State private var containerPickerRow: ContainerPickerRow? = nil
    @State private var scalePickerRow: ScalePickerRow? = nil
    @State private var showContainerInfo: String? = nil

    /// Design-language measurement color (replaces hardcoded hpCyan).
    private var measurementColor: Color { systemConfig.designMeasurement }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            // Title header — tappable to collapse/expand
            HStack {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    Text("Batch Measurements").font(.headline).foregroundStyle(systemConfig.designTitle)
                }
                .buttonStyle(.plain)

                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { viewModel.measurementsLocked.toggle() }
                } label: {
                    Image(systemName: viewModel.measurementsLocked ? "lock.fill" : "lock.open.fill")
                        .cmLockIcon(isLocked: viewModel.measurementsLocked, color: systemConfig.designAlert)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { isExpanded.toggle() }
                } label: {
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, isExpanded ? 2 : 12)

            if isExpanded {
            ThemedDivider()

            VStack(spacing: 0) {
                // MARK: Gelatin Mixture
                subsectionHeader("Gelatin Mixture")

                    // Compute theoretical masses on each scale (mix + container tare)
                    let batchResult = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
                    let sugarOverage = 1.0 + systemConfig.sugarMixtureOveragePercent / 100.0

                    let gelatinMass = batchResult.gelatinMix.totalMassGrams
                    let gelatinVol  = batchResult.gelatinMix.totalVolumeML
                    let sugarMass   = batchResult.sugarMix.totalMassGrams * sugarOverage
                    let sugarVol    = batchResult.sugarMix.totalVolumeML * sugarOverage
                    let activMass   = batchResult.activationMix.totalMassGrams
                    let activVol    = batchResult.activationMix.totalVolumeML

                    let substrateMass = gelatinMass + sugarMass
                    let substrateVol  = gelatinVol + sugarVol

                    let substrateTare = viewModel.hpSubstrateBeakerID
                        .map { systemConfig.containerTare(for: $0) } ?? systemConfig.recommendedBeaker(forVolumeML: substrateVol)
                        .map { systemConfig.containerTare(for: $0.id) } ?? 0
                    let sugarTare = viewModel.hpSugarMixBeakerID
                        .map { systemConfig.containerTare(for: $0) } ?? systemConfig.recommendedBeaker(forVolumeML: sugarVol)
                        .map { systemConfig.containerTare(for: $0.id) } ?? 0
                    let activTare = viewModel.hpActivationTrayID
                        .map { systemConfig.containerTare(for: $0) } ?? systemConfig.recommendedBeaker(forVolumeML: activVol)
                        .map { systemConfig.containerTare(for: $0.id) } ?? 0

                    let substrateMassOnScale = substrateMass + substrateTare
                    let sugarMassOnScale     = sugarMass + sugarTare
                    let activMassOnScale     = activMass + activTare

                    // ===== GELATIN / SUBSTRATE SECTION =====
                    hpSectionBox {
                        hpContainerSelector(
                            label: "Substrate Beaker",
                            selectedID: $viewModel.hpSubstrateBeakerID
                        )
                        hpScaleSelector(
                            label: "Substrate Scale",
                            selectedID: $viewModel.hpSubstrateScaleID,
                            theoreticalMassOnScale: substrateMassOnScale
                        )
                        hpContainerTareRow(
                            "Beaker (Clean)",
                            containerID: viewModel.hpSubstrateBeakerID
                        )
                        subWeightRow("+ Gelatin", value: $viewModel.hpGelatin, resolution: viewModel.hpScaleResolution(for: viewModel.hpSubstrateScaleID, systemConfig: systemConfig))
                        subWeightRow("+ Water", value: $viewModel.hpGelatinWater, resolution: viewModel.hpScaleResolution(for: viewModel.hpSubstrateScaleID, systemConfig: systemConfig))
                        hpTotalRow("Total | Gelatin Mixture", value: viewModel.hpGelatinMixtureTotal(systemConfig: systemConfig))
                    }

                    // ===== SUGAR MIX SECTION =====
                    subsectionHeader("Sugar Mixture")
                    hpSectionBox {
                        hpContainerSelector(
                            label: "Sugar Mix Beaker",
                            selectedID: $viewModel.hpSugarMixBeakerID
                        )
                        hpScaleSelector(
                            label: "Sugar Mix Scale",
                            selectedID: $viewModel.hpSugarMixScaleID,
                            theoreticalMassOnScale: sugarMassOnScale
                        )
                        hpContainerTareRow(
                            "Beaker (Clean)",
                            containerID: viewModel.hpSugarMixBeakerID
                        )
                        subWeightRow("+ Granulated Sugar", value: $viewModel.hpGranulated, resolution: viewModel.hpScaleResolution(for: viewModel.hpSugarMixScaleID, systemConfig: systemConfig))
                        subWeightRow("+ Glucose Syrup", value: $viewModel.hpGlucoseSyrup, resolution: viewModel.hpScaleResolution(for: viewModel.hpSugarMixScaleID, systemConfig: systemConfig))
                        subWeightRow("+ Water", value: $viewModel.hpSugarWater, resolution: viewModel.hpScaleResolution(for: viewModel.hpSugarMixScaleID, systemConfig: systemConfig))
                        hpTotalRow("Total | Sugar Mixture", value: viewModel.hpSugarMixtureTotal(systemConfig: systemConfig))
                    }

                    // ===== TRANSFER ROW =====
                    HStack(spacing: 6) {
                        Text("Total | Substrate + Sugar Transfer").cmHpLabel(color: systemConfig.designPrimaryAccent)
                        Spacer()
                        OptionalNumericField(value: $viewModel.hpSubstrateSugarTransfer, decimals: MeasurementResolution.thousandthGram.decimalPlaces)
                            .multilineTextAlignment(.trailing)
                            .cmHpValueSlot(color: systemConfig.designPrimaryAccent)
                        Text("g")
                            .cmMono11()
                            .foregroundStyle(CMTheme.textTertiary)
                            .frame(width: 28, alignment: .leading)
                    }
                    .cmHpSubRowPadding()
                    .cmExpandTransition()

                    // ===== ACTIVATION MIX SECTION =====
                    subsectionHeader("Activation Mixture")
                    hpSectionBox {
                        hpContainerSelector(
                            label: "Activation Tray",
                            selectedID: $viewModel.hpActivationTrayID
                        )
                        hpScaleSelector(
                            label: "Activation Scale",
                            selectedID: $viewModel.hpActivationScaleID,
                            theoreticalMassOnScale: activMassOnScale
                        )
                        hpContainerTareRow(
                            "Container (Clean)",
                            containerID: viewModel.hpActivationTrayID
                        )
                        subWeightRow("+ Citric Acid", value: $viewModel.hpCitricAcid, resolution: viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig))
                        subWeightRow("+ Activation Water", value: $viewModel.hpActivationWater, resolution: viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig))
                        subWeightRow("+ KSorbate", value: $viewModel.hpKSorbate, resolution: viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig))
                        subWeightRow("+ Flavor Oils + Terps + Active", value: $viewModel.hpFlavorOilsTerpsActive, resolution: viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig))
                        subWeightRow("- Activation Tray (Residue)", value: $viewModel.hpActivationTrayResidue, resolution: viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig))
                        hpTotalRow("Total | Activation Mixture", value: viewModel.hpActivationMixtureTotal(systemConfig: systemConfig))
                    }

                    // ===== SUBSTRATE + ACTIVATION TRANSFER =====
                    HStack(spacing: 6) {
                        Text("Total | Substrate + Activation Transfer").cmHpLabel(color: systemConfig.designPrimaryAccent)
                        Spacer()
                        OptionalNumericField(value: $viewModel.hpSubstrateActivationTransfer, decimals: MeasurementResolution.thousandthGram.decimalPlaces)
                            .multilineTextAlignment(.trailing)
                            .cmHpValueSlot(color: systemConfig.designPrimaryAccent)
                        Text("g")
                            .cmMono11()
                            .foregroundStyle(CMTheme.textTertiary)
                            .frame(width: 28, alignment: .leading)
                    }
                    .cmHpSubRowPadding()
                    .cmExpandTransition()

                    weightRow("Substrate Beaker (Residue)", value: $viewModel.weightBeakerResidue, resolution: systemConfig.resolutionBeakerResidue)

                // Corrections row
                correctionsRow

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Transfer Gummy Mixture to Trays
                subsectionHeader("Transfer Gummy Mixture to Trays")
                weightRow("Syringe (Clean)",            value: $viewModel.weightSyringeEmpty,     resolution: systemConfig.resolutionSyringeEmpty)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                weightRow("Syringe + Gummy Mix",        value: $viewModel.weightSyringeWithMix,   resolution: systemConfig.resolutionSyringeWithMix)
                volumeRow("Syringe + Gummy Mix",        value: $viewModel.volumeSyringeGummyMix)
                ThemedDivider(indent: 20).padding(.vertical, 4)
                weightRow("Syringe + Residue",          value: $viewModel.weightSyringeResidue,   resolution: systemConfig.resolutionSyringeResidue)
                weightRow("Beaker + Residue",           value: $viewModel.weightBeakerResidue,    resolution: systemConfig.resolutionBeakerResidue)

                ThemedDivider(indent: 20).padding(.vertical, 4)

                weightRow("Tray (Clean)",               value: $viewModel.weightTrayClean,        resolution: .thousandthGram)
                weightRow("Tray + Residue",             value: $viewModel.weightTrayPlusResidue,  resolution: .thousandthGram)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Molds
                subsectionHeader("Molds")
                intRow("Molds Filled",                  value: $viewModel.weightMoldsFilled)
                weightRow("Extra Gummy Mix",            value: $viewModel.extraGummyMixGrams,        resolution: .thousandthGram)

                // Fine print at bottom
                Text("The Substrate is defined as the primary beaker + all ingredients that have been added to the mixture.")
                    .cmFootnote()
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
            .disabled(viewModel.measurementsLocked)
            .opacity(viewModel.measurementsLocked ? 0.5 : 1.0)
            .cmExpandTransition()
            }
        }
        .overlay {
            if showAdditionalMeasurements {
                AdditionalMeasurementsPopup {
                    withAnimation(.cmSpring) { showAdditionalMeasurements = false }
                }
            }
        }
        .overlay {
            if showCorrections {
                CorrectionsView {
                    withAnimation(.cmSpring) { showCorrections = false }
                }
            }
        }
        .sheet(item: $containerPickerRow) { row in
            ContainerPickerSheet(row: row)
                .environment(systemConfig)
        }
        .sheet(item: $scalePickerRow) { row in
            ScalePickerSheet(row: row)
                .environment(systemConfig)
        }
        .overlay {
            if let containerID = showContainerInfo {
                ContainerInfoPopup(containerID: containerID) {
                    withAnimation(.cmSpring) { showContainerInfo = nil }
                }
            }
        }
    }

    private var fuchsia: Color { systemConfig.designPrimaryAccent }

    private var correctionsRow: some View {
        HStack(spacing: 6) {
            Text("Corrections")
                .cmRowLabel()

            // Plus/minus button to open corrections page
            Button {
                CMHaptic.light()
                showCorrections = true
            } label: {
                Image(systemName: "plus.forwardslash.minus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(fuchsia)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(fuchsia.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // Display total if available
            Group {
                if let total = viewModel.correctionsTotal {
                    Text(String(format: "%.3f", total))
                        .foregroundStyle(fuchsia)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmValueSlot(width: 80)

            Text("g")
                .cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .cmSubsectionPadding()
    }

    private func weightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            OptionalNumericField(value: value, decimals: decimals)
                .multilineTextAlignment(.trailing)
                .cmValueSlot(width: 80)
            Text("g").cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    /// Indented sub-row for high-precision mode fields.
    private func subWeightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label).cmHpLabel(color: measurementColor)
            Spacer()
            OptionalNumericField(value: value, decimals: decimals)
                .multilineTextAlignment(.trailing)
                .cmHpValueSlot(color: measurementColor)
            Text("g")
                .cmMono11()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmHpSubRowPadding()
        .cmExpandTransition()
    }

    private func volumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            OptionalNumericField(value: value, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValueSlot(width: 80)
            Text("mL").cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    /// Integer row — binds a Double? and formats with 0 decimal places
    private func intRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            OptionalNumericField(value: value, decimals: 0)
                .multilineTextAlignment(.trailing)
                .cmValueSlot(width: 80)
            Text("#").cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    // MARK: - HP Container Helpers

    /// Container selector row: tappable capsule that opens the wheel picker sheet.
    private func hpContainerSelector(label: String, selectedID: Binding<String?>) -> some View {
        let displayName = selectedID.wrappedValue
            .flatMap { id in systemConfig.containers.first { $0.id == id }?.name }
            ?? "Select..."

        return Button {
            CMHaptic.light()
            containerPickerRow = ContainerPickerRow(
                label: label,
                currentID: selectedID.wrappedValue,
                onSelect: { newID in selectedID.wrappedValue = newID }
            )
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(measurementColor.opacity(0.6))
                Text(displayName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(measurementColor)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(measurementColor.opacity(0.5))
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(measurementColor.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(measurementColor.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

    /// Scale selector row: tappable capsule that opens the wheel picker sheet.
    /// - Parameter theoreticalMassOnScale: The expected total mass (mix + container tare) in grams.
    ///   If the selected scale's max capacity is less than this value, a warning is shown.
    private func hpScaleSelector(label: String, selectedID: Binding<String?>, theoreticalMassOnScale: Double? = nil) -> some View {
        let selectedScale = selectedID.wrappedValue
            .flatMap { id in systemConfig.scales.first { $0.id == id } }
        let displayName = selectedScale
            .map { "\($0.name)  (\($0.resolutionLabel))" }
            ?? "Select..."

        let exceedsCapacity: Bool = {
            guard let scale = selectedScale, let mass = theoreticalMassOnScale else { return false }
            return mass > scale.maxCapacity
        }()

        return VStack(alignment: .leading, spacing: 2) {
            Button {
                CMHaptic.light()
                scalePickerRow = ScalePickerRow(
                    label: label,
                    currentID: selectedID.wrappedValue,
                    onSelect: { newID in selectedID.wrappedValue = newID }
                )
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(measurementColor.opacity(0.6))
                    Text(displayName)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(measurementColor)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(measurementColor.opacity(0.5))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(measurementColor.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(measurementColor.opacity(0.15), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)

            if exceedsCapacity, let scale = selectedScale, let mass = theoreticalMassOnScale {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text("Theoretical mass (\(String(format: "%.1f", mass)) g) exceeds \(scale.name) capacity (\(scale.capacityLabel))")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(systemConfig.designAlert)
                .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

    /// Auto-populated tare row with (i) info button.
    private func hpContainerTareRow(_ label: String, containerID: String?) -> some View {
        let tare: Double? = containerID.map { systemConfig.containerTare(for: $0) }

        return HStack(spacing: 6) {
            Text(label).cmHpLabel(color: measurementColor)

            // Info button
            if let id = containerID {
                Button {
                    CMHaptic.light()
                    showContainerInfo = id
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(measurementColor.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Group {
                if let t = tare {
                    Text(String(format: "%.3f", t))
                } else {
                    Text("—")
                }
            }
            .cmHpValueSlot(color: measurementColor)

            Text("g")
                .cmMono11()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmHpSubRowPadding()
        .cmExpandTransition()
    }

    /// Highlighted total row with computed value.
    private func hpTotalRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).cmTotalLabel()
            Spacer()
            Group {
                if let v = value {
                    Text(String(format: "%.3f", v))
                } else {
                    Text("—")
                }
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(measurementColor)
            .frame(width: 80, alignment: .trailing)

            Text("g")
                .cmMono11()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmHpSubRowPadding()
        .padding(.vertical, 2)
        .background(CMTheme.totalRowBG)
        .cmExpandTransition()
    }

    /// Rounded box around an HP mix section group.
    private func hpSectionBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(measurementColor.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(measurementColor.opacity(0.12), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    /// Thin divider between HP mix sections.
    private func hpSectionDivider() -> some View {
        ThemedDivider(indent: 36).padding(.vertical, 4)
    }
}

// MARK: - Calibration Measurements View

struct CalibrationMeasurementsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    @State private var isExpanded: Bool = false
    @State private var isLocked: Bool = false

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            // Header — tappable to collapse/expand
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Calibration Measurements")
                        .font(.headline)
                        .foregroundStyle(systemConfig.designTitle)
                    // Lock button
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { isLocked.toggle() }
                    } label: {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .cmLockIcon(isLocked: isLocked, color: systemConfig.designAlert)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    // Chevron
                    CMDisclosureChevron(isExpanded: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, isExpanded ? 2 : 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ThemedDivider()

                VStack(spacing: 0) {
                    // Sugar Mix Density
                    subsectionHeader("Sugar Mix")
                    weightRow("Syringe (Clean)",           value: $viewModel.densitySyringeCleanSugar,     resolution: .thousandthGram)
                    weightRow("Syringe + Sugar Mix",       value: $viewModel.densitySyringePlusSugarMass,  resolution: .thousandthGram)
                    volumeRow("Syringe + Sugar Mix",       value: $viewModel.densitySyringePlusSugarVol)

                    // Gelatin Mix Density
                    ThemedDivider(indent: 20).padding(.vertical, 8)
                    subsectionHeader("Gelatin Mix")
                    weightRow("Syringe (Clean)",           value: $viewModel.densitySyringeCleanGelatin,     resolution: .thousandthGram)
                    weightRow("Syringe + Gelatin Mix",     value: $viewModel.densitySyringePlusGelatinMass,  resolution: .thousandthGram)
                    volumeRow("Syringe + Gelatin Mix",     value: $viewModel.densitySyringePlusGelatinVol)

                    // Activation Mix Density
                    ThemedDivider(indent: 20).padding(.vertical, 8)
                    subsectionHeader("Activation Mix")
                    weightRow("Syringe (Clean)",           value: $viewModel.densitySyringeCleanActive,     resolution: .thousandthGram)
                    weightRow("Syringe + Activation Mix",  value: $viewModel.densitySyringePlusActiveMass,  resolution: .thousandthGram)
                    volumeRow("Syringe + Activation Mix",  value: $viewModel.densitySyringePlusActiveVol)
                }
                .padding(.bottom, 8)
                .disabled(isLocked)
                .opacity(isLocked ? 0.5 : 1.0)
                .cmExpandTransition()
            }
        }
    }

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
        }
        .cmSubsectionPadding()
    }

    private func weightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            OptionalNumericField(value: value, decimals: decimals)
                .multilineTextAlignment(.trailing)
                .cmValueSlot(width: 80)
            Text("g").cmUnitSlot()
        }
        .cmDataRowPadding()
    }

    private func volumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label).cmRowLabel()
            Spacer()
            OptionalNumericField(value: value, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmValueSlot(width: 80)
            Text("mL").cmUnitSlot()
        }
        .cmDataRowPadding()
    }
}

// MARK: - Save Batch Sheet

struct SaveBatchSheet: View {
    @Binding var saveName: String
    @Binding var saveBatchID: String
    let onSave: () -> Void
    var onSaveTemplate: ((String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(SystemConfig.self) private var systemConfig

    @State private var saveAsTemplate = false
    @State private var templateName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    // Batch ID field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Batch ID")
                            .cmSubsectionTitle()
                        TextField("AA", text: $saveBatchID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                                    .fill(CMTheme.fieldBG)
                            )
                    }

                    // Batch Name field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Batch Name")
                            .cmSubsectionTitle()
                        TextField("Optional name", text: $saveName)
                            .autocorrectionDisabled()
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                                    .fill(CMTheme.fieldBG)
                            )
                    }

                    // Save as Template toggle
                    if onSaveTemplate != nil {
                        VStack(spacing: 12) {
                            Toggle(isOn: $saveAsTemplate) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                    Text("Also Save as Template")
                                        .cmSubsectionTitle()
                                }
                                .foregroundStyle(CMTheme.textSecondary)
                            }
                            .tint(systemConfig.designTitle)

                            if saveAsTemplate {
                                TextField("Template name", text: $templateName)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundStyle(CMTheme.textPrimary)
                                    .padding(.horizontal, 12).padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                                            .fill(CMTheme.fieldBG)
                                    )
                                    .cmExpandTransition()
                            }
                        }
                        .animation(.cmSpring, value: saveAsTemplate)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 24)

                Spacer()

                // Save button
                Button {
                    onSave()
                    if saveAsTemplate, let onSaveTemplate {
                        let name = templateName.isEmpty ? (saveName.isEmpty ? "Untitled Template" : saveName) : templateName
                        onSaveTemplate(name)
                    }
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Save")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                            .fill(systemConfig.designTitle)
                    )
                }
                .buttonStyle(CMPressStyle())
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
            .background(CMTheme.pageBG)
            .navigationTitle("Save Batch")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(CMTheme.textSecondary)
                }
            }
        }
    }
}
