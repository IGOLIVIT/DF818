//
//  LevelsView.swift
//  DF818
//

import SwiftUI

struct LevelsView: View {
    @ObservedObject var navigation: NavigationManager
    @ObservedObject var gameManager: GameManager
    
    @State private var selectedDifficulty: Difficulty = .easy
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ThemeGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Difficulty tabs
                    difficultyTabs
                    
                    // Levels grid
                    levelsScrollView
                    
                    // Back button
                    backButton
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Choose Your Path")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.goldGlow)
                Text("\(gameManager.totalRunes) Runes")
                    .foregroundColor(.goldGlow)
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Difficulty Tabs
    private var difficultyTabs: some View {
        HStack(spacing: 0) {
            ForEach(Difficulty.allCases) { difficulty in
                difficultyTab(difficulty)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    private func difficultyTab(_ difficulty: Difficulty) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDifficulty = difficulty
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 20))
                
                Text(difficulty.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(selectedDifficulty == difficulty ? .deepStormBlue : .mistyLightBlue.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedDifficulty == difficulty ? Color.goldGlow : Color.clear)
            )
        }
    }
    
    // MARK: - Levels Grid
    private var levelsScrollView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(gameManager.getLevels(for: selectedDifficulty)) { level in
                    LevelCell(
                        level: level,
                        isUnlocked: gameManager.progress.isLevelUnlocked(level),
                        isCompleted: gameManager.progress.isLevelCompleted(level),
                        runesRequired: level.requiredRunes,
                        currentRunes: gameManager.totalRunes,
                        bestRunes: gameManager.progress.levelBestRunes[level.id]
                    ) {
                        if gameManager.progress.isLevelUnlocked(level) {
                            navigation.startLevel(level)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        Button(action: {
            navigation.navigateTo(.home)
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.mistyLightBlue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Level Cell
struct LevelCell: View {
    let level: GameLevel
    let isUnlocked: Bool
    let isCompleted: Bool
    let runesRequired: Int
    let currentRunes: Int
    let bestRunes: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Level number
                ZStack {
                    Circle()
                        .fill(isUnlocked ? level.difficulty.color : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else if isUnlocked {
                        Text("\(level.globalLevelNumber)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Level name
                Text(level.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.4))
                
                // Status / requirement
                if isCompleted, let best = bestRunes {
                    HStack(spacing: 4) {
                        Image(systemName: "rhombus.fill")
                            .font(.system(size: 10))
                        Text("\(best)")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.goldGlow)
                } else if !isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("\(runesRequired) needed")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.mistyLightBlue.opacity(0.5))
                } else {
                    Text("Ready")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.mistyLightBlue.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isUnlocked ? 0.08 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isCompleted ? Color.goldGlow.opacity(0.5) :
                                (isUnlocked ? Color.mistyLightBlue.opacity(0.2) : Color.clear),
                                lineWidth: 1
                            )
                    )
            )
        }
        .disabled(!isUnlocked)
    }
}

#Preview {
    LevelsView(navigation: NavigationManager(), gameManager: GameManager.shared)
}


