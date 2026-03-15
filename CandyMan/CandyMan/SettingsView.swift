//
//  SettingsView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var systemConfig = systemConfig
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    moldVolumeSection(systemConfig: systemConfig)
                        .cardStyle()
                    wellsSection(systemConfig: systemConfig)
                        .cardStyle()
                    sugarRatioSection(systemConfig: systemConfig)
                        .cardStyle()
                    gelToWaterSection(systemConfig: systemConfig)
                        .cardStyle()
                    additivesSection(systemConfig: systemConfig)
                        .cardStyle()
                    waterSection(systemConfig: systemConfig)
                        .cardStyle()
                    overageSection(viewModel: viewModel)
                        .cardStyle()
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGray4))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Mold Volume

    private func moldVolumeSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig

        return VStack(spacing: 0) {
            HStack {
                Text("Mold Volume")
                    .font(.headline)
                Spacer()
                Text("mL / cavity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Image(systemName: shape.sfSymbol)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(shape.rawValue)
                        .font(.body)
                    Spacer()
                    TextField("0.0", value: Binding(
                        get: { systemConfig.spec(for: shape).volume_ml },
                        set: { newVal in
                            var updated = systemConfig.spec(for: shape)
                            updated.volume_ml = newVal
                            systemConfig.setSpec(updated, for: shape)
                        }
                    ), format: .number.precision(.fractionLength(1...3)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    Text("mL")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                if shape != GummyShape.allCases.last {
                    Divider().padding(.leading, 56)
                }
            }

            Text("This is the statistical volume of the tray, not the ideal well volume.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Wells Per Tray

    private func wellsSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig

        return VStack(spacing: 0) {
            HStack {
                Text("Wells Per Tray")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(GummyShape.allCases) { shape in
                HStack {
                    Text(shape.rawValue)
                        .font(.body)
                    Spacer()
                    TextField("0", value: Binding(
                        get: { systemConfig.spec(for: shape).count },
                        set: { newVal in
                            var updated = systemConfig.spec(for: shape)
                            updated.count = newVal
                            systemConfig.setSpec(updated, for: shape)
                        }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    Text("wells")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                if shape != GummyShape.allCases.last {
                    Divider().padding(.leading, 16)
                }
            }

            Text("Count the number of wells on one tray for each mold shape.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Sugar Ratio

    private func sugarRatioSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig

        return VStack(spacing: 0) {
            HStack {
                Text("Sugar Ratio")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            HStack {
                Text("Syrup : Granulated")
                    .font(.body)
                Spacer()
                TextField("1.000", value: $systemConfig.glucoseToSugarMassRatio,
                          format: .number.precision(.fractionLength(3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                Text(": 1")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Text("Mass ratio of glucose syrup to granulated table sugar.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Pre-Active Gel to Water Mass Ratio

    private func gelToWaterSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig

        return VStack(spacing: 0) {
            HStack {
                Text("Pre-Active Gel to Water Mass Ratio")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            HStack {
                Text("Gel : Water")
                    .font(.body)
                Spacer()
                TextField("1.000", value: $systemConfig.gelToWaterMassRatio,
                          format: .number.precision(.fractionLength(3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                Text(": 1")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Text("Mass ratio of pre-active gel to water. Volume ratio: \(String(format: "%.3f", systemConfig.gelToWaterVolumeRatio)) : 1")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Additives

    private func additivesSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig

        return VStack(spacing: 0) {
            HStack {
                Text("Additives")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            HStack {
                Text("Potassium sorbate")
                    .font(.body)
                Spacer()
                TextField("0.0", value: $systemConfig.potassiumSorbatePercent,
                          format: .number.precision(.fractionLength(1...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                Text("%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 16)

            HStack {
                Text("Citric acid")
                    .font(.body)
                Spacer()
                TextField("0.0", value: $systemConfig.citricAcidPercent,
                          format: .number.precision(.fractionLength(1...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                Text("%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Text("Percent volume of the additives in the gummy mixture.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Water

    private func waterSection(systemConfig: SystemConfig) -> some View {
        @Bindable var systemConfig = systemConfig

        return VStack(spacing: 0) {
            HStack {
                Text("Water")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            HStack {
                Text("Gelatin Water")
                    .font(.body)
                Spacer()
                TextField("0.0", value: $systemConfig.gelatinWaterPercent,
                          format: .number.precision(.fractionLength(1...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                Text("%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Text("Water percentage used in the gelatin blooming step.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Overage Percentage

    private func overageSection(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 0) {
            HStack {
                Text("Overage")
                    .font(.headline)
                Spacer()
                Text("factor: \(String(format: "%.3f", viewModel.overageFactor))×")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            HStack {
                Text("Extra volume")
                    .font(.body)
                Spacer()
                TextField("0.0", value: $viewModel.overagePercent,
                          format: .number.precision(.fractionLength(1...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                Text("%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Text("Accounts for loss during transfer, stir bars, scum layer, and drips. 3% = 1.03× multiplier.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }
}
