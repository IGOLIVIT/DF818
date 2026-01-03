//
//  Theme.swift
//  DF818
//

import SwiftUI

// Colors are defined in Assets.xcassets and auto-generated as Color extensions:
// - Color.deepStormBlue (Primary Background - Deep Storm Blue #0A1638)
// - Color.goldGlow (Primary Accent - Gold Glow #E6B645)
// - Color.mistyLightBlue (Secondary Accent - Misty Light Blue #BFD9FF)

// MARK: - Theme Gradients
struct ThemeGradients {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.deepStormBlue,
            Color.deepStormBlue.opacity(0.9),
            Color(red: 0.05, green: 0.1, blue: 0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let goldButtonGradient = LinearGradient(
        colors: [
            Color.goldGlow,
            Color.goldGlow.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let mistyGlow = RadialGradient(
        colors: [
            Color.mistyLightBlue.opacity(0.3),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 150
    )
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeGradients.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.mistyLightBlue.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct GoldButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.deepStormBlue)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(isEnabled ? ThemeGradients.goldButtonGradient : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
            )
            .shadow(color: isEnabled ? Color.goldGlow.opacity(0.5) : Color.clear, radius: configuration.isPressed ? 5 : 10, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.mistyLightBlue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .stroke(Color.mistyLightBlue.opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Constants
struct GameConstants {
    static let corridorWidth: CGFloat = 300
    static let playerSize: CGFloat = 40
    static let obstacleHeight: CGFloat = 20
    static let collectibleSize: CGFloat = 30
    static let baseSpeed: Double = 2.0
}

