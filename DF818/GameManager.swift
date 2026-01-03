//
//  GameManager.swift
//  DF818
//

import SwiftUI
import Combine

// MARK: - Game Manager
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var progress: PlayerProgress {
        didSet {
            saveProgress()
        }
    }
    
    @Published var allLevels: [GameLevel]
    
    private let progressKey = "playerProgress"
    
    private init() {
        self.allLevels = LevelGenerator.generateAllLevels()
        
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(PlayerProgress.self, from: data) {
            self.progress = decoded
        } else {
            self.progress = PlayerProgress()
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }
    
    func resetProgress() {
        progress = PlayerProgress()
        progress.hasSeenOnboarding = true // Keep onboarding seen after reset
    }
    
    func completeOnboarding() {
        progress.hasSeenOnboarding = true
    }
    
    func getLevels(for difficulty: Difficulty) -> [GameLevel] {
        allLevels.filter { $0.difficulty == difficulty }
    }
    
    func getNextUnlockedLevel() -> GameLevel? {
        for level in allLevels {
            if progress.isLevelUnlocked(level) && !progress.isLevelCompleted(level) {
                return level
            }
        }
        // All completed, return first level
        return allLevels.first
    }
    
    func completeLevel(_ level: GameLevel, runesCollected: Int) {
        progress.completeLevel(level, runesCollected: runesCollected)
    }
    
    func recordAttempt(for level: GameLevel) {
        progress.recordAttempt(for: level)
    }
    
    // Stats
    var completedLevelsCount: Int {
        progress.completedLevels.count
    }
    
    var totalLevelsCount: Int {
        allLevels.count
    }
    
    var totalRunes: Int {
        progress.totalRunesCollected
    }
    
    var totalAttempts: Int {
        progress.totalAttempts
    }
}

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var selectedLevel: GameLevel?
    @Published var showOnboarding: Bool = false
    
    func navigateTo(_ screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }
    
    func startLevel(_ level: GameLevel) {
        selectedLevel = level
        navigateTo(.game)
    }
    
    func returnHome() {
        selectedLevel = nil
        navigateTo(.home)
    }
}

enum AppScreen {
    case home
    case levels
    case game
    case settings
}


