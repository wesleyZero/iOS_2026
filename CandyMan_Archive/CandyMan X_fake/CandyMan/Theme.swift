//
//  Theme.swift
//  CandyMan
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Accent Theme Palette

enum AccentTheme: String, CaseIterable, Identifiable {
    // Original palette
    case stone   = "Stone"
    case teal    = "Teal"
    case mauve   = "Mauve"
    case amber   = "Amber"
    case lagoon  = "Lagoon"
    case neon    = "Neon"
    case scarlet = "Scarlet"

    // Extended palette
    case jadeMist     = "Jade Mist"
    case deepCurrent  = "Deep Current"
    case citronGlow   = "Citron Glow"
    case rosePetal    = "Rose Petal"
    case frostedSky   = "Frosted Sky"
    case electricIce  = "Electric Ice"
    case fuchsiaFlare = "Fuchsia Flare"
    case pistachio    = "Pistachio"

    var id: String { rawValue }

    /// The original 7 themes (above the divider in settings)
    static let originalCases: [AccentTheme] = [.stone, .teal, .mauve, .amber, .lagoon, .neon, .scarlet]
    /// The extended 8 themes (below the divider in settings)
    static let extendedCases: [AccentTheme] = [.jadeMist, .deepCurrent, .citronGlow, .rosePetal, .frostedSky, .electricIce, .fuchsiaFlare, .pistachio]

    var color: Color {
        switch self {
        case .stone:        return Color(red: 0.753, green: 0.737, blue: 0.710)  // #C0BCB5
        case .teal:         return Color(red: 0.290, green: 0.424, blue: 0.435)  // #4A6C6F
        case .mauve:        return Color(red: 0.518, green: 0.376, blue: 0.459)  // #846075
        case .amber:        return Color(red: 1.000, green: 0.765, blue: 0.000)  // #FFC300
        case .lagoon:       return Color(red: 0.306, green: 0.553, blue: 0.612)  // #4E8D9C
        case .neon:         return Color(red: 1.000, green: 0.243, blue: 0.608)  // #FF3E9B
        case .scarlet:      return Color(red: 0.753, green: 0.027, blue: 0.027)  // #C00707
        case .jadeMist:     return Color(red: 0.365, green: 0.827, blue: 0.714)  // #5DD3B6
        case .deepCurrent:  return Color(red: 0.031, green: 0.514, blue: 0.584)  // #088395
        case .citronGlow:   return Color(red: 0.847, green: 0.914, blue: 0.514)  // #D8E983
        case .rosePetal:    return Color(red: 0.941, green: 0.459, blue: 0.682)  // #F075AE
        case .frostedSky:   return Color(red: 0.671, green: 0.855, blue: 0.863)  // #ABDADC
        case .electricIce:  return Color(red: 0.000, green: 0.969, blue: 1.000)  // #00F7FF
        case .fuchsiaFlare: return Color(red: 1.000, green: 0.000, blue: 0.529)  // #FF0087
        case .pistachio:    return Color(red: 0.722, green: 0.859, blue: 0.502)  // #B8DB80
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

    func body(content: Content) -> some View {
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

// MARK: - String-Buffered Numeric TextField

/// A text field for numeric input that avoids SwiftUI's real-time format coercion bugs.
/// Uses a string buffer internally and only commits the parsed value on focus loss.
/// This prevents decimal-place shuffling and keyboard dismissal mid-typing.
struct NumericField: View {
    @Binding var value: Double
    var decimals: Int = 3
    var placeholder: String? = nil
    /// Binding that reflects whether this field currently has keyboard focus.
    /// Use this to pause animations (e.g. skittleSwirlWide) while the user is typing.
    var isFocusedBinding: Binding<Bool> = .constant(false)

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder ?? placeholderString, text: $text)
            .keyboardType(.decimalPad)
            .scribbleDisabled()
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                isFocusedBinding.wrappedValue = focused
                if focused {
                    // On focus: show raw value so user can edit freely
                    text = formatForEditing(value)
                    #if canImport(UIKit)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                    }
                    #endif
                } else {
                    // On blur: commit parsed value and reformat display.
                    // Use a non-animated transaction so the text/layout change
                    // doesn't cause the parent ScrollView to animate its offset.
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        if let parsed = Double(text) {
                            value = parsed
                        }
                        text = formatForDisplay(value)
                    }
                }
            }
            .onAppear {
                text = formatForDisplay(value)
            }
            .onChange(of: value) { _, newVal in
                // External value change while not focused — sync display
                if !isFocused {
                    text = formatForDisplay(newVal)
                }
            }
    }

    private var placeholderString: String {
        decimals == 0 ? "0" : "0." + String(repeating: "0", count: decimals)
    }

    private func formatForDisplay(_ v: Double) -> String {
        if v == 0 { return "" }
        return String(format: "%.\(decimals)f", v)
    }

    private func formatForEditing(_ v: Double) -> String {
        if v == 0 { return "" }
        // Strip trailing zeros for easier editing
        let formatted = String(format: "%.\(decimals)f", v)
        if formatted.contains(".") {
            let trimmed = formatted.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            return trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed
        }
        return formatted
    }
}

/// Optional-Double variant for fields bound to Double? (nil = empty field).
struct OptionalNumericField: View {
    @Binding var value: Double?
    var decimals: Int = 3
    var placeholder: String? = nil

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder ?? placeholderString, text: $text)
            .keyboardType(.decimalPad)
            .scribbleDisabled()
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                if focused {
                    text = formatForEditing(value)
                    #if canImport(UIKit)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                    }
                    #endif
                } else {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        if text.trimmingCharacters(in: .whitespaces).isEmpty {
                            value = nil
                        } else if let parsed = Double(text) {
                            value = parsed
                        }
                        text = formatForDisplay(value)
                    }
                }
            }
            .onAppear {
                text = formatForDisplay(value)
            }
            .onChange(of: value) { _, newVal in
                if !isFocused {
                    text = formatForDisplay(newVal)
                }
            }
    }

    private var placeholderString: String {
        decimals == 0 ? "0" : "0." + String(repeating: "0", count: decimals)
    }

    private func formatForDisplay(_ v: Double?) -> String {
        guard let v, v != 0 else { return "" }
        return String(format: "%.\(decimals)f", v)
    }

    private func formatForEditing(_ v: Double?) -> String {
        guard let v, v != 0 else { return "" }
        let formatted = String(format: "%.\(decimals)f", v)
        if formatted.contains(".") {
            let trimmed = formatted.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            return trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed
        }
        return formatted
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

// MARK: - Bottom Jump Buttons

/// TopJumpButton1 — Glass orb scroll-to-top button.
struct TopJumpButton1: View {
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

                // Glass body (solid tint — avoids per-frame blur during scrolling)
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
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce.up, options: .speed(1.5), value: bounceCount)

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

/// BottomJumpButton1 — Glass orb scroll-to-bottom button. Do not delete.
struct BottomJumpButton1: View {
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

                // Glass body (solid tint — avoids per-frame blur during scrolling)
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
