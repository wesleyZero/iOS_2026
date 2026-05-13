//
//  CartConfigView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI
import SwiftData

struct CartConfigView: View {
    @Environment(CartConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext
    @Query private var savedCarts: [SavedCart]

    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showTemplates = false
    @State private var showResetTemplateAlert = false
    @State private var showSaveTemplateAlert = false
    @State private var saveTemplateName = ""
    @State private var showCartManToast = false
    @State private var showSaveBatchAlert = false
    @State private var saveBatchName = ""

    private var isRegular: Bool { sizeClass == .regular }

    // MARK: - Readiness

    private var canCalculate: Bool {
        let cannabis = viewModel.selectedTerpenes.keys.filter { if case .cannabis = $0 { return true }; return false }
        let flavors = viewModel.selectedTerpenes.keys.filter { if case .flavor = $0 { return true }; return false }
        let cannabisTotal = cannabis.reduce(0.0) { $0 + (viewModel.selectedTerpenes[$1] ?? 0) }
        let flavorTotal = flavors.reduce(0.0) { $0 + (viewModel.selectedTerpenes[$1] ?? 0) }
        let cannabisOK = cannabis.isEmpty || abs(cannabisTotal - 100) < 0.5
        let flavorsOK = flavors.isEmpty || abs(flavorTotal - 100) < 0.5
        let terpsOK = viewModel.selectedTerpenes.isEmpty || viewModel.terpenesLocked
        return cannabisOK && flavorsOK && terpsOK
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 12) {
                    Color.clear.frame(height: 0).id("scrollTop")

                    if viewModel.batchCalculated {
                        InputSummaryView().cardStyle()
                            .frame(maxWidth: isRegular ? 600 : .infinity)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        VStack(spacing: 12) {
                            templateSection.cardStyle()
                            chooseCartSize.cardStyle()
                            chooseCartCount(viewModel: viewModel).cardStyle()
                            chooseComposition(viewModel: viewModel).cardStyle()
                            TerpenePickerView().cardStyle()
                            Spacer().frame(height: 4)
                            calculateSection.cardStyle()
                        }
                        .frame(maxWidth: isRegular ? 600 : .infinity)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Output
                    if viewModel.batchCalculated {
                        if isRegular {
                            HStack(alignment: .top, spacing: 0) {
                                CartOutputView().cardStyle()
                                    .frame(maxWidth: .infinity)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                            saveBatchSection.cardStyle()
                                .frame(maxWidth: 400)
                            resetSection.cardStyle()
                                .frame(maxWidth: 400)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            Group {
                                CartOutputView().cardStyle()
                                saveBatchSection.cardStyle()
                                resetSection.cardStyle()
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .frame(maxWidth: isRegular ? 1100 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.batchCalculated) { _, calculated in
                if calculated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.cmSpring) {
                            scrollProxy.scrollTo("scrollTop", anchor: .top)
                        }
                    }
                }
            }
            .onChange(of: viewModel.templateInputsChanged) { _, changed in
                if changed, viewModel.activeTemplateID != nil {
                    withAnimation(.cmSpring) {
                        viewModel.activeTemplateID = nil
                        viewModel.activeTemplateName = ""
                    }
                }
            }
        }
        .navigationTitle("Cart Batch")
        .background(CMTheme.pageBG)
        .scrollDismissesKeyboard(.immediately)
        .preferredColorScheme(.dark)
        .overlay {
            if showCartManToast {
                Text("Because the CartMan can!!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(systemConfig.accent.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .top)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
                    .allowsHitTesting(false)
            }
        }
        .keyboardDismissToolbar()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showHistory = true } label: {
                    Image(systemName: "book.circle")
                        .foregroundStyle(CMTheme.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(CMTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(systemConfig)
        }
        .sheet(isPresented: $showHistory) {
            CartHistoryView().environment(systemConfig)
        }
        .sheet(isPresented: $showTemplates) {
            TemplateListView()
        }
    }

    // MARK: - Cart Size

    private var chooseCartSize: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Cart Size",
                          detail: viewModel.cartSize.rawValue,
                          showReset: viewModel.cartSize != .full) {
                viewModel.cartSize = .full
            }
            HStack(spacing: 12) {
                ForEach(CartSize.allCases) { size in
                    cartSizeButton(for: size)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func cartSizeButton(for size: CartSize) -> some View {
        let sel = viewModel.cartSize == size
        return Button {
            CMHaptic.medium()
            withAnimation(.cmSpring) { viewModel.cartSize = size }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: size.sfSymbol)
                    .font(.system(size: 30))
                Text(size.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(sel ? systemConfig.accent : CMTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                    .fill(sel ? systemConfig.accent.opacity(0.12) : CMTheme.fieldBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                    .stroke(sel ? systemConfig.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
            .animation(.cmSpring, value: sel)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cart Count

    private func chooseCartCount(viewModel: CartConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 4) {
            sectionHeader(title: "Carts",
                          detail: String(format: "%.2f ml total", viewModel.finalVolume_mL),
                          showReset: viewModel.cartCount != 1) {
                viewModel.cartCount = 1
            }
            HStack {
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.cartCount = max(1, viewModel.cartCount - 1) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(systemConfig.accent)
                }
                Spacer()
                Text("\(viewModel.cartCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CMTheme.textPrimary)
                    .contentTransition(.numericText())
                Text("Cart\(viewModel.cartCount == 1 ? "" : "s")")
                    .font(.system(size: 20))
                    .foregroundStyle(CMTheme.textSecondary)
                Spacer()
                Button {
                    CMHaptic.selection()
                    withAnimation(.cmSpring) { viewModel.cartCount = min(50, viewModel.cartCount + 1) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(systemConfig.accent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            Text("\(viewModel.cartCount) × \(viewModel.cartSize.rawValue) = \(String(format: "%.1f", viewModel.finalVolume_mL)) ml total")
                .font(.caption)
                .foregroundStyle(CMTheme.textTertiary)
            Spacer()
        }
    }

    // MARK: - Composition (Weed % / Terp %)

    private func chooseComposition(viewModel: CartConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let compositionChanged = viewModel.weedComposition != 0.80 || viewModel.terpComposition != 0.14
        return VStack(spacing: 8) {
            sectionHeader(title: "Composition",
                          detail: viewModel.socialDosing ? "Social Dose" : "Full Strength",
                          showReset: compositionChanged) {
                viewModel.weedComposition = 0.80
                viewModel.terpComposition = 0.14
            }

            // Weed %
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color(red: 0.2, green: 0.7, blue: 0.3))
                    Text("Weed Distillate")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    TextField("0", value: $viewModel.weedComposition,
                              format: .percent.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(width: 90)
                        .selectAllOnFocus()
                }
                .padding(.horizontal, 20)

                Slider(value: $viewModel.weedComposition, in: 0...1, step: 0.01)
                    .tint(Color(red: 0.2, green: 0.7, blue: 0.3))
                    .padding(.horizontal, 20)
                    .onChange(of: viewModel.weedComposition) { old, new in
                        if systemConfig.sliderVibrationsEnabled && old != new {
                            CMHaptic.selection()
                        }
                    }
            }

            ThemedDivider()

            // Terp %
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(Color(red: 0.7, green: 0.3, blue: 0.8))
                    Text("Terpenes")
                        .font(.subheadline)
                        .foregroundStyle(CMTheme.textSecondary)
                    Spacer()
                    TextField("0", value: $viewModel.terpComposition,
                              format: .percent.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(CMTheme.textPrimary)
                        .frame(width: 90)
                        .selectAllOnFocus()
                }
                .padding(.horizontal, 20)

                Slider(value: $viewModel.terpComposition, in: 0...0.30, step: 0.01)
                    .tint(Color(red: 0.7, green: 0.3, blue: 0.8))
                    .padding(.horizontal, 20)
                    .onChange(of: viewModel.terpComposition) { old, new in
                        if systemConfig.sliderVibrationsEnabled && old != new {
                            CMHaptic.selection()
                        }
                    }
            }

            // Derived values
            if viewModel.socialDosing {
                ThemedDivider()
                derivedRow("Base", value: String(format: "%.1f%%", viewModel.baseComposition * 100),
                           icon: "drop.triangle", color: Color(red: 0.4, green: 0.6, blue: 0.9))
                derivedRow("Cut", value: String(format: "%.1f%%", viewModel.cutComposition * 100),
                           icon: "scissors", color: Color(red: 0.9, green: 0.6, blue: 0.2))
            }

            // Composition bar preview
            compositionPreviewBar
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            Spacer().frame(height: 4)
        }
    }

    private var compositionPreviewBar: some View {
        let weed = viewModel.weedComposition
        let terp = viewModel.terpComposition
        let base = viewModel.baseComposition
        let cut = max(0, 1.0 - weed - terp - base)

        return GeometryReader { geo in
            HStack(spacing: 2) {
                if weed > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                        .frame(width: max(4, geo.size.width * weed))
                }
                if base > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.4, green: 0.6, blue: 0.9))
                        .frame(width: max(4, geo.size.width * base))
                }
                if cut > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.9, green: 0.6, blue: 0.2))
                        .frame(width: max(4, geo.size.width * cut))
                }
                if terp > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.7, green: 0.3, blue: 0.8))
                        .frame(width: max(4, geo.size.width * terp))
                }
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func derivedRow(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CMTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    // MARK: - Calculate

    private var calculateSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Calculate Batch")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                if viewModel.activeTemplateID != nil {
                    HStack(spacing: 6) {
                        Text("Info \(Text("saved").foregroundColor(CMTheme.danger)) as \(Text(viewModel.activeTemplateName).foregroundColor(CMTheme.danger))")
                            .font(.caption)
                            .foregroundStyle(CMTheme.textTertiary)
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                } else {
                    Button {
                        CMHaptic.medium()
                        saveTemplateName = ""
                        showSaveTemplateAlert = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Info \(canCalculate ? Text("not saved").foregroundColor(CMTheme.danger) : Text("not saved")) as template")
                                .font(.caption)
                                .foregroundStyle(CMTheme.textTertiary)
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !canCalculate {
                Text("All selected terpene blends must sum to 100%")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16)
            }

            Button {
                CMHaptic.heavy()
                withAnimation(.cmSpring) {
                    viewModel.batchCalculated = true
                    showCartManToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) { showCartManToast = false }
                }
            } label: {
                Label("Calculate", systemImage: "function")
                    .modifier(CMButtonStyle(color: systemConfig.accent, isDisabled: !canCalculate))
            }
            .buttonStyle(CMPressStyle())
            .disabled(!canCalculate)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .alert("Save as Template", isPresented: $showSaveTemplateAlert) {
            TextField("Template Name", text: $saveTemplateName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let trimmed = saveTemplateName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                CMHaptic.success()
                viewModel.saveAsTemplate(name: trimmed, modelContext: modelContext)
            }
        } message: {
            Text("Enter a name for this template.")
        }
    }

    // MARK: - Save Batch

    private var saveBatchSection: some View {
        VStack(spacing: 8) {
            CMSectionHeader(title: "Save Batch")
            Button {
                CMHaptic.medium()
                saveBatchName = ""
                showSaveBatchAlert = true
            } label: {
                Label("Save to History", systemImage: "square.and.arrow.down")
                    .modifier(CMButtonStyle(color: systemConfig.accent, isDisabled: false))
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .alert("Save Cart Batch", isPresented: $showSaveBatchAlert) {
            TextField("Batch Name", text: $saveBatchName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let trimmed = saveBatchName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                CMHaptic.success()
                let result = CartCalculator.calculate(viewModel: viewModel)
                let batchID = systemConfig.nextBatchID()
                let saved = viewModel.makeSavedCart(name: trimmed, batchID: batchID, result: result)
                modelContext.insert(saved)
            }
        } message: {
            Text("Enter a name for this batch.")
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        VStack(spacing: 8) {
            CMSectionHeader(title: "New Batch")
            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.resetBatch() }
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                    .foregroundStyle(CMTheme.textPrimary)
            }
            .buttonStyle(CMPressStyle())
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Templates

    private var templateSection: some View {
        VStack(spacing: 8) {
            Button {
                CMHaptic.medium()
                showTemplates = true
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(systemConfig.accent)
                    Text("Templates")
                        .font(.headline)
                        .foregroundStyle(CMTheme.textPrimary)
                    if viewModel.activeTemplateID != nil {
                        Button {
                            CMHaptic.medium()
                            showResetTemplateAlert = true
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .foregroundStyle(CMTheme.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    if viewModel.activeTemplateID == nil {
                        Text("No template is being used")
                            .font(.caption)
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if viewModel.activeTemplateID != nil {
                Text("The \(Text(viewModel.activeTemplateName).foregroundColor(CMTheme.danger)) template is being used.")
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .alert("Reset to Defaults", isPresented: $showResetTemplateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                CMHaptic.medium()
                withAnimation(.cmSpring) { viewModel.clearTemplate() }
            }
        } message: {
            Text("This will remove the current template and reset all inputs back to default values.")
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, detail: String, showReset: Bool = false, onReset: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title).font(.headline).foregroundStyle(CMTheme.textPrimary)
            if showReset {
                Button {
                    CMHaptic.light()
                    withAnimation(.cmSpring) { onReset?() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(CMTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            Text(detail).font(.subheadline).foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Input Summary (post-calculate)

struct InputSummaryView: View {
    @Environment(CartConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Cart Configuration")
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)

            summaryRow("Cart Size", value: viewModel.cartSize.rawValue)
            summaryRow("Cart Count", value: "\(viewModel.cartCount)")
            summaryRow("Total Volume", value: String(format: "%.2f ml", viewModel.finalVolume_mL))
            summaryRow("Weed %", value: String(format: "%.1f%%", viewModel.weedComposition * 100))
            summaryRow("Terp %", value: String(format: "%.1f%%", viewModel.terpComposition * 100))
            if viewModel.socialDosing {
                summaryRow("Base %", value: String(format: "%.1f%%", viewModel.baseComposition * 100))
                summaryRow("Cut %", value: String(format: "%.1f%%", viewModel.cutComposition * 100))
                summaryRow("Mode", value: "Social Dose")
            }

            if !viewModel.selectedTerpenes.isEmpty {
                summarySubheader("Terpene Blend")
                ForEach(viewModel.selectedTerpenes.sorted(by: { $0.key.id < $1.key.id }), id: \.key) { terp, pct in
                    summaryRow(terp.displayName, value: String(format: "%.0f%%", pct))
                }
            }

            Spacer().frame(height: 8)
        }
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 3)
    }

    private func summarySubheader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(CMTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}
