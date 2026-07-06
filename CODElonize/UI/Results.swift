import SwiftUI

/// The post-match results screen showing the winner and final leaderboard.
///
/// Reads from `MatchManager.matchResult` for live data instead of hardcoded values.
struct Results: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        ZStack {
            Color.themeTeal.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Winner banner
                Text("\(winnerName) WINS!")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 3)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                
                // Leaderboard list
                VStack(spacing: 0) {
                    ForEach(Array(leaderboard.enumerated()), id: \.element.playerID) { index, score in
                        HStack {
                            Text(score.displayName)
                                .font(.system(size: 24, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(score.conqueredAreas) area")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text(formatTime(score.totalTime))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 16)
                        
                        if index < leaderboard.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 60)
                
                Spacer()
                
                // Bottom Buttons
                VStack(spacing: 24) {
                    PrimaryButton(title: "Play again") {
                        // Reset match and go back to lobby
                        matchManager.gameState.reset()
                        matchManager.matchResult = nil
                        appState.navigate(to: .lobby)
                    }
                    
                    Button(action: {
                        matchManager.gameState.reset()
                        matchManager.matchResult = nil
                        appState.returnToHome()
                    }) {
                        Text("Back to home")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Data
    
    /// The winner's display name from match result, or fallback.
    private var winnerName: String {
        matchManager.matchResult?.winner?.displayName.uppercased() ?? "NO ONE"
    }
    
    /// The sorted leaderboard from match result.
    private var leaderboard: [PlayerScore] {
        matchManager.matchResult?.leaderboard ?? []
    }
    
    /// Formats a time interval as "Xs" for display.
    private func formatTime(_ time: TimeInterval) -> String {
        if time == 0 { return "" }
        return String(format: "%.1fs total", time)
    }
}

#Preview {
    Results()
        .environmentObject(AppState())
        .environmentObject(MatchManager())
}
