import SwiftUI

struct FloatNotificationView: View {
    let message: String
    var corner: Corner = .bottomRight
    var effect: String? = nil
    var sound: String? = nil
    var onTap: (() -> Void)?

    @State private var isVisible = false
    @State private var bounce = false
    @State private var entryOffset: CGFloat = 0
    @StateObject private var particleSystem = ParticleSystem()
    @State private var showGlow = false
    @State private var showShimmer = false
    @State private var showRipple = false

    private var effectiveEffect: String {
        effect ?? corner.defaultEffect
    }

    private var effectiveSound: String? {
        sound ?? corner.defaultSound
    }

    private var entryAnimation: (offset: CGFloat, y: CGFloat) {
        switch corner {
        case .bottomLeft, .bottomRight:
            return (entryOffset, 24)
        case .topLeft, .topRight:
            return (entryOffset, -24)
        case .center:
            return (entryOffset, 0)
        case .menubar:
            return (entryOffset, -60)
        case .horizontal:
            return (-200, 0)
        case .cursorFollow:
            return (0, 0)
        }
    }

    var body: some View {
        ZStack {
            contentView
                .opacity(isVisible ? 1 : 0)

            if showRipple {
                RippleView(color: .yellow.opacity(0.6))
                    .frame(width: 280, height: 68)
            }

            if corner == .cursorFollow {
                ParticleTrailView(system: particleSystem, color: .yellow)
                    .frame(width: 300, height: 100)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : entryAnimation.offset, y: isVisible ? 0 : entryAnimation.y)
        .onAppear {
            triggerEntry()
        }
    }

    private var contentView: some View {
        HStack(spacing: 10) {
            Text("🦆")
                .font(.system(size: 32))
                .scaleEffect(bounce ? 1.2 : 1.0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.5)
                    .repeatCount(3, autoreverses: true),
                    value: bounce
                )
                .modifier(GlowModifier(color: .yellow, radius: showGlow ? 12 : 0))

            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Code")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 280, height: 68)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        )
        .modifier(ShimmerModifier())
        .onTapGesture { onTap?() }
    }

    private func triggerEntry() {
        SoundManager.shared.play(effectiveSound)

        switch effectiveEffect {
        case "slide":
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bounce = true
            }
            showGlow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showGlow = false
            }

        case "fade":
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }
            showShimmer = true

        case "dropdown":
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            showRipple = true

        case "marquee":
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }

        case "trail":
            withAnimation(.easeIn(duration: 0.2)) {
                isVisible = true
            }
            particleSystem.emit(at: CGPoint(x: 140, y: 34))
            showGlow = true

        default:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bounce = true
            }
        }
    }
}
