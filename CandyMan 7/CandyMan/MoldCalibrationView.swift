import SwiftUI

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
                        Text("Mold Shape").font(.headline).foregroundStyle(CMTheme.textPrimary)
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
                        Text("Measurements").font(.headline).foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text("grams").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    HStack {
                        Text("Empty Tray Mass").font(.body)
                        Spacer()
                        TextField("0.000", value: $trayEmptyMass, format: .number.precision(.fractionLength(3)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .selectAllOnFocus()
                        Text("g").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Tray + Water Mass").font(.body)
                        Spacer()
                        TextField("0.000", value: $trayFilledMass, format: .number.precision(.fractionLength(3)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .selectAllOnFocus()
                        Text("g").font(.subheadline).foregroundStyle(CMTheme.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Number of Molds").font(.body)
                        Spacer()
                        TextField("0", value: $cavityCount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .selectAllOnFocus()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Text("Fill every mold in the tray with water exactly to the line, then weigh the filled tray.")
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .cardStyle()

                // Result
                VStack(spacing: 0) {
                    HStack {
                        Text("Result").font(.headline).foregroundStyle(CMTheme.textPrimary)
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
                            .foregroundStyle(isValid ? systemConfig.accent : CMTheme.textTertiary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    Text("1 g of water ≈ 1 mL at room temperature.")
                        .font(.caption).foregroundStyle(CMTheme.textTertiary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .cardStyle()

                // Apply button
                Button {
                    var spec = systemConfig.spec(for: selectedShape)
                    spec.volume_ml = volumePerCavity
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? systemConfig.accent : CMTheme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid)
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .navigationTitle("Calibrate a Mold")
        .keyboardDismissToolbar()
        .preferredColorScheme(.dark)
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
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.25)) { showConfirmation = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
                        }

                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(systemConfig.accent)

                        Text("You calibrated \(calibratedShapeName)!")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(CMTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Good work CandyMan!")
                            .font(.subheadline)
                            .foregroundStyle(CMTheme.textSecondary)

                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { showConfirmation = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(systemConfig.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .frame(maxWidth: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(CMTheme.cardBG)
                            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    )
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
        }
    }
}
