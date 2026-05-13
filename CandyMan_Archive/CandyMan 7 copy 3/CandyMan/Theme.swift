import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Accent Theme Palette

enum AccentTheme: String, CaseIterable, Identifiable {
    case stone = "Stone"
    case teal  = "Teal"
    case mauve = "Mauve"
    case rose  = "Rose"
    case red   = "Red"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .stone: return Color(red: 0.753, green: 0.737, blue: 0.710)  // #c0bcb5
        case .teal:  return Color(red: 0.290, green: 0.424, blue: 0.435)  // #4a6c6f
        case .mauve: return Color(red: 0.518, green: 0.376, blue: 0.459)  // #846075
        case .rose:  return Color(red: 0.686, green: 0.365, blue: 0.388)  // #af5d63
        case .red:   return Color(red: 0.929, green: 0.278, blue: 0.290)  // #ed474a
        }
    }
}

// MARK: - CandyMan Design System

enum CMTheme {

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

    /// Page background — deep cool gray
    static let pageBG = Color(red: 0.11, green: 0.11, blue: 0.14)
    /// Card background — slightly lifted dark surface
    static let cardBG = Color(red: 0.16, green: 0.16, blue: 0.20)
    /// Subtle row highlight
    static let rowHighlight = Color.white.opacity(0.04)
    /// Divider color
    static let divider = Color.white.opacity(0.08)
    /// Total-row background tint
    static let totalRowBG = Color.white.opacity(0.06)

    // MARK: Text

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.30)

    // MARK: Interactive

    /// Tag / chip unselected background
    static let chipBG = Color.white.opacity(0.08)
    /// Text field background
    static let fieldBG = Color.white.opacity(0.06)

    // MARK: Corner Radius

    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let chipRadius: CGFloat = 10
    static let fieldRadius: CGFloat = 10

    // MARK: Shadows

    static let cardShadow = Color.black.opacity(0.35)
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
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
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

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(CMTheme.textPrimary)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CMTheme.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
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

// MARK: - Keyboard Dismiss Toolbar

struct KeyboardDismissToolbar: ViewModifier {
    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CMTheme.textSecondary)
                    }
                }
            }
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
