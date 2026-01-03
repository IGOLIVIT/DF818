//
//  HomeView.swift
//  DF818
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var navigation: NavigationManager
    @ObservedObject var gameManager: GameManager
    
    @State private var cloudOffset1: CGFloat = -100
    @State private var cloudOffset2: CGFloat = 50
    @State private var lightningOpacity: Double = 0
    @State private var sphereScale: CGFloat = 1.0
    @State private var sphereGlow: Double = 0.5
    @State private var isActive: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background
                animatedBackground(geometry: geometry)
                
                // Main Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Hero Section
                    heroSection
                    
                    Spacer()
                    
                    // Menu Buttons
                    menuButtons
                    
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            isActive = true
            startAnimations()
        }
        .onDisappear {
            isActive = false
        }
    }
    
    // MARK: - Animated Background
    @ViewBuilder
    private func animatedBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            // Base gradient
            ThemeGradients.backgroundGradient
                .ignoresSafeArea()
            
            // Drifting clouds
            ForEach(0..<3, id: \.self) { index in
                cloudShape(index: index, geometry: geometry)
            }
            
            // Lightning flicker
            Rectangle()
                .fill(Color.mistyLightBlue.opacity(lightningOpacity))
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Subtle glow orbs
            Circle()
                .fill(ThemeGradients.mistyGlow)
                .frame(width: 300, height: 300)
                .offset(x: -50, y: -200)
                .blur(radius: 50)
            
            Circle()
                .fill(RadialGradient(
                    colors: [Color.goldGlow.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                ))
                .frame(width: 200, height: 200)
                .offset(x: 100, y: 300)
                .blur(radius: 30)
        }
    }
    
    @ViewBuilder
    private func cloudShape(index: Int, geometry: GeometryProxy) -> some View {
        let yOffset: CGFloat = CGFloat(index) * 150 - 100
        let baseOffset = index == 0 ? cloudOffset1 : (index == 1 ? cloudOffset2 : -cloudOffset1 * 0.5)
        
        Ellipse()
            .fill(Color.mistyLightBlue.opacity(0.03 + Double(index) * 0.01))
            .frame(width: 200 + CGFloat(index) * 50, height: 60 + CGFloat(index) * 20)
            .blur(radius: 30)
            .offset(x: baseOffset, y: yOffset)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Animated sphere
            ZStack {
                // Outer glow
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.goldGlow.opacity(sphereGlow * 0.6), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    ))
                    .frame(width: 160, height: 160)
                
                // Inner sphere
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.goldGlow, Color.goldGlow.opacity(0.7)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: Color.goldGlow.opacity(0.8), radius: 20, x: 0, y: 0)
            }
            .scaleEffect(sphereScale)
            
            // Tagline
            Text("Journey Through the Storm")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.mistyLightBlue)
                .multilineTextAlignment(.center)
            
            // Progress indicator
            if gameManager.completedLevelsCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.goldGlow)
                    Text("\(gameManager.totalRunes) Runes Collected")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.goldGlow.opacity(0.9))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.goldGlow.opacity(0.15))
                )
            }
        }
    }
    
    // MARK: - Menu Buttons
    private var menuButtons: some View {
        VStack(spacing: 16) {
            // Start Game Button
            Button(action: {
                if let nextLevel = gameManager.getNextUnlockedLevel() {
                    navigation.startLevel(nextLevel)
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Game")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            
            // Levels Button
            Button(action: {
                navigation.navigateTo(.levels)
            }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Levels")
                }
                .frame(maxWidth: 200)
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // Settings Button
            Button(action: {
                navigation.navigateTo(.settings)
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .frame(maxWidth: 200)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Cloud drift
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            cloudOffset1 = 100
        }
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true).delay(1)) {
            cloudOffset2 = -50
        }
        
        // Sphere pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            sphereScale = 1.05
            sphereGlow = 0.8
        }
        
        // Lightning flicker
        startLightningFlicker()
    }
    
    private func startLightningFlicker() {
        guard isActive else { return }
        let delay = Double.random(in: 3...8)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            guard isActive else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                lightningOpacity = 0.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    lightningOpacity = 0
                }
            }
            startLightningFlicker()
        }
    }
}

#Preview {
    HomeView(navigation: NavigationManager(), gameManager: GameManager.shared)
}

