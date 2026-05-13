//
//  ThemePickerView.swift
//  CandyMan
//
//  Theme browser and manager. Lets the user:
//    • Select from built-in design themes
//    • Select from user-saved themes
//    • Save the current color combination as a named theme
//    • Rename or delete user-saved themes
//

import SwiftUI

// MARK: - ThemePickerView

struct ThemePickerView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @State private var showSaveSheet = false
    @State private var themeToDelete: SystemConfig.DesignTheme? = nil
    @State private var showDeleteAlert = false
    @State private var themeToRename: SystemConfig.DesignTheme? = nil
    @State private var showRenameSheet = false

    private var activeThemeID: String? {
        systemConfig.activeDesignThemeID
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Live Preview
                themePreviewCard()
                    .cardStyle()
                    .padding(.top, 4)

                // MARK: - Built-in Themes
                categoryLabel("Built-in Themes")

                VStack(spacing: 0) {
                    ForEach(SystemConfig.designThemes, id: \.id) { theme in
                        themeRow(theme: theme, isActive: activeThemeID == theme.id, isUserTheme: false)
                        if theme.id != SystemConfig.designThemes.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .cardStyle()

                // MARK: - User Themes
                if !systemConfig.userThemes.isEmpty {
                    categoryLabel("My Themes")

                    VStack(spacing: 0) {
                        ForEach(systemConfig.userThemes, id: \.id) { theme in
                            themeRow(theme: theme, isActive: activeThemeID == theme.id, isUserTheme: true)
                            if theme.id != systemConfig.userThemes.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .cardStyle()
                }

                // MARK: - Save Current as Theme
                VStack(spacing: 0) {
                    Button {
                        CMHaptic.light()
                        showSaveSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(systemConfig.designTitle)
                            Text("Save Current as Theme")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(systemConfig.designTitle)
                            Spacer()
                            // Preview of current colors
                            HStack(spacing: 2) {
                                ForEach(SystemConfig.DesignColorRole.allCases) { role in
                                    Circle()
                                        .fill(systemConfig.designColor(for: role))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .cardStyle()

                Spacer().frame(height: 20)
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .navigationTitle("Themes")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showSaveSheet) {
            SaveThemeSheet(systemConfig: systemConfig)
        }
        .sheet(isPresented: $showRenameSheet) {
            if let theme = themeToRename {
                RenameThemeSheet(systemConfig: systemConfig, theme: theme)
            }
        }
        .alert("Delete Theme?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { themeToDelete = nil }
            Button("Delete", role: .destructive) {
                if let theme = themeToDelete {
                    CMHaptic.success()
                    withAnimation(.cmSpring) {
                        systemConfig.deleteUserTheme(id: theme.id)
                    }
                }
                themeToDelete = nil
            }
        } message: {
            if let theme = themeToDelete {
                Text("Are you sure you want to delete \"\(theme.name)\"? This cannot be undone.")
            }
        }
    }

    // MARK: - Theme Preview Card

    /// A miniature mock-up of the app's UI using the currently active design colors,
    /// so the user can see what each theme looks like in context.
    private func themePreviewCard() -> some View {
        let primary = systemConfig.designColor(for: .primary)
        let alert = systemConfig.designColor(for: .alert)
        let primaryAccent = systemConfig.designColor(for: .primaryAccent)
        let secondaryAccent = systemConfig.designColor(for: .secondaryAccent)
        let bodyText = systemConfig.designColor(for: .bodyText)
        let detailText = systemConfig.designColor(for: .detailText)

        return VStack(spacing: 0) {
            // Section title row
            HStack {
                Text("Gelatin Mix")
                    .font(.headline)
                    .foregroundStyle(primary)
                Spacer()
                Text("198.4 mL")
                    .font(.subheadline)
                    .foregroundStyle(bodyText.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            // Subsection title
            HStack {
                Text("Substrate")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(bodyText.opacity(0.5))
                Spacer()
                Text("g")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(detailText)
                    .frame(width: 60, alignment: .trailing)
                Text("+5%")
                    .font(.system(size: 10, design: .monospaced)).fontWeight(.semibold)
                    .foregroundStyle(primaryAccent.opacity(0.7))
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal, 16).padding(.bottom, 4)

            // Data rows
            previewDataRow(label: "Gelatin", value: "21.045", overage: "22.097", bodyText: bodyText, detailText: detailText, accentColor: primaryAccent)
            Divider().padding(.leading, 16).opacity(0.3)
            previewDataRow(label: "Water", value: "63.135", overage: "66.292", bodyText: bodyText, detailText: detailText, accentColor: primaryAccent)

            Divider().padding(.horizontal, 16).padding(.vertical, 6).opacity(0.3)

            // Activation section
            HStack {
                Text("Activation Mix")
                    .font(.headline)
                    .foregroundStyle(primary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 6)

            // Accent-colored data rows
            previewAccentRow(label: "Citric Acid", value: "0.845", color: alert, bodyText: bodyText)
            Divider().padding(.leading, 16).opacity(0.3)
            previewAccentRow(label: "LSD Transfer", value: "1.200", color: secondaryAccent, bodyText: bodyText)
            Divider().padding(.leading, 16).opacity(0.3)

            // Warning/error row
            HStack(spacing: 6) {
                Text("Error")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(alert)
                Spacer()
                Text("± 0.023 g")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(alert.opacity(0.8))
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 16).padding(.vertical, 4)

            // Footnote
            Text("Densities used to convert between mass and volume for each substance.")
                .font(.caption)
                .foregroundStyle(detailText)
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 10)
        }
    }

    private func previewDataRow(label: String, value: String, overage: String, bodyText: Color, detailText: Color, accentColor: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bodyText)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bodyText.opacity(0.5))
                .frame(width: 60, alignment: .trailing)
            Text(overage)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(accentColor.opacity(0.6))
                .frame(width: 54, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 3)
    }

    private func previewAccentRow(label: String, value: String, color: Color, bodyText: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bodyText)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 3)
    }

    private func categoryLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CMTheme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func themeRow(theme: SystemConfig.DesignTheme, isActive: Bool, isUserTheme: Bool) -> some View {
        Button {
            CMHaptic.medium()
            withAnimation(.cmSpring) { systemConfig.applyDesignTheme(theme) }
        } label: {
            HStack(spacing: 12) {
                // Color dots preview
                HStack(spacing: 3) {
                    ForEach(SystemConfig.DesignColorRole.allCases) { role in
                        Circle()
                            .fill(theme.color(for: role).color)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CMTheme.cardBG.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isActive ? systemConfig.designTitle : CMTheme.cardStroke, lineWidth: isActive ? 1.5 : 0.5)
                        )
                )

                Text(theme.name)
                    .font(.body)
                    .foregroundStyle(CMTheme.textPrimary)

                Spacer()

                if isUserTheme {
                    // Rename button
                    Button {
                        CMHaptic.light()
                        themeToRename = theme
                        showRenameSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(systemConfig.designTitle)
                    }
                    .buttonStyle(.plain)

                    // Delete button
                    Button {
                        CMHaptic.light()
                        themeToDelete = theme
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(systemConfig.designAlert)
                    }
                    .buttonStyle(.plain)
                }

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(systemConfig.designTitle)
                }
            }
            .contentShape(Rectangle())
            .cmSettingsRowPadding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Save Theme Sheet

struct SaveThemeSheet: View {
    var systemConfig: SystemConfig
    @Environment(\.dismiss) private var dismiss
    @State private var themeName = ""

    private var isValid: Bool {
        !themeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 8) {
                    Text("Current Colors")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(CMTheme.textSecondary)
                    HStack(spacing: 6) {
                        ForEach(SystemConfig.DesignColorRole.allCases) { role in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(systemConfig.designColor(for: role))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle().stroke(CMTheme.cardStroke, lineWidth: 0.5)
                                    )
                                Text(role.rawValue)
                                    .font(.system(size: 8))
                                    .foregroundStyle(CMTheme.textTertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(CMTheme.cardBG)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(CMTheme.cardStroke, lineWidth: 0.5)
                            )
                    )
                }
                .padding(.horizontal, 16)

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme Name")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(CMTheme.textSecondary)
                    TextField("My Theme", text: $themeName)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                                .fill(CMTheme.fieldBG)
                        )
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 20)
            .background(CMTheme.pageBG)
            .navigationTitle("Save Theme")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        CMHaptic.success()
                        let name = themeName.trimmingCharacters(in: .whitespacesAndNewlines)
                        systemConfig.saveCurrentAsTheme(name: name)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Rename Theme Sheet

struct RenameThemeSheet: View {
    var systemConfig: SystemConfig
    let theme: SystemConfig.DesignTheme
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String

    init(systemConfig: SystemConfig, theme: SystemConfig.DesignTheme) {
        self.systemConfig = systemConfig
        self.theme = theme
        _newName = State(initialValue: theme.name)
    }

    private var isValid: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme Name")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(CMTheme.textSecondary)
                    TextField("Theme Name", text: $newName)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                                .fill(CMTheme.fieldBG)
                        )
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 20)
            .background(CMTheme.pageBG)
            .navigationTitle("Rename Theme")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        CMHaptic.success()
                        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        systemConfig.renameUserTheme(id: theme.id, newName: name)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
