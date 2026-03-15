import SwiftUI
import SwiftData

struct WeightMeasurementsView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.modelContext) private var modelContext

    @State private var showSaveAlert = false
    @State private var saveName = ""
    @State private var savedConfirmation = false

    var body: some View {
        @Bindable var viewModel = viewModel
        let result = BatchCalculator.calculate(viewModel: viewModel, systemConfig: systemConfig)

        VStack(spacing: 0) {
            // Title header (no "g" unit next to title)
            HStack {
                Text("Measurements").font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 2)

            Text("The Substrate is defined as the primary beaker + all ingredients that have been added to the mixture.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            // MARK: Initial mass of container
            subsectionHeader("Initial mass of container")
            weightRow("Beaker (Empty)", value: $viewModel.weightBeakerEmpty)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Add gelatin mixture
            subsectionHeader("Add gelatin mixture")
            weightRow("Beaker + Gelatin Mix", value: $viewModel.weightBeakerPlusGelatin)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Add sugar mixture
            subsectionHeader("Add sugar mixture")
            weightRow("Substrate + Sugar Mix", value: $viewModel.weightBeakerPlusSugar)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Add activation mixture
            subsectionHeader("Add activation mixture")
            weightRow("Substrate + Activation Mix", value: $viewModel.weightBeakerPlusActive)

            Divider().padding(.horizontal, 16).padding(.top, 8)

            // MARK: Transfer to mold
            subsectionHeader("Transfer to mold")
            weightRow("Beaker + Residue", value: $viewModel.weightBeakerResidue)
            weightRow("Syringe (Clean)",          value: $viewModel.weightSyringeEmpty)
            weightRow("Syringe + Gummy Mix",       value: $viewModel.weightSyringeWithMix)
            volumeRow("Syringe Gummy Mixture Vol", value: $viewModel.volumeSyringeGummyMix)
            weightRow("Syringe + Residue",         value: $viewModel.weightSyringeResidue)
            moldsRow("Molds Filled",               value: $viewModel.weightMoldsFilled)

            Divider().padding(.horizontal, 16).padding(.vertical, 12)

            // Save button
            Button {
                saveName = ""
                showSaveAlert = true
            } label: {
                Label("Save Batch", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .alert("Save Batch", isPresented: $showSaveAlert) {
            TextField("Batch name", text: $saveName)
            Button("Save") { saveBatch(result: result) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this batch a name to save it to history.")
        }
        .overlay(alignment: .top) {
            if savedConfirmation {
                Text("Batch saved!")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(10)
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
                .foregroundStyle(.secondary)
            Spacer()
            Text("g")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func weightRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            TextField("0.000", value: value, format: .number.precision(.fractionLength(3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, design: .monospaced))
                .frame(width: 80)
            Text("g")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 5)
    }

    private func volumeRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            TextField("0.000", value: value, format: .number.precision(.fractionLength(3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, design: .monospaced))
                .frame(width: 80)
            Text("mL")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 5)
    }

    private func moldsRow(_ label: String, value: Binding<Double?>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            TextField("0.0", value: value, format: .number.precision(.fractionLength(1...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, design: .monospaced))
                .frame(width: 80)
            Text("molds")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 5)
    }

    private func saveBatch(result: BatchResult) {
        let batch = viewModel.makeSavedBatch(
            name: saveName.isEmpty ? "Batch \(Date.now.formatted(date: .abbreviated, time: .shortened))" : saveName,
            result: result,
            systemConfig: systemConfig
        )
        modelContext.insert(batch)
        savedConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            savedConfirmation = false
        }
    }
}
