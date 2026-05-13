import SwiftUI
import SwiftData

struct WeightMeasurementsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @State private var isExpanded: Bool = true

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            // Title header — tappable to collapse/expand
            Button {
                CMHaptic.light()
                withAnimation(.cmSpring) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Batch Measurements").font(.headline).foregroundStyle(systemConfig.accent)
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { viewModel.measurementsLocked.toggle() }
                    } label: {
                        Image(systemName: viewModel.measurementsLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(viewModel.measurementsLocked ? Color(red: 0.929, green: 0.278, blue: 0.290) : CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                        .animation(.cmExpand, value: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, isExpanded ? 2 : 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
            ThemedDivider()

            VStack(spacing: 0) {
                // MARK: Mixing Ingredients
                subsectionHeader("Mixing Ingredients")
                weightRow("Beaker (Empty)", value: $viewModel.weightBeakerEmpty, resolution: systemConfig.resolutionBeakerEmpty)
                weightRow("Beaker + Gelatin Mix", value: $viewModel.weightBeakerPlusGelatin, resolution: systemConfig.resolutionBeakerPlusGelatin)
                weightRow("Substrate + Sugar Mix", value: $viewModel.weightBeakerPlusSugar, resolution: systemConfig.resolutionBeakerPlusSugar)
                weightRow("Substrate + Activation Mix", value: $viewModel.weightBeakerPlusActive, resolution: systemConfig.resolutionBeakerPlusActive)

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
                weightRow("Extra Gummy Mix",            value: $viewModel.extraGummyMix_g,        resolution: .thousandthGram)

                // Fine print at bottom
                Text("The Substrate is defined as the primary beaker + all ingredients that have been added to the mixture.")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
            .disabled(viewModel.measurementsLocked)
            .opacity(viewModel.measurementsLocked ? 0.5 : 1.0)
            .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func weightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            OptionalNumericField(value: value, decimals: decimals)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 80)
            Text("g")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func volumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            OptionalNumericField(value: value, decimals: 3)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 80)
            Text("mL")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    /// Integer row — binds a Double? and formats with 0 decimal places
    private func intRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            OptionalNumericField(value: value, decimals: 0)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 80)
            Text("#")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
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
                        .foregroundStyle(systemConfig.accent)
                    // Lock button
                    Button {
                        CMHaptic.light()
                        withAnimation(.cmSpring) { isLocked.toggle() }
                    } label: {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isLocked ? Color(red: 0.929, green: 0.278, blue: 0.290) : CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                        .animation(.cmExpand, value: isExpanded)
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }

    private func weightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        return HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            OptionalNumericField(value: value, decimals: decimals)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 80)
            Text("g")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }

    private func volumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            OptionalNumericField(value: value, decimals: 3)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 80)
            Text("mL")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 2)
    }
}

// MARK: - Save Batch Sheet

struct SaveBatchSheet: View {
    @Binding var saveName: String
    @Binding var saveBatchID: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    // Batch ID field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Batch ID")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(CMTheme.textSecondary)
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
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(CMTheme.textSecondary)
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
                }
                .padding(.horizontal, 20).padding(.top, 24)

                Spacer()

                // Save button
                Button {
                    onSave()
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
                            .fill(systemConfig.accent)
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
            .preferredColorScheme(systemConfig.preferredColorScheme)
        }
    }
}
