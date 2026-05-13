import SwiftUI
import SwiftData

struct WeightMeasurementsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.modelContext) private var modelContext

    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var saveBatchID = ""
    @State private var savedConfirmation = false

    var body: some View {
        @Bindable var viewModel = viewModel
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)

        VStack(spacing: 0) {
            // Title header
            HStack {
                Text("Measurements").font(.headline).foregroundStyle(CMTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 2)

            Text("The Substrate is defined as the primary beaker + all ingredients that have been added to the mixture.")
                .font(.caption)
                .foregroundStyle(CMTheme.textTertiary)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            ThemedDivider()

            // MARK: Initial mass of container
            subsectionHeader("Initial mass of container")
            weightRow("Beaker (Empty)", value: $viewModel.weightBeakerEmpty, resolution: systemConfig.resolutionBeakerEmpty)

            ThemedDivider(indent: 16).padding(.top, 8)

            // MARK: Add gelatin mixture
            subsectionHeader("Add gelatin mixture")
            weightRow("Beaker + Gelatin Mix", value: $viewModel.weightBeakerPlusGelatin, resolution: systemConfig.resolutionBeakerPlusGelatin)

            ThemedDivider(indent: 16).padding(.top, 8)

            // MARK: Add sugar mixture
            subsectionHeader("Add sugar mixture")
            weightRow("Substrate + Sugar Mix", value: $viewModel.weightBeakerPlusSugar, resolution: systemConfig.resolutionBeakerPlusSugar)

            ThemedDivider(indent: 16).padding(.top, 8)

            // MARK: Add activation mixture
            subsectionHeader("Add activation mixture")
            weightRow("Substrate + Activation Mix", value: $viewModel.weightBeakerPlusActive, resolution: systemConfig.resolutionBeakerPlusActive)

            ThemedDivider(indent: 16).padding(.top, 8)

            // MARK: Transfer to mold
            subsectionHeader("Transfer to mold")
            weightRow("Syringe (Clean)",            value: $viewModel.weightSyringeEmpty,     resolution: systemConfig.resolutionSyringeEmpty)
            weightRow("Syringe + Gummy Mix",        value: $viewModel.weightSyringeWithMix,   resolution: systemConfig.resolutionSyringeWithMix)
            volumeRow("Syringe + Gummy Mix",        value: $viewModel.volumeSyringeGummyMix)
            weightRow("Syringe + Residue",          value: $viewModel.weightSyringeResidue,   resolution: systemConfig.resolutionSyringeResidue)
            weightRow("Beaker + Residue",           value: $viewModel.weightBeakerResidue,    resolution: systemConfig.resolutionBeakerResidue)
            moldsRow("Molds Filled",                value: $viewModel.weightMoldsFilled,      resolution: systemConfig.resolutionMoldsFilled)

            ThemedDivider(indent: 16).padding(.top, 8)

            // MARK: Mixture Densities
            HStack {
                Text("Mixture Densities").font(.subheadline).fontWeight(.semibold).foregroundStyle(CMTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)

            // Sugar Mix Density
            densitySubheader("Measure the Density of the Sugar Mix")
            weightRow("Syringe (Clean)",           value: $viewModel.densitySyringeCleanSugar,     resolution: .thousandthGram)
            weightRow("Syringe + Sugar Mix",       value: $viewModel.densitySyringePlusSugarMass,  resolution: .thousandthGram)
            volumeRow("Syringe + Sugar Mix",       value: $viewModel.densitySyringePlusSugarVol)

            // Gelatin Mix Density
            densitySubheader("Measure the Density of the Gelatin Mix")
            weightRow("Syringe (Clean)",           value: $viewModel.densitySyringeCleanGelatin,     resolution: .thousandthGram)
            weightRow("Syringe + Gelatin Mix",     value: $viewModel.densitySyringePlusGelatinMass,  resolution: .thousandthGram)
            volumeRow("Syringe + Gelatin Mix",     value: $viewModel.densitySyringePlusGelatinVol)

            // Activation Mix Density
            densitySubheader("Measure the Density of the Activation Mix")
            weightRow("Syringe (Clean)",           value: $viewModel.densitySyringeCleanActive,     resolution: .thousandthGram)
            weightRow("Syringe + Activation Mix",  value: $viewModel.densitySyringePlusActiveMass,  resolution: .thousandthGram)
            volumeRow("Syringe + Activation Mix",  value: $viewModel.densitySyringePlusActiveVol)

            ThemedDivider(indent: 16).padding(.vertical, 12)

            // Save button
            Button {
                CMHaptic.medium()
                if systemConfig.developerMode {
                    saveName = "DevMode | Dataset01"
                    saveBatchID = "XX"
                } else {
                    saveName = ""
                    saveBatchID = systemConfig.nextBatchID()
                }
                showSaveSheet = true
            } label: {
                Label("Save Batch", systemImage: "square.and.arrow.down")
                    .modifier(CMButtonStyle())
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveBatchSheet(
                saveName: $saveName,
                saveBatchID: $saveBatchID,
                onSave: { saveBatch(result: result) }
            )
            .presentationDetents([.height(280)])
        }
        .overlay(alignment: .top) {
            if savedConfirmation {
                Text("Batch saved!")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: CMTheme.chipRadius, style: .continuous)
                            .fill(CMTheme.success)
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: savedConfirmation)
    }

    private func subsectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func densitySubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 2)
    }

    private func weightRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        let placeholder = decimals == 0 ? "0" : "0." + String(repeating: "0", count: decimals)
        return HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            TextField(placeholder, value: value, format: .number.precision(.fractionLength(decimals)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
            Text("g")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 4)
    }

    private func volumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            TextField("0.000", value: value, format: .number.precision(.fractionLength(3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
            Text("mL")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 4)
    }

    private func moldsRow(_ label: String, value: Binding<Double?>, resolution: MeasurementResolution) -> some View {
        let decimals = resolution.decimalPlaces
        let placeholder = decimals == 0 ? "0" : "0." + String(repeating: "0", count: decimals)
        return HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            TextField(placeholder, value: value, format: .number.precision(.fractionLength(decimals)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .frame(width: 80)
            Text("molds")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textTertiary)
                .frame(width: 38, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 4)
    }

    private func saveBatch(result: BatchResult) {
        let batch = viewModel.makeSavedBatch(
            name: saveName.isEmpty ? "Batch \(Date.now.formatted(date: .abbreviated, time: .shortened))" : saveName,
            batchID: saveBatchID.isEmpty ? "AA" : saveBatchID.uppercased(),
            result: result,
            systemConfig: systemConfig
        )
        modelContext.insert(batch)
        showSaveSheet = false
        CMHaptic.success()
        savedConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            savedConfirmation = false
        }
    }
}

// MARK: - Save Batch Sheet

struct SaveBatchSheet: View {
    @Binding var saveName: String
    @Binding var saveBatchID: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Batch Identity") {
                    HStack {
                        Text("Batch ID")
                        Spacer()
                        TextField("AA", text: $saveBatchID)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .frame(width: 60)
                    }
                    TextField("Batch name (optional)", text: $saveName)
                }
            }
            .navigationTitle("Save Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
