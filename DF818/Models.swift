//
//  Models.swift
//  DF818
//

import SwiftUI

// MARK: - Difficulty
enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    
    var id: String { rawValue }
    
    var levelCount: Int {
        switch self {
        case .easy: return 4
        case .normal: return 3
        case .hard: return 3
        }
    }
    
    var baseSpeed: Double {
        switch self {
        case .easy: return 1.5
        case .normal: return 2.2
        case .hard: return 3.0
        }
    }
    
    var obstacleMultiplier: Double {
        switch self {
        case .easy: return 0.7
        case .normal: return 1.0
        case .hard: return 1.4
        }
    }
    
    var runesPerLevel: Int {
        switch self {
        case .easy: return 5
        case .normal: return 8
        case .hard: return 12
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "wind"
        case .normal: return "cloud.bolt"
        case .hard: return "tornado"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green.opacity(0.8)
        case .normal: return .goldGlow
        case .hard: return .red.opacity(0.8)
        }
    }
}

// MARK: - Game Level
struct GameLevel: Identifiable, Codable, Equatable {
    let id: String
    let difficulty: Difficulty
    let levelNumber: Int
    let requiredRunes: Int
    
    var displayName: String {
        "Stage \(globalLevelNumber)"
    }
    
    var globalLevelNumber: Int {
        switch difficulty {
        case .easy:
            return levelNumber
        case .normal:
            return Difficulty.easy.levelCount + levelNumber
        case .hard:
            return Difficulty.easy.levelCount + Difficulty.normal.levelCount + levelNumber
        }
    }
    
    // Obstacle patterns for this level
    var obstaclePatterns: [ObstaclePattern] {
        var patterns: [ObstaclePattern] = [.slidingHorizontal]
        
        if globalLevelNumber >= 2 {
            patterns.append(.stationary)
        }
        if globalLevelNumber >= 3 {
            patterns.append(.zigzag)
        }
        if globalLevelNumber >= 5 {
            patterns.append(.rotating)
        }
        if globalLevelNumber >= 7 {
            patterns.append(.disappearing)
        }
        if globalLevelNumber >= 9 {
            patterns.append(.converging)
        }
        
        return patterns
    }
    
    var corridorLength: CGFloat {
        CGFloat(800 + (globalLevelNumber * 100))
    }
    
    var obstacleCount: Int {
        4 + globalLevelNumber
    }
    
    static func == (lhs: GameLevel, rhs: GameLevel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Obstacle Pattern
enum ObstaclePattern: String, CaseIterable, Codable {
    case slidingHorizontal
    case stationary
    case zigzag
    case rotating
    case disappearing
    case converging
}

// MARK: - Obstacle
struct Obstacle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGSize
    var pattern: ObstaclePattern
    var speed: Double
    var rotation: Double = 0
    var isVisible: Bool = true
    var initialX: CGFloat = 0
    var movingRight: Bool = true
}

// MARK: - Collectible (Rune)
struct Collectible: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isCollected: Bool = false
    var glowPhase: Double = 0
}

// MARK: - Player Progress
struct PlayerProgress: Codable {
    var completedLevels: Set<String> = []
    var totalRunesCollected: Int = 0
    var totalAttempts: Int = 0
    var levelAttempts: [String: Int] = [:]
    var levelBestRunes: [String: Int] = [:]
    var hasSeenOnboarding: Bool = false
    
    func isLevelUnlocked(_ level: GameLevel) -> Bool {
        if level.globalLevelNumber == 1 {
            return true
        }
        return totalRunesCollected >= level.requiredRunes
    }
    
    func isLevelCompleted(_ level: GameLevel) -> Bool {
        completedLevels.contains(level.id)
    }
    
    mutating func completeLevel(_ level: GameLevel, runesCollected: Int) {
        let wasCompleted = completedLevels.contains(level.id)
        completedLevels.insert(level.id)
        
        // Only add runes on first completion
        if !wasCompleted {
            totalRunesCollected += runesCollected
        }
        
        // Always track best score
        if let current = levelBestRunes[level.id] {
            let newBest = max(current, runesCollected)
            // Add difference if new record
            if wasCompleted && newBest > current {
                totalRunesCollected += (newBest - current)
            }
            levelBestRunes[level.id] = newBest
        } else {
            levelBestRunes[level.id] = runesCollected
        }
    }
    
    mutating func recordAttempt(for level: GameLevel) {
        totalAttempts += 1
        levelAttempts[level.id, default: 0] += 1
    }
}

// MARK: - Game State
enum GameState: Equatable {
    case idle
    case playing
    case paused
    case won(runesCollected: Int)
    case lost
}

// MARK: - Level Generator
struct LevelGenerator {
    static func generateAllLevels() -> [GameLevel] {
        var levels: [GameLevel] = []
        var runeRequirement = 0
        
        for difficulty in Difficulty.allCases {
            for num in 1...difficulty.levelCount {
                let level = GameLevel(
                    id: "\(difficulty.rawValue)-\(num)",
                    difficulty: difficulty,
                    levelNumber: num,
                    requiredRunes: runeRequirement
                )
                levels.append(level)
                runeRequirement += difficulty.runesPerLevel - 2
            }
        }
        
        return levels
    }
}

// MARK: - Onboarding Page
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let animation: OnboardingAnimation
}

enum OnboardingAnimation {
    case sphere
    case obstacles
    case runes
    case progression
}

let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        icon: "circle.hexagongrid.fill",
        title: "Navigate the Storm",
        description: "Guide your energy sphere through the corridor. Swipe left and right to avoid obstacles.",
        animation: .sphere
    ),
    OnboardingPage(
        icon: "bolt.shield.fill",
        title: "Face the Challenges",
        description: "Obstacles move, rotate, and appear in patterns. Learn their timing to survive.",
        animation: .obstacles
    ),
    OnboardingPage(
        icon: "sparkles",
        title: "Collect Ancient Runes",
        description: "Gather glowing runes as you progress. They unlock new stages and track your journey.",
        animation: .runes
    ),
    OnboardingPage(
        icon: "arrow.up.circle.fill",
        title: "Master the Corridor",
        description: "Three difficulty modes await. Each stage grows more complex. How far can you go?",
        animation: .progression
    )
]

