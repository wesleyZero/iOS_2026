import SwiftUI
import SwiftData
import Charts

// MARK: - Shared JSON Copy Utility

/// Copies a dictionary as formatted JSON to the system pasteboard and triggers the confirmation banner.
func batchDetailCopyJSON(_ dict: [String: Any], copiedConfirmation: Binding<Bool>) {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
          let str = String(data: data, encoding: .utf8) else { return }
    CMClipboard.copy(str)
    CMHaptic.success()
    copiedConfirmation.wrappedValue = true
    Task {
        try? await Task.sleep(for: .seconds(2))
        copiedConfirmation.wrappedValue = false
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Quantitative Data Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchQuantitativeDataSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }

        let activeTotalMass   = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let activeTotalVol    = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gelatinTotalMass  = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gelatinTotalVol   = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sugarTotalMass    = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sugarTotalVol     = sugarItems.reduce(0.0) { $0 + $1.volume_mL }

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        let overageFactor    = batch.vBase_mL > 0 ? batch.vMix_mL / batch.vBase_mL : 1.0
        let targetVol        = batch.vBase_mL
        let volPerMold       = batch.wellCount > 0 ? targetVol / Double(batch.wellCount) : 0
        let volPerTray       = batch.trayCount > 0 ? targetVol / Double(batch.trayCount) : 0

        let finalMixVolNoOverage = overageFactor > 0 ? finalMixVol / overageFactor : finalMixVol
        let quantifiedError      = finalMixVolNoOverage - targetVol
        let relativeError        = targetVol > 0 ? (quantifiedError / targetVol) * 100.0 : 0.0

        VStack(spacing: 0) {
            HStack {
                Text("Quantitative Data").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { batchDetailCopyJSON(quantitativeDataJSON(), copiedConfirmation: $copiedConfirmation) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    validationSubheader("Target Volumes")
                    validationVolOnlyRow("Volume Per Mold", volume: volPerMold)
                    validationVolOnlyRow("Volume Per Tray", volume: volPerTray)
                    validationVolOnlyRow("Total Volume",    volume: targetVol, bold: true)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Active Mix Components")
                    validationComponentRows(activationItems)
                    validationTotalRow(mass: activeTotalMass, volume: activeTotalVol)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Gelatin Mix Components")
                    validationComponentRows(gelatinItems)
                    validationTotalRow(mass: gelatinTotalMass, volume: gelatinTotalVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Sugar Mix Components")
                    validationComponentRows(sugarItems)
                    validationTotalRow(mass: sugarTotalMass, volume: sugarTotalVol)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Input Mixtures")
                    validationCompRow("Active Mix",  mass: activeTotalMass,  volume: activeTotalVol)
                    validationCompRow("Gelatin Mix", mass: gelatinTotalMass, volume: gelatinTotalVol)
                    validationCompRow("Sugar Mix",   mass: sugarTotalMass,   volume: sugarTotalVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Final Mixture")
                    validationCompRow("Final Mix (with overage)",    mass: finalMixMass,                        volume: finalMixVol)
                    validationCompRow("Final Mix (without overage)", mass: finalMixMass / overageFactor,         volume: finalMixVolNoOverage, bold: true)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    validationSubheader("Error")
                    validationErrorRow("Quantified Error",
                                       value: String(format: "%+.3f mL", quantifiedError),
                                       highlight: abs(quantifiedError))
                    validationErrorRow("Relative Error",
                                       value: String(format: "%+.3f%%", relativeError),
                                       highlight: abs(relativeError))

                    Spacer().frame(height: 12)
                }
        }
    }

    // MARK: - Helpers

    private func validationSubheader(_ title: String) -> some View {
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
    private func validationComponentRows(_ items: [SavedBatchComponent]) -> some View {
        ForEach(items.indices, id: \.self) { i in
            HStack {
                Text(items[i].label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", items[i].mass_g))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", items[i].volume_mL))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func validationTotalRow(mass: Double, volume: Double) -> some View {
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

    private func validationCompRow(_ label: String, mass: Double, volume: Double, bold: Bool = false) -> some View {
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

    private func validationVolOnlyRow(_ label: String, volume: Double, bold: Bool = false) -> some View {
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

    private func validationErrorRow(_ label: String, value: String, highlight: Double) -> some View {
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

    // MARK: - JSON

    private func quantitativeDataJSON() -> [String: Any] {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }
        let aTM = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let aTV = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gTM = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gTV = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sTM = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sTV = sugarItems.reduce(0.0) { $0 + $1.volume_mL }
        let fMM = aTM + gTM + sTM; let fMV = aTV + gTV + sTV
        let of = batch.vBase_mL > 0 ? batch.vMix_mL / batch.vBase_mL : 1.0
        let tv = batch.vBase_mL
        let fMVno = of > 0 ? fMV / of : fMV
        let qErr = fMVno - tv
        let rErr = tv > 0 ? (qErr / tv) * 100.0 : 0.0
        return [
            "targetVolumes": ["volumePerMold_mL": batch.wellCount > 0 ? tv / Double(batch.wellCount) : 0, "volumePerTray_mL": batch.trayCount > 0 ? tv / Double(batch.trayCount) : 0, "totalTargetVolume_mL": tv],
            "mixTotals": ["activationMix": ["mass_g": aTM, "volume_mL": aTV], "gelatinMix": ["mass_g": gTM, "volume_mL": gTV], "sugarMix": ["mass_g": sTM, "volume_mL": sTV]],
            "finalMix": ["withOverage": ["mass_g": fMM, "volume_mL": fMV], "withoutOverage": ["mass_g": fMM / of, "volume_mL": fMVno]],
            "error": ["quantifiedError_mL": qErr, "relativeErrorPct": rErr],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Relative Data Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchRelativeDataSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }

        let activeTotalMass   = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let activeTotalVol    = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gelatinTotalMass  = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gelatinTotalVol   = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sugarTotalMass    = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sugarTotalVol     = sugarItems.reduce(0.0) { $0 + $1.volume_mL }

        let finalMixMass = activeTotalMass + gelatinTotalMass + sugarTotalMass
        let finalMixVol  = activeTotalVol  + gelatinTotalVol  + sugarTotalVol

        VStack(spacing: 0) {
            HStack {
                Text("Relative Data").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { batchDetailCopyJSON(relativeDataJSON(), copiedConfirmation: $copiedConfirmation) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ThemedDivider(indent: 16)

                VStack(spacing: 0) {
                    relativeSubheader("Active Mix Components")
                    relativeComponentRows(activationItems, totalMass: finalMixMass, totalVol: finalMixVol)
                    relativeTotalRow(mass: activeTotalMass, volume: activeTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Gelatin Mix Components")
                    relativeComponentRows(gelatinItems, totalMass: finalMixMass, totalVol: finalMixVol)
                    relativeTotalRow(mass: gelatinTotalMass, volume: gelatinTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Sugar Mix Components")
                    relativeComponentRows(sugarItems, totalMass: finalMixMass, totalVol: finalMixVol)
                    relativeTotalRow(mass: sugarTotalMass, volume: sugarTotalVol, totalMass: finalMixMass, totalVol: finalMixVol)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Input Mixtures")
                    relativeRow("Active Mix",  massPct: pct(activeTotalMass, of: finalMixMass),  volPct: pct(activeTotalVol, of: finalMixVol))
                    relativeRow("Gelatin Mix", massPct: pct(gelatinTotalMass, of: finalMixMass), volPct: pct(gelatinTotalVol, of: finalMixVol))
                    relativeRow("Sugar Mix",   massPct: pct(sugarTotalMass, of: finalMixMass),   volPct: pct(sugarTotalVol, of: finalMixVol))
                }

                VStack(spacing: 0) {
                    ThemedDivider(indent: 16).padding(.top, 8)

                    relativeSubheader("Final Mixture")
                    relativeRow("Final Mix", massPct: 100.0, volPct: 100.0, bold: true)

                    ThemedDivider(indent: 16).padding(.top, 8)

                    customMetricsSubheader("Custom Metrics")
                    relativeRow("Goop Ratio",
                                massPct: gelatinTotalMass > 0 ? sugarTotalMass / gelatinTotalMass : 0,
                                volPct: gelatinTotalVol > 0 ? sugarTotalVol / gelatinTotalVol : 0)
                    Text("The goop ratio is defined as the total sugar mixture divided by the total gelatin mixture (water included in each mixture), in mass and volume units.")
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 16).padding(.top, 6)

                    Spacer().frame(height: 12)
                }
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

    private func relativeSubheader(_ title: String) -> some View {
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
    private func relativeComponentRows(_ items: [SavedBatchComponent], totalMass: Double, totalVol: Double) -> some View {
        ForEach(items.indices, id: \.self) { i in
            HStack {
                Text(items[i].label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(String(format: "%.3f", pct(items[i].mass_g, of: totalMass)))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
                Text(String(format: "%.3f", pct(items[i].volume_mL, of: totalVol)))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(CMTheme.textSecondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.vertical, 2)
        }
    }

    private func relativeTotalRow(mass: Double, volume: Double, totalMass: Double, totalVol: Double) -> some View {
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

    private func relativeRow(_ label: String, massPct: Double, volPct: Double, bold: Bool = false) -> some View {
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

    // MARK: - JSON

    private func relativeDataJSON() -> [String: Any] {
        let activationItems = sortedComponents.filter { $0.group == "Activation Mix" }
        let gelatinItems    = sortedComponents.filter { $0.group == "Gelatin Mix" }
        let sugarItems      = sortedComponents.filter { $0.group == "Sugar Mix" }
        let aTM = activationItems.reduce(0.0) { $0 + $1.mass_g }
        let aTV = activationItems.reduce(0.0) { $0 + $1.volume_mL }
        let gTM = gelatinItems.reduce(0.0) { $0 + $1.mass_g }
        let gTV = gelatinItems.reduce(0.0) { $0 + $1.volume_mL }
        let sTM = sugarItems.reduce(0.0) { $0 + $1.mass_g }
        let sTV = sugarItems.reduce(0.0) { $0 + $1.volume_mL }
        let fMM = aTM + gTM + sTM; let fMV = aTV + gTV + sTV
        func p(_ part: Double, _ whole: Double) -> Double { whole > 0 ? (part / whole) * 100.0 : 0 }
        return [
            "components": sortedComponents.map { ["label": $0.label, "group": $0.group, "massPct": p($0.mass_g, fMM), "volumePct": p($0.volume_mL, fMV)] as [String: Any] },
            "mixTotals": ["activationMix": ["massPct": p(aTM, fMM), "volumePct": p(aTV, fMV)], "gelatinMix": ["massPct": p(gTM, fMM), "volumePct": p(gTV, fMV)], "sugarMix": ["massPct": p(sTM, fMM), "volumePct": p(sTV, fMV)]],
            "goopRatio": ["mass": gTM > 0 ? sTM / gTM : 0, "volume": gTV > 0 ? sTV / gTV : 0],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Measurements Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchMeasurementsSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Measurements").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { batchDetailCopyJSON(measurementsJSON(), copiedConfirmation: $copiedConfirmation) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            VStack(spacing: 0) {
                measureSubsection("Initial mass of container")
                savedWeightRow("Beaker (Empty)",          value: batch.weightBeakerEmpty)

                measureSubsection("Add gelatin mixture")
                savedWeightRow("Beaker + Gelatin Mix",    value: batch.weightBeakerPlusGelatin)

                measureSubsection("Add sugar mixture")
                savedWeightRow("Substrate + Sugar Mix",   value: batch.weightBeakerPlusSugar)

                measureSubsection("Add activation mixture")
                savedWeightRow("Substrate + Activation Mix", value: batch.weightBeakerPlusActive)
            }

            VStack(spacing: 0) {
                measureSubsection("Transfer to mold")
                savedWeightRow("Syringe (Clean)",         value: batch.weightSyringeEmpty)
                savedWeightRow("Syringe + Gummy Mix",     value: batch.weightSyringeWithMix)
                savedVolumeRow("Syringe Gummy Mix Vol",   value: batch.volumeSyringeGummyMix)
                savedWeightRow("Syringe + Residue",       value: batch.weightSyringeResidue)
                savedWeightRow("Beaker + Residue",        value: batch.weightBeakerResidue)
                savedMoldsRow("Molds Filled",             value: batch.weightMoldsFilled)
            }

            VStack(spacing: 0) {
                measureSubsection("Mixture Densities — Sugar Mix")
                savedWeightRow("Syringe (Clean)",         value: batch.densitySyringeCleanSugar)
                savedWeightRow("Syringe + Sugar Mix",     value: batch.densitySyringePlusSugarMass)
                savedVolumeRow("Syringe + Sugar Mix Vol",  value: batch.densitySyringePlusSugarVol)

                measureSubsection("Mixture Densities — Gelatin Mix")
                savedWeightRow("Syringe (Clean)",         value: batch.densitySyringeCleanGelatin)
                savedWeightRow("Syringe + Gelatin Mix",   value: batch.densitySyringePlusGelatinMass)
                savedVolumeRow("Syringe + Gelatin Mix Vol", value: batch.densitySyringePlusGelatinVol)
            }

            VStack(spacing: 0) {
                measureSubsection("Mixture Densities — Activation Mix")
                savedWeightRow("Syringe (Clean)",         value: batch.densitySyringeCleanActive)
                savedWeightRow("Syringe + Activation Mix", value: batch.densitySyringePlusActiveMass)
                savedVolumeRow("Syringe + Activation Mix Vol", value: batch.densitySyringePlusActiveVol)
            }

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Helpers

    private func measureSubsection(_ title: String) -> some View {
        HStack {
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 2)
    }

    private func savedWeightRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("g").font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedVolumeRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("mL").font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    private func savedMoldsRow(_ label: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textSecondary)
                .frame(width: 70, alignment: .trailing)
            Text("#").font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    // MARK: - JSON

    private func measurementsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "initialMass": ["beakerEmpty": opt(batch.weightBeakerEmpty)],
            "gelatinMixture": ["beakerPlusGelatin": opt(batch.weightBeakerPlusGelatin)],
            "sugarMixture": ["substratePlusSugar": opt(batch.weightBeakerPlusSugar)],
            "activationMixture": ["substratePlusActivation": opt(batch.weightBeakerPlusActive)],
            "transferToMold": ["syringeClean": opt(batch.weightSyringeEmpty), "syringePlusMix": opt(batch.weightSyringeWithMix), "syringeMixVol_mL": opt(batch.volumeSyringeGummyMix), "syringeResidue": opt(batch.weightSyringeResidue), "beakerResidue": opt(batch.weightBeakerResidue), "moldsFilled": opt(batch.weightMoldsFilled)],
            "densities": [
                "sugarMix": ["syringeClean": opt(batch.densitySyringeCleanSugar), "syringePlusMass": opt(batch.densitySyringePlusSugarMass), "syringePlusVol": opt(batch.densitySyringePlusSugarVol)],
                "gelatinMix": ["syringeClean": opt(batch.densitySyringeCleanGelatin), "syringePlusMass": opt(batch.densitySyringePlusGelatinMass), "syringePlusVol": opt(batch.densitySyringePlusGelatinVol)],
                "activationMix": ["syringeClean": opt(batch.densitySyringeCleanActive), "syringePlusMass": opt(batch.densitySyringePlusActiveMass), "syringePlusVol": opt(batch.densitySyringePlusActiveVol)],
            ],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Calculations Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchCalculationsSection: View {
    var batch: SavedBatch
    @Binding var copiedConfirmation: Bool

    private var savedOverageForNextBatch: Double? {
        guard let avgVol = batch.calcAverageGummyVolume,
              batch.wellCount > 0,
              batch.vBase_mL > 0 else { return nil }
        let volPerWell = batch.vBase_mL / Double(batch.wellCount)
        return avgVol / volPerWell
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Calculations").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { batchDetailCopyJSON(calculationsJSON(), copiedConfirmation: $copiedConfirmation) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            VStack(spacing: 0) {
                measureSubsection("Input Mixtures")
                savedCalcRow("Gelatin Mix Added",         value: batch.calcMassGelatinAdded,         unit: "g")
                savedCalcRow("Sugar Mix Added",           value: batch.calcMassSugarAdded,           unit: "g")
                savedCalcRow("Activation Mix Added",      value: batch.calcMassActiveAdded,          unit: "g")

                measureSubsection("Final Mixture")
                savedCalcRow("Final Mixture in Beaker",   value: batch.calcMassFinalMixtureInBeaker, unit: "g")
                savedCalcRow("Final Mixture in Tray/s",   value: batch.calcMassMixTransferredToMold, unit: "g")

                measureSubsection("Losses")
                savedCalcRow("Beaker Residue",            value: batch.calcMassBeakerResidue,        unit: "g")
            }

            VStack(spacing: 0) {
                savedCalcRow("Syringe Residue",           value: batch.calcMassSyringeResidue,       unit: "g")
                savedCalcRow("Total Residue",             value: batch.calcMassTotalLoss,            unit: "g")
                savedCalcRow("Lost \(batch.activeName) in Residue", value: batch.calcActiveLoss, unit: batch.activeUnit)

                measureSubsection("Mixture Densities")
                savedCalcRow("Sugar Mix Density",         value: batch.calcSugarMixDensity,          unit: "g/mL", decimals: 4)
                savedCalcRow("Gelatin Mix Density",       value: batch.calcGelatinMixDensity,        unit: "g/mL", decimals: 4)
                savedCalcRow("Activation Mix Density",    value: batch.calcActiveMixDensity,         unit: "g/mL", decimals: 4)
                savedCalcRow("Gummy Mixture Density",     value: batch.calcDensityFinalMix,          unit: "g/mL", decimals: 4)
            }

            VStack(spacing: 0) {
                measureSubsection("Gummies")
                savedCalcRow("Average Gummy Mass",        value: batch.calcMassPerGummyMold,         unit: "g")
                savedCalcRow("Average Gummy Volume",      value: batch.calcAverageGummyVolume,       unit: "mL", decimals: 3)
                savedCalcRow("Avg Gummy Active Dose",     value: batch.calcAverageGummyActiveDose,   unit: batch.activeUnit)

                measureSubsection("Overage")
                savedCalcRow("Overage for Next Batch",     value: savedOverageForNextBatch, unit: "", decimals: 4)
            }

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Helpers

    private func measureSubsection(_ title: String) -> some View {
        HStack {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func savedCalcRow(_ label: String, value: Double?, unit: String, decimals: Int = 3) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Text(value.map { String(format: "%.\(decimals)f", $0) } ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(value == nil ? CMTheme.textTertiary : CMTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(unit)
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 3)
    }

    // MARK: - JSON

    private func calculationsJSON() -> [String: Any] {
        func opt(_ v: Double?) -> Any { v as Any }
        return [
            "inputMixtures": ["gelatinMixAdded": opt(batch.calcMassGelatinAdded), "sugarMixAdded": opt(batch.calcMassSugarAdded), "activationMixAdded": opt(batch.calcMassActiveAdded)],
            "finalMixture": ["inBeaker": opt(batch.calcMassFinalMixtureInBeaker), "inTrays": opt(batch.calcMassMixTransferredToMold)],
            "losses": ["beakerResidue": opt(batch.calcMassBeakerResidue), "syringeResidue": opt(batch.calcMassSyringeResidue), "totalResidue": opt(batch.calcMassTotalLoss), "lostActive": opt(batch.calcActiveLoss)],
            "densities": ["sugarMix": opt(batch.calcSugarMixDensity), "gelatinMix": opt(batch.calcGelatinMixDensity), "activationMix": opt(batch.calcActiveMixDensity), "gummyMixture": opt(batch.calcDensityFinalMix)],
            "gummies": ["avgMass_g": opt(batch.calcMassPerGummyMold), "avgVolume_mL": opt(batch.calcAverageGummyVolume), "avgActiveDose": opt(batch.calcAverageGummyActiveDose)],
            "overage": ["overageForNextBatch": opt(savedOverageForNextBatch)],
        ] as [String: Any]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Dry Weight / Dehydration Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchDryWeightSection: View {
    @Bindable var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Environment(SystemConfig.self) private var systemConfig

    @State private var newDryMass: String = ""

    private var sortedComponents: [SavedBatchComponent] {
        batch.components.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var dryWeightEntries: [DryWeightReading] {
        batch.dryWeightReadings.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Dehydration Calculations

    private var wetMass: Double? {
        if let m = batch.wetGummyMass_g { return m }
        if let m = batch.calcMassMixTransferredToMold { return m }
        let total = sortedComponents.reduce(0.0) { $0 + $1.mass_g }
        return total > 0 ? total : nil
    }

    private var theoreticalTotalMass: Double {
        sortedComponents.reduce(0.0) { $0 + $1.mass_g }
    }

    private var formulationWaterMass: Double? {
        let waterComponents = sortedComponents.filter {
            $0.label == "Water" || $0.label == "Activation Water"
        }
        guard !waterComponents.isEmpty else { return nil }
        return waterComponents.reduce(0.0) { $0 + $1.mass_g }
    }

    private var waterMassFraction: Double? {
        guard let totalWater = formulationWaterMass else { return nil }
        let totalMix = batch.calcMassFinalMixtureInBeaker ?? theoreticalTotalMass
        guard totalMix > 0 else { return nil }
        return totalWater / totalMix
    }

    private var originalWaterInGummies: Double? {
        guard let wet = wetMass, let fraction = waterMassFraction else { return nil }
        return wet * fraction
    }

    private func waterMassPercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        guard waterMass >= 0 else { return nil }
        return (waterMass / wet) * 100.0
    }

    private var estimatedDensity: Double {
        let totalMass = sortedComponents.reduce(0.0) { $0 + $1.mass_g }
        let totalVol = sortedComponents.reduce(0.0) { $0 + $1.volume_mL }
        return totalVol > 0 ? totalMass / totalVol : 1.0
    }

    private func waterVolumePercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, wet > 0 else { return nil }
        let waterMass = wet - dryMass
        guard waterMass >= 0 else { return nil }
        let density = batch.calcDensityFinalMix ?? estimatedDensity
        guard density > 0 else { return nil }
        let totalVol = wet / density
        let waterVol = waterMass / 1.0
        return (waterVol / totalVol) * 100.0
    }

    private func dehydrationPercent(dryMass: Double) -> Double? {
        guard let wet = wetMass, let origWater = originalWaterInGummies, origWater > 0 else { return nil }
        let massRemoved = wet - dryMass
        guard massRemoved >= 0 else { return nil }
        return (massRemoved / origWater) * 100.0
    }

    private var avgDehydrationRate: Double? {
        let entries = dryWeightEntries
        guard entries.count >= 2,
              let wet = wetMass, wet > 0,
              let origWater = originalWaterInGummies, origWater > 0 else { return nil }
        let first = entries.first!
        let last = entries.last!
        let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600.0
        guard hours > 0 else { return nil }
        let dehydFirst = ((wet - first.mass_g) / origWater) * 100.0
        let dehydLast  = ((wet - last.mass_g)  / origWater) * 100.0
        return (dehydLast - dehydFirst) / hours
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Dehydration Tracking").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { batchDetailCopyJSON(dehydrationJSON(), copiedConfirmation: $copiedConfirmation) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // Add new reading
            HStack(spacing: 8) {
                TextField("Dry mass (g)", text: $newDryMass)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                    .padding(10)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(CMTheme.fieldRadius)
                Button("Record") {
                    if let mass = Double(newDryMass), mass > 0 {
                        CMHaptic.success()
                        withAnimation(.cmSpring) {
                            batch.dryWeightReadings.append(
                                DryWeightReading(mass_g: mass, timestamp: .now)
                            )
                        }
                        newDryMass = ""
                    }
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(systemConfig.accent)
                .cornerRadius(CMTheme.buttonRadius)
                .disabled(Double(newDryMass) == nil)
                .opacity(Double(newDryMass) == nil ? 0.4 : 1.0)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            // Recorded entries table with per-entry water content
            if !dryWeightEntries.isEmpty {
                ThemedDivider(indent: 16)
                HStack(spacing: 4) {
                    Text("Hrs Elapsed").font(.caption2).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    Text("Mass").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 55, alignment: .trailing)
                    Text("Mass%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 62, alignment: .trailing)
                    Text("Vol%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 58, alignment: .trailing)
                    Text("Dehyd%").font(.caption2).foregroundStyle(CMTheme.textTertiary).frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 2)

                ForEach(dryWeightEntries.indices, id: \.self) { i in
                    let entry = dryWeightEntries[i]
                    let hoursElapsed = dryWeightEntries.first.map { entry.timestamp.timeIntervalSince($0.timestamp) / 3600.0 } ?? 0
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f hrs", hoursElapsed))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text(String(format: "%.3f g", entry.mass_g))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                            .frame(width: 55, alignment: .trailing)
                        Text(waterMassPercent(dryMass: entry.mass_g).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 62, alignment: .trailing)
                        Text(waterVolumePercent(dryMass: entry.mass_g).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 58, alignment: .trailing)
                        Text(dehydrationPercent(dryMass: entry.mass_g).map { String(format: "%.1f%%", $0) } ?? "—")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 3)
                }

                // Avg dehydration rate
                if let rate = avgDehydrationRate {
                    ThemedDivider(indent: 16).padding(.top, 4)
                    HStack {
                        Text("Avg dehydration rate")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text(String(format: "%.3f %%/hr", rate))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                }

                // Dehydration chart
                if dryWeightEntries.count >= 2 {
                    dehydrationChart
                }
            }

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Dehydration Chart

    private var dehydrationChart: some View {
        let entries = dryWeightEntries
        let firstTimestamp = entries.first!.timestamp

        struct ChartPoint: Identifiable {
            let id = UUID()
            let hours: Double
            let massPercent: Double
            let dehydPercent: Double
        }

        let points: [ChartPoint] = entries.compactMap { entry in
            let hrs = entry.timestamp.timeIntervalSince(firstTimestamp) / 3600.0
            guard let mp = waterMassPercent(dryMass: entry.mass_g),
                  let dp = dehydrationPercent(dryMass: entry.mass_g) else { return nil }
            return ChartPoint(hours: hrs, massPercent: mp, dehydPercent: dp)
        }

        return VStack(spacing: 4) {
            ThemedDivider(indent: 16).padding(.top, 4)
            Chart {
                ForEach(points) { pt in
                    LineMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Mass %", pt.massPercent),
                        series: .value("Series", "Mass %")
                    )
                    .foregroundStyle(systemConfig.accent)
                    .symbol(Circle())
                    .symbolSize(20)

                    PointMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Mass %", pt.massPercent)
                    )
                    .foregroundStyle(systemConfig.accent)
                    .symbolSize(20)
                }

                ForEach(points) { pt in
                    LineMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Dehyd %", pt.dehydPercent),
                        series: .value("Series", "Dehyd %")
                    )
                    .foregroundStyle(CMTheme.danger)
                    .symbol(Circle())
                    .symbolSize(20)

                    PointMark(
                        x: .value("Hours", pt.hours),
                        y: .value("Dehyd %", pt.dehydPercent)
                    )
                    .foregroundStyle(CMTheme.danger)
                    .symbolSize(20)
                }
            }
            .chartXAxisLabel("Hours", alignment: .center)
            .chartYAxisLabel("%")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisGridLine().foregroundStyle(CMTheme.divider)
                    AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisGridLine().foregroundStyle(CMTheme.divider)
                    AxisValueLabel().foregroundStyle(CMTheme.textTertiary)
                }
            }
            .chartForegroundStyleScale([
                "Mass %": systemConfig.accent,
                "Dehyd %": CMTheme.danger
            ])
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 160)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    private func entryTimestampString(_ date: Date) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let day = cal.component(.day, from: date)
        let year = cal.component(.year, from: date)
        let monthName = date.formatted(.dateTime.month(.wide))
        return String(format: "%02d:%02d, %@ %d, %d", h, m, monthName, day, year)
    }

    // MARK: - JSON

    private func dehydrationJSON() -> [String: Any] {
        let isoFmt = ISO8601DateFormatter()
        var obj: [String: Any] = [
            "readings": dryWeightEntries.map { e in
                var d: [String: Any] = ["timestamp": isoFmt.string(from: e.timestamp), "mass_g": e.mass_g]
                if let wm = waterMassPercent(dryMass: e.mass_g) { d["waterMassPct"] = wm }
                if let wv = waterVolumePercent(dryMass: e.mass_g) { d["waterVolPct"] = wv }
                if let dp = dehydrationPercent(dryMass: e.mass_g) { d["dehydrationPct"] = dp }
                return d
            }
        ]
        if let rate = avgDehydrationRate { obj["avgDehydrationRatePctPerHr"] = rate }
        return obj
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Notes & Ratings Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BatchNotesAndRatingsSection: View {
    @Bindable var batch: SavedBatch
    @Binding var copiedConfirmation: Bool
    @Environment(SystemConfig.self) private var systemConfig

    private static let flavorTagOptions = ["Too sweet", "Harsh", "Chemical", "Gross", "Unsweet", "Incredible", "Sour", "Bad combo"]
    private static let appearanceTagOptions = ["Bubbles", "Smooth", "Waxy", "Opaque", "Misshapen", "Clear", "Ideal"]
    private static let textureTagOptions = ["Goopy", "Jell-O", "Rubber", "Snappy", "Soft", "Ideal", "Too hard"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Notes & Ratings").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
                GlassCopyButton { batchDetailCopyJSON(notesAndRatingsJSON(), copiedConfirmation: $copiedConfirmation) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            VStack(spacing: 0) {
                sectionHeader("Flavor Tags")
                tagRow(options: Self.flavorTagOptions, selection: $batch.flavorTags)
                sectionHeader("Flavor Notes")
                TextEditor(text: $batch.flavorNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(CMTheme.textPrimary)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(8)
                    .padding(.horizontal, 16).padding(.bottom, 10)
                sectionHeader("Flavor Rating")
                ratingField(value: $batch.flavorRating)
                ThemedDivider(indent: 16)
            }

            VStack(spacing: 0) {
                sectionHeader("Appearance Tags")
                tagRow(options: Self.appearanceTagOptions, selection: $batch.colorTags)
                sectionHeader("Appearance Notes")
                TextEditor(text: $batch.colorNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(CMTheme.textPrimary)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(8)
                    .padding(.horizontal, 16).padding(.bottom, 10)
                sectionHeader("Appearance Rating")
                ratingField(value: $batch.colorRating)
                ThemedDivider(indent: 16)
            }

            VStack(spacing: 0) {
                sectionHeader("Texture Tags")
                tagRow(options: Self.textureTagOptions, selection: $batch.textureTags)
                sectionHeader("Texture Notes")
                TextEditor(text: $batch.textureNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(CMTheme.textPrimary)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(8)
                    .padding(.horizontal, 16).padding(.bottom, 10)
                sectionHeader("Texture Rating")
                ratingField(value: $batch.textureRating)
                ThemedDivider(indent: 16)
            }

            VStack(spacing: 0) {
                sectionHeader("Process Notes")
                TextEditor(text: $batch.processNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(CMTheme.textPrimary)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(CMTheme.fieldBG)
                    .cornerRadius(8)
                    .padding(.horizontal, 16).padding(.bottom, 10)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)
    }

    private func tagRow(options: [String], selection: Binding<String>) -> some View {
        let selected = Set(selection.wrappedValue.split(separator: ",").map { String($0) })
        let columns = [GridItem(.adaptive(minimum: 70))]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { tag in
                let isSelected = selected.contains(tag)
                Button {
                    CMHaptic.light()
                    var tags = selected
                    if isSelected { tags.remove(tag) } else { tags.insert(tag) }
                    withAnimation(.cmSpring) {
                        selection.wrappedValue = tags.sorted().joined(separator: ",")
                    }
                } label: {
                    Text(tag)
                        .font(.caption).lineLimit(1)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                                .fill(isSelected ? systemConfig.accent.opacity(0.25) : CMTheme.chipBG)
                        )
                        .foregroundStyle(isSelected ? systemConfig.accent : CMTheme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                                .stroke(isSelected ? systemConfig.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                        .animation(.cmSpring, value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
    }

    private func ratingField(value: Binding<Int>) -> some View {
        HStack {
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.leading)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 50)
                .selectAllOnFocus()
                .padding(8)
                .background(CMTheme.fieldBG)
                .cornerRadius(CMTheme.fieldRadius)
                .onChange(of: value.wrappedValue) { _, newVal in
                    value.wrappedValue = min(max(newVal, 0), 100)
                }
            Text("/ 100")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    // MARK: - JSON

    private func notesAndRatingsJSON() -> [String: Any] {
        func tagsArr(_ s: String) -> [String] { s.isEmpty ? [] : s.split(separator: ",").map { String($0) } }
        return [
            "flavor": ["rating": batch.flavorRating, "tags": tagsArr(batch.flavorTags), "notes": batch.flavorNotes] as [String: Any],
            "color": ["rating": batch.colorRating, "tags": tagsArr(batch.colorTags), "notes": batch.colorNotes] as [String: Any],
            "texture": ["rating": batch.textureRating, "tags": tagsArr(batch.textureTags), "notes": batch.textureNotes] as [String: Any],
            "processNotes": batch.processNotes,
        ] as [String: Any]
    }
}
