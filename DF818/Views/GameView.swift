//
//  GameView.swift
//  DF818
//

import SwiftUI

struct GameView: View {
    @ObservedObject var navigation: NavigationManager
    @ObservedObject var gameManager: GameManager
    let level: GameLevel
    
    @StateObject private var engine = GameEngine()
    @State private var showPauseMenu = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ThemeGradients.backgroundGradient
                    .ignoresSafeArea()
                
                // Game content
                VStack(spacing: 0) {
                    // Top HUD
                    gameHUD
                    
                    // Game area
                    gameArea(geometry: geometry)
                }
                
                // Pause overlay
                if showPauseMenu {
                    pauseOverlay
                }
                
                // Win overlay
                if case .won(let runes) = engine.gameState {
                    winOverlay(runesCollected: runes)
                }
                
                // Lose overlay
                if engine.gameState == .lost {
                    loseOverlay
                }
            }
        }
        .onAppear {
            startNewGame()
        }
    }
    
    private func startNewGame() {
        engine.setupLevel(level)
        gameManager.recordAttempt(for: level)
    }
    
    // MARK: - Game HUD
    private var gameHUD: some View {
        HStack {
            // Pause button
            Button(action: {
                engine.pause()
                showPauseMenu = true
            }) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.mistyLightBlue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            
            Spacer()
            
            // Level info
            VStack(spacing: 2) {
                Text(level.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(level.difficulty.rawValue)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(level.difficulty.color)
            }
            
            Spacer()
            
            // Runes collected
            HStack(spacing: 6) {
                Image(systemName: "rhombus.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.goldGlow)
                
                Text("\(engine.runesCollected)/\(level.difficulty.runesPerLevel)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.1)))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Game Area
    private func gameArea(geometry: GeometryProxy) -> some View {
        let corridorWidth: CGFloat = min(geometry.size.width - 48, 320)
        let corridorHeight: CGFloat = geometry.size.height - 150
        
        return ZStack {
            // Corridor background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.deepStormBlue.opacity(0.8),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.mistyLightBlue.opacity(0.3), lineWidth: 2)
                )
                .frame(width: corridorWidth, height: corridorHeight)
            
            // Grid lines for depth effect
            corridorGrid(width: corridorWidth, height: corridorHeight)
            
            // Game elements
            ZStack {
                // Collectibles (Runes)
                ForEach(engine.collectibles) { collectible in
                    if !collectible.isCollected {
                        RuneView(collectible: collectible, corridorWidth: corridorWidth, corridorHeight: corridorHeight)
                    }
                }
                
                // Obstacles
                ForEach(engine.obstacles) { obstacle in
                    if obstacle.isVisible {
                        ObstacleView(obstacle: obstacle, corridorWidth: corridorWidth, corridorHeight: corridorHeight)
                    }
                }
                
                // Player
                PlayerSphereView(
                    position: engine.playerPosition,
                    corridorWidth: corridorWidth,
                    corridorHeight: corridorHeight
                )
            }
            .frame(width: corridorWidth, height: corridorHeight)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Calculate normalized X based on corridor position
                    let corridorLeft = (geometry.size.width - corridorWidth) / 2
                    let relativeX = value.location.x - corridorLeft
                    let normalizedX = relativeX / corridorWidth
                    
                    // Calculate normalized Y based on game area
                    let gameAreaTop: CGFloat = 0
                    let gameAreaHeight = corridorHeight
                    let relativeY = value.location.y - gameAreaTop
                    let normalizedY = 0.2 + (relativeY / gameAreaHeight) * 0.7
                    
                    engine.movePlayer(toX: normalizedX, toY: normalizedY)
                }
        )
        .onAppear {
            // Start game only if not already playing (prevents double-start)
            if engine.gameState == .idle {
                engine.startGame(corridorWidth: corridorWidth, corridorHeight: corridorHeight)
            }
        }
    }
    
    private func corridorGrid(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Vertical lines
            ForEach(0..<5, id: \.self) { i in
                let x = (CGFloat(i) / 4.0 - 0.5) * width
                Rectangle()
                    .fill(Color.mistyLightBlue.opacity(0.05))
                    .frame(width: 1, height: height)
                    .offset(x: x)
            }
            
            // Horizontal lines (more dense at bottom for perspective)
            ForEach(0..<10, id: \.self) { i in
                let progress = CGFloat(i) / 9.0
                let y = (progress - 0.5) * height
                Rectangle()
                    .fill(Color.mistyLightBlue.opacity(0.03 + progress * 0.05))
                    .frame(width: width, height: 1)
                    .offset(y: y)
            }
        }
    }
    
    // MARK: - Pause Overlay
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Paused")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Button(action: {
                        showPauseMenu = false
                        engine.resume()
                    }) {
                        Text("Resume")
                            .frame(width: 180)
                    }
                    .buttonStyle(GoldButtonStyle())
                    
                    Button(action: {
                        showPauseMenu = false
                        engine.restart(for: level)
                        gameManager.recordAttempt(for: level)
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restart")
                        }
                        .frame(width: 180)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: {
                        navigation.returnHome()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Exit")
                        }
                        .frame(width: 180)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.deepStormBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.mistyLightBlue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Win Overlay
    private func winOverlay(runesCollected: Int) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.goldGlow.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.goldGlow)
                }
                
                Text("Stage Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Runes earned
                HStack(spacing: 8) {
                    Image(systemName: "rhombus.fill")
                        .foregroundColor(.goldGlow)
                    Text("+\(runesCollected) Runes")
                        .foregroundColor(.goldGlow)
                }
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                
                VStack(spacing: 16) {
                    Button(action: {
                        // Save progress
                        gameManager.completeLevel(level, runesCollected: runesCollected)
                        
                        // Find next level
                        if let nextLevel = findNextLevel() {
                            engine.restart(for: nextLevel)
                            navigation.selectedLevel = nextLevel
                            gameManager.recordAttempt(for: nextLevel)
                        } else {
                            navigation.navigateTo(.levels)
                        }
                    }) {
                        Text("Continue")
                            .frame(width: 180)
                    }
                    .buttonStyle(GoldButtonStyle())
                    
                    Button(action: {
                        gameManager.completeLevel(level, runesCollected: runesCollected)
                        navigation.navigateTo(.levels)
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Levels")
                        }
                        .frame(width: 180)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.deepStormBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.goldGlow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Lose Overlay
    private var loseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Fail icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red.opacity(0.8))
                }
                
                Text("Storm Claimed You")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("The corridor demands precision")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.mistyLightBlue.opacity(0.7))
                
                VStack(spacing: 16) {
                    Button(action: {
                        engine.restart(for: level)
                        gameManager.recordAttempt(for: level)
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Try Again")
                        }
                        .frame(width: 180)
                    }
                    .buttonStyle(GoldButtonStyle())
                    
                    Button(action: {
                        navigation.navigateTo(.levels)
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Levels")
                        }
                        .frame(width: 180)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.deepStormBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func findNextLevel() -> GameLevel? {
        guard let currentIndex = gameManager.allLevels.firstIndex(where: { $0.id == level.id }),
              currentIndex + 1 < gameManager.allLevels.count else {
            return nil
        }
        let nextLevel = gameManager.allLevels[currentIndex + 1]
        // Check if next level would be unlocked after completing current
        let futureRunes = gameManager.totalRunes + engine.runesCollected
        return futureRunes >= nextLevel.requiredRunes ? nextLevel : nil
    }
}

// MARK: - Player Sphere View
struct PlayerSphereView: View {
    let position: CGPoint
    let corridorWidth: CGFloat
    let corridorHeight: CGFloat
    
    @State private var glowPhase: Double = 0
    
    var body: some View {
        // X position calculation
        let actualX = (position.x - 0.5) * (corridorWidth - 50)
        
        // Y position: 0.2 = top of play area, 0.9 = bottom
        let playAreaTop: CGFloat = 50
        let playAreaBottom: CGFloat = corridorHeight - 50
        let actualY = playAreaTop + (position.y - 0.2) / 0.7 * (playAreaBottom - playAreaTop)
        
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.goldGlow.opacity(0.4 + glowPhase * 0.2), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
            
            // Inner sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.goldGlow],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .shadow(color: Color.goldGlow, radius: 10, x: 0, y: 0)
        }
        .position(x: corridorWidth / 2 + actualX, y: actualY)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }
}

// MARK: - Obstacle View
struct ObstacleView: View {
    let obstacle: Obstacle
    let corridorWidth: CGFloat
    let corridorHeight: CGFloat
    
    var body: some View {
        let actualX = obstacle.position.x
        let actualY = obstacle.position.y
        
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: obstacle.size.width, height: obstacle.size.height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.red.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color.red.opacity(0.5), radius: 8, x: 0, y: 0)
            .rotationEffect(.degrees(obstacle.rotation))
            .position(x: actualX, y: actualY)
            .opacity(obstacle.isVisible ? 1 : 0)
    }
}

// MARK: - Rune View
struct RuneView: View {
    let collectible: Collectible
    let corridorWidth: CGFloat
    let corridorHeight: CGFloat
    
    @State private var glowPhase: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        let actualX = collectible.position.x
        let actualY = collectible.position.y
        
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.goldGlow.opacity(0.5 + glowPhase * 0.3), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
            
            // Rune shape
            Image(systemName: "rhombus.fill")
                .font(.system(size: 20))
                .foregroundColor(.goldGlow)
                .shadow(color: Color.goldGlow, radius: 5, x: 0, y: 0)
                .rotationEffect(.degrees(rotation))
        }
        .position(x: actualX, y: actualY)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    GameView(
        navigation: NavigationManager(),
        gameManager: GameManager.shared,
        level: GameLevel(id: "Easy-1", difficulty: .easy, levelNumber: 1, requiredRunes: 0)
    )
}

