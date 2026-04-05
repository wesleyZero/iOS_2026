//
//  ContainerInfoPopup.swift
//  CandyMan
//
//  Overlay popup shown when the user taps the (i) info button next to a
//  container tare row in high-precision mode. Displays factory tare, an
//  editable tare field, and a button to save the edited value back to
//  system settings. Follows the same overlay pattern as
//  AdditionalMeasurementsPopup and CorrectionsView.
//

import SwiftUI

struct ContainerInfoPopup: View {
    @Environment(SystemConfig.self) private var systemConfig
    let containerID: String
    let onDismiss: () -> Void

    @State private var editedTare: Double = 0

    private var beaker: SystemConfig.BeakerContainer? {
        systemConfig.containers.first { $0.id == containerID }
    }

    private static func factoryTare(for id: String) -> Double {
        SystemConfig.factoryContainers.first(where: { $0.id == id })?.tareWeight ?? 0
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(beaker?.name ?? containerID)
                        .font(.headline)
                        .foregroundStyle(systemConfig.designMeasurement)
                    Spacer()
                    Button {
                        CMHaptic.light()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)

                ThemedDivider()

                // Factory tare (read-only)
                HStack(spacing: 6) {
                    Text("Factory Tare")
                        .cmRowLabel()
                    Spacer()
                    Text(String(format: "%.3f", Self.factoryTare(for: containerID)))
                        .cmMono12()
                        .foregroundStyle(CMTheme.textTertiary)
                    Text("g").cmUnitSlot()
                }
                .cmDataRowPadding().padding(.top, 8)

                // Editable tare
                HStack(spacing: 6) {
                    Text("Saved Tare")
                        .cmRowLabel()
                    Spacer()
                    NumericField(value: $editedTare, decimals: 3)
                        .multilineTextAlignment(.trailing)
                        .cmValueSlot(width: 80)
                    Text("g").cmUnitSlot()
                }
                .cmDataRowPadding()

                // Status indicator
                if systemConfig.containerTareIsOverridden(for: containerID) {
                    Text("Custom tare saved")
                        .cmFootnote()
                        .foregroundStyle(systemConfig.designMeasurement.opacity(0.7))
                        .padding(.horizontal, 20).padding(.top, 4)
                }

                ThemedDivider().padding(.vertical, 8)

                // Action buttons
                HStack(spacing: 12) {
                    // Save to system settings
                    Button {
                        CMHaptic.success()
                        systemConfig.setContainerTare(editedTare, for: containerID)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 12))
                            Text("Save to Settings")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(systemConfig.designMeasurement)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(
                            Capsule().fill(systemConfig.designMeasurement.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)

                    // Reset to factory
                    if systemConfig.containerTareIsOverridden(for: containerID) {
                        Button {
                            CMHaptic.light()
                            systemConfig.resetContainerTare(for: containerID)
                            editedTare = Self.factoryTare(for: containerID)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12))
                                Text("Reset")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(systemConfig.designAlert)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            }
            .cmModalCard()
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
        .onAppear {
            editedTare = systemConfig.containerTare(for: containerID)
        }
    }
}
