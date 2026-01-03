//
//  ContentView.swift
//  DF818
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigation = NavigationManager()
    @ObservedObject private var gameManager = GameManager.shared
    
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            // Main content based on current screen
            Group {
                switch navigation.currentScreen {
                case .home:
                    HomeView(navigation: navigation, gameManager: gameManager)
                        .transition(.opacity)
                    
                case .levels:
                    LevelsView(navigation: navigation, gameManager: gameManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                    
                case .game:
                    if let level = navigation.selectedLevel {
                        GameView(navigation: navigation, gameManager: gameManager, level: level)
                            .transition(.opacity)
                    }
                    
                case .settings:
                    SettingsView(navigation: navigation, gameManager: gameManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: navigation.currentScreen)
            
            // Onboarding overlay
            if showOnboarding {
                OnboardingView(gameManager: gameManager) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onAppear {
            if !gameManager.progress.hasSeenOnboarding {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
}
