import SwiftUI

/// The main gameplay screen shown during an active match.
///
/// Displays the AR camera feed (or placeholder island view) with the HUD overlay.
/// When a player taps a pinpoint and a quiz starts, the `QuestionView` is overlaid
/// on top of this screen.
struct GameScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        ZStack {
            // Background / 3D Model
            Color.themeCream.edgesIgnoringSafeArea(.all)
            
            Island3DView()
                .edgesIgnoringSafeArea(.all)
            
            // Map Pins Overlay (Mockup pins — these will be replaced by AR pinpoints in production)
            ZStack {
                MapPin(iconName: "mappin.circle.fill", areaIndex: 0)
                    .offset(x: -80, y: 150)
                    .onTapGesture { matchManager.handlePinpointTap(areaIndex: 0) }
                
                MapPin(iconName: "mappin.circle.fill", areaIndex: 1)
                    .offset(x: 10, y: -50)
                    .onTapGesture { matchManager.handlePinpointTap(areaIndex: 1) }
                
                MapPin(iconName: "mappin.circle.fill", areaIndex: 2)
                    .offset(x: 120, y: -20)
                    .onTapGesture { matchManager.handlePinpointTap(areaIndex: 2) }
                
                MapPin(iconName: "mappin.circle.fill", areaIndex: 3)
                    .offset(x: 80, y: 100)
                    .onTapGesture { matchManager.handlePinpointTap(areaIndex: 3) }
                
                MapPin(iconName: "mappin.circle.fill", areaIndex: 4)
                    .offset(x: -50, y: 30)
                    .onTapGesture { matchManager.handlePinpointTap(areaIndex: 4) }
                
                MapPin(iconName: "mappin.circle.fill", areaIndex: 5)
                    .offset(x: 30, y: -130)
                    .onTapGesture { matchManager.handlePinpointTap(areaIndex: 5) }
            }
            
            // HUD Overlay
            HUD()
            
            // Quiz Overlay (shown when a quiz is active)
            if matchManager.isQuizActive {
                QuestionView(quizManager: matchManager.quizManager) { completionTime in
                    matchManager.handleQuizCompletion(time: completionTime)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: matchManager.isQuizActive)
        .onAppear {
            // Start a single-player match for testing if no match is active yet
            if !matchManager.gameState.isMatchActive && !matchManager.gameState.isMatchFinished {
                matchManager.startSinglePlayerMatch(playerName: appState.playerName.isEmpty ? "Player" : appState.playerName)
            }
        }
        .onChange(of: matchManager.gameState.isMatchFinished) { _, isFinished in
            if isFinished {
                appState.navigate(to: .results)
            }
        }
    }
}

/// A tappable map pin representing an area on the island.
struct MapPin: View {
    let iconName: String
    let areaIndex: Int
    @EnvironmentObject var matchManager: MatchManager
    
    /// Color based on ownership state.
    private var pinColor: Color {
        guard areaIndex < matchManager.gameState.areas.count else {
            return Color.themeDarkTeal
        }
        let area = matchManager.gameState.areas[areaIndex]
        
        if area.isLocked {
            return .gray
        } else if area.isConquered {
            return Color.themeOrange
        } else {
            return Color.themeDarkTeal
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(pinColor)
                .background(Circle().fill(Color.white).frame(width: 24, height: 24))
                .shadow(radius: 3, y: 3)
            
            // Show area topic label
            if areaIndex < GameConstants.areaTopics.count {
                Text(GameConstants.areaTopics[areaIndex])
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(pinColor.opacity(0.8))
                    .cornerRadius(4)
            }
        }
    }
}

#Preview {
    GameScreen()
        .environmentObject(AppState())
        .environmentObject(MatchManager())
}
