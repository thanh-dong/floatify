import SwiftUI
import Lottie

struct FloatNotificationView: View {
    let message: String
    var project: String?
    var corner: Corner = .bottomRight
    var effect: String?
    var sound: String?
    var onTap: (() -> Void)?
    @ObservedObject var dismissController: DismissController

    @State private var showGlow = false
    @State private var showIdleAnimations = false
    @State private var isEntryPlaying = false
    @State private var panelScale: CGFloat = 0.85
    @State private var panelOpacity: CGFloat = 0
    @StateObject private var particleSystem = ParticleSystem()

    private var effectiveEffect: String {
        effect ?? corner.defaultEffect
    }

    private var effectiveSound: String? {
        sound ?? corner.defaultSound
    }

    private var displayName: String {
        let name = project ?? "Claude Code"
        if name.count > 20 {
            return String(name.prefix(20)) + "..."
        }
        return name
    }

    var body: some View {
        ZStack {
            if corner == .cursorFollow {
                ParticleTrailView(system: particleSystem, color: .yellow)
                    .frame(width: 300, height: 100)
            }

            // Background material
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)

            // Lottie panel - drives the panel visual
            LottiePanelBackground(
                animationName: effectiveEffect.lottieFileName,
                isPlaying: $isEntryPlaying,
                onEntryComplete: {
                    showIdleAnimations = true
                    showGlow = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showGlow = false
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Content on top
            HStack(spacing: 10) {
                duckIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 280, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        .scaleEffect(panelScale)
        .opacity(panelOpacity)
        .onAppear {
            triggerEntry()
        }
        .onChange(of: dismissController.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                triggerExit()
            }
        }
    }

    private var duckIcon: some View {
        Text("\u{1F986}")
            .font(.system(size: 32))
            .bobbing(isEnabled: showIdleAnimations)
            .glowPulse(isEnabled: showIdleAnimations && showGlow)
            .floatDrift(isEnabled: showIdleAnimations)
            .hoverScale()
    }

    private func triggerEntry() {
        SoundManager.shared.play(effectiveSound)

        isEntryPlaying = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            panelScale = 1.0
            panelOpacity = 1.0
        }
    }

    private func triggerExit() {
        showIdleAnimations = false
        isEntryPlaying = false

        withAnimation(.easeOut(duration: 0.25)) {
            panelScale = 0.85
            panelOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            dismissController.onDismissComplete?()
        }
    }
}
