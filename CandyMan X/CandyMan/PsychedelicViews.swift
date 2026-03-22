//
//  PsychedelicViews.swift
//  CandyMan
//
//  Animated psychedelic UI components used throughout the app.
//
//  Contents:
//    PsychedelicAlert1     – Iridescent "CandyMan can!!" toast (post-calculate)
//    PsychedelicAlert2     – Plasma dialog with orbital rings (generic confirmation)
//    PsychedelicAlert3     – "Liquid Mercury" dialog (density confirmations)
//    PsychedelicAlert4     – "Molten Ember" dialog (overage confirmations)
//    PsychedelicAlert5     – "Acid Rain" dialog (additional water updated)
//    PsychedelicTitleView  – SkittleSwirl "CandyMan X" navigation title
//    PsychedelicButton1    – Plasma button background (no vignette)
//    PsychedelicButton2    – Plasma button background (dark center vignette)
//    PsychedelicProgressBar – Plasma-filled horizontal progress bar
//

import SwiftUI

// MARK: - PsychedelicAlert1

/// Iridescent rotating angular gradient with counter-rotating overlay,
/// hue-shifting text, pulsing glow aura, breathing scale, and 3D wobble.
/// Shown briefly after the user taps "Calculate".
struct PsychedelicAlert1: View {
    @State private var phase: CGFloat = 0
    @State private var breathe: CGFloat = 1.0
    @State private var glowPulse: CGFloat = 0.5
    @State private var wobble: CGFloat = 0

    private let psychedelicColors: [Color] = [
        Color(red: 1.0, green: 0.05, blue: 0.5),   // neon pink
        Color(red: 0.7, green: 0.0, blue: 1.0),     // vivid purple
        Color(red: 0.2, green: 0.0, blue: 1.0),     // deep indigo
        Color(red: 0.0, green: 0.5, blue: 1.0),     // electric blue
        Color(red: 0.0, green: 1.0, blue: 0.8),     // acid cyan
        Color(red: 0.0, green: 1.0, blue: 0.3),     // toxic green
        Color(red: 0.8, green: 1.0, blue: 0.0),     // electric lime
        Color(red: 1.0, green: 0.8, blue: 0.0),     // golden
        Color(red: 1.0, green: 0.3, blue: 0.0),     // lava orange
        Color(red: 1.0, green: 0.05, blue: 0.5),    // back to neon pink
    ]

    var body: some View {
        ZStack {
            // Outer glow aura (flattened into single texture)
            Capsule()
                .fill(
                    AngularGradient(colors: psychedelicColors, center: .center, angle: .degrees(-phase))
                )
                .blur(radius: 24)
                .drawingGroup()
                .opacity(0.4 + glowPulse * 0.2)
                .scaleEffect(1.15 + glowPulse * 0.1)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)

            // Main pill
            Text("Because the CandyMan can!!")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 1.0, green: 0.9, blue: 0.95)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .hueRotation(.degrees(phase * 2))
                .shadow(color: .white.opacity(0.8), radius: 3)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        // Base rotating gradient
                        Capsule()
                            .fill(
                                AngularGradient(colors: psychedelicColors, center: .center, angle: .degrees(phase))
                            )

                        // Counter-rotating overlay gradient for interference pattern
                        Capsule()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        Color(red: 0.0, green: 1.0, blue: 1.0).opacity(0.5),
                                        Color(red: 1.0, green: 0.0, blue: 1.0).opacity(0.5),
                                        Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.5),
                                        Color(red: 0.0, green: 1.0, blue: 1.0).opacity(0.5),
                                    ],
                                    center: .center,
                                    angle: .degrees(-phase + 180)
                                )
                            )
                            .blendMode(.screen)

                        // Glass overlay (solid tint — avoids GPU-expensive blur)
                        Capsule()
                            .fill(Color(red: 0.16, green: 0.16, blue: 0.20).opacity(0.3))

                        // Shimmering border
                        Capsule()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        .white.opacity(0.9),
                                        .clear,
                                        Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.6),
                                        .clear,
                                        Color(red: 1.0, green: 0.05, blue: 0.5).opacity(0.6),
                                        .clear,
                                        .white.opacity(0.9),
                                    ],
                                    center: .center,
                                    angle: .degrees(-phase * 2)
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .drawingGroup()
                    .shadow(color: Color(red: 0.7, green: 0.0, blue: 1.0).opacity(glowPulse), radius: 16, y: 2)
                )
        }
        .scaleEffect(breathe)
        .rotation3DEffect(.degrees(wobble), axis: (x: 0.1, y: 1, z: 0.05))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathe = 1.04
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = 1.0
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                wobble = 4
            }
        }
    }
}

// MARK: - PsychedelicTitleView

/// **SkittleSwirl** — Animated "CandyMan X" title with a rotating angular gradient
/// in Skittles candy + rave neon colors. Do not delete.
struct PsychedelicTitleView: View {
    @State private var phase: CGFloat = 0

    /// Skittles candy + rave neon palette, bookended for seamless loop.
    private let candyColors: [Color] = [
        Color(red: 1.00, green: 0.00, blue: 0.30),  // Neon strawberry
        Color(red: 1.00, green: 0.35, blue: 0.00),  // Skittles orange
        Color(red: 1.00, green: 0.95, blue: 0.00),  // Electric lemon
        Color(red: 0.00, green: 1.00, blue: 0.40),  // Rave green
        Color(red: 0.00, green: 0.85, blue: 1.00),  // Neon cyan
        Color(red: 0.55, green: 0.00, blue: 1.00),  // Grape rave
        Color(red: 1.00, green: 0.00, blue: 0.70),  // Hot magenta
        Color(red: 1.00, green: 0.00, blue: 0.30),  // Neon strawberry (loop)
    ]

    var body: some View {
        Text("CandyMan Χ")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(
                AngularGradient(
                    colors: candyColors,
                    center: .center,
                    angle: .degrees(phase)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
    }
}

// MARK: - PsychedelicButton1

/// Psychedelic button background matching PsychedelicAlert2 aesthetic.
/// Animated plasma gradient with neon shimmer border and pulsing glow.
/// No center vignette — plasma is fully visible.
struct PsychedelicButton1: View {
    var cornerRadius: CGFloat = CMTheme.buttonRadius
    var isDisabled: Bool = false

    @State private var phase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3

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
        ZStack {
            // Base plasma
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                )

            // Counter-rotating shimmer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                .blendMode(.screen)

            // Glass overlay for depth (solid tint — avoids GPU-expensive blur)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.16, green: 0.16, blue: 0.20).opacity(0.25))

            // Neon border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
        }
        .drawingGroup()
        .shadow(color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(glowPulse), radius: 10, y: 4)
        .opacity(isDisabled ? 0 : 1)
        .onAppear { startAnimationsIfNeeded() }
        .onChange(of: isDisabled) { _, disabled in
            if !disabled { startAnimationsIfNeeded() }
        }
    }

    private func startAnimationsIfNeeded() {
        guard !isDisabled, phase == 0 else { return }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            phase = 360
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
    }
}

// MARK: - PsychedelicButton2

/// Same plasma animation as PsychedelicButton1 but with a dark center vignette
/// that fades to transparent at the edges. The text sits on a dark background
/// that gradually reveals the psychedelic animation toward the button edges.
struct PsychedelicButton2: View {
    var cornerRadius: CGFloat = CMTheme.buttonRadius
    var isDisabled: Bool = false
    var isPaused: Bool = false

    @State private var phase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3

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

    /// The dark grey matching the page background
    private let vignetteColor = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        ZStack {
            // Base plasma
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                )

            // Counter-rotating shimmer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                .blendMode(.screen)

            // Glass overlay (solid tint — avoids GPU-expensive blur)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.16, green: 0.16, blue: 0.20).opacity(0.25))

            // Dark center vignette — opaque dark grey in center, fading to transparent at edges
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            vignetteColor,
                            vignetteColor,
                            vignetteColor.opacity(0.95),
                            vignetteColor.opacity(0.6),
                            vignetteColor.opacity(0.25),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )

            // Neon border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
        }
        .drawingGroup()
        .shadow(color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(glowPulse), radius: 10, y: 4)
        .opacity(isDisabled ? 0 : 1)
        .onAppear { startAnimationsIfNeeded() }
        .onChange(of: isDisabled) { _, disabled in
            if !disabled { startAnimationsIfNeeded() }
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                // Freeze animation by snapping phase to a static value without animation
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    phase = 0
                    glowPulse = 0.3
                }
            } else {
                // Keyboard dismissed — restart on next run loop so the animation
                // transaction doesn't interfere with the scroll-view layout pass.
                DispatchQueue.main.async {
                    startAnimationsIfNeeded()
                }
            }
        }
    }

    private func startAnimationsIfNeeded() {
        guard !isDisabled, phase == 0 else { return }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            phase = 360
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
    }
}

// MARK: - PsychedelicProgressBar

/// A progress bar styled like PsychedelicButton2.
/// The plasma + vignette fill extends only to the progress percentage.
/// White text showing the percentage sits centered with a dark vignette behind it.
struct PsychedelicProgressBar: View {
    var progress: Double  // 0...100
    var cornerRadius: CGFloat = CMTheme.buttonRadius

    @State private var phase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3

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

    private let vignetteColor = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var fraction: CGFloat { min(max(CGFloat(progress) / 100.0, 0), 1) }
    private var isComplete: Bool { abs(progress - 100) < 0.5 }

    var body: some View {
        GeometryReader { geo in
            let fillWidth = geo.size.width * fraction

            ZStack {
                // Empty track — jet black
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.black)

                // Filled portion — psychedelic plasma clipped to progress width
                ZStack {
                    // Base plasma
                    AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))

                    // Counter-rotating shimmer
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
                    .blendMode(.screen)

                    // Glass overlay (solid tint — avoids GPU-expensive blur)
                    Rectangle()
                        .fill(Color(red: 0.16, green: 0.16, blue: 0.20).opacity(0.25))

                    // Dark center vignette — scales with progress (gentle 1/4 decay)
                    RadialGradient(
                        colors: [
                            vignetteColor.opacity(0.75 + 0.25 * fraction * fraction),  // 0.75→1.0
                            vignetteColor.opacity(0.71 + 0.24 * fraction),             // 0.71→0.95
                            vignetteColor.opacity(0.45 + 0.25 * fraction),             // 0.45→0.70
                            vignetteColor.opacity(0.19 + 0.16 * fraction),             // 0.19→0.35
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geo.size.width * (0.41 + 0.14 * fraction), 90)  // 0.41→0.55 of width
                    )
                }
                .frame(width: fillWidth)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: fraction >= 0.98 ? cornerRadius : 4,
                        topTrailingRadius: fraction >= 0.98 ? cornerRadius : 4
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                // Neon border on the full bar
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7 * Double(fraction)),
                                .clear,
                                Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5 * Double(fraction)),
                                .clear,
                                Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.7 * Double(fraction)),
                                .clear,
                                Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.7 * Double(fraction)),
                            ],
                            center: .center,
                            angle: .degrees(-phase)
                        ),
                        lineWidth: 1.5
                    )

                // Percentage text — centered in the filled portion
                if fillWidth > 30 {
                    Text("\(Int(progress))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                        .position(x: fillWidth / 2, y: geo.size.height / 2)
                } else if progress > 0 {
                    Text("\(Int(progress))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(CMTheme.textTertiary)
                        .position(x: fillWidth + 20, y: geo.size.height / 2)
                }
            }
            .shadow(
                color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(Double(glowPulse) * Double(fraction)),
                radius: 10, y: 4
            )
        }
        .frame(height: 44)
        .drawingGroup()
        .animation(.cmSpring, value: progress)
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            phase = 360
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
    }
}

// MARK: - PsychedelicAlert2

/// Morphing radial plasma with concentric rings, kaleidoscope shimmer,
/// pulsing neon border, floating particles feel, and dissolving text entrance.
struct PsychedelicAlert2: View {
    let title: String
    let subtitle: String
    let buttonLabel: String
    let onDismiss: () -> Void
    @State private var phase: CGFloat = 0
    @State private var ringPulse: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var iconSpin: CGFloat = 0
    @State private var plasmaShift: CGFloat = 0

    private let plasmaColors: [Color] = [
        Color(red: 0.0, green: 0.0, blue: 0.2),     // deep void
        Color(red: 0.3, green: 0.0, blue: 0.8),     // indigo plasma
        Color(red: 0.8, green: 0.0, blue: 0.6),     // magenta fire
        Color(red: 1.0, green: 0.2, blue: 0.0),     // solar flare
        Color(red: 1.0, green: 0.8, blue: 0.0),     // golden nova
        Color(red: 0.0, green: 1.0, blue: 0.5),     // alien green
        Color(red: 0.0, green: 0.4, blue: 1.0),     // deep ocean
        Color(red: 0.0, green: 0.0, blue: 0.2),     // back to void
    ]

    private let ringColors: [Color] = [
        Color(red: 1.0, green: 0.0, blue: 0.8),
        Color(red: 0.0, green: 0.8, blue: 1.0),
        Color(red: 1.0, green: 1.0, blue: 0.0),
        Color(red: 1.0, green: 0.0, blue: 0.8),
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop with subtle color tint
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 0.0, blue: 0.5).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                )
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 20) {
                // Animated icon with orbital rings
                ZStack {
                    // Outer orbital ring 1
                    Circle()
                        .stroke(
                            AngularGradient(colors: ringColors, center: .center, angle: .degrees(phase)),
                            lineWidth: 2
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(phase))
                        .opacity(0.7)

                    // Outer orbital ring 2 (counter)
                    Circle()
                        .stroke(
                            AngularGradient(colors: ringColors, center: .center, angle: .degrees(-phase * 2)),
                            lineWidth: 1.5
                        )
                        .frame(width: 95, height: 95)
                        .rotationEffect(.degrees(-phase * 0.5))
                        .opacity(0.4)

                    // Pulsing glow behind icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.6),
                                    Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 35 + ringPulse * 10
                            )
                        )
                        .frame(width: 70, height: 70)
                        .hueRotation(.degrees(phase * 3))

                    // Icon
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(iconSpin))
                        )
                        .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.8), radius: 10)
                }

                // Title
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .hueRotation(.degrees(phase))
                    .shadow(color: Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.5), radius: 4)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Subtitle
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .hueRotation(.degrees(-phase * 0.5))
                    .opacity(textOpacity)

                // Button
                Button {
                    onDismiss()
                } label: {
                    Text(buttonLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.8, green: 0.0, blue: 0.6),
                                                Color(red: 0.3, green: 0.0, blue: 1.0),
                                                Color(red: 0.0, green: 0.5, blue: 1.0),
                                            ],
                                            startPoint: UnitPoint(x: plasmaShift, y: 0),
                                            endPoint: UnitPoint(x: plasmaShift + 1, y: 1)
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        AngularGradient(
                                            colors: [.white.opacity(0.6), .clear, .white.opacity(0.3), .clear, .white.opacity(0.6)],
                                            center: .center,
                                            angle: .degrees(phase * 2)
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
                .buttonStyle(CMPressStyle())
                .padding(.top, 4)
                .opacity(textOpacity)
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(
                ZStack {
                    // Plasma background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            AngularGradient(colors: plasmaColors, center: .center, angle: .degrees(phase))
                        )
                        .opacity(0.4)

                    // Dark glass (solid tint — avoids GPU-expensive blur)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.92))

                    // Neon border
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.8),
                                    Color(red: 1.0, green: 0.0, blue: 0.8).opacity(0.5),
                                    Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.8),
                                    Color(red: 1.0, green: 1.0, blue: 0.0).opacity(0.5),
                                    Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.8),
                                ],
                                center: .center,
                                angle: .degrees(-phase)
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color(red: 0.3, green: 0.0, blue: 0.8).opacity(0.6), radius: 20, y: 10)
            )
            .scaleEffect(0.95 + ringPulse * 0.05)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                iconSpin = 360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                ringPulse = 1.0
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: true)) {
                plasmaShift = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - PsychedelicAlert3

/// "Liquid Mercury": Rippling concentric rings with a silver-to-cyan
/// chromatic palette, wobbling mercury blob icon, scanning beam sweep, and dissolve-in text.
/// Used for density-update confirmations.
struct PsychedelicAlert3: View {
    let title: String
    let subtitle: String
    let value: String
    let onDismiss: () -> Void

    @State private var phase: CGFloat = 0
    @State private var ripple: CGFloat = 0
    @State private var blobWobble: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var scanBeam: CGFloat = 0
    @State private var dismissed = false
    private let mercuryColors: [Color] = [
        Color(red: 0.55, green: 0.60, blue: 0.68),  // gunmetal
        Color(red: 0.78, green: 0.82, blue: 0.90),  // silver mist
        Color(red: 0.0,  green: 0.85, blue: 0.95),  // liquid cyan
        Color(red: 0.45, green: 0.0,  blue: 0.90),  // ultra-violet
        Color(red: 0.0,  green: 0.55, blue: 1.0),   // cobalt pulse
        Color(red: 0.78, green: 0.82, blue: 0.90),  // silver mist
        Color(red: 0.55, green: 0.60, blue: 0.68),  // gunmetal
    ]

    private let ringColors: [Color] = [
        Color(red: 0.0, green: 0.90, blue: 1.0),
        Color(red: 0.6, green: 0.0,  blue: 1.0),
        Color(red: 0.85, green: 0.85, blue: 0.95),
        Color(red: 0.0, green: 0.90, blue: 1.0),
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop with silver radial tint
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [
                            Color(red: 0.4, green: 0.45, blue: 0.6).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                )
                .onTapGesture {
                    guard !dismissed else { return }
                    dismissed = true
                    onDismiss()
                }

            // Card
            VStack(spacing: 18) {
                // Mercury blob icon with concentric ripple rings
                ZStack {
                    // Ripple rings expanding outward
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                AngularGradient(colors: ringColors, center: .center, angle: .degrees(phase + Double(i) * 120)),
                                lineWidth: 1.2
                            )
                            .frame(width: 70 + CGFloat(i) * 20, height: 70 + CGFloat(i) * 20)
                            .scaleEffect(1.0 + ripple * 0.08 * CGFloat(i + 1))
                            .opacity(0.5 - Double(i) * 0.12)
                            .rotationEffect(.degrees(Double(i % 2 == 0 ? 1 : -1) * phase * 0.5))
                    }

                    // Pulsing mercury glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.5),
                                    Color(red: 0.45, green: 0.0, blue: 0.90).opacity(0.25),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30 + ripple * 8
                            )
                        )
                        .frame(width: 60, height: 60)
                        .hueRotation(.degrees(phase * 2))

                    // Mercury droplet icon
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            AngularGradient(colors: mercuryColors, center: .center, angle: .degrees(phase * 1.5))
                        )
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.95).opacity(0.7), radius: 8)
                        .scaleEffect(x: 1.0 + blobWobble * 0.06, y: 1.0 - blobWobble * 0.04)
                }

                // Title
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.88, blue: 0.95), .white],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .hueRotation(.degrees(phase * 0.5))
                    .shadow(color: Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.4), radius: 4)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Value readout
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.90, blue: 1.0),
                                Color(red: 0.78, green: 0.82, blue: 0.95),
                                Color(red: 0.0, green: 0.90, blue: 1.0),
                            ],
                            startPoint: UnitPoint(x: scanBeam, y: 0),
                            endPoint: UnitPoint(x: scanBeam + 0.5, y: 1)
                        )
                    )
                    .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.95).opacity(0.6), radius: 6)
                    .opacity(textOpacity)

                // Subtitle
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .hueRotation(.degrees(-phase * 0.3))
                    .opacity(textOpacity)

                // Dismiss button
                Button {
                    guard !dismissed else { return }
                    dismissed = true
                    onDismiss()
                } label: {
                    Text("OK")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.4), radius: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.35, green: 0.0, blue: 0.75),
                                                Color(red: 0.0, green: 0.55, blue: 0.90),
                                                Color(red: 0.0, green: 0.80, blue: 0.85),
                                            ],
                                            startPoint: UnitPoint(x: scanBeam, y: 0),
                                            endPoint: UnitPoint(x: scanBeam + 1, y: 1)
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        AngularGradient(
                                            colors: [.white.opacity(0.5), .clear, Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.4), .clear, .white.opacity(0.5)],
                                            center: .center,
                                            angle: .degrees(phase * 2)
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
                .buttonStyle(CMPressStyle())
                .padding(.top, 4)
                .opacity(textOpacity)
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(
                ZStack {
                    // Mercury plasma background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            AngularGradient(colors: mercuryColors, center: .center, angle: .degrees(phase * 0.8))
                        )
                        .opacity(0.35)

                    // Dark glass (solid tint — avoids GPU-expensive blur)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.92))

                    // Scanning beam overlay
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.08), .clear],
                                startPoint: UnitPoint(x: 0, y: scanBeam - 0.2),
                                endPoint: UnitPoint(x: 0, y: scanBeam + 0.2)
                            )
                        )

                    // Chromatic border
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.7),
                                    Color(red: 0.78, green: 0.82, blue: 0.95).opacity(0.4),
                                    Color(red: 0.45, green: 0.0, blue: 0.90).opacity(0.6),
                                    Color(red: 0.78, green: 0.82, blue: 0.95).opacity(0.4),
                                    Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.7),
                                ],
                                center: .center,
                                angle: .degrees(-phase * 1.2)
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color(red: 0.0, green: 0.55, blue: 0.90).opacity(0.5), radius: 20, y: 8)
            )
            .scaleEffect(0.96 + ripple * 0.04)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                ripple = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                blobWobble = 1.0
            }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) {
                scanBeam = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - PsychedelicAlert5

/// "Acid Rain": Deep aqua-to-violet rippling water rings with a raindrop icon,
/// concentric wave pulses, chromatic sweep, and dissolve-in text.
/// Used when the user changes "Additional Water for Dissolving Active".
struct PsychedelicAlert5: View {
    let title: String
    let subtitle: String
    let value: String
    let onDismiss: () -> Void

    @State private var phase: CGFloat = 0
    @State private var ripple: CGFloat = 0
    @State private var dropBounce: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var waveSweep: CGFloat = 0
    @State private var dismissed = false

    private let aquaColors: [Color] = [
        Color(red: 0.0,  green: 0.12, blue: 0.20),  // abyss
        Color(red: 0.0,  green: 0.35, blue: 0.55),  // deep teal
        Color(red: 0.0,  green: 0.70, blue: 0.85),  // electric aqua
        Color(red: 0.25, green: 0.90, blue: 1.0),   // neon cyan
        Color(red: 0.55, green: 0.0,  blue: 1.0),   // ultraviolet
        Color(red: 0.0,  green: 0.55, blue: 0.90),  // cobalt rain
        Color(red: 0.0,  green: 0.70, blue: 0.85),  // electric aqua
        Color(red: 0.0,  green: 0.12, blue: 0.20),  // abyss
    ]

    private let ringColors: [Color] = [
        Color(red: 0.0,  green: 0.90, blue: 1.0),
        Color(red: 0.55, green: 0.0,  blue: 1.0),
        Color(red: 0.25, green: 0.90, blue: 1.0),
        Color(red: 0.0,  green: 0.90, blue: 1.0),
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop with aqua radial tint
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.30, blue: 0.50).opacity(0.35),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                )
                .onTapGesture {
                    guard !dismissed else { return }
                    dismissed = true
                    onDismiss()
                }

            // Card
            VStack(spacing: 18) {
                // Raindrop icon with concentric water ripple rings
                ZStack {
                    // Expanding ripple rings
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: ringColors,
                                    center: .center,
                                    angle: .degrees(phase + Double(i) * 90)
                                ),
                                lineWidth: 1.0
                            )
                            .frame(
                                width: 60 + CGFloat(i) * 22,
                                height: 60 + CGFloat(i) * 22
                            )
                            .scaleEffect(1.0 + ripple * 0.1 * CGFloat(i + 1))
                            .opacity(0.55 - Double(i) * 0.1)
                            .rotationEffect(.degrees(Double(i % 2 == 0 ? 1 : -1) * phase * 0.4))
                    }

                    // Pulsing aqua glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.55),
                                    Color(red: 0.55, green: 0.0, blue: 1.0).opacity(0.25),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30 + ripple * 10
                            )
                        )
                        .frame(width: 60, height: 60)
                        .hueRotation(.degrees(phase * 2.5))

                    // Raindrop icon
                    Image(systemName: "drop.halffull")
                        .font(.system(size: 42))
                        .foregroundStyle(
                            AngularGradient(
                                colors: aquaColors,
                                center: .center,
                                angle: .degrees(phase * 1.3)
                            )
                        )
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.7), radius: 10)
                        .scaleEffect(1.0 + dropBounce * 0.08)
                        .offset(y: -dropBounce * 2)
                }

                // Title
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.75, green: 0.95, blue: 1.0),
                                .white
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .hueRotation(.degrees(phase * 0.6))
                    .shadow(color: Color(red: 0.0, green: 0.80, blue: 1.0).opacity(0.45), radius: 4)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Value readout
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.90, blue: 1.0),
                                Color(red: 0.55, green: 0.0, blue: 1.0),
                                Color(red: 0.25, green: 0.90, blue: 1.0),
                            ],
                            startPoint: UnitPoint(x: waveSweep, y: 0),
                            endPoint: UnitPoint(x: waveSweep + 0.5, y: 1)
                        )
                    )
                    .shadow(color: Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.55), radius: 6)
                    .opacity(textOpacity)

                // Subtitle
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .hueRotation(.degrees(-phase * 0.3))
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Dismiss button
                Button {
                    guard !dismissed else { return }
                    dismissed = true
                    onDismiss()
                } label: {
                    Text("OK")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.4), radius: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.30, blue: 0.70),
                                                Color(red: 0.0, green: 0.60, blue: 0.85),
                                                Color(red: 0.25, green: 0.85, blue: 1.0),
                                            ],
                                            startPoint: UnitPoint(x: waveSweep, y: 0),
                                            endPoint: UnitPoint(x: waveSweep + 1, y: 1)
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        AngularGradient(
                                            colors: [
                                                .white.opacity(0.5), .clear,
                                                Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.4),
                                                .clear, .white.opacity(0.5)
                                            ],
                                            center: .center,
                                            angle: .degrees(phase * 2)
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
                .buttonStyle(CMPressStyle())
                .padding(.top, 4)
                .opacity(textOpacity)
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(
                ZStack {
                    // Aqua plasma background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            AngularGradient(colors: aquaColors, center: .center, angle: .degrees(phase * 0.7))
                        )
                        .opacity(0.35)

                    // Dark glass (solid tint — avoids GPU-expensive blur)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.92))

                    // Wave sweep overlay
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.07),
                                    .clear
                                ],
                                startPoint: UnitPoint(x: 0, y: waveSweep - 0.2),
                                endPoint: UnitPoint(x: 0, y: waveSweep + 0.2)
                            )
                        )

                    // Chromatic aqua border
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.7),
                                    Color(red: 0.55, green: 0.0, blue: 1.0).opacity(0.5),
                                    Color(red: 0.25, green: 0.90, blue: 1.0).opacity(0.6),
                                    Color(red: 0.55, green: 0.0, blue: 1.0).opacity(0.5),
                                    Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.7),
                                ],
                                center: .center,
                                angle: .degrees(-phase * 1.1)
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color(red: 0.0, green: 0.40, blue: 0.85).opacity(0.5), radius: 20, y: 8)
            )
            .scaleEffect(0.96 + ripple * 0.04)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                ripple = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                dropBounce = 1.0
            }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) {
                waveSweep = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - PsychedelicAlert4

/// "Molten Ember": Glowing ember-to-gold radial plasma with honeycomb shimmer,
/// spinning flame icon, ember-particle glow, and warm dissolve text.
/// Used for overage-update confirmations.
struct PsychedelicAlert4: View {
    let title: String
    let subtitle: String
    let value: String
    let onDismiss: () -> Void

    @State private var phase: CGFloat = 0
    @State private var emberPulse: CGFloat = 0
    @State private var flameSpin: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var heatWave: CGFloat = 0
    @State private var dismissed = false

    private let emberColors: [Color] = [
        Color(red: 0.15, green: 0.02, blue: 0.0),   // dark coal
        Color(red: 0.60, green: 0.08, blue: 0.0),   // deep ember
        Color(red: 0.95, green: 0.25, blue: 0.0),   // molten orange
        Color(red: 1.0,  green: 0.65, blue: 0.0),   // liquid gold
        Color(red: 1.0,  green: 0.90, blue: 0.35),  // white-hot
        Color(red: 1.0,  green: 0.65, blue: 0.0),   // liquid gold
        Color(red: 0.95, green: 0.25, blue: 0.0),   // molten orange
        Color(red: 0.15, green: 0.02, blue: 0.0),   // dark coal
    ]

    private let crownColors: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.0),
        Color(red: 1.0, green: 0.3, blue: 0.0),
        Color(red: 1.0, green: 0.95, blue: 0.5),
        Color(red: 1.0, green: 0.8, blue: 0.0),
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop with warm radial tint
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [
                            Color(red: 0.5, green: 0.15, blue: 0.0).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                )
                .onTapGesture {
                    guard !dismissed else { return }
                    dismissed = true
                    onDismiss()
                }

            // Card
            VStack(spacing: 18) {
                // Flame icon with ember corona
                ZStack {
                    // Outer heat corona
                    Circle()
                        .stroke(
                            AngularGradient(colors: crownColors, center: .center, angle: .degrees(phase * 0.7)),
                            lineWidth: 2.5
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(phase * 0.3))
                        .opacity(0.55)
                        .blur(radius: 1)

                    // Inner ember ring
                    Circle()
                        .stroke(
                            AngularGradient(colors: crownColors, center: .center, angle: .degrees(-phase * 1.3)),
                            lineWidth: 1.5
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-phase * 0.6))
                        .opacity(0.4)

                    // Pulsing heat glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.5),
                                    Color(red: 0.95, green: 0.20, blue: 0.0).opacity(0.25),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 32 + emberPulse * 10
                            )
                        )
                        .frame(width: 64, height: 64)
                        .hueRotation(.degrees(phase * 1.5))

                    // Flame icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(
                            AngularGradient(colors: emberColors, center: .center, angle: .degrees(flameSpin))
                        )
                        .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.8), radius: 10)
                        .scaleEffect(1.0 + emberPulse * 0.06)
                }

                // Title
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.92, blue: 0.75), .white],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .hueRotation(.degrees(phase * 0.3))
                    .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.4), radius: 4)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Value readout
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.90, blue: 0.35),
                                Color(red: 1.0, green: 0.55, blue: 0.0),
                                Color(red: 1.0, green: 0.90, blue: 0.35),
                            ],
                            startPoint: UnitPoint(x: heatWave, y: 0),
                            endPoint: UnitPoint(x: heatWave + 0.5, y: 1)
                        )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.5), radius: 6)
                    .opacity(textOpacity)

                // Subtitle
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .hueRotation(.degrees(-phase * 0.2))
                    .opacity(textOpacity)

                // Dismiss button
                Button {
                    guard !dismissed else { return }
                    dismissed = true
                    onDismiss()
                } label: {
                    Text("OK")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.4), radius: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.70, green: 0.10, blue: 0.0),
                                                Color(red: 0.95, green: 0.40, blue: 0.0),
                                                Color(red: 1.0,  green: 0.70, blue: 0.0),
                                            ],
                                            startPoint: UnitPoint(x: heatWave, y: 0),
                                            endPoint: UnitPoint(x: heatWave + 1, y: 1)
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        AngularGradient(
                                            colors: [
                                                .white.opacity(0.5), .clear,
                                                Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4),
                                                .clear, .white.opacity(0.5)
                                            ],
                                            center: .center,
                                            angle: .degrees(phase * 2)
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
                .buttonStyle(CMPressStyle())
                .padding(.top, 4)
                .opacity(textOpacity)
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(
                ZStack {
                    // Ember plasma background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            AngularGradient(colors: emberColors, center: .center, angle: .degrees(phase * 0.6))
                        )
                        .opacity(0.35)

                    // Dark glass (solid tint — avoids GPU-expensive blur)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.92))

                    // Heat wave overlay
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.06), .clear],
                                startPoint: UnitPoint(x: 0, y: heatWave - 0.2),
                                endPoint: UnitPoint(x: 0, y: heatWave + 0.2)
                            )
                        )

                    // Molten border
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.80, blue: 0.0).opacity(0.7),
                                    Color(red: 0.95, green: 0.25, blue: 0.0).opacity(0.5),
                                    Color(red: 1.0, green: 0.90, blue: 0.35).opacity(0.6),
                                    Color(red: 0.95, green: 0.25, blue: 0.0).opacity(0.5),
                                    Color(red: 1.0, green: 0.80, blue: 0.0).opacity(0.7),
                                ],
                                center: .center,
                                angle: .degrees(-phase * 0.9)
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color(red: 0.70, green: 0.10, blue: 0.0).opacity(0.5), radius: 20, y: 8)
            )
            .scaleEffect(0.96 + emberPulse * 0.04)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                flameSpin = 360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                emberPulse = 1.0
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: true)) {
                heatWave = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                textOpacity = 1.0
            }
        }
    }
}
