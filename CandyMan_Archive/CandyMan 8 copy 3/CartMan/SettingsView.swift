//
//  SettingsView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        @Bindable var systemConfig = systemConfig
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Accent theme
                    VStack(spacing: 8) {
                        CMSectionHeader(title: "Accent Color")
                        HStack(spacing: 12) {
                            ForEach(AccentTheme.allCases) { theme in
                                Button {
                                    CMHaptic.medium()
                                    withAnimation(.cmSpring) { systemConfig.accentTheme = theme }
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: systemConfig.accentTheme == theme ? 2 : 0)
                                            )
                                        Text(theme.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(systemConfig.accentTheme == theme ? CMTheme.textPrimary : CMTheme.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .cardStyle()

                    // Haptics
                    VStack(spacing: 8) {
                        Toggle(isOn: $systemConfig.sliderVibrationsEnabled) {
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundStyle(systemConfig.accent)
                                Text("Slider Vibrations")
                                    .foregroundStyle(CMTheme.textPrimary)
                            }
                        }
                        .tint(systemConfig.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .cardStyle()

                    // About
                    VStack(spacing: 8) {
                        CMSectionHeader(title: "About")
                        HStack {
                            Text("CartMan")
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textPrimary)
                            Spacer()
                            Text("v1.0")
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        Text("Cannabis cart calculator. Performs the same calculations as the Carts & Gummies spreadsheet.")
                            .font(.caption)
                            .foregroundStyle(CMTheme.textTertiary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                    }
                    .cardStyle()
                }
                .padding(.vertical, 12)
            }
            .background(CMTheme.pageBG)
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
