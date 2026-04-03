import SwiftUI

// MARK: - Particle

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var opacity: Double
    var scale: Double
    var birthTime: Date

    var age: TimeInterval {
        Date().timeIntervalSince(birthTime)
    }
}

// MARK: - ParticleSystem

class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []

    private var timer: Timer?

    var particleLifetime: TimeInterval = 0.8
    var emissionRate: Int = 12
    var particleSpeed: CGFloat = 60

    deinit {
        stopTimer()
    }

    func emit(at position: CGPoint, direction: CGVector? = nil) {
        let count = emissionRate
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: particleSpeed * 0.5...particleSpeed)

            let velocity = direction ?? CGVector(
                dx: Darwin.cos(angle) * speed,
                dy: Darwin.sin(angle) * speed
            )

            let particle = Particle(
                position: position,
                velocity: velocity,
                opacity: 1.0,
                scale: Double.random(in: 0.3...1.0),
                birthTime: Date()
            )
            particles.append(particle)
        }
        startTimerIfNeeded()
    }

    private func update(deltaTime: TimeInterval) {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.dx * deltaTime
            particles[i].position.y += particles[i].velocity.dy * deltaTime

            let age = particles[i].age / particleLifetime
            particles[i].opacity = max(0, 1 - age)
            particles[i].scale = max(0, 1 - age * 0.5)
        }

        particles.removeAll { $0.opacity <= 0 }

        if particles.isEmpty {
            stopTimer()
        }
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        var lastUpdate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            let delta = now.timeIntervalSince(lastUpdate)
            lastUpdate = now
            self.update(deltaTime: delta)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - ParticleTrailView

struct ParticleTrailView: View {
    @ObservedObject var system: ParticleSystem
    let color: Color

    var body: some View {
        Canvas { context, size in
            for particle in system.particles {
                let rect = CGRect(
                    x: particle.position.x - 4 * particle.scale,
                    y: particle.position.y - 4 * particle.scale,
                    width: 8 * particle.scale,
                    height: 8 * particle.scale
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(color.opacity(particle.opacity * 0.8))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - GlowModifier

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius * 0.4, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 0.6, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
}

// MARK: - RippleShape

struct RippleShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = max(rect.width, rect.height) / 2
        let currentRadius = maxRadius * progress

        path.addEllipse(in: CGRect(
            x: center.x - currentRadius,
            y: center.y - currentRadius,
            width: currentRadius * 2,
            height: currentRadius * 2
        ))

        return path
    }
}

// MARK: - RippleView

struct RippleView: View {
    let color: Color
    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .opacity(opacity)
            .scaleEffect(1 + progress * 0.5)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    progress = 1
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - ShimmerModifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func glow(color: Color = .yellow, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Effect Animation Names

extension String {
    var lottieFileName: String {
        switch self {
        case "slide":   return "slide_entry"
        case "fade":    return "fade_entry"
        case "dropdown": return "dropdown_entry"
        case "marquee": return "marquee_entry"
        case "trail":   return "trail_entry"
        default:        return "slide_entry"
        }
    }

    var exitLottieFileName: String {
        switch self {
        case "slide", "dropdown", "marquee", "trail":
            return "exit_slide"
        case "fade":
            return "exit_fade"
        default:
            return "exit_slide"
        }
    }
}
