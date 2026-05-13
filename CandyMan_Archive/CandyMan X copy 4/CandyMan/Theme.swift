//
//  Theme.swift
//  CandyMan
//
//  Design system for the CandyMan app.
//
//  Contents:
//    AccentTheme       – 15 preset accent color palettes
//    CMTheme           – Semantic colors, corner radii, shadows
//    GlassCard         – Card background modifier
//    CMButtonStyle     – Accent-filled button modifier
//    CMFieldStyle      – Text field background modifier
//    CMHaptic          – Haptic feedback helpers
//    NumericField      – String-buffered numeric text fields
//    GlassCopyButton   – Animated clipboard copy button
//    PsychedelicCopyAlert – Animated "Copied" toast
//    GlassOrbButton    – Scroll-to-top/bottom orb buttons
//    SkittleSwirl*     – Rotating candy-color gradient modifiers
//    CMClipboard       – Cross-platform clipboard helper
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Accent Theme Palette

enum AccentTheme: String, CaseIterable, Identifiable {
    case deepCurrent  = "Deep Current"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .deepCurrent:  return Color(red: 0.031, green: 0.514, blue: 0.584)  // #088395
        }
    }
}

// MARK: - CandyMan Design System

enum CMTheme {

    /// Mutable flag read by all color properties. Updated by SystemConfig.
    nonisolated(unsafe) static var isDark: Bool = true

    /// The colorScheme environment override matching the current mode
    static var colorSchemeEnvironment: ColorScheme {
        isDark ? .dark : .light
    }

    // MARK: Accent Colors

    /// Default accent — used as fallback in modifiers with default parameters
    static let defaultAccent = Color(red: 0.38, green: 0.45, blue: 0.95)
    /// Secondary accent — warm amber
    static let accentWarm = Color(red: 0.92, green: 0.68, blue: 0.32)
    /// Success green
    static let success = Color(red: 0.30, green: 0.78, blue: 0.55)
    /// Danger / error red
    static let danger = Color(red: 0.90, green: 0.32, blue: 0.35)
    /// Lock / reset red — used for lock icons, reset arrows, and destructive inline actions
    static let lockRed = Color(red: 0.929, green: 0.278, blue: 0.290)
    /// High-precision cyan — used for HP mode sub-rows and the scope toggle
    static let hpCyan = Color(red: 0.0, green: 0.85, blue: 1.0)

    // MARK: Surfaces

    /// Page background — deep cool gray / solarized cream
    static var pageBG: Color {
        isDark
            ? Color(red: 0.11, green: 0.11, blue: 0.14)
            : Color(red: 0.992, green: 0.965, blue: 0.890)  // #FDF6E3
    }
    /// Card background — slightly lifted dark / solarized base2
    static var cardBG: Color {
        isDark
            ? Color(red: 0.16, green: 0.16, blue: 0.20)
            : Color(red: 0.933, green: 0.910, blue: 0.835)  // #EEE8D5
    }
    /// Subtle row highlight
    static var rowHighlight: Color {
        isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
    }
    /// Divider color
    static var divider: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    /// Total-row background tint
    static var totalRowBG: Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    // MARK: Text

    static var textPrimary: Color {
        isDark
            ? Color.white.opacity(0.92)
            : Color(red: 0.027, green: 0.212, blue: 0.259)  // #073642
    }
    static var textSecondary: Color {
        isDark
            ? Color.white.opacity(0.45)
            : Color(red: 0.345, green: 0.431, blue: 0.459)  // #586E75
    }
    static var textTertiary: Color {
        isDark
            ? Color.white.opacity(0.22)
            : Color(red: 0.576, green: 0.631, blue: 0.631)  // #93A1A1
    }

    // MARK: Interactive

    /// Tag / chip unselected background
    static var chipBG: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
    /// Text field background
    static var fieldBG: Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    // MARK: Adaptive Helpers

    /// Card stroke color — adapts to mode
    static var cardStroke: Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }
    /// Overlay highlight — subtle strokes and capsule backgrounds
    static var overlayHighlight: Color {
        isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }
    /// Selection ring for accent/color swatches
    static var selectionRing: Color {
        isDark ? Color.white.opacity(0.90) : Color.black.opacity(0.60)
    }
    /// Custom toggle capsule off-state background
    static var toggleOffBG: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    /// Custom toggle capsule off-state knob
    static var toggleOffKnob: Color {
        isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.25)
    }

    // MARK: Corner Radius

    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let chipRadius: CGFloat = 10
    static let fieldRadius: CGFloat = 10

    // MARK: Shadows

    static var cardShadow: Color {
        isDark ? Color.black.opacity(0.35) : Color.black.opacity(0.10)
    }
    static let cardShadowRadius: CGFloat = 12
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    @Environment(\.colorScheme) private var colorScheme  // forces re-render on mode change

    func body(content: Content) -> some View {
        let _ = colorScheme  // read to establish dependency
        content
            .background(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .fill(CMTheme.cardBG)
                    .overlay(
                        RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                            .stroke(CMTheme.cardStroke, lineWidth: 0.5)
                    )
                    .shadow(color: CMTheme.cardShadow, radius: CMTheme.cardShadowRadius, x: 0, y: 6)
            )
            .padding(.horizontal, padding)
            .padding(.vertical, 6)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Themed Divider

struct ThemedDivider: View {
    var indent: CGFloat = 16

    var body: some View {
        Rectangle()
            .fill(CMTheme.divider)
            .frame(height: 0.5)
            .padding(.horizontal, indent)
    }
}

// MARK: - RainbowSlide Slider Tint

/// **RainbowSlide** — Slider tint that shifts through a candy spectrum based on
/// the current percentage value (0–100). At 0% the slider is cool blue, ramping
/// through cyan, green, yellow, orange, and finishing at hot magenta at 100%.
/// Do not delete.
struct RainbowSlideModifier: ViewModifier {
    let value: Double   // 0...100
    let range: ClosedRange<Double>  // e.g. 0...100

    /// Candy spectrum stops — interpolated by slider position.
    /// Candy spectrum stops — interpolated by slider position.
    private static let spectrum: [(pos: Double, color: (r: Double, g: Double, b: Double))] = [
        (0.00, (0.35, 0.45, 0.95)),  // Cool indigo
        (0.15, (0.00, 0.70, 1.00)),  // Electric cyan
        (0.30, (0.00, 0.90, 0.50)),  // Rave green
        (0.50, (1.00, 0.85, 0.00)),  // Skittles yellow
        (0.70, (1.00, 0.45, 0.00)),  // Tangerine
        (0.85, (1.00, 0.10, 0.30)),  // Neon strawberry
        (1.00, (1.00, 0.00, 0.55)),  // Hot magenta
    ]

    private var tintColor: Color {
        let t = range.upperBound > range.lowerBound
            ? (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            : 0
        let clamped = min(max(t, 0), 1)

        // Find the two surrounding stops
        let stops = Self.spectrum
        guard var lower = stops.first, var upper = stops.last else { return .clear }
        for i in 0..<(stops.count - 1) {
            if clamped >= stops[i].pos && clamped <= stops[i + 1].pos {
                lower = stops[i]
                upper = stops[i + 1]
                break
            }
        }

        let segLen = upper.pos - lower.pos
        let frac = segLen > 0 ? (clamped - lower.pos) / segLen : 0

        let r = lower.color.r + (upper.color.r - lower.color.r) * frac
        let g = lower.color.g + (upper.color.g - lower.color.g) * frac
        let b = lower.color.b + (upper.color.b - lower.color.b) * frac

        return Color(red: r, green: g, blue: b)
    }

    func body(content: Content) -> some View {
        content.tint(tintColor)
    }
}

extension View {
    /// Apply the **RainbowSlide** tint to a slider based on its current value and range.
    func rainbowSlide(value: Double, in range: ClosedRange<Double> = 0...100) -> some View {
        modifier(RainbowSlideModifier(value: value, range: range))
    }
}

// MARK: - Accent Button Style

struct CMButtonStyle: ViewModifier {
    var color: Color = CMTheme.defaultAccent
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: CMTheme.buttonRadius, style: .continuous)
                    .fill(isDisabled ? CMTheme.chipBG : color)
            )
            .foregroundStyle(isDisabled ? CMTheme.textTertiary : .white)
            .font(.headline)
    }
}

// MARK: - Section Header Style

struct CMSectionHeader: View {
    let title: String
    var detail: String? = nil
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(systemConfig.accent)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(CMTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Themed Text Field Background

struct CMFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: CMTheme.fieldRadius, style: .continuous)
                    .fill(CMTheme.fieldBG)
            )
    }
}

extension View {
    func cmFieldStyle() -> some View {
        modifier(CMFieldStyle())
    }
}

// MARK: - Design Language — Font-Only Modifiers

extension View {
    /// Monospaced 12pt — the primary data font across all tables.
    func cmMono12() -> some View {
        self.font(.system(size: 12, design: .monospaced))
    }
    /// Monospaced 11pt — HP sub-rows and validation rows.
    func cmMono11() -> some View {
        self.font(.system(size: 11, design: .monospaced))
    }
    /// Monospaced 10pt — column headers and fine-print breakdown rows.
    func cmMono10() -> some View {
        self.font(.system(size: 10, design: .monospaced))
    }
}

// MARK: - Design Language — Text Style Modifiers

struct CMRowLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(CMTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

struct CMSubsectionTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(CMTheme.textSecondary)
    }
}

struct CMFootnoteStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(CMTheme.textTertiary)
    }
}

struct CMTotalLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .fontWeight(.semibold)
            .foregroundStyle(CMTheme.textPrimary)
    }
}

struct CMHpLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(CMTheme.hpCyan.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

struct CMFinePrintStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(CMTheme.textTertiary)
    }
}

extension View {
    /// Row label: mono 12pt, primary color, clamped to 1 line.
    func cmRowLabel() -> some View { modifier(CMRowLabel()) }
    /// Subsection header: subheadline semibold, secondary color.
    func cmSubsectionTitle() -> some View { modifier(CMSubsectionTitleStyle()) }
    /// Section title: headline font + dynamic accent color.
    func cmSectionTitle(accent: Color) -> some View {
        self.font(.headline).foregroundStyle(accent)
    }
    /// Footnote / fine-print: caption, tertiary color.
    func cmFootnote() -> some View { modifier(CMFootnoteStyle()) }
    /// Total-row label: mono 11pt, semibold, primary color.
    func cmTotalLabel() -> some View { modifier(CMTotalLabelStyle()) }
    /// High-precision sub-row label: mono 11pt, cyan, clamped.
    func cmHpLabel() -> some View { modifier(CMHpLabelStyle()) }
    /// Fine print: mono 10pt, tertiary.
    func cmFinePrint() -> some View { modifier(CMFinePrintStyle()) }
}

// MARK: - Design Language — Slot Modifiers (Font + Color + Frame)

struct CMValueSlot: ViewModifier {
    var width: CGFloat = 70
    var color: Color = CMTheme.textSecondary

    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(color)
            .frame(width: width, alignment: .trailing)
    }
}

struct CMUnitSlot: ViewModifier {
    var width: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(CMTheme.textTertiary)
            .frame(width: width, alignment: .leading)
    }
}

struct CMColumnHeader: ViewModifier {
    var width: CGFloat = 70

    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(CMTheme.textTertiary)
            .frame(width: width, alignment: .trailing)
    }
}

struct CMValidationSlot: ViewModifier {
    var width: CGFloat = 70
    var color: Color = CMTheme.textSecondary

    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(color)
            .frame(width: width, alignment: .trailing)
    }
}

struct CMHpValueSlot: ViewModifier {
    var width: CGFloat = 80

    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(CMTheme.hpCyan.opacity(0.6))
            .frame(width: width, alignment: .trailing)
    }
}

extension View {
    /// Value slot: mono 12pt, secondary color, fixed width trailing-aligned.
    func cmValueSlot(width: CGFloat = 70, color: Color = CMTheme.textSecondary) -> some View {
        modifier(CMValueSlot(width: width, color: color))
    }
    /// Unit slot: mono 12pt, tertiary color, fixed width leading-aligned.
    func cmUnitSlot(width: CGFloat = 28) -> some View {
        modifier(CMUnitSlot(width: width))
    }
    /// Column header slot: mono 10pt, tertiary, fixed width trailing.
    func cmColumnHeader(width: CGFloat = 70) -> some View {
        modifier(CMColumnHeader(width: width))
    }
    /// Validation value slot: mono 11pt, secondary, fixed width trailing.
    func cmValidationSlot(width: CGFloat = 70, color: Color = CMTheme.textSecondary) -> some View {
        modifier(CMValidationSlot(width: width, color: color))
    }
    /// HP sub-row value: mono 11pt, cyan 0.6 opacity, fixed width trailing.
    func cmHpValueSlot(width: CGFloat = 80) -> some View {
        modifier(CMHpValueSlot(width: width))
    }
}

// MARK: - Design Language — Padding Modifiers

extension View {
    /// Standard data row: horizontal 20, vertical 2.
    func cmDataRowPadding() -> some View {
        self.padding(.horizontal, 20).padding(.vertical, 2)
    }
    /// Saved/total row: horizontal 20, vertical 3.
    func cmSavedRowPadding() -> some View {
        self.padding(.horizontal, 20).padding(.vertical, 3)
    }
    /// Settings row: horizontal 16, vertical 10.
    func cmSettingsRowPadding() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 10)
    }
    /// Card header: horizontal 16, vertical 12.
    func cmCardHeaderPadding() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 12)
    }
    /// HP sub-row: leading 36, trailing 20, vertical 1.
    func cmHpSubRowPadding() -> some View {
        self.padding(.leading, 36).padding(.trailing, 20).padding(.vertical, 1)
    }
    /// Subsection header: horizontal 16, top 10, bottom 4.
    func cmSubsectionPadding() -> some View {
        self.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
    }
}

// MARK: - Design Language — Icon Style Modifiers

extension View {
    /// Reset icon: size 14, medium weight, lockRed.
    func cmResetIcon() -> some View {
        self.font(.system(size: 14, weight: .medium))
            .foregroundStyle(CMTheme.lockRed)
    }
    /// Lock icon: size 14, medium weight; red when locked, tertiary when unlocked.
    func cmLockIcon(isLocked: Bool) -> some View {
        self.font(.system(size: 14, weight: .medium))
            .foregroundStyle(isLocked ? CMTheme.lockRed : CMTheme.textTertiary)
    }
}

// MARK: - Design Language — Transition Modifiers

extension View {
    /// Section expand/collapse transition: fade + slide from top.
    func cmExpandTransition() -> some View {
        self.transition(.opacity.combined(with: .move(edge: .top)))
    }
    /// Reset button appear/disappear: scale + opacity.
    func cmResetTransition() -> some View {
        self.transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Design Language — Composite Modifiers

struct CMModalCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .fill(CMTheme.cardBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CMTheme.cardRadius, style: .continuous)
                    .stroke(CMTheme.cardStroke, lineWidth: 1)
            )
            .padding(.horizontal, 24)
    }
}

struct CMPopupRowBG: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(CMTheme.fieldBG)
            )
    }
}

extension View {
    /// Modal overlay card: cardBG fill, cardStroke border, 24pt horizontal padding.
    func cmModalCard() -> some View { modifier(CMModalCardStyle()) }
    /// Popup table row background: 4pt inset padding + 6pt corner radius field BG.
    func cmPopupRowBG() -> some View { modifier(CMPopupRowBG()) }
}

/// Reusable chevron that rotates 180° to indicate expand/collapse state.
struct CMDisclosureChevron: View {
    let isExpanded: Bool

    var body: some View {
        Image(systemName: "chevron.down")
            .font(.subheadline)
            .foregroundStyle(CMTheme.textTertiary)
            .rotationEffect(.degrees(isExpanded ? -180 : 0))
            .animation(.cmExpand, value: isExpanded)
    }
}

// MARK: - Haptic Feedback

enum CMHaptic {
#if canImport(UIKit)
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Light tap — chip/tag selection, minor toggles
    static func light() {
        lightGenerator.impactOccurred()
    }

    /// Light tap with custom intensity (0.0–1.0) — slider feedback
    static func light(intensity: CGFloat) {
        lightGenerator.impactOccurred(intensity: intensity)
    }

    /// Medium tap — button presses, shape selection, locking actions
    static func medium() {
        mediumGenerator.impactOccurred()
    }

    /// Heavy tap — calculate, reset, save actions
    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    /// Crisp selection tick — stepper increment, picker change
    static func selection() {
        selectionGenerator.selectionChanged()
    }

    /// Success — batch saved, data copied
    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Error — validation failure
    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }
#else
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func selection() {}
    static func success() {}
    static func error() {}
#endif
}

// MARK: - Smooth Spring Animation

extension Animation {
    /// Snappy spring used across the app for interactive feedback
    static var cmSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }

    /// Gentler spring for section expand/collapse
    static var cmExpand: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
}

// MARK: - Glass Copy Button

struct GlassCopyButton: View {
    let action: () -> Void

    @State private var tapped = false
    @State private var ringFlash: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0

    private static let glassBase = Color(red: 0.18, green: 0.18, blue: 0.22)
    private static let flashCyan = Color(red: 0.0, green: 1.0, blue: 0.85)
    private static let flashPink = Color(red: 1.0, green: 0.05, blue: 0.5)

    var body: some View {
        Button {
            guard !tapped else { return }
            tapped = true
            action()

            // Bounce down then overshoot up
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                bounceScale = 0.7
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) {
                    bounceScale = 1.0
                }
            }

            // Ring flash
            withAnimation(.easeOut(duration: 0.25)) {
                ringFlash = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeIn(duration: 0.3)) {
                    ringFlash = 0
                }
            }

            // Reset icon after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.cmSpring) { tapped = false }
            }
        } label: {
            ZStack {
                // Expanding ring flash
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Self.flashCyan, Self.flashPink, Self.flashCyan],
                            center: .center
                        ),
                        lineWidth: 2.0 * ringFlash
                    )
                    .scaleEffect(1.0 + ringFlash * 0.5)
                    .opacity(Double(ringFlash) * 0.9)

                // Glass circle
                Circle()
                    .fill(Self.glassBase.opacity(tapped ? 0.95 : 0.85))

                // Border
                Circle()
                    .stroke(
                        tapped
                            ? LinearGradient(colors: [Self.flashCyan, Self.flashPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [CMTheme.overlayHighlight, CMTheme.overlayHighlight], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: tapped ? 1.2 : 0.5
                    )

                // Icon: morphs from clipboard to checkmark
                Image(systemName: tapped ? "checkmark" : "doc.on.clipboard")
                    .font(.system(size: tapped ? 13 : 12, weight: tapped ? .bold : .medium))
                    .foregroundStyle(tapped ? Self.flashCyan : CMTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace.offUp))
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .scaleEffect(bounceScale)
    }
}

// MARK: - Glass Settings Button

/// Animated toolbar button for opening Settings. Spins the gear on tap with a
/// neon ring flash and morphs to a checkmark before resetting.
struct GlassSettingsButton: View {
    let action: () -> Void

    @State private var tapped = false
    @State private var ringFlash: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var gearRotation: Double = 0

    private static let glassBase = Color(red: 0.18, green: 0.18, blue: 0.22)
    private static let flashGold = Color(red: 1.0, green: 0.8, blue: 0.0)
    private static let flashViolet = Color(red: 0.6, green: 0.0, blue: 1.0)

    var body: some View {
        Button {
            guard !tapped else { return }
            tapped = true
            action()

            // Gear spin
            withAnimation(.easeInOut(duration: 0.5)) {
                gearRotation += 180
            }

            // Bounce
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                bounceScale = 0.7
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) {
                    bounceScale = 1.0
                }
            }

            // Ring flash
            withAnimation(.easeOut(duration: 0.25)) {
                ringFlash = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeIn(duration: 0.3)) {
                    ringFlash = 0
                }
            }

            // Reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.cmSpring) { tapped = false }
            }
        } label: {
            ZStack {
                // Expanding ring flash
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Self.flashGold, Self.flashViolet, Self.flashGold],
                            center: .center
                        ),
                        lineWidth: 2.0 * ringFlash
                    )
                    .scaleEffect(1.0 + ringFlash * 0.5)
                    .opacity(Double(ringFlash) * 0.9)

                // Glass circle
                Circle()
                    .fill(Self.glassBase.opacity(tapped ? 0.95 : 0.85))

                // Border
                Circle()
                    .stroke(
                        tapped
                            ? LinearGradient(colors: [Self.flashGold, Self.flashViolet], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [CMTheme.overlayHighlight, CMTheme.overlayHighlight], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: tapped ? 1.2 : 0.5
                    )

                // Spinning gear icon
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tapped ? Self.flashGold : CMTheme.textSecondary)
                    .rotationEffect(.degrees(gearRotation))
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .scaleEffect(bounceScale)
    }
}

// MARK: - Glass History Button

/// Animated toolbar button for opening Batch History. Flips the book icon on
/// tap with a neon ring flash and a page-turn 3D rotation.
struct GlassHistoryButton: View {
    let action: () -> Void

    @State private var tapped = false
    @State private var ringFlash: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var flipAngle: Double = 0

    private static let glassBase = Color(red: 0.18, green: 0.18, blue: 0.22)
    private static let flashCyan = Color(red: 0.0, green: 1.0, blue: 0.85)
    private static let flashOrange = Color(red: 1.0, green: 0.45, blue: 0.0)

    var body: some View {
        Button {
            guard !tapped else { return }
            tapped = true
            action()

            // Page-flip rotation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                flipAngle = 360
            }

            // Bounce
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                bounceScale = 0.7
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) {
                    bounceScale = 1.0
                }
            }

            // Ring flash
            withAnimation(.easeOut(duration: 0.25)) {
                ringFlash = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeIn(duration: 0.3)) {
                    ringFlash = 0
                }
            }

            // Reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.cmSpring) {
                    tapped = false
                    flipAngle = 0
                }
            }
        } label: {
            ZStack {
                // Expanding ring flash
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Self.flashCyan, Self.flashOrange, Self.flashCyan],
                            center: .center
                        ),
                        lineWidth: 2.0 * ringFlash
                    )
                    .scaleEffect(1.0 + ringFlash * 0.5)
                    .opacity(Double(ringFlash) * 0.9)

                // Glass circle
                Circle()
                    .fill(Self.glassBase.opacity(tapped ? 0.95 : 0.85))

                // Border
                Circle()
                    .stroke(
                        tapped
                            ? LinearGradient(colors: [Self.flashCyan, Self.flashOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [CMTheme.overlayHighlight, CMTheme.overlayHighlight], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: tapped ? 1.2 : 0.5
                    )

                // Book icon with page-flip 3D rotation
                Image(systemName: "book.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(tapped ? Self.flashCyan : CMTheme.textSecondary)
                    .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0))
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .scaleEffect(bounceScale)
    }
}

// MARK: - Psychedelic Copy Alert

/// A floating psychedelic toast that shows what was copied to the clipboard.
/// Appears with a scale-in + fade, breathes while visible, then auto-dismisses.
struct PsychedelicCopyAlert: View {
    let label: String
    @State private var phase: CGFloat = 0
    @State private var breathe: CGFloat = 0.85
    @State private var textOpacity: CGFloat = 0

    private let neonPalette: [Color] = [
        Color(red: 0.0, green: 1.0, blue: 0.85),   // acid cyan
        Color(red: 0.4, green: 0.0, blue: 1.0),     // deep violet
        Color(red: 1.0, green: 0.05, blue: 0.5),    // neon pink
        Color(red: 1.0, green: 0.8, blue: 0.0),     // golden
        Color(red: 0.0, green: 1.0, blue: 0.4),     // toxic green
        Color(red: 0.0, green: 0.5, blue: 1.0),     // electric blue
        Color(red: 0.0, green: 1.0, blue: 0.85),    // back to cyan
    ]

    var body: some View {
        ZStack {
            // Outer glow aura
            Capsule()
                .fill(
                    AngularGradient(colors: neonPalette, center: .center, angle: .degrees(-phase))
                )
                .blur(radius: 18)
                .drawingGroup()
                .opacity(0.35)
                .scaleEffect(1.1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Main pill
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Copied")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.7), radius: 3)

                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Rotating gradient fill
                    Capsule()
                        .fill(
                            AngularGradient(colors: neonPalette, center: .center, angle: .degrees(phase))
                        )

                    // Dark glass overlay
                    Capsule()
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.14).opacity(0.55))

                    // Shimmer border
                    Capsule()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .white.opacity(0.8),
                                    .clear,
                                    Color(red: 0.0, green: 1.0, blue: 0.85).opacity(0.6),
                                    .clear,
                                    Color(red: 1.0, green: 0.05, blue: 0.5).opacity(0.5),
                                    .clear,
                                    .white.opacity(0.8),
                                ],
                                center: .center,
                                angle: .degrees(-phase * 1.5)
                            ),
                            lineWidth: 1.2
                        )
                }
                .drawingGroup()
                .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.85).opacity(0.4), radius: 12, y: 2)
            )
            .opacity(textOpacity)
        }
        .scaleEffect(breathe)
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.easeOut(duration: 0.3)) {
                breathe = 1.0
                textOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3)) {
                breathe = 1.03
            }
        }
    }
}

/// View modifier that overlays a `PsychedelicCopyAlert` anchored to the top of the view.
struct CopyAlertOverlay: ViewModifier {
    @Binding var isShowing: Bool
    let label: String

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isShowing {
                PsychedelicCopyAlert(label: label)
                    .padding(.top, 8)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isShowing)
    }
}

extension View {
    /// Attach a psychedelic "Copied" toast to this view.
    func copyAlert(isShowing: Binding<Bool>, label: String) -> some View {
        modifier(CopyAlertOverlay(isShowing: isShowing, label: label))
    }
}

// MARK: - Press-Scale Button Style

/// Button style that adds a subtle scale-down on press
struct CMPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.cmSpring, value: configuration.isPressed)
    }
}

// MARK: - Select-All-On-Focus for Numeric Fields

struct SelectAllOnFocus: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                if focused {
                    #if canImport(UIKit)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                    }
                    #endif
                }
            }
    }
}

extension View {
    func selectAllOnFocus() -> some View {
        modifier(SelectAllOnFocus())
    }
}

// MARK: - Scribble (Apple Pencil Handwriting) Removal

#if canImport(UIKit)
/// Strips UIScribbleInteraction from ALL UITextFields globally, before the
/// pencil ever touches them. Runs once at launch and observes keyboard show
/// to re-strip any that iOS re-adds.
/// Helper class for the keyboard dismiss toolbar action target.
private final class KeyboardDismissHelper: NSObject {
    static let shared = KeyboardDismissHelper()
    @objc func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum ScribbleKiller {
    private static var installed = false
    /// Creates a new accessory view placed above the keyboard with a dismiss button at top-right.
    /// Each text field gets its own instance so the view stays properly attached.
    private static func makeDismissToolbar() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 36))
        container.backgroundColor = .clear

        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.down.circle")?.withConfiguration(config), for: .normal)
        button.tintColor = UIColor(red: 0.753, green: 0.027, blue: 0.027, alpha: 1)
        button.addTarget(KeyboardDismissHelper.shared, action: #selector(KeyboardDismissHelper.dismissKeyboard), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        return container
    }

    static func install() {
        guard !installed else { return }
        installed = true

        // When the keyboard appears for any text field, strip scribble
        // and attach the dismiss toolbar as inputAccessoryView.
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidBeginEditingNotification,
            object: nil,
            queue: .main
        ) { note in
            guard let tf = note.object as? UITextField else { return }
            stripScribble(from: tf)
            if tf.inputAccessoryView == nil {
                tf.inputAccessoryView = makeDismissToolbar()
                tf.reloadInputViews()
            }
        }

        // Also strip when any window's scene becomes active, catching fields
        // that existed before any editing began.
        NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                stripAllTextFields()
            }
        }
    }

    static func stripScribble(from tf: UITextField) {
        var toRemove: [UIInteraction] = []
        for interaction in tf.interactions {
            if interaction is UIScribbleInteraction {
                toRemove.append(interaction)
            }
        }
        for interaction in toRemove {
            tf.removeInteraction(interaction)
        }
    }

    private static func stripAllTextFields() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in scene.windows {
            stripTextFieldsRecursive(in: window)
        }
    }

    private static func stripTextFieldsRecursive(in view: UIView) {
        if let tf = view as? UITextField {
            stripScribble(from: tf)
        }
        for sub in view.subviews {
            stripTextFieldsRecursive(in: sub)
        }
    }
}
#endif

extension View {
    /// Per-field scribble removal kept for defense-in-depth. The heavy lifting
    /// is done globally by ScribbleKiller; this catches any edge cases.
    func scribbleDisabled() -> some View { self }
}

// MARK: - Numeric Field Formatting Helpers

/// Shared formatting logic for `NumericField` and `OptionalNumericField`.
private enum NumericFormatting {
    /// Placeholder string for a given decimal count (e.g. "0.000").
    static func placeholder(decimals: Int) -> String {
        decimals == 0 ? "0" : "0." + String(repeating: "0", count: decimals)
    }

    /// Display format: fixed decimal places, blank if zero.
    static func display(_ v: Double, decimals: Int) -> String {
        if v == 0 { return "" }
        return String(format: "%.\(decimals)f", v)
    }

    /// Editing format: strips trailing zeros for easier typing.
    static func editing(_ v: Double, decimals: Int) -> String {
        if v == 0 { return "" }
        let formatted = String(format: "%.\(decimals)f", v)
        guard formatted.contains(".") else { return formatted }
        let trimmed = formatted.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed
    }

    /// Select-all on focus via UIKit (no-op on macOS).
    static func selectAll() {
        #if canImport(UIKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
        }
        #endif
    }
}

// MARK: - String-Buffered Numeric TextField

/// A text field for numeric input that avoids SwiftUI's real-time format coercion bugs.
/// Uses a string buffer internally and only commits the parsed value on focus loss.
struct NumericField: View {
    @Binding var value: Double
    var decimals: Int = 3
    var placeholder: String? = nil
    /// External focus binding — use to pause animations while the user is typing.
    var isFocusedBinding: Binding<Bool> = .constant(false)

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder ?? NumericFormatting.placeholder(decimals: decimals), text: $text)
            .keyboardType(.decimalPad)
            .scribbleDisabled()
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                isFocusedBinding.wrappedValue = focused
                if focused {
                    text = NumericFormatting.editing(value, decimals: decimals)
                    NumericFormatting.selectAll()
                } else {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        if let parsed = Double(text) { value = parsed }
                        text = NumericFormatting.display(value, decimals: decimals)
                    }
                }
            }
            .onAppear { text = NumericFormatting.display(value, decimals: decimals) }
            .onChange(of: value) { _, newVal in
                if !isFocused { text = NumericFormatting.display(newVal, decimals: decimals) }
            }
    }
}

/// Optional-Double variant for fields bound to `Double?` (nil = empty field).
struct OptionalNumericField: View {
    @Binding var value: Double?
    var decimals: Int = 3
    var placeholder: String? = nil

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder ?? NumericFormatting.placeholder(decimals: decimals), text: $text)
            .keyboardType(.decimalPad)
            .scribbleDisabled()
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                if focused {
                    text = value.map { NumericFormatting.editing($0, decimals: decimals) } ?? ""
                    NumericFormatting.selectAll()
                } else {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        if text.trimmingCharacters(in: .whitespaces).isEmpty {
                            value = nil
                        } else if let parsed = Double(text) {
                            value = parsed
                        }
                        text = value.map { NumericFormatting.display($0, decimals: decimals) } ?? ""
                    }
                }
            }
            .onAppear { text = value.map { NumericFormatting.display($0, decimals: decimals) } ?? "" }
            .onChange(of: value) { _, newVal in
                if !isFocused { text = newVal.map { NumericFormatting.display($0, decimals: decimals) } ?? "" }
            }
    }
}

// MARK: - Keyboard Dismiss Toolbar

struct KeyboardDismissToolbar: ViewModifier {
    @Environment(SystemConfig.self) private var systemConfig

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    KeyboardDismissButton(accent: systemConfig.accent)
                }
            }
        #else
        content
        #endif
    }
}

#if canImport(UIKit)
private struct KeyboardDismissButton: View {
    let accent: Color
    @State private var tapCount = 0

    var body: some View {
        Button {
            tapCount += 1
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        } label: {
            Image(systemName: "chevron.down.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.753, green: 0.027, blue: 0.027))
                .symbolEffect(.bounce.down, options: .speed(1.5), value: tapCount)
        }
    }
}
#endif

extension View {
    func keyboardDismissToolbar() -> some View {
        modifier(KeyboardDismissToolbar())
    }
}

// MARK: - Glass Orb Scroll Buttons
//
// TopJumpButton1 and BottomJumpButton1 share an identical glass orb visual —
// only the arrow direction differs. The shared rendering is in `GlassOrbButton`.

/// Reusable glass orb button with a configurable SF Symbol and bounce direction.
private struct GlassOrbButton: View {
    let systemName: String
    let bounceUp: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var bounceCount = 0

    var body: some View {
        Button {
            bounceCount += 1
            action()
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 54, height: 54)
                    .blur(radius: 6)

                // Glass body
                Circle()
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.85))
                    .frame(width: 48, height: 48)

                // Top highlight crescent
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: 36, height: 21)
                    .offset(y: -9)

                // Icon
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(
                        bounceUp ? .bounce.up : .bounce.down,
                        options: .speed(1.5),
                        value: bounceCount
                    )

                // Edge ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.0), .white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
                    .frame(width: 48, height: 48)
            }
            .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// Glass orb scroll-to-top button.
struct TopJumpButton1: View {
    let action: () -> Void
    var body: some View {
        GlassOrbButton(systemName: "arrow.up", bounceUp: true, action: action)
    }
}

/// Glass orb scroll-to-bottom button.
struct BottomJumpButton1: View {
    let action: () -> Void
    var body: some View {
        GlassOrbButton(systemName: "arrow.down", bounceUp: false, action: action)
    }
}

/// BottomJumpButton2 — Glass orb with psychedelic burst on tap that decays as e^(-kt).
/// k = ln(100)/4 ≈ 1.1513 so 99% of the effect fades in 4 seconds.
struct BottomJumpButton2: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var bounceCount = 0
    @State private var tapTime: Date? = nil
    @State private var phase: CGFloat = 0
    @State private var animating = false

    /// Decay constant: 99% gone in 4 s  →  e^(-k·4) = 0.01  →  k = ln(100)/4
    private let k: Double = log(100.0) / 4.0   // ≈ 1.1513

    private let plasmaColors: [Color] = [
        Color(red: 0.0, green: 0.0, blue: 0.2),
        Color(red: 0.3, green: 0.0, blue: 0.8),
        Color(red: 0.8, green: 0.0, blue: 0.6),
        Color(red: 1.0, green: 0.2, blue: 0.0),
        Color(red: 1.0, green: 0.8, blue: 0.0),
        Color(red: 0.0, green: 1.0, blue: 0.5),
        Color(red: 0.0, green: 0.4, blue: 1.0),
        Color(red: 0.0, green: 0.0, blue: 0.2),
    ]

    var body: some View {
        Button {
            bounceCount += 1
            tapTime = .now
            // Start rotation if not already running
            if !animating {
                animating = true
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
            action()
        } label: {
            TimelineView(.animation(paused: tapTime == nil || tapTime.map { Date.now.timeIntervalSince($0) > 5 } == true)) { timeline in
                let elapsed = tapTime.map { timeline.date.timeIntervalSince($0) } ?? 99
                let intensity = max(0, exp(-k * elapsed))

                ZStack {
                    // ── Psychedelic background (decays) ──

                    // Base plasma
                    Circle()
                        .fill(
                            AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                        )
                        .frame(width: 48, height: 48)

                    // Counter-rotating shimmer
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                                    Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.3),
                                    Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.3),
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
                                ],
                                center: .center,
                                angle: .degrees(-phase + 180)
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blendMode(.screen)

                    // Neon ring (decays with plasma)
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7),
                                    .clear,
                                    Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5),
                                    .clear,
                                    Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.7),
                                    .clear,
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7),
                                ],
                                center: .center,
                                angle: .degrees(-phase)
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 48, height: 48)
                        .opacity(intensity)

                    // ── Glass orb (always visible) ──

                    // Outer glow — blends between psychedelic glow and subtle white
                    Circle()
                        .fill(.white.opacity(0.06 + 0.12 * intensity))
                        .frame(width: 54, height: 54)
                        .blur(radius: 6)

                    // Glass body (solid tint — avoids per-frame blur inside TimelineView)
                    Circle()
                        .fill(Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.85))
                        .frame(width: 48, height: 48)

                    // Top highlight crescent
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 36, height: 21)
                        .offset(y: -9)

                    // Icon
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce.down, options: .speed(1.5), value: bounceCount)

                    // Edge ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.0), .white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                        .frame(width: 48, height: 48)
                }
                .shadow(
                    color: intensity > 0.01
                        ? Color(red: 0.3, green: 0.0, blue: 0.8).opacity(0.5 * intensity)
                        : .black.opacity(0.3),
                    radius: 16,
                    x: 0,
                    y: intensity > 0.01 ? 0 : 8
                )
                .onChange(of: elapsed) {
                    // Stop the timeline once fully decayed
                    if elapsed > 6 { tapTime = nil; animating = false; phase = 0 }
                }
            }
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - SkittleSwirl Text Modifier

/// Applies the same rotating candy-color gradient as the CandyMan title
/// to any view content. Works at any size by rendering the AngularGradient
/// inside a large square overlay and masking to the content shape.
struct SkittleSwirlModifier: ViewModifier {
    var isPaused: Bool = false
    @State private var phase: CGFloat = 0

    private let candyColors: [Color] = [
        Color(red: 1.00, green: 0.00, blue: 0.30),
        Color(red: 1.00, green: 0.35, blue: 0.00),
        Color(red: 1.00, green: 0.95, blue: 0.00),
        Color(red: 0.00, green: 1.00, blue: 0.40),
        Color(red: 0.00, green: 0.85, blue: 1.00),
        Color(red: 0.55, green: 0.00, blue: 1.00),
        Color(red: 1.00, green: 0.00, blue: 0.70),
        Color(red: 1.00, green: 0.00, blue: 0.30),
    ]

    func body(content: Content) -> some View {
        // Always use the gradient style to preserve view identity; hide via
        // opacity when paused so @FocusState on child text fields isn't killed.
        content
            .foregroundStyle(
                AnyShapeStyle(AngularGradient(
                    colors: candyColors,
                    center: .center,
                    angle: .degrees(phase)
                ))
            )
            .opacity(isPaused ? 0 : 1)
            .overlay {
                if isPaused {
                    content.foregroundStyle(CMTheme.textPrimary)
                }
            }
            .environment(\.foregroundStylePhase, phase)
            .onAppear { startAnimation() }
            .onChange(of: isPaused) { _, paused in
                if paused {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { phase = 0 }
                } else {
                    DispatchQueue.main.async { startAnimation() }
                }
            }
    }

    private func startAnimation() {
        guard phase == 0 else { return }
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            phase = 360
        }
    }
}

/// Variant that renders the gradient in a fixed large square so narrow/small
/// views still show the full color sweep instead of collapsing to one hue.
struct SkittleSwirlOverlayModifier: ViewModifier {
    var isPaused: Bool = false
    @State private var phase: CGFloat = 0

    private let candyColors: [Color] = [
        Color(red: 1.00, green: 0.00, blue: 0.30),
        Color(red: 1.00, green: 0.35, blue: 0.00),
        Color(red: 1.00, green: 0.95, blue: 0.00),
        Color(red: 0.00, green: 1.00, blue: 0.40),
        Color(red: 0.00, green: 0.85, blue: 1.00),
        Color(red: 0.55, green: 0.00, blue: 1.00),
        Color(red: 1.00, green: 0.00, blue: 0.70),
        Color(red: 1.00, green: 0.00, blue: 0.30),
    ]

    func body(content: Content) -> some View {
        content
            // When not paused, hide the base content so only the gradient-
            // masked copy is visible. When paused, show the base content
            // with a normal readable foreground color.
            .foregroundStyle(isPaused ? AnyShapeStyle(CMTheme.textPrimary) : AnyShapeStyle(.clear))
            .overlay {
                // Always present to preserve view identity (avoids killing
                // @FocusState on the content when isPaused toggles).
                AngularGradient(
                    colors: candyColors,
                    center: .center,
                    angle: .degrees(phase)
                )
                .frame(width: 300, height: 300)
                .mask { content }
                .allowsHitTesting(false)
                .opacity(isPaused ? 0 : 1)
            }
            .clipped()
            .onAppear { startAnimation() }
            .onChange(of: isPaused) { _, paused in
                if paused {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { phase = 0 }
                } else {
                    DispatchQueue.main.async { startAnimation() }
                }
            }
    }

    private func startAnimation() {
        guard phase == 0 else { return }
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            phase = 360
        }
    }
}

private struct ForegroundStylePhaseKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var foregroundStylePhase: CGFloat {
        get { self[ForegroundStylePhaseKey.self] }
        set { self[ForegroundStylePhaseKey.self] = newValue }
    }
}

extension View {
    /// SkittleSwirl for wide content (Text labels, large headings).
    func skittleSwirl(isPaused: Bool = false) -> some View {
        modifier(SkittleSwirlModifier(isPaused: isPaused))
    }

    /// SkittleSwirl for narrow content (TextFields, small numbers).
    /// Uses an overlay so the full color sweep is always visible.
    func skittleSwirlWide(isPaused: Bool = false) -> some View {
        modifier(SkittleSwirlOverlayModifier(isPaused: isPaused))
    }
}

// MARK: - Cross-Platform Clipboard

enum CMClipboard {
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }

    static func paste() -> String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }
}

// MARK: - macOS Compatibility

#if !canImport(UIKit)
// Provide no-op stubs for iOS-only SwiftUI modifiers so the same
// view code compiles on macOS without #if guards at every call site.

enum UIKeyboardType { case decimalPad, numberPad, `default` }
enum TextInputAutocapitalization { case never, words, sentences, characters }

extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View { self }
    func scrollDismissesKeyboard(_ mode: Any) -> some View { self }
    func textInputAutocapitalization(_ style: TextInputAutocapitalization?) -> some View { self }
}

extension ToolbarItemPlacement {
    static var topBarLeading: ToolbarItemPlacement { .automatic }
    static var topBarTrailing: ToolbarItemPlacement { .automatic }
}
#endif
