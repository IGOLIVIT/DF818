//
//  SettingsView.swift
//  DF818
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var navigation: NavigationManager
    @ObservedObject var gameManager: GameManager
    
    @State private var showResetAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ThemeGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Stats section
                            statsSection
                            
                            // Progress section
                            progressSection
                            
                            // Reset section
                            resetSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    
                    // Back button
                    backButton
                }
            }
        }
        .alert("Reset Progress", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                gameManager.resetProgress()
            }
        } message: {
            Text("All your progress will be lost. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        Text("Statistics")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 20)
            .padding(.bottom, 24)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statCard(
                    icon: "flag.checkered",
                    value: "\(gameManager.completedLevelsCount)",
                    label: "Stages Cleared",
                    color: .green
                )
                
                statCard(
                    icon: "sparkles",
                    value: "\(gameManager.totalRunes)",
                    label: "Runes Collected",
                    color: .goldGlow
                )
            }
            
            HStack(spacing: 16) {
                statCard(
                    icon: "arrow.counterclockwise",
                    value: "\(gameManager.totalAttempts)",
                    label: "Total Attempts",
                    color: .mistyLightBlue
                )
                
                statCard(
                    icon: "percent",
                    value: completionPercentage,
                    label: "Completion",
                    color: .purple
                )
            }
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.mistyLightBlue.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var completionPercentage: String {
        let total = gameManager.totalLevelsCount
        let completed = gameManager.completedLevelsCount
        guard total > 0 else { return "0%" }
        let percentage = (Double(completed) / Double(total)) * 100
        return "\(Int(percentage))%"
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress by Difficulty")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            ForEach(Difficulty.allCases) { difficulty in
                difficultyProgressRow(difficulty)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func difficultyProgressRow(_ difficulty: Difficulty) -> some View {
        let levels = gameManager.getLevels(for: difficulty)
        let completed = levels.filter { gameManager.progress.isLevelCompleted($0) }.count
        let total = levels.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0
        
        return HStack(spacing: 12) {
            Image(systemName: difficulty.icon)
                .font(.system(size: 18))
                .foregroundColor(difficulty.color)
                .frame(width: 30)
            
            Text(difficulty.rawValue)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(difficulty.color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)
            
            Text("\(completed)/\(total)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.mistyLightBlue.opacity(0.7))
                .frame(width: 40)
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(spacing: 12) {
            Text("Danger Zone")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.red.opacity(0.7))
            
            Button(action: {
                showResetAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Progress")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
        )
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

#Preview {
    SettingsView(navigation: NavigationManager(), gameManager: GameManager.shared)
}


