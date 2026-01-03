//
//  ParticleEffects.swift
//  DF818
//

import SwiftUI

// MARK: - Lightning Particle
struct LightningParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var opacity: Double
    var scale: CGFloat
    var rotation: Double
}

// MARK: - Sparkle Effect View
struct SparkleEffectView: View {
    let isActive: Bool
    let color: Color
    
    @State private var particles: [LightningParticle] = []
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12 * particle.scale))
                        .foregroundColor(color.opacity(particle.opacity))
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startEmitting()
            } else {
                stopEmitting()
            }
        }
        .onAppear {
            if isActive {
                startEmitting()
            }
        }
        .onDisappear {
            stopEmitting()
        }
    }
    
    private func startEmitting() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            addParticle()
            updateParticles()
        }
    }
    
    private func stopEmitting() {
        timer?.invalidate()
        timer = nil
    }
    
    private func addParticle() {
        let particle = LightningParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...200),
                y: CGFloat.random(in: 0...200)
            ),
            opacity: 1.0,
            scale: CGFloat.random(in: 0.5...1.5),
            rotation: Double.random(in: 0...360)
        )
        particles.append(particle)
    }
    
    private func updateParticles() {
        particles = particles.compactMap { particle in
            var updated = particle
            updated.opacity -= 0.1
            updated.position.y -= 2
            updated.rotation += 10
            return updated.opacity > 0 ? updated : nil
        }
    }
}

// MARK: - Floating Particles Background
struct FloatingParticlesView: View {
    @State private var particles: [(id: UUID, offset: CGSize, opacity: Double, scale: CGFloat)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(Color.mistyLightBlue)
                        .frame(width: 4 * particle.scale, height: 4 * particle.scale)
                        .opacity(particle.opacity)
                        .offset(particle.offset)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            (
                id: UUID(),
                offset: CGSize(
                    width: CGFloat.random(in: -size.width/2...size.width/2),
                    height: CGFloat.random(in: -size.height/2...size.height/2)
                ),
                opacity: Double.random(in: 0.1...0.4),
                scale: CGFloat.random(in: 0.5...2.0)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let duration = Double.random(in: 8...15)
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                particles[i].offset = CGSize(
                    width: CGFloat.random(in: -size.width/2...size.width/2),
                    height: CGFloat.random(in: -size.height/2...size.height/2)
                )
                particles[i].opacity = Double.random(in: 0.1...0.5)
            }
        }
    }
}

// MARK: - Rune Collection Effect
struct RuneCollectionEffect: View {
    @State private var isAnimating = false
    @State private var showBurst = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Burst circles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .stroke(Color.goldGlow, lineWidth: 2)
                    .frame(width: showBurst ? 100 : 20, height: showBurst ? 100 : 20)
                    .opacity(showBurst ? 0 : 0.8)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .offset(
                        x: showBurst ? CGFloat(cos(Double(index) * .pi / 4)) * 50 : 0,
                        y: showBurst ? CGFloat(sin(Double(index) * .pi / 4)) * 50 : 0
                    )
            }
            
            // Center flash
            Circle()
                .fill(Color.goldGlow)
                .frame(width: isAnimating ? 60 : 20, height: isAnimating ? 60 : 20)
                .opacity(isAnimating ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = true
                showBurst = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }
}

// MARK: - Lightning Flash Effect
struct LightningFlashView: View {
    @State private var opacity: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.mistyLightBlue)
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                triggerFlash()
            }
    }
    
    private func triggerFlash() {
        let delay = Double.random(in: 4...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.05)) {
                opacity = 0.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.1)) {
                    opacity = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.03)) {
                    opacity = 0.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        opacity = 0
                    }
                }
            }
            triggerFlash()
        }
    }
}

// MARK: - Pulsing Glow Effect
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.8 : 0.3), radius: isGlowing ? 20 : 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func pulsingGlow(color: Color = .goldGlow) -> some View {
        modifier(PulsingGlowModifier(color: color))
    }
}

// MARK: - Success Celebration Effect
struct SuccessCelebrationView: View {
    @State private var particles: [(id: UUID, x: CGFloat, y: CGFloat, delay: Double)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    ParticleStar(delay: particle.delay)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<15).map { i in
            (
                id: UUID(),
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height * 0.6),
                delay: Double(i) * 0.1
            )
        }
    }
}

struct ParticleStar: View {
    let delay: Double
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: CGFloat.random(in: 10...20)))
            .foregroundColor(.goldGlow)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        scale = 1
                        opacity = 1
                        rotation = Double.random(in: -30...30)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            scale = 0
                            opacity = 0
                        }
                    }
                }
            }
    }
}

