//
//  SigFigAnalysisView.swift
//  CandyMan
//
//  Expandable card that displays the number of significant figures
//  for every experimental computation shown in "Experiment Data 2".
//
//  Each HP measurement is a cumulative scale reading; individual masses
//  come from subtracting consecutive readings (or reading − tare).
//  Sig figs propagate through subtraction (limiting DP), multiplication/
//  division (limiting SF), and addition (limiting DP).
//

import SwiftUI

// MARK: - Detail Item

/// Identifiable wrapper for presenting the sig fig detail sheet.
private struct SFDetailItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

// MARK: - SigFigAnalysisView

struct SigFigAnalysisView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded = false
    @State private var activeDetail: SFDetailItem?

    // Column widths
    private let valColWidth: CGFloat = 68
    private let unitColWidth: CGFloat = 30
    private let sfColWidth: CGFloat = 38

    // MARK: - BatchResult shortcut

    private var result: BatchResult {
        BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)
    }

    // MARK: - Scale Resolutions

    private var substrateRes: MeasurementResolution {
        viewModel.hpScaleResolution(for: viewModel.hpSubstrateScaleID, systemConfig: systemConfig)
    }
    private var sugarRes: MeasurementResolution {
        viewModel.hpScaleResolution(for: viewModel.hpSugarMixScaleID, systemConfig: systemConfig)
    }
    private var activationRes: MeasurementResolution {
        viewModel.hpScaleResolution(for: viewModel.hpActivationScaleID, systemConfig: systemConfig)
    }
    private var transferRes: MeasurementResolution {
        viewModel.hpScaleResolution(for: viewModel.hpTransferScaleID, systemConfig: systemConfig)
    }
    private var moldsRes: MeasurementResolution {
        viewModel.hpScaleResolution(for: viewModel.hpMoldsScaleID, systemConfig: systemConfig)
    }

    // MARK: - Gelatin Mixture SF

    private var sfExpGelatin: SigFigInfo? {
        guard let gel = viewModel.hpGelatin else { return nil }
        let tare = viewModel.hpSubstrateTare(systemConfig: systemConfig)
        return SigFigs.sfOfDifference(gel, resA: substrateRes, minus: tare, resB: substrateRes)
    }

    private var sfExpGelatinWater: SigFigInfo? {
        guard let water = viewModel.hpGelatinWater, let gel = viewModel.hpGelatin else { return nil }
        return SigFigs.sfOfDifference(water, resA: substrateRes, minus: gel, resB: substrateRes)
    }

    private var sfExpGelatinMixTotal: SigFigInfo? {
        guard let g = sfExpGelatin, let w = sfExpGelatinWater else { return nil }
        let resultDP = SigFigs.addSubtract(g, w)
        let value = (viewModel.hpIndividualGelatin(systemConfig: systemConfig) ?? 0)
            + (viewModel.hpIndividualGelatinWater ?? 0)
        let str = SigFigs.formatDP(value, decimalPlaces: resultDP)
        return SigFigs.count(from: str)
    }

    // MARK: - Sugar Mixture SF

    private var sfExpGranulated: SigFigInfo? {
        guard let gran = viewModel.hpGranulated else { return nil }
        let tare = viewModel.hpSugarMixTare(systemConfig: systemConfig)
        return SigFigs.sfOfDifference(gran, resA: sugarRes, minus: tare, resB: sugarRes)
    }

    private var sfExpGlucoseSyrup: SigFigInfo? {
        guard let gluc = viewModel.hpGlucoseSyrup, let gran = viewModel.hpGranulated else { return nil }
        return SigFigs.sfOfDifference(gluc, resA: sugarRes, minus: gran, resB: sugarRes)
    }

    private var sfExpSugarWater: SigFigInfo? {
        guard let water = viewModel.hpSugarWater else { return nil }
        let prev = viewModel.hpGlucoseSyrup ?? viewModel.hpGranulated
        guard let p = prev else { return nil }
        return SigFigs.sfOfDifference(water, resA: sugarRes, minus: p, resB: sugarRes)
    }

    private var sfExpSugarMixTotal: SigFigInfo? {
        guard let g = sfExpGranulated, let gl = sfExpGlucoseSyrup, let w = sfExpSugarWater else { return nil }
        let resultDP = SigFigs.addSubtract(g, gl, w)
        let value = (viewModel.hpIndividualGranulated(systemConfig: systemConfig) ?? 0)
            + (viewModel.hpIndividualGlucoseSyrup ?? 0)
            + (viewModel.hpIndividualSugarWater ?? 0)
        let str = SigFigs.formatDP(value, decimalPlaces: resultDP)
        return SigFigs.count(from: str)
    }

    // MARK: - Activation Mixture SF

    private var sfExpCitricAcid: SigFigInfo? {
        guard let citric = viewModel.hpCitricAcid else { return nil }
        let tare = viewModel.hpActivationTare(systemConfig: systemConfig)
        return SigFigs.sfOfDifference(citric, resA: activationRes, minus: tare, resB: activationRes)
    }

    private var sfExpActivationWater: SigFigInfo? {
        guard let water = viewModel.hpActivationWater, let citric = viewModel.hpCitricAcid else { return nil }
        return SigFigs.sfOfDifference(water, resA: activationRes, minus: citric, resB: activationRes)
    }

    private var sfExpKSorbate: SigFigInfo? {
        guard let k = viewModel.hpKSorbate, let water = viewModel.hpActivationWater else { return nil }
        return SigFigs.sfOfDifference(k, resA: activationRes, minus: water, resB: activationRes)
    }

    private var sfExpFlavorOilsTerps: SigFigInfo? {
        guard let flavor = viewModel.hpFlavorOilsTerpsActive, let k = viewModel.hpKSorbate else { return nil }
        return SigFigs.sfOfDifference(flavor, resA: activationRes, minus: k, resB: activationRes)
    }

    private var sfExpActivationMixTotal: SigFigInfo? {
        guard let c = sfExpCitricAcid, let w = sfExpActivationWater,
              let k = sfExpKSorbate, let f = sfExpFlavorOilsTerps else { return nil }
        let resultDP = SigFigs.addSubtract(c, w, k, f)
        let v1: Double = viewModel.hpIndividualCitricAcid(systemConfig: systemConfig) ?? 0
        let v2: Double = viewModel.hpIndividualActivationWater ?? 0
        let v3: Double = viewModel.hpIndividualKSorbate ?? 0
        let v4: Double = viewModel.hpIndividualFlavorOilsTerpsActive ?? 0
        let value = v1 + v2 + v3 + v4
        let str = SigFigs.formatDP(value, decimalPlaces: resultDP)
        return SigFigs.count(from: str)
    }

    // MARK: - Mixture Densities SF

    private var sfGelatinMixDensity: Int? {
        guard let clean = viewModel.densitySyringeCleanGelatin,
              let mass = viewModel.densitySyringePlusGelatinMass,
              let vol = viewModel.densitySyringePlusGelatinVol,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(
            mass, resA: substrateRes, minus: clean, resB: substrateRes
        )
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    private var sfSugarMixDensity: Int? {
        guard let clean = viewModel.densitySyringeCleanSugar,
              let mass = viewModel.densitySyringePlusSugarMass,
              let vol = viewModel.densitySyringePlusSugarVol,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(
            mass, resA: sugarRes, minus: clean, resB: sugarRes
        )
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    private var sfActivationMixDensity: Int? {
        guard let clean = viewModel.densitySyringeCleanActive,
              let mass = viewModel.densitySyringePlusActiveMass,
              let vol = viewModel.densitySyringePlusActiveVol,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(
            mass, resA: activationRes, minus: clean, resB: activationRes
        )
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    private var sfFinalMixDensity: Int? {
        guard let syringeMix = viewModel.weightSyringeWithMix,
              let syringeClean = viewModel.weightSyringeEmpty,
              let vol = viewModel.volumeSyringeGummyMix,
              vol > 0 else { return nil }
        let massDiff = SigFigs.sfOfDifference(
            syringeMix, resA: systemConfig.resolutionSyringeWithMix,
            minus: syringeClean, resB: systemConfig.resolutionSyringeEmpty
        )
        let volSF = SigFigs.count(from: String(format: "%.3f", vol))
        return SigFigs.multiplyDivide(massDiff, volSF)
    }

    // MARK: - Losses SF

    private var sfBeakerResidue: SigFigInfo? {
        guard let residue = viewModel.weightBeakerResidue else { return nil }
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return SigFigs.sfOfDifference(
            residue, resA: systemConfig.resolutionBeakerResidue,
            minus: tare, resB: systemConfig.resolutionBeakerResidue
        )
    }

    private var sfActivationTrayResidue: SigFigInfo? {
        guard let residue = viewModel.hpActivationTrayResidue else { return nil }
        let activVol = result.activationMix.totalVolumeML
        let containerID = viewModel.hpActivationTrayID
            ?? systemConfig.recommendedBeaker(forVolumeML: activVol)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return SigFigs.sfOfDifference(
            residue, resA: activationRes, minus: tare, resB: activationRes
        )
    }

    private var sfSyringeResidue: SigFigInfo? {
        guard let residue = viewModel.weightSyringeResidue else { return nil }
        let syringeID = viewModel.hpTransferSyringeID ?? systemConfig.syringes.first?.id
        let tare = syringeID.map { systemConfig.syringeTare(for: $0) } ?? 0
        return SigFigs.sfOfDifference(
            residue, resA: systemConfig.resolutionSyringeResidue,
            minus: tare, resB: systemConfig.resolutionSyringeResidue
        )
    }

    private var sfTrayResidue: SigFigInfo? {
        guard let reading = viewModel.weightTrayPlusResidue else { return nil }
        let trayID = viewModel.hpMoldsTrayID ?? systemConfig.trays.first?.id
        let tare = trayID.map { systemConfig.trayTare(for: $0) } ?? 0
        return SigFigs.sfOfDifference(
            reading, resA: moldsRes, minus: tare, resB: moldsRes
        )
    }

    private var sfExtraGummyMix: SigFigInfo? {
        guard let v = viewModel.extraGummyMixGrams else { return nil }
        return SigFigs.quickCount(v)
    }

    private var sfTotalLoss: Int? {
        let infos = [sfBeakerResidue, sfActivationTrayResidue, sfSyringeResidue, sfTrayResidue, sfExtraGummyMix].compactMap { $0 }
        guard !infos.isEmpty else { return nil }
        let minDP = infos.map { $0.decimalPlaces ?? 0 }.min()!
        let beaker = calcHPBeakerResidue ?? 0
        let actTray = calcActivationTrayResidue ?? 0
        let syringe = calcSyringeResidue ?? 0
        let tray = calcTrayResidue ?? 0
        let extra = viewModel.extraGummyMixGrams ?? 0
        let sum = beaker + actTray + syringe + tray + extra
        let str = SigFigs.formatDP(sum, decimalPlaces: minDP)
        return SigFigs.count(from: str).sigFigs
    }

    // Loss helpers
    private var calcHPBeakerResidue: Double? {
        guard let residue = viewModel.weightBeakerResidue else { return nil }
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return residue - tare
    }

    private var calcActivationTrayResidue: Double? {
        guard let residue = viewModel.hpActivationTrayResidue else { return nil }
        let activVol = result.activationMix.totalVolumeML
        let containerID = viewModel.hpActivationTrayID
            ?? systemConfig.recommendedBeaker(forVolumeML: activVol)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return residue - tare
    }

    private var calcSyringeResidue: Double? {
        guard let residue = viewModel.weightSyringeResidue else { return nil }
        let syringeID = viewModel.hpTransferSyringeID ?? systemConfig.syringes.first?.id
        let tare = syringeID.map { systemConfig.syringeTare(for: $0) } ?? 0
        return residue - tare
    }

    private var calcTrayResidue: Double? {
        guard let reading = viewModel.weightTrayPlusResidue else { return nil }
        let trayID = viewModel.hpMoldsTrayID ?? systemConfig.trays.first?.id
        let tare = trayID.map { systemConfig.trayTare(for: $0) } ?? 0
        return reading - tare
    }

    // MARK: - Active Lost SF

    private var sfGummyMixtureMass: SigFigInfo? {
        guard let transfer = viewModel.hpSubstrateActivationTransfer else { return nil }
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return SigFigs.sfOfDifference(
            transfer, resA: transferRes, minus: tare, resB: transferRes
        )
    }

    private var sfTotalActive: SigFigInfo? {
        let active = SigFigs.quickCount(viewModel.activeConcentration)
        return active
    }

    private var sfActiveLost: Int? {
        guard let activeSF = sfTotalActive?.sigFigs,
              let lossSF = sfTotalLoss,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(activeSF, lossSF, mixSF)
    }

    // MARK: - Gummy Properties SF

    private var sfExpGummyMass: Int? {
        guard let mixInfo = sfGummyMixtureMass,
              let lossSF = sfTotalLoss,
              let moldsFilled = viewModel.weightMoldsFilled else { return nil }
        let massVal = viewModel.hpSubstrateActivationTransfer ?? 0
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        let netMass = massVal - tare

        let beaker = calcHPBeakerResidue ?? 0
        let actTray = calcActivationTrayResidue ?? 0
        let syringe = calcSyringeResidue ?? 0
        let trayRes = calcTrayResidue ?? 0
        let extra = viewModel.extraGummyMixGrams ?? 0
        let totalLoss = beaker + actTray + syringe + trayRes + extra

        let diffDP = min(mixInfo.decimalPlaces ?? 0, lossSF > 0 ? 3 : 0)
        let diff = netMass - totalLoss
        let diffInfo = SigFigs.count(from: SigFigs.formatDP(diff, decimalPlaces: diffDP))

        let moldsInfo = SigFigs.count(moldsFilled, resolution: moldsRes)
        return SigFigs.multiplyDivide(diffInfo, moldsInfo)
    }

    private var sfExpGummyVolume: Int? {
        guard let massSF = sfExpGummyMass,
              let densitySF = sfFinalMixDensity else { return nil }
        return min(massSF, densitySF)
    }

    private var sfExpGummyConcentration: Int? {
        sfActiveLost
    }

    private var sfExpCitricAcidFraction: Int? {
        guard let citricSF = sfExpCitricAcid?.sigFigs,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(citricSF, mixSF)
    }

    private var sfExpKSorbateFraction: Int? {
        guard let kSF = sfExpKSorbate?.sigFigs,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(kSF, mixSF)
    }

    private var sfExpGelatinFraction: Int? {
        guard let gelSF = sfExpGelatin?.sigFigs,
              let mixSF = sfGummyMixtureMass?.sigFigs else { return nil }
        return min(gelSF, mixSF)
    }

    // MARK: - Computed Values

    private var sugarOverage: Double {
        1.0 + systemConfig.sugarMixtureOveragePercent / 100.0
    }

    private var valGelatinMixDensity: Double? { viewModel.calcGelatinMixDensity }
    private var valSugarMixDensity: Double? { viewModel.calcSugarMixDensity }
    private var valActivationMixDensity: Double? { viewModel.calcActiveMixDensity }
    private var valFinalMixDensity: Double? { viewModel.calcDensityFinalMix(systemConfig: systemConfig) }

    private var valTotalLoss: Double? {
        let vals = [calcHPBeakerResidue, calcActivationTrayResidue, calcSyringeResidue, calcTrayResidue, viewModel.extraGummyMixGrams]
        let available = vals.compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +)
    }

    private var valGummyMixtureMass: Double? {
        guard let transfer = viewModel.hpSubstrateActivationTransfer else { return nil }
        let containerID = viewModel.hpSubstrateBeakerID
            ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id
        let tare = containerID.map { systemConfig.containerTare(for: $0) } ?? 0
        return transfer - tare
    }

    private var valTotalActive: Double {
        viewModel.activeConcentration * Double(viewModel.totalGummies(using: systemConfig))
    }

    private var valActiveLost: Double? {
        guard let loss = valTotalLoss,
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return valTotalActive * (loss / mixMass)
    }

    private var valExpGummyMass: Double? {
        guard let mixMass = valGummyMixtureMass,
              let losses = valTotalLoss,
              let molds = viewModel.weightMoldsFilled,
              molds > 0 else { return nil }
        return (mixMass - losses) / molds
    }

    private var valExpGummyVolume: Double? {
        guard let mass = valExpGummyMass,
              let density = valFinalMixDensity,
              density > 0 else { return nil }
        return mass / density
    }

    private var valExpGummyConcentration: Double? {
        guard let lost = valActiveLost,
              let moldsFilled = viewModel.weightMoldsFilled,
              moldsFilled > 0 else { return nil }
        return (valTotalActive - lost) / moldsFilled
    }

    private var valExpCitricAcidFraction: Double? {
        guard let citric = viewModel.hpIndividualCitricAcid(systemConfig: systemConfig),
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (citric / mixMass) * 100.0
    }

    private var valExpKSorbateFraction: Double? {
        guard let ksorbate = viewModel.hpIndividualKSorbate,
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (ksorbate / mixMass) * 100.0
    }

    private var valExpGelatinFraction: Double? {
        guard let gelatin = viewModel.hpIndividualGelatin(systemConfig: systemConfig),
              let mixMass = valGummyMixtureMass,
              mixMass > 0 else { return nil }
        return (gelatin / mixMass) * 100.0
    }

    // MARK: - Detail Text Builders

    private func subtractionDetail(label: String, reading: Double?, readingLabel: String, tare: Double, tareLabel: String, res: MeasurementResolution, result: SigFigInfo?) -> String {
        let dp = res.decimalPlaces
        let readingStr = reading.map { String(format: "%.\(dp)f", $0) } ?? "—"
        let tareStr = String(format: "%.\(dp)f", tare)
        let diffStr = result.map { SigFigs.format($0.value, sigFigs: $0.sigFigs) } ?? "—"
        let sfCount = result?.sigFigs ?? 0
        return """
        Calculation: \(label)
        Operation: Subtraction

        \(readingLabel) = \(readingStr)
        \(tareLabel) = \(tareStr)
        Result = \(readingStr) - \(tareStr) = \(diffStr)

        Scale resolution: \(res.label)  (\(dp) decimal places)

        Sig Fig Rule (Subtraction):
        The result of a subtraction has the same number of
        decimal places as the operand with the fewest decimal
        places. Both operands are at \(dp) DP (from the same
        scale), so the difference is also at \(dp) DP.

        The number of significant figures in the result
        depends on the magnitude of the difference at \(dp) DP.

        Result: \(diffStr) has \(sfCount) significant figure\(sfCount == 1 ? "" : "s").
        """
    }

    private func consecutiveSubDetail(label: String, a: Double?, aLabel: String, b: Double?, bLabel: String, res: MeasurementResolution, result: SigFigInfo?) -> String {
        let dp = res.decimalPlaces
        let aStr = a.map { String(format: "%.\(dp)f", $0) } ?? "—"
        let bStr = b.map { String(format: "%.\(dp)f", $0) } ?? "—"
        let diffStr = result.map { SigFigs.format($0.value, sigFigs: $0.sigFigs) } ?? "—"
        let sfCount = result?.sigFigs ?? 0
        return """
        Calculation: \(label)
        Operation: Subtraction (consecutive cumulative readings)

        \(aLabel) = \(aStr)
        \(bLabel) = \(bStr)
        Result = \(aStr) - \(bStr) = \(diffStr)

        Scale resolution: \(res.label)  (\(dp) decimal places)

        Sig Fig Rule (Subtraction):
        Both readings are on the same scale at \(dp) DP.
        The difference inherits \(dp) DP.
        The significant figures depend on the magnitude
        of the result at that precision.

        Result: \(diffStr) has \(sfCount) significant figure\(sfCount == 1 ? "" : "s").
        """
    }

    private func additionDetail(label: String, components: [(String, SigFigInfo?)], totalValue: Double?, totalSF: SigFigInfo?) -> String {
        let sfCount = totalSF?.sigFigs ?? 0
        let valStr = totalSF.map { SigFigs.format($0.value, sigFigs: $0.sigFigs) } ?? "—"
        var lines = "Calculation: \(label)\nOperation: Addition\n\nComponents:\n"
        for (name, info) in components {
            if let info = info {
                lines += "  \(name): \(SigFigs.format(info.value, sigFigs: info.sigFigs))  (\(info.sigFigs) SF, \(info.decimalPlaces ?? 0) DP)\n"
            } else {
                lines += "  \(name): —\n"
            }
        }
        let dpValues = components.compactMap { $0.1?.decimalPlaces }
        let minDP = dpValues.min() ?? 0
        lines += """

        Sig Fig Rule (Addition):
        The result has the same number of decimal places as
        the component with the fewest decimal places.
        Limiting DP = \(minDP)

        Sum rounded to \(minDP) DP: \(valStr)
        Result: \(sfCount) significant figure\(sfCount == 1 ? "" : "s").
        """
        return lines
    }

    private func densityDetail(label: String, mass: Double?, massLabel: String, clean: Double?, cleanLabel: String, vol: Double?, massRes: MeasurementResolution, densityVal: Double?, sf: Int?) -> String {
        let mdp = massRes.decimalPlaces
        let massStr = mass.map { String(format: "%.\(mdp)f", $0) } ?? "—"
        let cleanStr = clean.map { String(format: "%.\(mdp)f", $0) } ?? "—"
        let volStr = vol.map { String(format: "%.3f", $0) } ?? "—"
        let diffVal = (mass ?? 0) - (clean ?? 0)
        let diffStr = String(format: "%.\(mdp)f", diffVal)
        let diffInfo = SigFigs.count(from: diffStr)
        let volSF = vol.map { SigFigs.count(from: String(format: "%.3f", $0)).sigFigs } ?? 0
        let resultSF = sf ?? 0
        let resultStr = (densityVal != nil && sf != nil) ? SigFigs.format(densityVal!, sigFigs: sf!) : "—"
        return """
        Calculation: \(label)
        Operation: Subtraction then Division

        Step 1 — Mass of mix (subtraction):
          \(massLabel) = \(massStr)
          \(cleanLabel) = \(cleanStr)
          Mass = \(massStr) - \(cleanStr) = \(diffStr)
          Scale resolution: \(massRes.label)  (\(mdp) DP)
          Mass difference: \(diffInfo.sigFigs) SF

        Step 2 — Divide by volume:
          Volume = \(volStr) mL  (\(volSF) SF)

        Sig Fig Rule (Division):
        Result SF = min(SF of numerator, SF of denominator)
                  = min(\(diffInfo.sigFigs), \(volSF)) = \(resultSF) SF

        Result: \(resultStr) g/mL  (\(resultSF) significant figure\(resultSF == 1 ? "" : "s"))
        """
    }

    private func activeLostDetail() -> String {
        let activeSF = sfTotalActive?.sigFigs ?? 0
        let lossSF = sfTotalLoss ?? 0
        let mixSF = sfGummyMixtureMass?.sigFigs ?? 0
        let resultSF = sfActiveLost ?? 0
        let valStr = valActiveLost.map { SigFigs.format($0, sigFigs: resultSF) } ?? "—"
        let totalActiveStr = SigFigs.format(valTotalActive, sigFigs: activeSF)
        let lossStr = valTotalLoss.map { String(format: "%.3f", $0) } ?? "—"
        let mixStr = valGummyMixtureMass.map { String(format: "%.3f", $0) } ?? "—"
        return """
        Calculation: Active Lost in Losses
        Operation: Multiplication and Division chain

        Formula:
          Active Lost = Total Active x (Total Losses / Gummy Mixture Mass)

        Values:
          Total Active     = \(totalActiveStr) \(viewModel.units.rawValue)  (\(activeSF) SF)
          Total Losses     = \(lossStr) g  (\(lossSF) SF)
          Gummy Mix Mass   = \(mixStr) g  (\(mixSF) SF)

        Sig Fig Rule (Multiplication / Division):
        Result SF = min(SF of all operands)
                  = min(\(activeSF), \(lossSF), \(mixSF)) = \(resultSF) SF

        Result: \(valStr) \(viewModel.units.rawValue)  (\(resultSF) significant figure\(resultSF == 1 ? "" : "s"))
        """
    }

    private func gummyMassDetail() -> String {
        let resultSF = sfExpGummyMass ?? 0
        let valStr = valExpGummyMass.map { SigFigs.format($0, sigFigs: resultSF) } ?? "—"
        let mixSF = sfGummyMixtureMass?.sigFigs ?? 0
        let lossSF = sfTotalLoss ?? 0
        let moldsFilled = viewModel.weightMoldsFilled
        let moldsSF = moldsFilled.map { SigFigs.count($0, resolution: moldsRes).sigFigs } ?? 0
        let mixStr = valGummyMixtureMass.map { String(format: "%.3f", $0) } ?? "—"
        let lossStr = valTotalLoss.map { String(format: "%.3f", $0) } ?? "—"
        let moldsStr = moldsFilled.map { String(format: "%.\(moldsRes.decimalPlaces)f", $0) } ?? "—"
        return """
        Calculation: Experimental Mass per Gummy
        Operation: Subtraction then Division

        Formula:
          Gummy Mass = (Gummy Mix Mass - Total Losses) / Molds Filled

        Step 1 — Subtraction:
          Gummy Mix Mass = \(mixStr) g  (\(mixSF) SF)
          Total Losses   = \(lossStr) g  (\(lossSF) SF)
          Numerator SF determined by DP alignment of the difference.

        Step 2 — Division by Molds Filled:
          Molds Filled = \(moldsStr)  (\(moldsSF) SF, \(moldsRes.label) resolution)

        Sig Fig Rule (Division):
        Result SF = min(SF of numerator, SF of molds)
                  = \(resultSF) SF

        Result: \(valStr) g  (\(resultSF) significant figure\(resultSF == 1 ? "" : "s"))
        """
    }

    private func gummyVolumeDetail() -> String {
        let massSF = sfExpGummyMass ?? 0
        let densSF = sfFinalMixDensity ?? 0
        let resultSF = sfExpGummyVolume ?? 0
        let valStr = valExpGummyVolume.map { SigFigs.format($0, sigFigs: resultSF) } ?? "—"
        let massStr = valExpGummyMass.map { SigFigs.format($0, sigFigs: massSF) } ?? "—"
        let densStr = valFinalMixDensity.map { SigFigs.format($0, sigFigs: densSF) } ?? "—"
        return """
        Calculation: Experimental Volume per Gummy
        Operation: Division

        Formula:
          Gummy Volume = Gummy Mass / Final Mix Density

        Values:
          Gummy Mass       = \(massStr) g  (\(massSF) SF)
          Final Mix Density = \(densStr) g/mL  (\(densSF) SF)

        Sig Fig Rule (Division):
        Result SF = min(\(massSF), \(densSF)) = \(resultSF) SF

        Result: \(valStr) mL  (\(resultSF) significant figure\(resultSF == 1 ? "" : "s"))
        """
    }

    private func massFractionDetail(label: String, componentMass: Double?, componentSF: Int?, mixMass: Double?, mixSF: Int?, resultVal: Double?, resultSF: Int?, unit: String) -> String {
        let sf = resultSF ?? 0
        let valStr = (resultVal != nil && resultSF != nil) ? SigFigs.format(resultVal!, sigFigs: sf) : "—"
        let compStr = componentMass.map { String(format: "%.3f", $0) } ?? "—"
        let mixStr = mixMass.map { String(format: "%.3f", $0) } ?? "—"
        let compSFCount = componentSF ?? 0
        let mixSFCount = mixSF ?? 0
        return """
        Calculation: \(label) Mass Fraction
        Operation: Division

        Formula:
          Fraction (%) = (\(label) Mass / Gummy Mix Mass) x 100

        Values:
          \(label) Mass   = \(compStr) g  (\(compSFCount) SF)
          Gummy Mix Mass = \(mixStr) g  (\(mixSFCount) SF)
          x 100 is exact (defined conversion).

        Sig Fig Rule (Division):
        Result SF = min(\(compSFCount), \(mixSFCount)) = \(sf) SF

        Result: \(valStr) %  (\(sf) significant figure\(sf == 1 ? "" : "s"))
        """
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
                    Text("Significant Figures").cmSectionTitle(accent: systemConfig.designTitle)
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

                Text("Significant figures for each experimental computation. Tap \(Image(systemName: "info.circle")) for details.")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                // MARK: Gelatin Mixture
                sfSubheader("Gelatin Mixture")
                sfRow("Gelatin", info: sfExpGelatin, unit: "g",
                      detail: subtractionDetail(label: "Gelatin Mass", reading: viewModel.hpGelatin, readingLabel: "Cumulative reading", tare: viewModel.hpSubstrateTare(systemConfig: systemConfig), tareLabel: "Container tare", res: substrateRes, result: sfExpGelatin))
                sfRow("Water", info: sfExpGelatinWater, unit: "g",
                      detail: consecutiveSubDetail(label: "Gelatin Water Mass", a: viewModel.hpGelatinWater, aLabel: "Reading after water", b: viewModel.hpGelatin, bLabel: "Reading after gelatin", res: substrateRes, result: sfExpGelatinWater))
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRow("Gelatin Mix Total", info: sfExpGelatinMixTotal, unit: "g", bold: true,
                      detail: additionDetail(label: "Gelatin Mix Total", components: [("Gelatin", sfExpGelatin), ("Water", sfExpGelatinWater)], totalValue: sfExpGelatinMixTotal?.value, totalSF: sfExpGelatinMixTotal))
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Sugar Mixture
                sfSubheader("Sugar Mixture")
                sfRow("Granulated Sugar", info: sfExpGranulated, unit: "g",
                      detail: subtractionDetail(label: "Granulated Sugar Mass", reading: viewModel.hpGranulated, readingLabel: "Cumulative reading", tare: viewModel.hpSugarMixTare(systemConfig: systemConfig), tareLabel: "Container tare", res: sugarRes, result: sfExpGranulated))
                sfRow("Glucose Syrup", info: sfExpGlucoseSyrup, unit: "g",
                      detail: consecutiveSubDetail(label: "Glucose Syrup Mass", a: viewModel.hpGlucoseSyrup, aLabel: "Reading after syrup", b: viewModel.hpGranulated, bLabel: "Reading after granulated", res: sugarRes, result: sfExpGlucoseSyrup))
                sfRow("Water", info: sfExpSugarWater, unit: "g",
                      detail: consecutiveSubDetail(label: "Sugar Water Mass", a: viewModel.hpSugarWater, aLabel: "Reading after water", b: viewModel.hpGlucoseSyrup ?? viewModel.hpGranulated, bLabel: "Previous reading", res: sugarRes, result: sfExpSugarWater))
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRow("Sugar Mix Total", info: sfExpSugarMixTotal, unit: "g", bold: true,
                      detail: additionDetail(label: "Sugar Mix Total", components: [("Granulated", sfExpGranulated), ("Glucose Syrup", sfExpGlucoseSyrup), ("Water", sfExpSugarWater)], totalValue: sfExpSugarMixTotal?.value, totalSF: sfExpSugarMixTotal))
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Activation Mixture
                sfSubheader("Activation Mixture")
                sfRow("Citric Acid", info: sfExpCitricAcid, unit: "g",
                      detail: subtractionDetail(label: "Citric Acid Mass", reading: viewModel.hpCitricAcid, readingLabel: "Cumulative reading", tare: viewModel.hpActivationTare(systemConfig: systemConfig), tareLabel: "Container tare", res: activationRes, result: sfExpCitricAcid))
                sfRow("Activation Water", info: sfExpActivationWater, unit: "g",
                      detail: consecutiveSubDetail(label: "Activation Water Mass", a: viewModel.hpActivationWater, aLabel: "Reading after water", b: viewModel.hpCitricAcid, bLabel: "Reading after citric acid", res: activationRes, result: sfExpActivationWater))
                sfRow("K Sorbate", info: sfExpKSorbate, unit: "g",
                      detail: consecutiveSubDetail(label: "K Sorbate Mass", a: viewModel.hpKSorbate, aLabel: "Reading after K sorbate", b: viewModel.hpActivationWater, bLabel: "Reading after water", res: activationRes, result: sfExpKSorbate))
                sfRow("Oils/Terps/Active", info: sfExpFlavorOilsTerps, unit: "g",
                      detail: consecutiveSubDetail(label: "Flavor/Oils/Terps/Active Mass", a: viewModel.hpFlavorOilsTerpsActive, aLabel: "Reading after addition", b: viewModel.hpKSorbate, bLabel: "Reading after K sorbate", res: activationRes, result: sfExpFlavorOilsTerps))
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRow("Activation Mix Total", info: sfExpActivationMixTotal, unit: "g", bold: true,
                      detail: additionDetail(label: "Activation Mix Total", components: [("Citric Acid", sfExpCitricAcid), ("Water", sfExpActivationWater), ("K Sorbate", sfExpKSorbate), ("Oils/Terps/Active", sfExpFlavorOilsTerps)], totalValue: sfExpActivationMixTotal?.value, totalSF: sfExpActivationMixTotal))
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Mixture Densities
                sfSubheader("Mixture Densities")
                sfRowFromInt("Gelatin Mix", value: valGelatinMixDensity, sf: sfGelatinMixDensity, unit: "g/mL",
                             detail: densityDetail(label: "Gelatin Mix Density", mass: viewModel.densitySyringePlusGelatinMass, massLabel: "Syringe + mix", clean: viewModel.densitySyringeCleanGelatin, cleanLabel: "Syringe clean", vol: viewModel.densitySyringePlusGelatinVol, massRes: substrateRes, densityVal: valGelatinMixDensity, sf: sfGelatinMixDensity))
                sfRowFromInt("Sugar Mix", value: valSugarMixDensity, sf: sfSugarMixDensity, unit: "g/mL",
                             detail: densityDetail(label: "Sugar Mix Density", mass: viewModel.densitySyringePlusSugarMass, massLabel: "Syringe + mix", clean: viewModel.densitySyringeCleanSugar, cleanLabel: "Syringe clean", vol: viewModel.densitySyringePlusSugarVol, massRes: sugarRes, densityVal: valSugarMixDensity, sf: sfSugarMixDensity))
                sfRowFromInt("Activation Mix", value: valActivationMixDensity, sf: sfActivationMixDensity, unit: "g/mL",
                             detail: densityDetail(label: "Activation Mix Density", mass: viewModel.densitySyringePlusActiveMass, massLabel: "Syringe + mix", clean: viewModel.densitySyringeCleanActive, cleanLabel: "Syringe clean", vol: viewModel.densitySyringePlusActiveVol, massRes: activationRes, densityVal: valActivationMixDensity, sf: sfActivationMixDensity))
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRowFromInt("Gummy Mixture", value: valFinalMixDensity, sf: sfFinalMixDensity, unit: "g/mL", bold: true,
                             detail: densityDetail(label: "Final Mix Density", mass: viewModel.weightSyringeWithMix, massLabel: "Syringe + mix", clean: viewModel.weightSyringeEmpty, cleanLabel: "Syringe clean", vol: viewModel.volumeSyringeGummyMix, massRes: systemConfig.resolutionSyringeWithMix, densityVal: valFinalMixDensity, sf: sfFinalMixDensity))
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Losses
                sfSubheader("Losses")
                sfRow("Beaker Residue", info: sfBeakerResidue, unit: "g",
                      detail: subtractionDetail(label: "Beaker Residue", reading: viewModel.weightBeakerResidue, readingLabel: "Residue reading", tare: (viewModel.hpSubstrateBeakerID ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id).map { systemConfig.containerTare(for: $0) } ?? 0, tareLabel: "Container tare", res: systemConfig.resolutionBeakerResidue, result: sfBeakerResidue))
                sfRow("Activ. Tray Residue", info: sfActivationTrayResidue, unit: "g",
                      detail: subtractionDetail(label: "Activation Tray Residue", reading: viewModel.hpActivationTrayResidue, readingLabel: "Residue reading", tare: (viewModel.hpActivationTrayID ?? systemConfig.recommendedBeaker(forVolumeML: result.activationMix.totalVolumeML)?.id).map { systemConfig.containerTare(for: $0) } ?? 0, tareLabel: "Container tare", res: activationRes, result: sfActivationTrayResidue))
                sfRow("Syringe Residue", info: sfSyringeResidue, unit: "g",
                      detail: subtractionDetail(label: "Syringe Residue", reading: viewModel.weightSyringeResidue, readingLabel: "Residue reading", tare: (viewModel.hpTransferSyringeID ?? systemConfig.syringes.first?.id).map { systemConfig.syringeTare(for: $0) } ?? 0, tareLabel: "Syringe tare", res: systemConfig.resolutionSyringeResidue, result: sfSyringeResidue))
                sfRow("Tray Residue", info: sfTrayResidue, unit: "g",
                      detail: subtractionDetail(label: "Tray Residue", reading: viewModel.weightTrayPlusResidue, readingLabel: "Tray + residue reading", tare: (viewModel.hpMoldsTrayID ?? systemConfig.trays.first?.id).map { systemConfig.trayTare(for: $0) } ?? 0, tareLabel: "Tray tare", res: moldsRes, result: sfTrayResidue))
                sfRow("Extra Gummy Mix", info: sfExtraGummyMix, unit: "g",
                      detail: "Calculation: Extra Gummy Mixture\n\nThis is a user-entered value.\nSig figs are determined from the entered number's representation.\n\nValue: \(viewModel.extraGummyMixGrams.map { String(format: "%.3f", $0) } ?? "—") g\nSig Figs: \(sfExtraGummyMix?.sigFigs ?? 0)")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRowFromInt("Total Losses", value: valTotalLoss, sf: sfTotalLoss, unit: "g", bold: true,
                             detail: "Calculation: Total Losses\nOperation: Addition of all loss components\n\nComponents:\n  Beaker Residue: \(calcHPBeakerResidue.map { String(format: "%.3f", $0) } ?? "—") g  (\(sfBeakerResidue?.sigFigs ?? 0) SF)\n  Activ. Tray Residue: \(calcActivationTrayResidue.map { String(format: "%.3f", $0) } ?? "—") g  (\(sfActivationTrayResidue?.sigFigs ?? 0) SF)\n  Syringe Residue: \(calcSyringeResidue.map { String(format: "%.3f", $0) } ?? "—") g  (\(sfSyringeResidue?.sigFigs ?? 0) SF)\n  Tray Residue: \(calcTrayResidue.map { String(format: "%.3f", $0) } ?? "—") g  (\(sfTrayResidue?.sigFigs ?? 0) SF)\n  Extra Gummy Mix: \(viewModel.extraGummyMixGrams.map { String(format: "%.3f", $0) } ?? "—") g  (\(sfExtraGummyMix?.sigFigs ?? 0) SF)\n\nSig Fig Rule (Addition):\nResult DP = min(DP of all components)\n\nResult: \(valTotalLoss.map { String(format: "%.3f", $0) } ?? "—") g  (\(sfTotalLoss ?? 0) SF)")
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Active Lost
                sfSubheader("Active Lost")
                sfRow("Gummy Mixture Mass", info: sfGummyMixtureMass, unit: "g",
                      detail: subtractionDetail(label: "Gummy Mixture Mass", reading: viewModel.hpSubstrateActivationTransfer, readingLabel: "Transfer reading", tare: (viewModel.hpSubstrateBeakerID ?? systemConfig.recommendedBeaker(forVolumeML: result.gelatinMix.totalVolumeML + result.sugarMix.totalVolumeML)?.id).map { systemConfig.containerTare(for: $0) } ?? 0, tareLabel: "Container tare", res: transferRes, result: sfGummyMixtureMass))
                sfRow("Total Active", info: sfTotalActive, unit: viewModel.units.rawValue,
                      detail: "Calculation: Total Active Substance\nOperation: Multiplication\n\nFormula:\n  Total Active = Concentration x Total Gummies\n\n  Concentration = \(viewModel.activeConcentration) \(viewModel.units.rawValue)  (\(sfTotalActive?.sigFigs ?? 0) SF)\n  Total Gummies = \(viewModel.totalGummies(using: systemConfig))  (exact count, infinite SF)\n\nSig Fig Rule (Multiplication):\nMultiplying by an exact number does not reduce SF.\nResult inherits the SF of the concentration.\n\nResult: \(SigFigs.format(valTotalActive, sigFigs: sfTotalActive?.sigFigs ?? 1)) \(viewModel.units.rawValue)  (\(sfTotalActive?.sigFigs ?? 0) SF)")
                sfRowFromInt("Total Losses", value: valTotalLoss, sf: sfTotalLoss, unit: "g",
                             detail: "See Total Losses row in the Losses section above for full breakdown.")
                ThemedDivider(indent: 20).padding(.vertical, 4)
                sfRowFromInt("Active Lost", value: valActiveLost, sf: sfActiveLost, unit: viewModel.units.rawValue, bold: true,
                             detail: activeLostDetail())
                    .background(CMTheme.totalRowBG)

                ThemedDivider(indent: 20).padding(.vertical, 8)

                // MARK: Gummies
                sfSubheader("Gummies")
                sfRowFromInt("Volume", value: valExpGummyVolume, sf: sfExpGummyVolume, unit: "mL",
                             detail: gummyVolumeDetail())
                sfRowFromInt("Mass", value: valExpGummyMass, sf: sfExpGummyMass, unit: "g",
                             detail: gummyMassDetail())
                sfRowFromInt("Concentration", value: valExpGummyConcentration, sf: sfExpGummyConcentration, unit: viewModel.units.rawValue,
                             detail: "Calculation: Experimental Concentration per Gummy\nOperation: Same chain as Active Lost, divided by molds filled\n\nThis calculation follows the same sig fig propagation as Active Lost.\nResult SF = min(SF of total active, SF of total losses, SF of gummy mix mass)\n         = \(sfExpGummyConcentration ?? 0) SF\n\nResult: \(valExpGummyConcentration.map { val in sfExpGummyConcentration.map { sf in SigFigs.format(val, sigFigs: sf) } ?? "—" } ?? "—") \(viewModel.units.rawValue)")
                sfRowFromInt("Citric Acid", value: valExpCitricAcidFraction, sf: sfExpCitricAcidFraction, unit: "%",
                             detail: massFractionDetail(label: "Citric Acid", componentMass: viewModel.hpIndividualCitricAcid(systemConfig: systemConfig), componentSF: sfExpCitricAcid?.sigFigs, mixMass: valGummyMixtureMass, mixSF: sfGummyMixtureMass?.sigFigs, resultVal: valExpCitricAcidFraction, resultSF: sfExpCitricAcidFraction, unit: "%"))
                sfRowFromInt("K Sorbate", value: valExpKSorbateFraction, sf: sfExpKSorbateFraction, unit: "%",
                             detail: massFractionDetail(label: "K Sorbate", componentMass: viewModel.hpIndividualKSorbate, componentSF: sfExpKSorbate?.sigFigs, mixMass: valGummyMixtureMass, mixSF: sfGummyMixtureMass?.sigFigs, resultVal: valExpKSorbateFraction, resultSF: sfExpKSorbateFraction, unit: "%"))
                sfRowFromInt("Gelatin", value: valExpGelatinFraction, sf: sfExpGelatinFraction, unit: "%",
                             detail: massFractionDetail(label: "Gelatin", componentMass: viewModel.hpIndividualGelatin(systemConfig: systemConfig), componentSF: sfExpGelatin?.sigFigs, mixMass: valGummyMixtureMass, mixSF: sfGummyMixtureMass?.sigFigs, resultVal: valExpGelatinFraction, resultSF: sfExpGelatinFraction, unit: "%"))

                if !hasAnyData {
                    Text("Record high-precision weight measurements to populate sig fig analysis.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.top, 8)
                }

                Spacer().frame(height: 12)
            }
        }
        .onChange(of: viewModel.batchActivated) { _, activated in
            if !activated { withAnimation(.cmSpring) { isExpanded = false } }
        }
        .sheet(item: $activeDetail) { item in
            SFDetailSheet(title: item.title, detail: item.detail, accentColor: systemConfig.designTitle)
        }
    }

    private var hasAnyData: Bool {
        sfExpGelatin != nil || sfExpGranulated != nil || sfExpCitricAcid != nil
        || sfGelatinMixDensity != nil || sfSugarMixDensity != nil
        || sfActivationMixDensity != nil || sfFinalMixDensity != nil
    }

    // MARK: - Sub-views

    private func sfSubheader(_ title: String) -> some View {
        HStack {
            Text(title).cmSubsectionTitle()
            Spacer()
            Text("value")
                .cmFinePrint()
                .frame(width: valColWidth + unitColWidth, alignment: .trailing)
            Text("SF")
                .cmFinePrint()
                .frame(width: sfColWidth, alignment: .trailing)
            // Space for info button
            Color.clear.frame(width: 24, height: 1)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func sfRow(
        _ label: String,
        info: SigFigInfo?,
        unit: String,
        bold: Bool = false,
        detail: String
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()

            // Value rounded to significant figures
            Group {
                if let info = info {
                    Text(SigFigs.format(info.value, sigFigs: info.sigFigs))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: valColWidth, alignment: .trailing)

            // Unit
            Text(unit)
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: unitColWidth, alignment: .leading)

            // Sig figs count
            Group {
                if let info = info {
                    Text("\(info.sigFigs)")
                        .foregroundStyle(sfColor(info.sigFigs))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: sfColWidth, alignment: .trailing)

            // Info button
            infoButton(title: label, detail: detail, hasData: info != nil)
        }
        .cmDataRowPadding()
    }

    private func sfRowFromInt(
        _ label: String,
        value: Double? = nil,
        sf: Int?,
        unit: String,
        bold: Bool = false,
        detail: String
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .cmMono12()
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()

            // Value rounded to significant figures
            Group {
                if let sf = sf, let value = value {
                    Text(SigFigs.format(value, sigFigs: sf))
                        .foregroundStyle(CMTheme.textPrimary)
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: valColWidth, alignment: .trailing)

            // Unit
            Text(unit)
                .cmMono12()
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: unitColWidth, alignment: .leading)

            // Sig figs count
            Group {
                if let sf = sf {
                    Text("\(sf)")
                        .foregroundStyle(sfColor(sf))
                } else {
                    Text("—")
                        .foregroundStyle(CMTheme.textTertiary)
                }
            }
            .cmMono12()
            .fontWeight(bold ? .bold : .regular)
            .frame(width: sfColWidth, alignment: .trailing)

            // Info button
            infoButton(title: label, detail: detail, hasData: sf != nil)
        }
        .cmDataRowPadding()
    }

    private func infoButton(title: String, detail: String, hasData: Bool) -> some View {
        Button {
            CMHaptic.light()
            activeDetail = SFDetailItem(title: title, detail: detail)
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(hasData ? systemConfig.designTitle : CMTheme.textTertiary)
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24)
    }

    private func sfColor(_ sf: Int) -> Color {
        if sf >= 4 {
            return CMTheme.success
        } else if sf == 3 {
            return systemConfig.designSecondaryAccent
        } else {
            return systemConfig.designAlert
        }
    }
}

// MARK: - Detail Sheet

private struct SFDetailSheet: View {
    let title: String
    let detail: String
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(detail)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(accentColor)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
