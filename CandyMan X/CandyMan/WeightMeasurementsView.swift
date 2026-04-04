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
    var isFullScreen: Bool = false

    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded: Bool = true
    @State private var showFullScreen = false
    @State private var showAdditionalMeasurements = false
    @State private var showCorrectionsSection: BatchConfigViewModel.CorrectionSection? = nil
    @State private var containerPickerRow: ContainerPickerRow? = nil
    @State private var scalePickerRow: ScalePickerRow? = nil
    @State private var syringePickerRow: SyringePickerRow? = nil
    @State private var trayPickerRow: TrayPickerRow? = nil
    @State private var stirBarPickerRow: StirBarPickerRow? = nil
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

                Button {
                    CMHaptic.medium()
                    if isFullScreen {
                        dismiss()
                    } else {
                        showFullScreen = true
                    }
                } label: {
                    Image(systemName: isFullScreen
                          ? "arrow.down.right.and.arrow.up.left"
                          : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CMTheme.textSecondary)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(CMTheme.chipBG)
                        )
                }
                .buttonStyle(CMPressStyle())

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

                    let substrateContainerID = viewModel.hpSubstrateBeakerID
                        ?? systemConfig.recommendedBeaker(forVolumeML: substrateVol)?.id
                    let sugarContainerID = viewModel.hpSugarMixBeakerID
                        ?? systemConfig.recommendedBeaker(forVolumeML: sugarVol)?.id
                    let activContainerID = viewModel.hpActivationTrayID
                        ?? systemConfig.recommendedBeaker(forVolumeML: activVol)?.id

                    let substrateBeakerTare = substrateContainerID.map { systemConfig.containerTare(for: $0) } ?? 0
                    let sugarBeakerTare = sugarContainerID.map { systemConfig.containerTare(for: $0) } ?? 0
                    let activBeakerTare = activContainerID.map { systemConfig.containerTare(for: $0) } ?? 0

                    // Stir bar masses for substrate, sugar, and activation sections
                    let substrateStirBarID = viewModel.hpSubstrateStirBarID ?? systemConfig.stirBars.first?.id
                    let sugarStirBarID = viewModel.hpSugarMixStirBarID ?? systemConfig.stirBars.first?.id
                    let activStirBarID = viewModel.hpActivationStirBarID ?? systemConfig.stirBars.first?.id
                    let substrateStirBarMass = substrateStirBarID.map { systemConfig.stirBarMass(for: $0) } ?? 0
                    let sugarStirBarMass = sugarStirBarID.map { systemConfig.stirBarMass(for: $0) } ?? 0
                    let activStirBarMass = activStirBarID.map { systemConfig.stirBarMass(for: $0) } ?? 0

                    // Combined tares (beaker + stir bar)
                    let substrateTare = substrateBeakerTare + substrateStirBarMass
                    let sugarTare = sugarBeakerTare + sugarStirBarMass
                    let activTare = activBeakerTare + activStirBarMass

                    let substrateMassOnScale = substrateMass + substrateTare
                    let sugarMassOnScale     = sugarMass + sugarTare
                    let activMassOnScale     = activMass + activTare

                // MARK: Activation Mixture
                    // ===== ACTIVATION MIX SECTION =====
                    HStack {
                        Text("Activation Mixture").cmSubsectionTitle()
                        CMCorrectionsButton(accentColor: systemConfig.designPrimaryAccent) {
                            showCorrectionsSection = .activation
                        }
                        Spacer()
                    }
                    .cmSubsectionPadding()
                    hpSectionBox {
                        hpContainerSelector(
                            label: "Activation Tray",
                            selectedID: Binding(
                                get: { activContainerID },
                                set: { viewModel.hpActivationTrayID = $0 }
                            )
                        )
                        hpStirBarSelector(
                            label: "Activation Stir Bar",
                            selectedID: Binding(
                                get: { activStirBarID },
                                set: { viewModel.hpActivationStirBarID = $0 }
                            )
                        )
                        hpScaleSelector(
                            label: "Activation Scale",
                            selectedID: $viewModel.hpActivationScaleID,
                            theoreticalMassOnScale: activMassOnScale
                        )
                        let activRes = viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig)
                        let activComps = batchResult.activationMix.components
                        let mCitric = activComps.first(where: { $0.label == "Citric Acid" })?.massGrams ?? 0
                        let mKSorbate = activComps.first(where: { $0.label == "Potassium Sorbate" })?.massGrams ?? 0
                        let mTotalActivWater = activComps.first(where: { $0.label == "Activation Water" })?.massGrams ?? 0
                        let mAdditionalActivWater = viewModel.additionalActiveWaterML * systemConfig.densityWater
                        let mBaseActivWater = mTotalActivWater - mAdditionalActivWater
                        let mFlavorOils = activComps.filter { $0.activationCategory == .flavorOil }.reduce(0) { $0 + $1.massGrams }
                        let mColor = activComps.filter { $0.activationCategory == .color }.reduce(0) { $0 + $1.massGrams }
                        let mTerps = activComps.filter { $0.activationCategory == .terpene }.reduce(0) { $0 + $1.massGrams }

                        // Expected cumulative readings (shown as hints when previous field is filled)
                        let expectedCitric: Double? = viewModel.hpActive.map { $0 + mCitric }
                        let expectedKSorbate: Double? = viewModel.hpCitricAcid.map { $0 + mKSorbate }
                        let expectedBaseWater: Double? = viewModel.hpKSorbate.map { $0 + mBaseActivWater }
                        let expectedAdditionalWater: Double? = viewModel.hpActivationWater.map { $0 + mAdditionalActivWater }
                        let expectedFlavorOils: Double? = viewModel.hpAdditionalActivationWater.map { $0 + mFlavorOils }
                        let expectedColor: Double? = viewModel.hpFlavorOils.map { $0 + mColor }
                        let expectedTerps: Double? = viewModel.hpColor.map { $0 + mTerps }

                        hpTareDisplayRow("Container", tare: activBeakerTare, resolution: activRes)
                        hpTareDisplayRow("+ Stir Bar", tare: activTare, resolution: activRes)
                        subWeightRow("+ Active", value: $viewModel.hpActive, resolution: activRes)
                        subWeightRow("+ Citric Acid", value: $viewModel.hpCitricAcid, resolution: activRes,
                                     expected: viewModel.hpActive != nil && viewModel.hpCitricAcid == nil ? expectedCitric : nil,
                                     individualMass: mCitric)
                        subWeightRow("+ Potassium Sorbate", value: $viewModel.hpKSorbate, resolution: activRes,
                                     expected: viewModel.hpCitricAcid != nil && viewModel.hpKSorbate == nil ? expectedKSorbate : nil,
                                     individualMass: mKSorbate)
                        subWeightRow("+ (Base) Activation Water", value: $viewModel.hpActivationWater, resolution: activRes,
                                     expected: viewModel.hpKSorbate != nil && viewModel.hpActivationWater == nil ? expectedBaseWater : nil,
                                     individualMass: mBaseActivWater)
                        subWeightRow("+ Additional Activation Water", value: $viewModel.hpAdditionalActivationWater, resolution: activRes,
                                     expected: viewModel.hpActivationWater != nil && viewModel.hpAdditionalActivationWater == nil ? expectedAdditionalWater : nil,
                                     individualMass: mAdditionalActivWater)
                        subWeightRow("+ Flavor Oils", value: $viewModel.hpFlavorOils, resolution: activRes,
                                     expected: viewModel.hpAdditionalActivationWater != nil && viewModel.hpFlavorOils == nil ? expectedFlavorOils : nil,
                                     individualMass: mFlavorOils)
                        subWeightRow("+ Color", value: $viewModel.hpColor, resolution: activRes,
                                     expected: viewModel.hpFlavorOils != nil && viewModel.hpColor == nil ? expectedColor : nil,
                                     individualMass: mColor)
                        subWeightRow("+ Terps", value: $viewModel.hpTerps, resolution: activRes,
                                     expected: viewModel.hpColor != nil && viewModel.hpTerps == nil ? expectedTerps : nil,
                                     individualMass: mTerps)
                        // Corrections total (if any corrections have been entered)
                        if let activCorrTotal = viewModel.activationCorrectionsTotal {
                            hpTotalRow("Corrections", value: activCorrTotal)
                        }
                        subWeightRow("- Activation Tray (Residue)", value: $viewModel.hpActivationTrayResidue, resolution: activRes)
                        let residueLoss: Double? = viewModel.hpActivationTrayResidue.map { $0 - activTare }
                        hpTotalRow("Residue Loss", value: residueLoss)
                        let activNetTotal: Double? = {
                            guard let last = viewModel.hpTerps else { return nil }
                            let loss = residueLoss ?? 0
                            return (last - activTare) - loss + (viewModel.activationCorrectionsTotal ?? 0)
                        }()
                        hpTotalRow("Net Total | Activation Mixture", value: activNetTotal)
                    }

                // MARK: Gelatin Mixture
                HStack {
                    Text("Gelatin Mixture").cmSubsectionTitle()
                    CMCorrectionsButton(accentColor: systemConfig.designPrimaryAccent) {
                        showCorrectionsSection = .gelatin
                    }
                    Spacer()
                }
                .cmSubsectionPadding()

                    // ===== GELATIN / SUBSTRATE SECTION =====
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
                        let mGelatinWater = batchResult.gelatinMix.components[1].massGrams
                        let mGelatinPowder = batchResult.gelatinMix.components[0].massGrams
                        let expectedWater = substrateTare + mGelatinWater
                        let expectedGelatin: Double? = viewModel.hpGelatinWater.map { $0 + mGelatinPowder }

                        hpTareDisplayRow("Beaker", tare: substrateBeakerTare, resolution: substrateRes)
                        hpTareDisplayRow("+ Stir Bar", tare: substrateTare, resolution: substrateRes)
                        subWeightRow("+ Water", value: $viewModel.hpGelatinWater, resolution: substrateRes,
                                     expected: viewModel.hpGelatinWater == nil ? expectedWater : nil,
                                     individualMass: mGelatinWater)
                        subWeightRow("+ Gelatin", value: $viewModel.hpGelatin, resolution: substrateRes,
                                     expected: viewModel.hpGelatinWater != nil && viewModel.hpGelatin == nil ? expectedGelatin : nil,
                                     individualMass: mGelatinPowder)
                        subWeightRow("- Substrate Beaker (Residue)", value: $viewModel.weightBeakerResidue, resolution: substrateRes)
                        let gelatinResidueLoss: Double? = viewModel.weightBeakerResidue.map { $0 - substrateTare }
                        hpTotalRow("Residue Loss", value: gelatinResidueLoss)
                        // Corrections total (if any corrections have been entered)
                        if let corrTotal = viewModel.correctionsTotal {
                            hpTotalRow("Corrections", value: corrTotal)
                        }
                        let gelatinNet: Double? = viewModel.hpGelatin.map {
                            let loss = gelatinResidueLoss ?? 0
                            return ($0 - substrateTare) - loss + (viewModel.correctionsTotal ?? 0)
                        }
                        hpTotalRow("Net Total | Gelatin Mixture", value: gelatinNet)
                    }

                    // ===== SUGAR MIX SECTION =====
                    HStack {
                        Text("Sugar Mixture").cmSubsectionTitle()
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
                        let mSugarWater = batchResult.sugarMix.components[2].massGrams * sugarOverage
                        let mGlucoseSyrup = batchResult.sugarMix.components[0].massGrams * sugarOverage
                        let mGranulated = batchResult.sugarMix.components[1].massGrams * sugarOverage
                        let expectedSugarWater = sugarTare + mSugarWater
                        let expectedGlucose: Double? = viewModel.hpSugarWater.map { $0 + mGlucoseSyrup }
                        let expectedGranulated: Double? = viewModel.hpGlucoseSyrup.map { $0 + mGranulated }

                        hpTareDisplayRow("Beaker", tare: sugarBeakerTare, resolution: sugarRes)
                        hpTareDisplayRow("+ Stir Bar", tare: sugarTare, resolution: sugarRes)
                        subWeightRow("+ Water", value: $viewModel.hpSugarWater, resolution: sugarRes,
                                     expected: viewModel.hpSugarWater == nil ? expectedSugarWater : nil,
                                     individualMass: mSugarWater)
                        subWeightRow("+ Glucose Syrup", value: $viewModel.hpGlucoseSyrup, resolution: sugarRes,
                                     expected: viewModel.hpSugarWater != nil && viewModel.hpGlucoseSyrup == nil ? expectedGlucose : nil,
                                     individualMass: mGlucoseSyrup)
                        subWeightRow("+ Granulated Sugar", value: $viewModel.hpGranulated, resolution: sugarRes,
                                     expected: viewModel.hpGlucoseSyrup != nil && viewModel.hpGranulated == nil ? expectedGranulated : nil,
                                     individualMass: mGranulated)
                        // Corrections total (if any corrections have been entered)
                        if let sugarCorrTotal = viewModel.sugarCorrectionsTotal {
                            hpTotalRow("Corrections", value: sugarCorrTotal)
                        }
                        let sugarNet: Double? = viewModel.hpGranulated.map {
                            ($0 - sugarTare) + (viewModel.sugarCorrectionsTotal ?? 0)
                        }
                        hpTotalRow("Net Total | Sugar Mixture", value: sugarNet)
                    }

                    // ===== TRANSFER ROW =====
                    let expectedSugarTransfer: Double? = viewModel.hpGelatin.map { $0 + batchResult.sugarMix.totalMassGrams }
                    HStack(spacing: 6) {
                        Text("+ Sugar Mixture").cmHpLabel(color: systemConfig.designPrimaryAccent)
                        Spacer()
                        if expectedSugarTransfer != nil, viewModel.hpSubstrateSugarTransfer == nil {
                            Text(String(format: "%.3f", batchResult.sugarMix.totalMassGrams))
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        if let expected = expectedSugarTransfer, viewModel.hpSubstrateSugarTransfer == nil {
                            Text(String(format: "%.3f", expected))
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(systemConfig.designSecondaryAccent.opacity(0.7))
                        }
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

                    // ===== ACTIVATION TRANSFER =====
                    let activNetTotal: Double? = {
                        guard let last = viewModel.hpTerps else { return nil }
                        let residue = viewModel.hpActivationTrayResidue.map { $0 - activTare } ?? 0
                        return (last - activTare) - residue + (viewModel.activationCorrectionsTotal ?? 0)
                    }()
                    let expectedActivTransfer: Double? = {
                        guard let sugarTransfer = viewModel.hpSubstrateSugarTransfer,
                              let activNet = activNetTotal else { return nil }
                        return sugarTransfer + activNet
                    }()
                    HStack(spacing: 6) {
                        Text("+ Activation Mixture").cmHpLabel(color: systemConfig.designPrimaryAccent)
                        Spacer()
                        if let activNet = activNetTotal, expectedActivTransfer != nil, viewModel.hpSubstrateActivationTransfer == nil {
                            Text(String(format: "%.3f", activNet))
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        if let expected = expectedActivTransfer, viewModel.hpSubstrateActivationTransfer == nil {
                            Text(String(format: "%.3f", expected))
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(systemConfig.designSecondaryAccent.opacity(0.7))
                        }
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

                    // ===== NET TOTAL GUMMY MIXTURE =====
                    let gummyMixtureTotal: Double? = viewModel.hpSubstrateActivationTransfer.map { $0 - substrateTare }
                    hpTotalRow("Net Total | Gummy Mixture", value: gummyMixtureTotal)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Transfer Gummy Mixture to Trays
                subsectionHeader("Transfer Gummy Mixture to Trays")
                    let transferSyringeID = viewModel.hpTransferSyringeID
                        ?? systemConfig.syringes.first?.id
                    let transferTare = transferSyringeID.map { systemConfig.syringeTare(for: $0) } ?? 0
                    let transferRes = viewModel.hpScaleResolution(for: viewModel.hpTransferScaleID, systemConfig: systemConfig)

                    hpSectionBox {
                        hpSyringeSelector(
                            label: "Transfer Syringe",
                            selectedID: Binding(
                                get: { transferSyringeID },
                                set: { viewModel.hpTransferSyringeID = $0 }
                            )
                        )
                        hpScaleSelector(
                            label: "Transfer Scale",
                            selectedID: $viewModel.hpTransferScaleID
                        )

                        hpTareDisplayRow("Syringe (Clean)", tare: transferTare, resolution: transferRes)
                        subWeightRow("+ Gummy Mix", value: $viewModel.weightSyringeWithMix, resolution: transferRes)
                        subVolumeRow("Gummy Mix Volume", value: $viewModel.volumeSyringeGummyMix)
                        subWeightRow("- Syringe (Residue)", value: $viewModel.weightSyringeResidue, resolution: transferRes)

                        let residueLoss: Double? = viewModel.weightSyringeResidue.map { $0 - transferTare }
                        hpTotalRow("Syringe Residue Loss", value: residueLoss)

                        let netTransferred: Double? = {
                            guard let mixMass = viewModel.weightSyringeWithMix else { return nil }
                            let loss = residueLoss ?? 0
                            return (mixMass - transferTare) - loss
                        }()
                        hpTotalRow("Net Gummy Mix Transferred", value: netTransferred)
                    }
                    Text("Measure the syringe with the locking cap and syringe tip attached to ensure tare measurements are consistent.")
                        .cmFootnote()
                        .padding(.horizontal, 20)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Molds
                subsectionHeader("Molds")
                    let moldsTrayID = viewModel.hpMoldsTrayID
                        ?? systemConfig.trays.first?.id
                    let moldsTare = moldsTrayID.map { systemConfig.trayTare(for: $0) } ?? 0
                    let moldsRes = viewModel.hpScaleResolution(for: viewModel.hpMoldsScaleID, systemConfig: systemConfig)

                    hpSectionBox {
                        hpTraySelector(
                            label: "Mold Tray",
                            selectedID: Binding(
                                get: { moldsTrayID },
                                set: { viewModel.hpMoldsTrayID = $0 }
                            )
                        )
                        hpScaleSelector(
                            label: "Molds Scale",
                            selectedID: $viewModel.hpMoldsScaleID
                        )

                        hpTareDisplayRow("Tray (Clean)", tare: moldsTare, resolution: moldsRes)
                        subWeightRow("+ Tray Residue", value: $viewModel.weightTrayPlusResidue, resolution: moldsRes)

                        let trayResidueLoss: Double? = viewModel.weightTrayPlusResidue.map { $0 - moldsTare }
                        hpTotalRow("Tray Residue", value: trayResidueLoss)

                        ThemedDivider(indent: 36).padding(.vertical, 4)

                        subIntRow("Molds Filled", value: $viewModel.weightMoldsFilled)
                        subAccentWeightRow("− Extra Gummy Mix", value: $viewModel.extraGummyMixGrams, resolution: moldsRes)
                    }

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
            if let section = showCorrectionsSection {
                CorrectionsView(section: section) {
                    withAnimation(.cmSpring) { showCorrectionsSection = nil }
                }
            }
        }
        .fullScreenCover(isPresented: isFullScreen ? .constant(false) : $showFullScreen) {
            WeightMeasurementsFullScreenView()
                .environment(viewModel)
                .environment(systemConfig)
        }
        .sheet(item: $containerPickerRow) { row in
            ContainerPickerSheet(row: row)
                .environment(systemConfig)
        }
        .sheet(item: $syringePickerRow) { row in
            SyringePickerSheet(row: row)
                .environment(systemConfig)
        }
        .sheet(item: $trayPickerRow) { row in
            TrayPickerSheet(row: row)
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
        .overlay {
            if let containerID = showContainerInfo {
                ContainerInfoPopup(containerID: containerID) {
                    withAnimation(.cmSpring) { showContainerInfo = nil }
                }
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

    /// Indented sub-row for high-precision mode fields.
    /// `expected` is the theoretical cumulative scale reading shown in secondary accent next to input.
    /// `individualMass` is the individual ingredient mass shown in white text (full-screen only).
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

    /// Indented sub-row for high-precision mode volume fields (mL units, blue text).
    /// Uses a shippingbox icon to indicate this is an informational volume measurement
    /// that does not participate in the mass transfer calculation.
    private func subVolumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 10))
                    .foregroundStyle(measurementColor)
                Text(label).cmHpLabel(color: measurementColor)
            }
            Spacer()
            OptionalNumericField(value: value, decimals: 3)
                .multilineTextAlignment(.trailing)
                .cmHpValueSlot(color: measurementColor)
            Text("mL")
                .cmMono11()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmHpSubRowPadding()
        .cmExpandTransition()
    }

    /// Read-only sub-row showing an equipment item's tare mass from settings.
    private func hpTareDisplayRow(_ label: String, tare: Double, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label).cmHpLabel(color: measurementColor)
            Spacer()
            Text(String(format: "%.\(decimals)f", tare))
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(measurementColor)
                .frame(width: 80, alignment: .trailing)
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

    // MARK: - HP Syringe Helpers

    /// Syringe selector row: tappable capsule that opens the wheel picker sheet.
    private func hpSyringeSelector(label: String, selectedID: Binding<String?>) -> some View {
        let displayName = selectedID.wrappedValue
            .flatMap { id in systemConfig.syringes.first { $0.id == id }?.name }
            ?? "Select..."

        return Button {
            CMHaptic.light()
            syringePickerRow = SyringePickerRow(
                label: label,
                currentID: selectedID.wrappedValue,
                onSelect: { newID in selectedID.wrappedValue = newID }
            )
        } label: {
            CMEquipmentCapsule(icon: "syringe.fill", displayName: displayName, color: measurementColor)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

    // MARK: - HP Tray Helpers

    /// Tray selector row: tappable capsule that opens the wheel picker sheet.
    private func hpTraySelector(label: String, selectedID: Binding<String?>) -> some View {
        let displayName = selectedID.wrappedValue
            .flatMap { id in systemConfig.trays.first { $0.id == id }?.name }
            ?? "Select..."

        return Button {
            CMHaptic.light()
            trayPickerRow = TrayPickerRow(
                label: label,
                currentID: selectedID.wrappedValue,
                onSelect: { newID in selectedID.wrappedValue = newID }
            )
        } label: {
            CMEquipmentCapsule(icon: "tray.fill", displayName: displayName, color: measurementColor)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

    /// HP-styled integer row (molds filled count).
    private func subIntRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label).cmHpLabel(color: measurementColor)
            Spacer()
            OptionalNumericField(value: value, decimals: 0)
                .multilineTextAlignment(.trailing)
                .cmHpValueSlot(color: measurementColor)
            Text("#")
                .cmMono11()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmHpSubRowPadding()
        .cmExpandTransition()
    }

    /// HP-styled weight sub-row in primary accent color (for "− Extra Gummy Mix").
    private func subAccentWeightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let accentColor = systemConfig.designPrimaryAccent
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label).cmHpLabel(color: accentColor)
            Spacer()
            OptionalNumericField(value: value, decimals: decimals)
                .multilineTextAlignment(.trailing)
                .cmHpValueSlot(color: accentColor)
            Text("g")
                .cmMono11()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .cmHpSubRowPadding()
        .cmExpandTransition()
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
            CMEquipmentCapsule(icon: "flask.fill", displayName: displayName, color: measurementColor)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 3)
        .cmExpandTransition()
    }

    /// Stir bar selector row: tappable capsule that opens the wheel picker sheet.
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

// MARK: - Full Screen Batch Measurements

struct WeightMeasurementsFullScreenView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss

    private let scaleFactor: CGFloat = 1.5
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let narrowWidth = geo.size.width / scaleFactor
                ScrollView([.horizontal, .vertical]) {
                    WeightMeasurementsView(isFullScreen: true)
                        .frame(width: narrowWidth)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { inner in
                                Color.clear.preference(
                                    key: ContentHeightKey.self,
                                    value: inner.size.height
                                )
                            }
                        )
                        .scaleEffect(scaleFactor, anchor: .topLeading)
                        .frame(
                            width: geo.size.width,
                            height: contentHeight * scaleFactor,
                            alignment: .topLeading
                        )
                }
                .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
            }
            .background(CMTheme.pageBG)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                }
            }
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
