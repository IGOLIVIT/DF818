//
//  GameEngine.swift
//  DF818
//

import SwiftUI
import Combine

class GameEngine: ObservableObject {
    @Published var gameState: GameState = .idle
    @Published var playerPosition: CGPoint = CGPoint(x: 0.5, y: 0.9)
    @Published var obstacles: [Obstacle] = []
    @Published var collectibles: [Collectible] = []
    @Published var runesCollected: Int = 0
    @Published var scrollOffset: CGFloat = 0
    
    private var currentLevel: GameLevel?
    private var corridorWidth: CGFloat = 300
    private var corridorHeight: CGFloat = 500
    private var gameTimer: AnyCancellable?
    private var gameTime: Double = 0
    private var targetPlayerX: CGFloat = 0.5
    private var targetPlayerY: CGFloat = 0.8
    
    // MARK: - Setup
    func setupLevel(_ level: GameLevel) {
        currentLevel = level
        gameState = .idle
        runesCollected = 0
        scrollOffset = 0
        gameTime = 0
        playerPosition = CGPoint(x: 0.5, y: 0.8)
        targetPlayerX = 0.5
        targetPlayerY = 0.8
        obstacles = []
        collectibles = []
    }
    
    func startGame(corridorWidth: CGFloat, corridorHeight: CGFloat) {
        guard let level = currentLevel else { return }
        guard gameState == .idle else { return } // Prevent double start
        
        self.corridorWidth = corridorWidth
        self.corridorHeight = corridorHeight
        
        generateObstacles(for: level)
        generateCollectibles(for: level)
        
        gameState = .playing
        startGameLoop()
    }
    
    // MARK: - Game Loop
    private func startGameLoop() {
        gameTimer?.cancel()
        gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.update()
            }
    }
    
    private func update() {
        guard gameState == .playing, let level = currentLevel else { return }
        
        let deltaTime = 1.0 / 60.0
        gameTime += deltaTime
        
        // Smooth player movement
        let smoothing: CGFloat = 0.15
        playerPosition.x += (targetPlayerX - playerPosition.x) * smoothing
        playerPosition.y += (targetPlayerY - playerPosition.y) * smoothing
        
        // Update scroll (move obstacles and collectibles down)
        let speed = level.difficulty.baseSpeed * 100
        scrollOffset += CGFloat(speed * deltaTime)
        
        // Update obstacles
        updateObstacles(deltaTime: deltaTime, level: level)
        
        // Update collectibles
        updateCollectibles()
        
        // Check collisions
        checkCollisions()
        
        // Check win condition
        checkWinCondition()
    }
    
    private func updateObstacles(deltaTime: Double, level: GameLevel) {
        for i in 0..<obstacles.count {
            // Move down with scroll
            obstacles[i].position.y += CGFloat(level.difficulty.baseSpeed * 100 * deltaTime)
            
            // Apply pattern behavior
            switch obstacles[i].pattern {
            case .slidingHorizontal:
                let range = (corridorWidth - obstacles[i].size.width) / 2 - 20
                let centerX = corridorWidth / 2
                
                if obstacles[i].movingRight {
                    obstacles[i].position.x += CGFloat(obstacles[i].speed * deltaTime)
                    if obstacles[i].position.x > centerX + range {
                        obstacles[i].movingRight = false
                    }
                } else {
                    obstacles[i].position.x -= CGFloat(obstacles[i].speed * deltaTime)
                    if obstacles[i].position.x < centerX - range {
                        obstacles[i].movingRight = true
                    }
                }
                
            case .zigzag:
                let amplitude = (corridorWidth - obstacles[i].size.width) / 2 - 30
                let frequency = 0.003
                obstacles[i].position.x = corridorWidth / 2 + CGFloat(sin(Double(obstacles[i].position.y) * frequency)) * amplitude
                
            case .rotating:
                obstacles[i].rotation += obstacles[i].speed * deltaTime * 2
                
            case .disappearing:
                let cycle = sin(gameTime * 2 + Double(obstacles[i].id.hashValue % 10))
                obstacles[i].isVisible = cycle > 0
                
            case .converging:
                let centerX = corridorWidth / 2
                let targetX = centerX
                let convergenceSpeed = obstacles[i].speed * 0.5
                if obstacles[i].position.x < targetX {
                    obstacles[i].position.x += CGFloat(convergenceSpeed * deltaTime)
                } else {
                    obstacles[i].position.x -= CGFloat(convergenceSpeed * deltaTime)
                }
                
            case .stationary:
                break
            }
        }
    }
    
    private func updateCollectibles() {
        guard let level = currentLevel else { return }
        let deltaTime = 1.0 / 60.0
        
        for i in 0..<collectibles.count {
            collectibles[i].position.y += CGFloat(level.difficulty.baseSpeed * 100 * deltaTime)
        }
    }
    
    // MARK: - Collision Detection
    private func checkCollisions() {
        let playerRadius: CGFloat = 18
        // Match PlayerSphereView calculation exactly
        let actualX = (playerPosition.x - 0.5) * (corridorWidth - 50)
        let playerActualX = corridorWidth / 2 + actualX
        // Y position: 0.2 = top of play area, 0.9 = bottom
        let playAreaTop: CGFloat = 50
        let playAreaBottom: CGFloat = corridorHeight - 50
        let playerActualY = playAreaTop + (playerPosition.y - 0.2) / 0.7 * (playAreaBottom - playAreaTop)
        let playerCenter = CGPoint(x: playerActualX, y: playerActualY)
        
        // Check obstacle collisions
        for obstacle in obstacles {
            guard obstacle.isVisible else { continue }
            
            // Simple rect-circle collision
            let closestX = max(obstacle.position.x - obstacle.size.width / 2,
                              min(playerCenter.x, obstacle.position.x + obstacle.size.width / 2))
            let closestY = max(obstacle.position.y - obstacle.size.height / 2,
                              min(playerCenter.y, obstacle.position.y + obstacle.size.height / 2))
            
            let distanceX = playerCenter.x - closestX
            let distanceY = playerCenter.y - closestY
            let distanceSquared = distanceX * distanceX + distanceY * distanceY
            
            if distanceSquared < playerRadius * playerRadius {
                gameOver()
                return
            }
        }
        
        // Check collectible collisions
        for i in 0..<collectibles.count {
            guard !collectibles[i].isCollected else { continue }
            
            let collectibleCenter = collectibles[i].position
            let distanceX = playerCenter.x - collectibleCenter.x
            let distanceY = playerCenter.y - collectibleCenter.y
            let distanceSquared = distanceX * distanceX + distanceY * distanceY
            
            if distanceSquared < (playerRadius + 15) * (playerRadius + 15) {
                collectibles[i].isCollected = true
                runesCollected += 1
            }
        }
    }
    
    private func checkWinCondition() {
        // Win when all obstacles have passed (scrolled below screen)
        let passedObstacles = obstacles.filter { $0.position.y > corridorHeight + 50 }
        
        if passedObstacles.count == obstacles.count && !obstacles.isEmpty {
            win()
        }
    }
    
    // MARK: - Player Control
    func movePlayer(toX normalizedX: CGFloat, toY normalizedY: CGFloat) {
        guard gameState == .playing else { return }
        targetPlayerX = max(0.1, min(0.9, normalizedX))
        // Limit Y movement: 0.2 (top) to 0.9 (bottom)
        targetPlayerY = max(0.2, min(0.9, normalizedY))
    }
    
    // MARK: - Game State
    func pause() {
        guard gameState == .playing else { return }
        gameState = .paused
        gameTimer?.cancel()
    }
    
    func resume() {
        guard gameState == .paused else { return }
        gameState = .playing
        startGameLoop()
    }
    
    func restart(for level: GameLevel) {
        gameTimer?.cancel()
        setupLevel(level)
        startGame(corridorWidth: corridorWidth, corridorHeight: corridorHeight)
    }
    
    private func gameOver() {
        gameState = .lost
        gameTimer?.cancel()
    }
    
    private func win() {
        gameState = .won(runesCollected: runesCollected)
        gameTimer?.cancel()
    }
    
    // MARK: - Level Generation
    private func generateObstacles(for level: GameLevel) {
        obstacles = []
        let patterns = level.obstaclePatterns
        let count = level.obstacleCount
        let spacing = level.corridorLength / CGFloat(count + 1)
        
        for i in 0..<count {
            let pattern = patterns[i % patterns.count]
            let yPosition = -spacing * CGFloat(i + 1)
            
            var width: CGFloat
            var height: CGFloat = 16
            var speed: Double = 80 * level.difficulty.obstacleMultiplier
            
            switch pattern {
            case .stationary:
                width = CGFloat.random(in: 60...120)
            case .slidingHorizontal:
                width = CGFloat.random(in: 50...100)
                speed = Double.random(in: 60...120) * level.difficulty.obstacleMultiplier
            case .zigzag:
                width = CGFloat.random(in: 40...80)
            case .rotating:
                width = CGFloat.random(in: 80...140)
                height = 14
            case .disappearing:
                width = CGFloat.random(in: 100...160)
            case .converging:
                width = CGFloat.random(in: 50...80)
            }
            
            let startX: CGFloat
            if pattern == .converging {
                startX = Bool.random() ? 40 : corridorWidth - 40
            } else {
                // Ensure valid range
                let minX = width/2 + 20
                let maxX = corridorWidth - width/2 - 20
                if minX >= maxX {
                    startX = corridorWidth / 2
                } else {
                    startX = CGFloat.random(in: minX...maxX)
                }
            }
            
            let obstacle = Obstacle(
                position: CGPoint(x: startX, y: yPosition),
                size: CGSize(width: width, height: height),
                pattern: pattern,
                speed: speed,
                initialX: startX,
                movingRight: Bool.random()
            )
            
            obstacles.append(obstacle)
        }
    }
    
    private func generateCollectibles(for level: GameLevel) {
        collectibles = []
        let count = level.difficulty.runesPerLevel
        let spacing = level.corridorLength / CGFloat(count + 2)
        
        for i in 0..<count {
            let yPosition = -spacing * CGFloat(i + 1) - 50
            let minX: CGFloat = 40
            let maxX = max(minX + 1, corridorWidth - 40)
            let xPosition = CGFloat.random(in: minX...maxX)
            
            let collectible = Collectible(
                position: CGPoint(x: xPosition, y: yPosition)
            )
            
            collectibles.append(collectible)
        }
    }
    
    deinit {
        gameTimer?.cancel()
    }
}

