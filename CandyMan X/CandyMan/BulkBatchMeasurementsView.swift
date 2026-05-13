//
//  BulkBatchMeasurementsView.swift
//  CandyMan
//
//  Collapsible card for recording the bulk mix weights: Bulk Gelatin Mixture
//  and Bulk Sugar Mixture. Shares the measurementsLocked state with
//  WeightMeasurementsView via the shared BatchConfigViewModel.
//

import SwiftUI

struct BulkBatchMeasurementsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    @State private var isExpanded: Bool = true
    @State private var showCorrectionsSection: BatchConfigViewModel.CorrectionSection? = nil
    @State private var containerPickerRow: ContainerPickerRow? = nil
    @State private var scalePickerRow: ScalePickerRow? = nil
    @State private var stirBarPickerRow: StirBarPickerRow? = nil

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
                    Text("Bulk Measurements").font(.headline).foregroundStyle(systemConfig.designTitle)
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
                    let batchResult = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
                    let sugarOverage   = 1.0 + systemConfig.sugarMixtureOveragePercent / 100.0
                    let gelatinOverage = 1.0 + systemConfig.gelatinMixtureOveragePercent / 100.0

                    let perTrayResult: MultiActiveBatchResult.PerTrayResult? = {
                        guard viewModel.multiActiveEnabled else { return nil }
                        let multiResult = BatchCalculator.calculateMultiActive(viewModel: viewModel, systemConfig: systemConfig)
                        let idx = min(viewModel.selectedTrayIndex, multiResult.perTrayResults.count - 1)
                        guard idx >= 0 else { return nil }
                        return multiResult.perTrayResults[idx]
                    }()
                    let sugarMix = perTrayResult?.sugarMix ?? batchResult.sugarMix

                    let gelatinMass = batchResult.gelatinMix.totalMassGrams * gelatinOverage
                    let gelatinVol  = batchResult.gelatinMix.totalVolumeML * gelatinOverage
                    let sugarMass   = sugarMix.totalMassGrams * sugarOverage
                    let sugarVol    = sugarMix.totalVolumeML * sugarOverage

                    let substrateVol  = gelatinVol + sugarVol

                    let substrateContainerID = viewModel.hpSubstrateBeakerID
                        ?? systemConfig.recommendedBeaker(forVolumeML: substrateVol)?.id
                    let sugarContainerID = viewModel.hpSugarMixBeakerID
                        ?? systemConfig.recommendedBeaker(forVolumeML: sugarVol)?.id

                    let substrateBeakerTare = substrateContainerID.map { systemConfig.containerTare(for: $0) } ?? 0
                    let sugarBeakerTare = sugarContainerID.map { systemConfig.containerTare(for: $0) } ?? 0

                    let substrateStirBarID = viewModel.hpSubstrateStirBarID ?? systemConfig.stirBars.first?.id
                    let sugarStirBarID = viewModel.hpSugarMixStirBarID ?? systemConfig.stirBars.first?.id
                    let substrateStirBarMass = substrateStirBarID.map { systemConfig.stirBarMass(for: $0) } ?? 0
                    let sugarStirBarMass = sugarStirBarID.map { systemConfig.stirBarMass(for: $0) } ?? 0

                    let substrateMassOnScale = gelatinMass + sugarMass + substrateBeakerTare + substrateStirBarMass
                    let substrateTare = substrateBeakerTare + substrateStirBarMass
                    let sugarTare = sugarBeakerTare + sugarStirBarMass
                    let sugarMassOnScale = sugarMass + sugarTare

                    // MARK: Bulk Gelatin Mixture
                    HStack {
                        Text("Bulk Gelatin Mixture").cmSubsectionTitle()
                        CMCorrectionsButton(accentColor: systemConfig.designPrimaryAccent) {
                            showCorrectionsSection = .gelatin
                        }
                        Spacer()
                    }
                    .cmSubsectionPadding()

                    hpSectionBox {
                        hpContainerSelector(
                            label: "Substrate Beaker",
                            selectedID: Binding(
                                get: { substrateContainerID },
                                set: { viewModel.hpSubstrateBeakerID = $0 }
                            )
                        )
                        hpStirBarSelector(
                            label: "Substrate Stir Bar",
                            selectedID: Binding(
                                get: { substrateStirBarID },
                                set: { viewModel.hpSubstrateStirBarID = $0 }
                            )
                        )
                        hpScaleSelector(
                            label: "Substrate Scale",
                            selectedID: $viewModel.hpSubstrateScaleID,
                            theoreticalMassOnScale: substrateMassOnScale
                        )
                        let substrateRes = viewModel.hpScaleResolution(for: viewModel.hpSubstrateScaleID, systemConfig: systemConfig)
                        let mGelatinWater = batchResult.gelatinMix.components[1].massGrams * gelatinOverage
                        let mGelatinPowder = batchResult.gelatinMix.components[0].massGrams * gelatinOverage
                        let expectedWater = substrateTare + mGelatinWater
                        let expectedGelatin: Double? = viewModel.hpGelatinWater.map { $0 + mGelatinPowder }

                        subWeightRow("Beaker", value: $viewModel.hpSubstrateBeakerReading, resolution: substrateRes,
                                     expected: viewModel.hpSubstrateBeakerReading == nil ? substrateBeakerTare : nil,
                                     individualMass: substrateBeakerTare)
                        subWeightRow("+ Stir Bar", value: $viewModel.hpSubstrateStirBarReading, resolution: substrateRes,
                                     expected: viewModel.hpSubstrateBeakerReading != nil && viewModel.hpSubstrateStirBarReading == nil ? substrateTare : nil,
                                     individualMass: substrateStirBarMass)
                        subWeightRow("+ Water", value: $viewModel.hpGelatinWater, resolution: substrateRes,
                                     expected: viewModel.hpSubstrateStirBarReading != nil && viewModel.hpGelatinWater == nil ? expectedWater : nil,
                                     individualMass: mGelatinWater)
                        subWeightRow("+ Gelatin", value: $viewModel.hpGelatin, resolution: substrateRes,
                                     expected: viewModel.hpGelatinWater != nil && viewModel.hpGelatin == nil ? expectedGelatin : nil,
                                     individualMass: mGelatinPowder)
                        if let corrTotal = viewModel.correctionsTotal {
                            hpTotalRow("Corrections", value: corrTotal)
                        }
                        let gelatinNet: Double? = {
                            guard let gelatin = viewModel.hpGelatin, let stirBar = viewModel.hpSubstrateStirBarReading else { return nil }
                            return (gelatin - stirBar) + (viewModel.correctionsTotal ?? 0)
                        }()
                        hpTotalRow("Net Total | Bulk Gelatin Mixture", value: gelatinNet)
                    }

                    // MARK: Bulk Sugar Mixture
                    HStack {
                        Text("Bulk Sugar Mixture").cmSubsectionTitle()
                        CMCorrectionsButton(accentColor: systemConfig.designPrimaryAccent) {
                            showCorrectionsSection = .sugar
                        }
                        Spacer()
                    }
                    .cmSubsectionPadding()

                    hpSectionBox {
                        hpContainerSelector(
                            label: "Sugar Mix Beaker",
                            selectedID: Binding(
                                get: { sugarContainerID },
                                set: { viewModel.hpSugarMixBeakerID = $0 }
                            )
                        )
                        hpStirBarSelector(
                            label: "Sugar Mix Stir Bar",
                            selectedID: Binding(
                                get: { sugarStirBarID },
                                set: { viewModel.hpSugarMixStirBarID = $0 }
                            )
                        )
                        hpScaleSelector(
                            label: "Sugar Mix Scale",
                            selectedID: $viewModel.hpSugarMixScaleID,
                            theoreticalMassOnScale: sugarMassOnScale
                        )
                        let sugarRes = viewModel.hpScaleResolution(for: viewModel.hpSugarMixScaleID, systemConfig: systemConfig)
                        let mSugarWater = sugarMix.components[2].massGrams * sugarOverage
                        let mGlucoseSyrup = sugarMix.components[0].massGrams * sugarOverage
                        let mGranulated = sugarMix.components[1].massGrams * sugarOverage
                        let expectedSugarWater = sugarTare + mSugarWater
                        let expectedGlucose: Double? = viewModel.hpSugarWater.map { $0 + mGlucoseSyrup }
                        let expectedGranulated: Double? = viewModel.hpGlucoseSyrup.map { $0 + mGranulated }

                        subWeightRow("Beaker", value: $viewModel.hpSugarBeakerReading, resolution: sugarRes,
                                     expected: viewModel.hpSugarBeakerReading == nil ? sugarBeakerTare : nil,
                                     individualMass: sugarBeakerTare)
                        subWeightRow("+ Stir Bar", value: $viewModel.hpSugarStirBarReading, resolution: sugarRes,
                                     expected: viewModel.hpSugarBeakerReading != nil && viewModel.hpSugarStirBarReading == nil ? sugarTare : nil,
                                     individualMass: sugarStirBarMass)
                        subWeightRow("+ Water", value: $viewModel.hpSugarWater, resolution: sugarRes,
                                     expected: viewModel.hpSugarStirBarReading != nil && viewModel.hpSugarWater == nil ? expectedSugarWater : nil,
                                     individualMass: mSugarWater)
                        subWeightRow("+ Glucose Syrup", value: $viewModel.hpGlucoseSyrup, resolution: sugarRes,
                                     expected: viewModel.hpSugarWater != nil && viewModel.hpGlucoseSyrup == nil ? expectedGlucose : nil,
                                     individualMass: mGlucoseSyrup)
                        subWeightRow("+ Granulated Sugar", value: $viewModel.hpGranulated, resolution: sugarRes,
                                     expected: viewModel.hpGlucoseSyrup != nil && viewModel.hpGranulated == nil ? expectedGranulated : nil,
                                     individualMass: mGranulated)
                        if let sugarCorrTotal = viewModel.sugarCorrectionsTotal {
                            hpTotalRow("Corrections", value: sugarCorrTotal)
                        }
                        let sugarNet: Double? = {
                            guard let granulated = viewModel.hpGranulated, let stirBar = viewModel.hpSugarStirBarReading else { return nil }
                            return (granulated - stirBar) + (viewModel.sugarCorrectionsTotal ?? 0)
                        }()
                        hpTotalRow("Net Total | Bulk Sugar Mixture", value: sugarNet)
                    }
                }
                .disabled(viewModel.measurementsLocked)
                .opacity(viewModel.measurementsLocked ? 0.5 : 1.0)
                .cmExpandTransition()
            }
        }
        .overlay {
            if let section = showCorrectionsSection {
                CorrectionsView(section: section) {
                    withAnimation(.cmSpring) { showCorrectionsSection = nil }
                }
            }
        }
        .sheet(item: $containerPickerRow) { row in
            ContainerPickerSheet(row: row)
                .environment(systemConfig)
        }
        .sheet(item: $stirBarPickerRow) { row in
            StirBarPickerSheet(row: row)
                .environment(systemConfig)
        }
        .sheet(item: $scalePickerRow) { row in
            ScalePickerSheet(row: row)
                .environment(systemConfig)
        }
    }

    // MARK: - Helpers

    private func subWeightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution, expected: Double? = nil, individualMass: Double? = nil) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label).cmHpLabel(color: measurementColor)
            Spacer()
            if let mass = individualMass, expected != nil {
                Text(String(format: "%.\(decimals)f", mass))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }
            if let expected {
                Text(String(format: "%.\(decimals)f", expected))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(systemConfig.designSecondaryAccent.opacity(0.7))
            }
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
            CMEquipmentCapsule(icon: "flask.fill", displayName: displayName, color: measurementColor)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

    private func hpStirBarSelector(label: String, selectedID: Binding<String?>) -> some View {
        let displayName = selectedID.wrappedValue
            .flatMap { id in systemConfig.stirBars.first { $0.id == id }?.name }
            ?? "Select..."
        return Button {
            CMHaptic.light()
            stirBarPickerRow = StirBarPickerRow(
                label: label,
                currentID: selectedID.wrappedValue,
                onSelect: { newID in selectedID.wrappedValue = newID }
            )
        } label: {
            CMEquipmentCapsule(icon: "wand.and.rays", displayName: displayName, color: measurementColor)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

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
                CMEquipmentCapsule(icon: "scalemass.fill", displayName: displayName, color: measurementColor)
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
}
