//
//  OnboardingView.swift
//  DF818
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var gameManager: GameManager
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var animationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ThemeGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button(action: completeOnboarding) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.mistyLightBlue.opacity(0.7))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(
                                page: page,
                                animationPhase: animationPhase,
                                geometry: geometry
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Page indicators
                    HStack(spacing: 10) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.goldGlow : Color.mistyLightBlue.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Continue button
                    Button(action: {
                        if currentPage < onboardingPages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentPage < onboardingPages.count - 1 ? "Continue" : "Begin")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
    
    private func completeOnboarding() {
        gameManager.completeOnboarding()
        onComplete()
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let animationPhase: Double
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated illustration
            animationView
                .frame(height: 200)
            
            Spacer()
                .frame(height: 20)
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 40))
                .foregroundColor(.goldGlow)
                .padding(.bottom, 8)
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(.mistyLightBlue.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var animationView: some View {
        switch page.animation {
        case .sphere:
            SphereAnimation(phase: animationPhase)
        case .obstacles:
            ObstaclesAnimation(phase: animationPhase)
        case .runes:
            RunesAnimation(phase: animationPhase)
        case .progression:
            ProgressionAnimation(phase: animationPhase)
        }
    }
}

// MARK: - Animation Views
struct SphereAnimation: View {
    let phase: Double
    
    var body: some View {
        ZStack {
            // Track
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mistyLightBlue.opacity(0.2), lineWidth: 2)
                .frame(width: 200, height: 150)
            
            // Sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.goldGlow, Color.goldGlow.opacity(0.7)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: Color.goldGlow.opacity(0.8), radius: 15, x: 0, y: 0)
                .offset(x: CGFloat(sin(phase * .pi * 2)) * 60)
        }
    }
}

struct ObstaclesAnimation: View {
    let phase: Double
    
    var body: some View {
        ZStack {
            // Corridor
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mistyLightBlue.opacity(0.2), lineWidth: 2)
                .frame(width: 200, height: 150)
            
            // Obstacles
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 60, height: 12)
                    .offset(
                        x: CGFloat(sin((phase + Double(index) * 0.3) * .pi * 2)) * 50,
                        y: CGFloat(index - 1) * 40
                    )
            }
            
            // Player sphere
            Circle()
                .fill(Color.goldGlow)
                .frame(width: 30, height: 30)
                .offset(y: 50)
                .shadow(color: Color.goldGlow.opacity(0.6), radius: 10)
        }
    }
}

struct RunesAnimation: View {
    let phase: Double
    
    var body: some View {
        ZStack {
            // Floating runes
            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) * (2 * .pi / 5) + phase * .pi
                let radius: CGFloat = 70
                
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color.goldGlow.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .blur(radius: 10)
                    
                    // Rune symbol
                    Image(systemName: "rhombus.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.goldGlow)
                }
                .offset(
                    x: CGFloat(cos(angle)) * radius,
                    y: CGFloat(sin(angle)) * radius * 0.5
                )
                .scaleEffect(1 + CGFloat(sin(phase * .pi * 2 + Double(index))) * 0.2)
            }
        }
    }
}

struct ProgressionAnimation: View {
    let phase: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress bars
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 12) {
                    Image(systemName: Difficulty.allCases[index].icon)
                        .font(.system(size: 20))
                        .foregroundColor(Difficulty.allCases[index].color)
                        .frame(width: 30)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            
                            // Fill - ensure positive width
                            let fillProgress = max(0.1, min(1.0, 0.3 + phase * 0.5 - Double(index) * 0.12))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Difficulty.allCases[index].color)
                                .frame(width: geo.size.width * CGFloat(fillProgress))
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
        .frame(width: 200)
    }
}

#Preview {
    OnboardingView(gameManager: GameManager.shared, onComplete: {})
}

