//
//  MoldCalibrationView.swift
//  CandyMan
//
//  Water-displacement calibration tool for determining mold cavity volume.
//  The user selects a shape, enters the empty tray mass, the tray + water mass,
//  and the cavity count. Volume per cavity is computed as (waterMass / count) mL
//  (1 g water ≈ 1 mL at room temperature). The result can be applied to update
//  the SystemConfig spec for the selected shape.
//

import SwiftUI

// MARK: - MoldCalibrationView

struct MoldCalibrationView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.dismiss) private var dismiss

    @State private var selectedShape: GummyShape = .circle
    @State private var trayEmptyMass: Double = 0
    @State private var trayFilledMass: Double = 0
    @State private var cavityCount: Int = 0
    @State private var showConfirmation = false
    @State private var calibratedShapeName = ""

    private var waterMass: Double {
        max(trayFilledMass - trayEmptyMass, 0)
    }

    /// Volume per cavity in mL (1 g water ≈ 1 mL at room temp)
    private var volumePerCavity: Double {
        guard cavityCount > 0 else { return 0 }
        return waterMass / Double(cavityCount)
    }

    private var isValid: Bool {
        waterMass > 0 && cavityCount > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Shape picker
                VStack(spacing: 0) {
                    HStack {
                        Text("Mold Shape").cmSectionTitle(accent: systemConfig.designTitle)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    Picker("Shape", selection: $selectedShape) {
                        ForEach(GummyShape.allCases) { shape in
                            Label(shape.rawValue, systemImage: shape.sfSymbol).tag(shape)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .padding(.horizontal, 16).padding(.bottom, 8)
                }
                .cardStyle()

                // Measurements
                VStack(spacing: 0) {
                    HStack {
                        Text("Measurements").cmSectionTitle(accent: systemConfig.designTitle)
                        Spacer()
                        Text("grams").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    HStack {
                        Text("Empty Tray Mass").font(.body)
                        Spacer()
                        NumericField(value: $trayEmptyMass, decimals: 3)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Tray + Water Mass").font(.body)
                        Spacer()
                        NumericField(value: $trayFilledMass, decimals: 3)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Number of Molds").font(.body)
                        Spacer()
                        NumericField(value: Binding(
                            get: { Double(cavityCount) },
                            set: { cavityCount = Int($0.rounded()) }
                        ), decimals: 0)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Text("Fill every mold in the tray with water exactly to the line, then weigh the filled tray.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .cardStyle()

                // Result
                VStack(spacing: 0) {
                    HStack {
                        Text("Result").cmSectionTitle(accent: systemConfig.designTitle)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    HStack {
                        Text("Water Mass").font(.body)
                        Spacer()
                        Text(String(format: "%.3f g", waterMass))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Volume per Mold").font(.body).fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.3f mL", volumePerCavity))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(isValid ? systemConfig.designTitle : CMTheme.textTertiary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Text("1 g of water ≈ 1 mL at room temperature.")
                        .cmFootnote()
                        .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .cardStyle()

                // Apply button
                Button {
                    var spec = systemConfig.spec(for: selectedShape)
                    spec.volumeML = volumePerCavity
                    spec.count = cavityCount
                    systemConfig.setSpec(spec, for: selectedShape)
                    CMHaptic.medium()
                    calibratedShapeName = selectedShape.rawValue
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showConfirmation = true
                    }
                } label: {
                    Label("Apply to \(selectedShape.rawValue)", systemImage: "arrowshape.right.circle")
                        .font(.headline)
                        .foregroundStyle(!isValid ? CMTheme.textTertiary : .white)
                        .shadow(color: isValid ? .white.opacity(0.3) : .clear, radius: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                                    .fill(CMTheme.chipBG)
                                PsychedelicButton2(isDisabled: !isValid)
                            }
                        )
                }
                .buttonStyle(CMPressStyle())
                .disabled(!isValid)
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Calibrate a Mold")
        .keyboardDismissToolbar()
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            // Pre-fill cavity count from current config
            cavityCount = systemConfig.spec(for: selectedShape).count
        }
        .onChange(of: selectedShape) { _, newShape in
            cavityCount = systemConfig.spec(for: newShape).count
        }
        .overlay {
            if showConfirmation {
                PsychedelicAlert2(
                    title: "You calibrated \(calibratedShapeName)!",
                    subtitle: "Good work CandyMan!",
                    buttonLabel: "Done"
                ) {
                    withAnimation(.easeOut(duration: 0.25)) { showConfirmation = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
                }
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
    }
}
