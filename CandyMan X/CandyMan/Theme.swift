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
                .foregroundStyle(systemConfig.designTitle)
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
    var color: Color = CMTheme.hpCyan

    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(color.opacity(0.8))
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
    func cmHpLabel(color: Color = CMTheme.hpCyan) -> some View { modifier(CMHpLabelStyle(color: color)) }
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
    var color: Color = CMTheme.hpCyan

    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(color.opacity(0.6))
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
    func cmHpValueSlot(width: CGFloat = 80, color: Color = CMTheme.hpCyan) -> some View {
        modifier(CMHpValueSlot(width: width, color: color))
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
    /// Reset icon: size 14, medium weight, alert color.
    func cmResetIcon(color: Color = CMTheme.lockRed) -> some View {
        self.font(.system(size: 14, weight: .medium))
            .foregroundStyle(color)
    }
    /// Lock icon: size 14, medium weight; alert when locked, tertiary when unlocked.
    func cmLockIcon(isLocked: Bool, color: Color = CMTheme.lockRed) -> some View {
        self.font(.system(size: 14, weight: .medium))
            .foregroundStyle(isLocked ? color : CMTheme.textTertiary)
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

// MARK: - Weighted Slider



/// Manual spring state — we drive the spring ourselves so we always know the
/// exact current position (no SwiftUI animation black-box).
///
/// Modeled as a **critically damped** harmonic oscillator:
///   m·x'' + c·x' + k·x = 0
/// where c = 2·√(k·m)  (critical damping condition, ζ = 1).
///
/// This gives the fastest return to equilibrium without overshoot.
private class SpringState {
    var position: Double = 0   // current animated fraction (0–1)
    var velocity: Double = 0   // current velocity
    var target: Double = 0     // where the spring is heading

    // Spring constants — damping derived for critical damping (ζ = 1)
    let stiffness: Double = 180
    let mass: Double = 1.2
    /// Critical damping coefficient: c = 2√(k·m)
    var damping: Double { 2.0 * (stiffness * mass).squareRoot() }

    /// Advance the spring by `dt` seconds using semi-implicit Euler.
    /// Returns the new position.
    @discardableResult
    func step(dt: Double) -> Double {
        let dt = min(dt, 1.0 / 15.0) // cap to avoid huge jumps
        let displacement = position - target
        let springForce = -stiffness * displacement
        let dampingForce = -damping * velocity
        let acceleration = (springForce + dampingForce) / mass
        velocity += acceleration * dt
        position += velocity * dt
        return position
    }

    /// True when the spring has settled close enough to the target.
    var isSettled: Bool {
        abs(position - target) < 0.0005 && abs(velocity) < 0.001
    }

    func settle() {
        position = target
        velocity = 0
    }
}

/// A single ghost afterimage left behind by the slider thumb.
private struct SliderGhost: Identifiable {
    let id: UInt64
    let x: CGFloat          // center X position in the track coordinate space
    let spawnTime: Date     // when this ghost was created
}

/// Shamanic gradient spectrum: deep indigo → purple → magenta → orange → golden yellow.
/// Maps a normalised age (0 = newest, 1 = oldest) to a color along the spectrum.
private func shamanicColor(age t: Double) -> Color {
    // Spectrum stops — positions mapped to (r, g, b)
    let stops: [(pos: Double, r: Double, g: Double, b: Double)] = [
        (0.00, 0.08, 0.02, 0.30),  // deep indigo / near-black purple
        (0.20, 0.30, 0.00, 0.55),  // dark purple
        (0.40, 0.70, 0.00, 0.50),  // magenta
        (0.60, 0.90, 0.15, 0.25),  // hot rose / red-magenta
        (0.80, 1.00, 0.50, 0.00),  // orange
        (1.00, 1.00, 0.85, 0.00),  // golden yellow
    ]
    let clamped = min(max(t, 0), 1)
    // Find surrounding stops
    var lo = stops.first!
    var hi = stops.last!
    for i in 0..<(stops.count - 1) {
        if clamped >= stops[i].pos && clamped <= stops[i + 1].pos {
            lo = stops[i]; hi = stops[i + 1]; break
        }
    }
    let segLen = hi.pos - lo.pos
    let f = segLen > 0 ? (clamped - lo.pos) / segLen : 0
    return Color(
        red:   lo.r + (hi.r - lo.r) * f,
        green: lo.g + (hi.g - lo.g) * f,
        blue:  lo.b + (hi.b - lo.b) * f
    )
}

/// A custom slider that visually tracks the finger at full resolution for
/// smooth movement, but commits the bound `value` at the given `step` size
/// (default 5%). On release the critically-damped spring animates the thumb
/// from the raw finger position to the nearest snap increment. While dragging,
/// shamanic tracer afterimages are left at historical thumb positions, coloured
/// along a deep-indigo → golden-yellow gradient and fading out over time.
struct WeightedSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100
    var step: Double = 5
    var tint: Color = CMTheme.textPrimary
    var showLabel: Bool = true
    var onChanged: ((Double) -> Void)? = nil

    @Environment(SystemConfig.self) private var systemConfig

    /// Manual spring that we tick each frame — gives us the real position.
    @State private var spring = SpringState()
    /// The fraction (0–1) we render at — updated each TimelineView tick.
    @State private var renderFraction: Double = 0
    /// Tracks whether the user is actively dragging.
    @State private var isDragging = false
    /// When the current drag started (for label growth animation).
    @State private var dragStartDate: Date? = nil
    /// When the drag ended (for label shrink animation).
    @State private var dragEndDate: Date? = nil
    /// The label scale at the moment the drag ended (shrink starting point).
    @State private var labelScaleAtRelease: Double = 1.0
    /// Current label scale factor (1.0 = rest, up to 3.0).
    @State private var labelScale: Double = 1.0
    /// The previous thumb X position — used to compute per-frame velocity.
    @State private var prevThumbX: CGFloat = .nan
    /// Whether the timeline should tick.
    @State private var timelineActive = false
    /// Last timeline tick date for computing delta-time.
    @State private var lastTickDate: Date? = nil
    /// Monotonically increasing ID for ghost instances.
    @State private var ghostIDCounter: UInt64 = 0
    /// Active ghost afterimages.
    @State private var ghosts: [SliderGhost] = []


    private func snap(_ raw: Double) -> Double {
        guard step > 0 else { return raw }
        let snapped = (raw / step).rounded() * step
        return min(max(snapped, range.lowerBound), range.upperBound)
    }

    private func valueFraction(_ v: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (v - range.lowerBound) / span
    }



    /// Label growth function: F(x, k) = k / (1 + e^(1/x))
    ///
    /// x = seconds since drag started, k = max-scale parameter.
    /// Label scale range: 1.0 (rest) → maxScale (fully expanded).
    private static let labelMaxScale: Double = 3.0

    // RC circuit time constants.
    // Charge:  99% of max in 0.25s → τ = 0.25 / -ln(0.01)
    // Discharge: 99% decay in 0.25s → τ = 0.25 / -ln(0.01)
    private static let tauCharge:    Double = 0.25 / -log(0.01)   // ≈ 0.0543 s
    private static let tauDischarge: Double = 0.25 / -log(0.01)   // ≈ 0.0543 s

    /// Growth (RC charge): 1 − e^(−t/τ), reaches 99% of maxScale in 0.5 s.
    private static func labelGrowth(elapsed t: Double) -> Double {
        guard t > 0 else { return 1.0 }
        let charge = 1.0 - exp(-t / tauCharge)
        return 1.0 + charge * (labelMaxScale - 1.0)
    }

    /// Decay (RC discharge): e^(−t/τ), returns to 1.0 from scaleAtRelease in ~0.25 s.
    private static func labelDecay(elapsed t: Double, scaleAtRelease: Double) -> Double {
        guard t > 0 else { return scaleAtRelease }
        let discharge = exp(-t / tauDischarge)
        return 1.0 + discharge * (scaleAtRelease - 1.0)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !timelineActive)) { timeline in
            let now = timeline.date

            GeometryReader { geo in
                let trackHeight: CGFloat = 4
                let thumbSize: CGFloat = 28
                let usableWidth = geo.size.width - thumbSize
                let thumbX = thumbSize / 2 + usableWidth * renderFraction
                let displayPercent = range.lowerBound + renderFraction * (range.upperBound - range.lowerBound)

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(CMTheme.fieldBG)
                        .frame(height: trackHeight)

                    // Filled track
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, thumbX), height: trackHeight)

                    // Shamanic tracer ghost trail: gradient-coloured afterimages at
                    // historical positions that fade and blur with age.
                    if systemConfig.doubleVisionEnabled {
                        let fadeTime = max(systemConfig.doubleVisionFadeTime, 0.05)
                        ForEach(ghosts) { ghost in
                            let age = now.timeIntervalSince(ghost.spawnTime)
                            let life = min(max(1.0 - age / fadeTime, 0), 1)
                            let ageFrac = 1.0 - life  // 0 = newest, 1 = oldest
                            if life > 0 {
                                Circle()
                                    .fill(shamanicColor(age: ageFrac))
                                    .opacity(life * life * 0.8)  // quadratic fade — lingers then drops
                                    .frame(width: thumbSize + CGFloat(ageFrac) * CGFloat(systemConfig.doubleVisionIntensity) * 2,
                                           height: thumbSize + CGFloat(ageFrac) * CGFloat(systemConfig.doubleVisionIntensity) * 2)
                                    .blur(radius: 1 + CGFloat(ageFrac) * CGFloat(systemConfig.doubleVisionIntensity) * 3)
                                    .position(x: ghost.x, y: geo.size.height / 2)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    // Thumb (green/white center — always present)
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                        .position(x: thumbX, y: geo.size.height / 2)

                    // Floating label — always shows the snapped value.
                    // At rest (labelScale ≈ 1): centered inside the thumb, black text.
                    // While dragging: grows up to 3× via the parameterised sigmoid
                    // F(x, k) = k / (1 + e^(1/x)), lifts just above the thumb,
                    // cross-fades to white, and gains a dark vignette for contrast.
                    if showLabel {
                        let baseSize: CGFloat = 9
                        let fontSize: CGFloat = baseSize * CGFloat(labelScale)
                        // t = 0 at rest, 1 at full scale
                        let t = min(max(CGFloat((labelScale - 1.0) / (Self.labelMaxScale - 1.0)), 0), 1)
                        // Y position: centred in thumb → just above thumb
                        let restY = geo.size.height / 2
                        let activeY = geo.size.height / 2 - thumbSize / 2 - fontSize * 0.55
                        let labelY = restY + (activeY - restY) * t

                        let labelText = "\(Int(snap(displayPercent)))%"

                        ZStack {
                            // Dark vignette — 2D Gaussian opacity falloff
                            if t > 0.01 {
                                let vigW = fontSize * 3
                                let vigH = fontSize * 2
                                Canvas { ctx, size in
                                    let cx = size.width / 2
                                    let cy = size.height / 2
                                    let sigmaX = size.width / 4   // σ_x: ~95% falls within frame
                                    let sigmaY = size.height / 4  // σ_y
                                    let peakOpacity = 0.6 * Double(t)
                                    let steps = 20
                                    // Draw concentric ellipses from outside-in
                                    for i in stride(from: steps, through: 1, by: -1) {
                                        let r = Double(i) / Double(steps) // 1 → 1/steps
                                        // Gaussian: e^(-r²/2) evaluated at r standard deviations
                                        let alpha = peakOpacity * exp(-0.5 * (r * 2.0) * (r * 2.0))
                                        let rx = sigmaX * 2.0 * r
                                        let ry = sigmaY * 2.0 * r
                                        let rect = CGRect(
                                            x: cx - rx, y: cy - ry,
                                            width: rx * 2, height: ry * 2
                                        )
                                        ctx.fill(
                                            Path(ellipseIn: rect),
                                            with: .color(.black.opacity(alpha))
                                        )
                                    }
                                }
                                .frame(width: vigW, height: vigH)
                                .allowsHitTesting(false)
                            }

                            // Text: black at rest → white when active
                            Text(labelText)
                                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.black.opacity(Double(1 - t)))
                                .overlay {
                                    Text(labelText)
                                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(Double(t)))
                                }
                        }
                        .position(x: thumbX, y: labelY)
                        .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            if !isDragging { dragStartDate = .now }
                            isDragging = true
                            timelineActive = true

                            // Raw finger position — full floating-point resolution
                            let rawFraction = (drag.location.x - thumbSize / 2) / usableWidth
                            let clamped = min(max(rawFraction, 0), 1)
                            let rawValue = range.lowerBound + clamped * (range.upperBound - range.lowerBound)

                            // Shamanic tracer — spawn a ghost at the current thumb position.
                            // Ghosts stay where they were born (no velocity offset) so the
                            // trail is a series of stacked afterimages like shamanic tracers.
                            let newX = thumbSize / 2 + usableWidth * clamped
                            if systemConfig.doubleVisionEnabled {
                                // Only spawn if the thumb moved enough (> 1 pt) to avoid
                                // flooding stationary positions with overlapping ghosts.
                                let moved = prevThumbX.isNaN ? true : abs(newX - prevThumbX) > 1.0
                                if moved {
                                    let ghost = SliderGhost(
                                        id: ghostIDCounter,
                                        x: newX,
                                        spawnTime: .now
                                    )
                                    ghostIDCounter += 1
                                    ghosts.append(ghost)
                                    // Cap trail length
                                    let maxCount = max(systemConfig.doubleVisionTrailCount, 3)
                                    if ghosts.count > maxCount {
                                        ghosts.removeFirst(ghosts.count - maxCount)
                                    }
                                }
                            }
                            prevThumbX = newX

                            // Thumb tracks finger smoothly — no snapping
                            spring.target = clamped
                            spring.position = clamped
                            spring.velocity = 0
                            renderFraction = clamped

                            // Commit the snapped value to the binding
                            let snapped = snap(rawValue)
                            if snapped != value {
                                value = snapped
                                onChanged?(snapped)
                            }
                        }
                        .onEnded { drag in
                            isDragging = false
                            dragEndDate = .now
                            labelScaleAtRelease = labelScale
                            dragStartDate = nil
                            prevThumbX = .nan

                            // Spring animates from the raw finger position to
                            // the nearest snap increment.
                            let releaseVelocityPts = drag.predictedEndLocation.x - drag.location.x
                            let velocityFraction = releaseVelocityPts / usableWidth
                            spring.velocity = velocityFraction
                            spring.target = valueFraction(value)
                            timelineActive = true
                        }
                )
                .onChange(of: now) { _, newDate in
                    // Compute delta time
                    let dt: Double
                    if let last = lastTickDate {
                        dt = newDate.timeIntervalSince(last)
                    } else {
                        dt = 1.0 / 60.0
                    }
                    lastTickDate = newDate

                    // Step the manual spring
                    spring.step(dt: dt)

                    // Update render fraction
                    renderFraction = spring.position

                    // Prune expired ghosts
                    let fadeTime = max(systemConfig.doubleVisionFadeTime, 0.05)
                    ghosts.removeAll { newDate.timeIntervalSince($0.spawnTime) > fadeTime }

                    // Update label scale — grows while dragging, decays back to 1 on release.
                    // Growth uses e^(-1/x); decay uses the mirror: 1 - e^(-1/x).
                    if isDragging, let start = dragStartDate {
                        let elapsed = newDate.timeIntervalSince(start)
                        let target = Self.labelGrowth(elapsed: elapsed)
                        if target >= labelScale {
                            labelScale = target
                        }
                    } else if labelScale > 1.001, let end = dragEndDate {
                        let elapsed = newDate.timeIntervalSince(end)
                        labelScale = Self.labelDecay(elapsed: elapsed, scaleAtRelease: labelScaleAtRelease)
                        if labelScale <= 1.001 {
                            labelScale = 1.0
                            dragEndDate = nil
                        }
                    } else {
                        labelScale = 1.0
                    }

                    // Check if we can stop ticking
                    if spring.isSettled && !isDragging && ghosts.isEmpty && labelScale <= 1.001 {
                        spring.settle()
                        renderFraction = spring.target
                        timelineActive = false
                    }
                }
            }
        }
        .frame(height: 32)
        .onAppear {
            let frac = valueFraction(value)
            spring.position = frac
            spring.target = frac
            spring.velocity = 0
            renderFraction = frac
        }
        .onChange(of: value) { _, newVal in
            spring.target = valueFraction(newVal)
            timelineActive = true
        }
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

// MARK: - Floating Numeric Keypad
//
// Custom keypad that replaces the system decimalPad keyboard entirely.
// Built from pure SwiftUI buttons — no UITextField, no system keyboard,
// no TextInputUI.  Apple Pencil works flawlessly.

/// A custom floating keypad that mimics the system decimalPad appearance.
struct FloatingNumericKeypad: View {
    @Binding var text: String
    var accentColor: Color = CMTheme.defaultAccent
    var cancelColor: Color = CMTheme.danger
    var onDone: () -> Void
    var onCancel: (() -> Void)? = nil

    private let keys: [[KeypadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.decimal,    .digit("0"), .backspace  ]
    ]

    private enum KeypadKey: Hashable {
        case digit(String)
        case decimal
        case backspace

        var label: String {
            switch self {
            case .digit(let d): return d
            case .decimal: return "."
            case .backspace: return "⌫"
            }
        }

        var subtitle: String? {
            switch self {
            case .digit("2"): return "ABC"
            case .digit("3"): return "DEF"
            case .digit("4"): return "GHI"
            case .digit("5"): return "JKL"
            case .digit("6"): return "MNO"
            case .digit("7"): return "PQRS"
            case .digit("8"): return "TUV"
            case .digit("9"): return "WXYZ"
            default: return nil
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if onCancel != nil {
                    Button("Cancel") { onCancel?() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(cancelColor)
                        .frame(width: 60, alignment: .leading)
                } else {
                    Spacer().frame(width: 60)
                }
                Spacer()
                Text(text.isEmpty ? "0" : text)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundStyle(text.isEmpty ? .white.opacity(0.3) : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Button("Done") { onDone() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 0.5)

            VStack(spacing: 8) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { key in
                            keyButton(for: key)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.17, green: 0.17, blue: 0.19))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func keyButton(for key: KeypadKey) -> some View {
        Button {
            handleTap(key)
        } label: {
            VStack(spacing: 1) {
                switch key {
                case .backspace:
                    Image(systemName: "delete.backward")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                case .decimal:
                    Text(key.label)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                default:
                    Text(key.label)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                    if let sub = key.subtitle {
                        Text(sub)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                            .tracking(1.5)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(keyBackground(for: key))
            )
        }
        .buttonStyle(KeypadPressStyle())
    }

    private func keyBackground(for key: KeypadKey) -> Color {
        switch key {
        case .decimal, .backspace: return .clear
        default: return Color(red: 0.25, green: 0.25, blue: 0.28)
        }
    }

    private func handleTap(_ key: KeypadKey) {
        switch key {
        case .backspace:
            if !text.isEmpty { text.removeLast() }
        case .decimal:
            if !text.contains(".") { text.append(".") }
        case .digit(let d):
            text.append(d)
        }
    }
}

/// Button style that dims on press for tactile keypad feedback.
private struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Scribble (Apple Pencil Handwriting) Suppression

#if canImport(UIKit)
/// Prevents Apple Pencil Scribble (handwriting recognition) from activating on
/// text fields, while keeping the `UIScribbleInteraction` objects intact.
///
/// Uses a delegate-proxy approach: each `UIScribbleInteraction` is replaced
/// with one whose delegate returns `false` from `shouldBeginAt:`.  The
/// interaction stays attached so UIKit's input session management is stable.
///
/// NOTE: No `inputAccessoryView` is set on UITextFields.  The keyboard dismiss
/// button is provided solely by SwiftUI's `.toolbar(.keyboard)` via the
/// `KeyboardDismissToolbar` view modifier.  The previous UIKit accessory view
/// caused Apple Pencil taps on on-screen keyboard keys to be intercepted by
/// the accessory button's hit area, dismissing the keyboard mid-typing.
enum ScribbleKiller {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true
        swizzleTextFieldDidMoveToWindow()
    }

    // MARK: - Swizzle UITextField.didMoveToWindow

    private static var swizzled = false

    private static func swizzleTextFieldDidMoveToWindow() {
        guard !swizzled else { return }
        swizzled = true

        let originalSelector = #selector(UITextField.didMoveToWindow)
        let swizzledSelector = #selector(UITextField.cm_didMoveToWindow)

        guard let originalMethod = class_getInstanceMethod(UITextField.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UITextField.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    /// Replace the system `UIScribbleInteraction` with one whose delegate
    /// blocks handwriting.  Skips the swap if the field is first responder.
    static func disableScribble(on tf: UITextField) {
        guard !tf.isFirstResponder else { return }

        for interaction in tf.interactions {
            if let scribble = interaction as? UIScribbleInteraction {
                if scribble.delegate is ScribbleBlockerDelegate { continue }
                let blocker = ScribbleBlockerDelegate(original: scribble.delegate)
                objc_setAssociatedObject(tf, &AssociatedKeys.scribbleBlocker, blocker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                tf.removeInteraction(scribble)
                tf.addInteraction(UIScribbleInteraction(delegate: blocker))
            }
        }
    }

    private enum AssociatedKeys {
        nonisolated(unsafe) static var scribbleBlocker: UInt8 = 0
    }
}

/// Proxy delegate that blocks Scribble from starting while forwarding all
/// other delegate calls to the original delegate (if any).
private final class ScribbleBlockerDelegate: NSObject, UIScribbleInteractionDelegate {
    weak var original: (any UIScribbleInteractionDelegate)?

    init(original: (any UIScribbleInteractionDelegate)?) {
        self.original = original
    }

    func scribbleInteraction(_ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint) -> Bool {
        return false
    }

    func scribbleInteractionShouldDelayFocus(_ interaction: UIScribbleInteraction) -> Bool {
        return original?.scribbleInteractionShouldDelayFocus?(interaction) ?? false
    }

    func scribbleInteractionWillBeginWriting(_ interaction: UIScribbleInteraction) {
        original?.scribbleInteractionWillBeginWriting?(interaction)
    }

    func scribbleInteractionDidFinishWriting(_ interaction: UIScribbleInteraction) {
        original?.scribbleInteractionDidFinishWriting?(interaction)
    }
}

extension UITextField {
    /// Swizzled `didMoveToWindow`.  Disables Scribble when the text field
    /// enters the view hierarchy.  Does NOT set `inputAccessoryView`.
    @objc func cm_didMoveToWindow() {
        cm_didMoveToWindow()
        guard self.window != nil else { return }
        ScribbleKiller.disableScribble(on: self)
    }
}
#endif

extension View {
    /// No-op — Scribble is disabled globally via ScribbleKiller delegate proxy.
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

    /// Monotonic token incremented on each focus event.  Used to cancel
    /// a pending select-all when the user starts typing before the delay fires.
    nonisolated(unsafe) static var selectAllToken: UInt64 = 0

    /// Select-all on focus via UIKit (no-op on macOS).
    /// The selection is cancelled if the text field content changes before the
    /// delay elapses (e.g. the user already began typing with Apple Pencil).
    static func selectAll(ifTextStill expectedText: String, in textBinding: @escaping () -> String) {
        #if canImport(UIKit)
        selectAllToken &+= 1
        let token = selectAllToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard token == selectAllToken,
                  textBinding() == expectedText else { return }
            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
        }
        #endif
    }
}

// MARK: - Keypad-Based Numeric Fields
//
// These replace the old TextField-based numeric fields.  Instead of using the
// system keyboard (which breaks with Apple Pencil + .decimalPad), they show a
// custom FloatingNumericKeypad popup on tap.  The public API is identical so
// all existing call sites compile without changes.

/// Preference key for capturing a view's frame in global coordinates.
private struct FieldGlobalFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// A numeric input field that routes between the custom floating keypad (iPad default)
/// and the system decimalPad keyboard (iPhone default) based on `SystemConfig.useCustomKeypad`.
struct NumericField: View {
    @Binding var value: Double
    var decimals: Int = 3
    var placeholder: String? = nil
    var isFocusedBinding: Binding<Bool> = .constant(false)

    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        if systemConfig.useCustomKeypad {
            KeypadNumericField(value: $value, decimals: decimals,
                               placeholder: placeholder, isFocusedBinding: isFocusedBinding)
        } else {
            TextFieldNumericField(value: $value, decimals: decimals,
                                  placeholder: placeholder, isFocusedBinding: isFocusedBinding)
        }
    }
}

/// Optional-Double variant — routes between custom keypad and system keyboard.
struct OptionalNumericField: View {
    @Binding var value: Double?
    var decimals: Int = 3
    var placeholder: String? = nil

    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        if systemConfig.useCustomKeypad {
            KeypadOptionalNumericField(value: $value, decimals: decimals, placeholder: placeholder)
        } else {
            TextFieldOptionalNumericField(value: $value, decimals: decimals, placeholder: placeholder)
        }
    }
}

// MARK: - Custom Keypad Variants

/// NumericField variant using the floating keypad overlay.
private struct KeypadNumericField: View {
    @Binding var value: Double
    var decimals: Int = 3
    var placeholder: String? = nil
    var isFocusedBinding: Binding<Bool> = .constant(false)

    @Environment(SystemConfig.self) private var systemConfig
    @State private var showKeypad = false
    @State private var displayText = ""
    @State private var fieldRect: CGRect = .zero

    #if canImport(UIKit)
    @State private var keypadState: KeypadState?
    #endif

    private var placeholderText: String {
        placeholder ?? NumericFormatting.placeholder(decimals: decimals)
    }

    private var accent: Color { systemConfig.designKeypadAccent }

    var body: some View {
        Text(displayText.isEmpty ? placeholderText : displayText)
            .foregroundStyle(displayText.isEmpty ? CMTheme.textTertiary : CMTheme.textPrimary)
            .contentShape(Rectangle())
            .background(GeometryReader { geo in
                Color.clear.preference(key: FieldGlobalFrameKey.self, value: geo.frame(in: .global))
            })
            .onPreferenceChange(FieldGlobalFrameKey.self) { fieldRect = $0 }
            .onTapGesture { openKeypad() }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(showKeypad ? accent.opacity(0.08) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(showKeypad ? accent.opacity(0.35) : .clear, lineWidth: 1)
            )
            .onAppear { displayText = NumericFormatting.display(value, decimals: decimals) }
            .onChange(of: value) { _, newVal in
                if !showKeypad { displayText = NumericFormatting.display(newVal, decimals: decimals) }
            }
    }

    private func openKeypad() {
        guard !showKeypad else { return }
        showKeypad = true
        isFocusedBinding.wrappedValue = true
        #if canImport(UIKit)
        let state = KeypadOverlayController.shared.show(
            text: "", sourceRect: fieldRect,
            accentColor: accent, cancelColor: systemConfig.designAlert
        ) { commitFromState() } onCancel: { cancelFromState() }
        self.keypadState = state
        #endif
    }

    private func commitFromState() {
        #if canImport(UIKit)
        let finalText = keypadState?.text ?? ""
        #else
        let finalText = ""
        #endif
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            if let parsed = Double(finalText) { value = parsed }
            displayText = NumericFormatting.display(value, decimals: decimals)
        }
        showKeypad = false
        isFocusedBinding.wrappedValue = false
        #if canImport(UIKit)
        keypadState = nil
        #endif
    }

    private func cancelFromState() {
        // Restore display text from current value without committing any changes
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            displayText = NumericFormatting.display(value, decimals: decimals)
        }
        showKeypad = false
        isFocusedBinding.wrappedValue = false
        #if canImport(UIKit)
        keypadState = nil
        #endif
    }
}

/// OptionalNumericField variant using the floating keypad overlay.
private struct KeypadOptionalNumericField: View {
    @Binding var value: Double?
    var decimals: Int = 3
    var placeholder: String? = nil

    @Environment(SystemConfig.self) private var systemConfig
    @State private var showKeypad = false
    @State private var displayText = ""
    @State private var fieldRect: CGRect = .zero

    #if canImport(UIKit)
    @State private var keypadState: KeypadState?
    #endif

    private var placeholderText: String {
        placeholder ?? NumericFormatting.placeholder(decimals: decimals)
    }

    private var accent: Color { systemConfig.designKeypadAccent }

    var body: some View {
        Text(displayText.isEmpty ? placeholderText : displayText)
            .foregroundStyle(displayText.isEmpty ? CMTheme.textTertiary : CMTheme.textPrimary)
            .contentShape(Rectangle())
            .background(GeometryReader { geo in
                Color.clear.preference(key: FieldGlobalFrameKey.self, value: geo.frame(in: .global))
            })
            .onPreferenceChange(FieldGlobalFrameKey.self) { fieldRect = $0 }
            .onTapGesture { openKeypad() }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(showKeypad ? accent.opacity(0.08) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(showKeypad ? accent.opacity(0.35) : .clear, lineWidth: 1)
            )
            .onAppear { displayText = value.map { NumericFormatting.display($0, decimals: decimals) } ?? "" }
            .onChange(of: value) { _, newVal in
                if !showKeypad { displayText = newVal.map { NumericFormatting.display($0, decimals: decimals) } ?? "" }
            }
    }

    private func openKeypad() {
        guard !showKeypad else { return }
        showKeypad = true
        #if canImport(UIKit)
        let state = KeypadOverlayController.shared.show(
            text: "", sourceRect: fieldRect,
            accentColor: accent, cancelColor: systemConfig.designAlert
        ) { commitFromState() } onCancel: { cancelFromState() }
        self.keypadState = state
        #endif
    }

    private func commitFromState() {
        #if canImport(UIKit)
        let finalText = keypadState?.text ?? ""
        #else
        let finalText = ""
        #endif
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            if finalText.trimmingCharacters(in: .whitespaces).isEmpty {
                value = nil
            } else if let parsed = Double(finalText) {
                value = parsed
            }
            displayText = value.map { NumericFormatting.display($0, decimals: decimals) } ?? ""
        }
        showKeypad = false
        #if canImport(UIKit)
        keypadState = nil
        #endif
    }

    private func cancelFromState() {
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            displayText = value.map { NumericFormatting.display($0, decimals: decimals) } ?? ""
        }
        showKeypad = false
        #if canImport(UIKit)
        keypadState = nil
        #endif
    }
}

// MARK: - System Keyboard Variants

/// NumericField variant using the standard system TextField + .decimalPad keyboard.
private struct TextFieldNumericField: View {
    @Binding var value: Double
    var decimals: Int = 3
    var placeholder: String? = nil
    var isFocusedBinding: Binding<Bool> = .constant(false)

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder ?? NumericFormatting.placeholder(decimals: decimals), text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                isFocusedBinding.wrappedValue = focused
                if focused {
                    text = NumericFormatting.editing(value, decimals: decimals)
                } else {
                    var t = Transaction(); t.disablesAnimations = true
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

/// OptionalNumericField variant using the standard system TextField + .decimalPad keyboard.
private struct TextFieldOptionalNumericField: View {
    @Binding var value: Double?
    var decimals: Int = 3
    var placeholder: String? = nil

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder ?? NumericFormatting.placeholder(decimals: decimals), text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                if focused {
                    text = value.map { NumericFormatting.editing($0, decimals: decimals) } ?? ""
                } else {
                    var t = Transaction(); t.disablesAnimations = true
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

// MARK: - Keypad Overlay Window
//
// SwiftUI overlays are clipped to their parent's hit-test bounds, so a small
// Text field can't reliably block touches across the whole screen.  Instead we
// host BOTH the backdrop AND the keypad inside a separate UIWindow that sits
// above the entire app.  The backdrop area absorbs all taps; the keypad floats
// centered in the window and works normally.

#if canImport(UIKit)
/// Observable model shared between the keypad window and the field that opened it.
@MainActor @Observable
private final class KeypadState {
    var text: String = ""
    var onDone: (() -> Void)?
    var onCancel: (() -> Void)?
    /// The tapped field's frame in screen (global) coordinates.
    var sourceRect: CGRect = .zero
    /// Accent color for the Done button and field highlight.
    var accentColor: Color = CMTheme.defaultAccent
    /// Cancel button color (design language alert color).
    var cancelColor: Color = CMTheme.danger
}

/// The SwiftUI view rendered inside the keypad window.
/// Positions the keypad intelligently relative to the field that opened it.
private struct KeypadWindowContent: View {
    @Bindable var state: KeypadState

    /// Approximate keypad dimensions (width is fixed at 280, height ~340).
    private let keypadWidth: CGFloat = 280
    private let keypadHeight: CGFloat = 340
    /// Minimum gap between keypad and field / screen edges.
    private let margin: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let pos = keypadPosition(screen: geo.size, safeArea: geo.safeAreaInsets)

            ZStack(alignment: .topLeading) {
                // Backdrop — absorbs all taps (cancel, don't commit)
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { state.onCancel?() }

                // Keypad — positioned at the computed location
                FloatingNumericKeypad(text: $state.text, accentColor: state.accentColor, cancelColor: state.cancelColor) {
                    state.onDone?()
                } onCancel: {
                    state.onCancel?()
                }
                .offset(x: pos.x, y: pos.y)
            }
        }
    }

    /// Determines the best (x, y) offset for the keypad's top-leading corner.
    ///
    /// Strategy:
    /// 1. Prefer placing the keypad directly below the field with 8pt gap.
    /// 2. If not enough room below, place it above the field.
    /// 3. Horizontally, center on the field — but clamp to screen bounds.
    private func keypadPosition(screen: CGSize, safeArea: EdgeInsets) -> CGPoint {
        let field = state.sourceRect
        let gap: CGFloat = 8

        // --- Vertical ---
        let spaceBelow = screen.height - field.maxY - safeArea.bottom
        let spaceAbove = field.minY - safeArea.top

        let y: CGFloat
        if spaceBelow >= keypadHeight + gap + margin {
            // Place below the field
            y = field.maxY + gap
        } else if spaceAbove >= keypadHeight + gap + margin {
            // Place above the field
            y = field.minY - gap - keypadHeight
        } else {
            // Not enough room either way — center vertically on screen
            y = (screen.height - keypadHeight) / 2
        }

        // --- Horizontal ---
        // Center keypad on the field's horizontal center, clamped to screen
        let fieldCenterX = field.midX
        var x = fieldCenterX - keypadWidth / 2
        x = max(margin + safeArea.leading, x)
        x = min(screen.width - keypadWidth - margin - safeArea.trailing, x)

        return CGPoint(x: x, y: y)
    }
}

/// Manages a UIWindow that displays the keypad + backdrop above the entire app.
@MainActor
private final class KeypadOverlayController {
    static let shared = KeypadOverlayController()

    private var window: UIWindow?
    private let state = KeypadState()

    /// Show the keypad with the given initial text, positioned relative to `sourceRect`
    /// (the tapped field's frame in screen/global coordinates).
    @discardableResult
    func show(text: String, sourceRect: CGRect, accentColor: Color = CMTheme.defaultAccent, cancelColor: Color = CMTheme.danger, onDone: @escaping () -> Void, onCancel: (() -> Void)? = nil) -> KeypadState {
        hide()
        state.text = text
        state.sourceRect = sourceRect
        state.accentColor = accentColor
        state.cancelColor = cancelColor
        state.onDone = {
            onDone()
            self.hide()
        }
        state.onCancel = {
            onCancel?()
            self.hide()
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return state }

        let hostingVC = UIHostingController(rootView: KeypadWindowContent(state: state))
        hostingVC.view.backgroundColor = .clear

        let w = UIWindow(windowScene: scene)
        w.windowLevel = .alert - 1
        w.backgroundColor = .clear
        w.rootViewController = hostingVC
        w.isHidden = false

        self.window = w
        return state
    }

    func hide() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        state.onDone = nil
        state.onCancel = nil
    }
}
#endif

/// String-bound numeric field — routes between custom keypad and system keyboard.
struct KeypadStringField: View {
    @Binding var text: String
    var placeholder: String = "0.000"

    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        if systemConfig.useCustomKeypad {
            KeypadStringFieldKeypad(text: $text, placeholder: placeholder)
        } else {
            KeypadStringFieldTextField(text: $text, placeholder: placeholder)
        }
    }
}

/// KeypadStringField variant using the floating keypad overlay.
private struct KeypadStringFieldKeypad: View {
    @Binding var text: String
    var placeholder: String = "0.000"

    @Environment(SystemConfig.self) private var systemConfig
    @State private var showKeypad = false
    @State private var fieldRect: CGRect = .zero

    #if canImport(UIKit)
    @State private var keypadState: KeypadState?
    #endif

    private var accent: Color { systemConfig.designKeypadAccent }

    var body: some View {
        Text(text.isEmpty ? placeholder : text)
            .foregroundStyle(text.isEmpty ? CMTheme.textTertiary : CMTheme.textPrimary)
            .contentShape(Rectangle())
            .background(GeometryReader { geo in
                Color.clear.preference(key: FieldGlobalFrameKey.self, value: geo.frame(in: .global))
            })
            .onPreferenceChange(FieldGlobalFrameKey.self) { fieldRect = $0 }
            .onTapGesture { openKeypad() }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(showKeypad ? accent.opacity(0.08) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(showKeypad ? accent.opacity(0.35) : .clear, lineWidth: 1)
            )
    }

    private func openKeypad() {
        guard !showKeypad else { return }
        showKeypad = true
        #if canImport(UIKit)
        let state = KeypadOverlayController.shared.show(text: "", sourceRect: fieldRect, accentColor: accent, cancelColor: systemConfig.designAlert) {
            self.commitFromState()
        } onCancel: {
            self.cancelFromState()
        }
        self.keypadState = state
        #endif
    }

    private func commitFromState() {
        #if canImport(UIKit)
        let finalText = keypadState?.text ?? ""
        #else
        let finalText = ""
        #endif
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { text = finalText }
        showKeypad = false
        #if canImport(UIKit)
        keypadState = nil
        #endif
    }

    private func cancelFromState() {
        // Don't change text — just dismiss
        showKeypad = false
        #if canImport(UIKit)
        keypadState = nil
        #endif
    }
}

/// KeypadStringField variant using the standard system TextField + .decimalPad.
private struct KeypadStringFieldTextField: View {
    @Binding var text: String
    var placeholder: String = "0.000"

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
    }
}

// MARK: - Keyboard Dismiss Button (Floating Overlay)
//
// Apple Pencil's broader hit-testing area causes taps on software-keyboard
// keys to be intercepted by any button placed in `.toolbar(.keyboard)`, in a
// UIKit `inputAccessoryView`, or even in the lower portion of the content
// area.  The dismiss button is therefore placed at the **top-trailing**
// corner of the view — far from the keyboard — and only shown while a
// keyboard is visible.

#if canImport(UIKit)
/// Tracks keyboard visibility and frame via UIKit notifications.
@Observable
final class KeyboardVisibility {
    var isVisible = false
    var keyboardHeight: CGFloat = 0

    init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            self?.isVisible = true
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self?.keyboardHeight = frame.height
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.isVisible = false
            self?.keyboardHeight = 0
        }
    }
}
#endif

struct KeyboardDismissToolbar: ViewModifier {
    #if canImport(UIKit)
    @State private var keyboard = KeyboardVisibility()
    #endif

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .overlay(alignment: .bottomTrailing) {
                if keyboard.isVisible {
                    Button {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                            )
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, keyboard.keyboardHeight + 8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: keyboard.isVisible)
        #else
        content
        #endif
    }
}

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
