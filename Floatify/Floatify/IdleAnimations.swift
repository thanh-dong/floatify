import SwiftUI

// MARK: - BobModifier

struct BobModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isEnabled ? 1.04 : 1.0)
            .animation(
                isEnabled
                    ? .spring(response: 1.8, dampingFraction: 0.6).repeatForever(autoreverses: true)
                    : .default,
                value: isEnabled
            )
    }
}

// MARK: - GlowPulseModifier

struct GlowPulseModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .shadow(color: FloaterPalette.idle.opacity(isEnabled ? 0.55 : 0), radius: 8, x: 0, y: 0)
            .animation(
                isEnabled
                    ? .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
                    : .default,
                value: isEnabled
            )
    }
}

// MARK: - FloatDriftModifier

struct FloatDriftModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isEnabled ? -2 : 0)
            .animation(
                isEnabled
                    ? .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
                    : .default,
                value: isEnabled
            )
    }
}

// MARK: - HoverScaleModifier

struct HoverScaleModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Extensions

extension View {
    func bobbing(isEnabled: Bool = true) -> some View {
        modifier(BobModifier(isEnabled: isEnabled))
    }

    func glowPulse(isEnabled: Bool = true) -> some View {
        modifier(GlowPulseModifier(isEnabled: isEnabled))
    }

    func floatDrift(isEnabled: Bool = true) -> some View {
        modifier(FloatDriftModifier(isEnabled: isEnabled))
    }

    func hoverScale() -> some View {
        modifier(HoverScaleModifier())
    }
}
