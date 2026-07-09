import SwiftUI

/// The post-match results screen showing the winner and final leaderboard.
///
/// Reads from `MatchManager.matchResult` for live data instead of hardcoded values.
struct Results: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop (assuming it overlays the island)
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Main Paper Container
                VStack(spacing: 30) {
                    // Winner Title
                    Text("\(winnerName) WINS!")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeDarkTeal)
                        // Simple outline effect for text
                        .shadow(color: .white, radius: 1, x: 2, y: 2)
                        .shadow(color: .white, radius: 1, x: -2, y: -2)
                        .shadow(color: .white, radius: 1, x: 2, y: -2)
                        .shadow(color: .white, radius: 1, x: -2, y: 2)
                        .padding(.top, 20)
                    
                    // Podium
                    HStack(alignment: .bottom, spacing: 10) {
                        // 2nd Place
                        if leaderboard.count > 1 {
                            podiumColumn(place: 2, score: leaderboard[1])
                        } else {
                            Color.clear.frame(width: 80, height: 120)
                        }
                        
                        // 1st Place
                        if leaderboard.count > 0 {
                            podiumColumn(place: 1, score: leaderboard[0])
                        } else {
                            Color.clear.frame(width: 90, height: 160)
                        }
                        
                        // 3rd Place
                        if leaderboard.count > 2 {
                            podiumColumn(place: 3, score: leaderboard[2])
                        } else {
                            Color.clear.frame(width: 80, height: 90)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 4th and 5th
                    VStack(spacing: 8) {
                        if leaderboard.count > 3 {
                            runnerUpRow(place: 4, score: leaderboard[3])
                        }
                        if leaderboard.count > 4 {
                            runnerUpRow(place: 5, score: leaderboard[4])
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .padding(20)
                .background(Color.themePaper)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 6)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Back to Home Button
                Button(action: {
                    matchManager.gameState.reset()
                    matchManager.matchResult = nil
                    appState.returnToHome()
                }) {
                    Text("Back to Home")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.themeDarkTeal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func podiumColumn(place: Int, score: PlayerScore) -> some View {
        let height: CGFloat = place == 1 ? 160 : (place == 2 ? 120 : 90)
        let width: CGFloat = place == 1 ? 100 : 85
        let medalColor: Color = place == 1 ? Color(hex: "E6A31E") : (place == 2 ? Color(hex: "E3E3E3") : Color(hex: "CD7F32"))
        let ribbonColor = Color(hex: "A31E1E")
        
        VStack(spacing: -10) {
            // Medal
            VStack(spacing: 0) {
                // Circle medal
                Circle()
                    .fill(medalColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("\(place)")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(place == 2 ? Color.themeOrange : .white)
                    )
                    .zIndex(1)
                
                // Ribbon ends (mocked as simple rectangles)
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(ribbonColor)
                        .frame(width: 14, height: 24)
                    Rectangle()
                        .fill(ribbonColor)
                        .frame(width: 14, height: 24)
                }
                .zIndex(0)
            }
            .padding(.bottom, 15)
            
            // Column
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.themeDarkTeal)
                    .frame(width: width, height: height)
                
                Text(score.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .lineLimit(1)
            }
        }
    }
    
    private func runnerUpRow(place: Int, score: PlayerScore) -> some View {
        HStack(spacing: 12) {
            Text("\(place)\(ordinal(place))")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "A31E1E"))
            
            Text(score.displayName)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeOrange)
        }
    }
    
    private func ordinal(_ n: Int) -> String {
        switch n {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
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
}

#Preview {
    Results()
        .environmentObject(AppState())
        .environmentObject(MatchManager())
}
