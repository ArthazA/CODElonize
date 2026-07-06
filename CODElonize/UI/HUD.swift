import SwiftUI

/// The heads-up display shown during gameplay.
///
/// Displays the live leaderboard (top-left), match countdown timer (top-right),
/// and the power-up action bar (bottom). All data is driven by `MatchManager`.
struct HUD: View {
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Top Left: Leaderboard
                leaderboardPanel
                
                Spacer()
                
                // Top Right: Timer
                timerDisplay
            }
            
            Spacer()
            
            // Bottom Action Bar (power-ups — Phase 7 placeholder)
            HStack(spacing: 20) {
                ActionButton(iconName: "drop.fill", color: .blue)
                ActionButton(iconName: "house.fill", color: .red)
                ActionButton(iconName: "tree.fill", color: .green)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(Color.themeDarkTeal.opacity(0.9))
            .cornerRadius(24)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Leaderboard Panel
    
    private var leaderboardPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Area Conquer")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeOrange)
                .padding(.bottom, 4)
            
            if matchManager.leaderboard.isEmpty {
                Text("No players")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                ForEach(Array(matchManager.leaderboard.enumerated()), id: \.element.playerID) { index, score in
                    HStack {
                        Text(score.displayName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(score.conqueredAreas) area")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    if index < matchManager.leaderboard.count - 1 {
                        Divider().background(Color.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 150)
        .background(Color.themeDarkTeal.opacity(0.9))
        .cornerRadius(12, corners: [.bottomRight])
        .edgesIgnoringSafeArea(.top)
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        Text(matchManager.timerSystem.formattedTime)
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .foregroundColor(timerColor)
            .monospacedDigit()
            .padding(.top, 50)
            .padding(.trailing, 20)
            // Outline effect using shadows
            .shadow(color: Color.themeOrange, radius: 1, x: 2, y: 2)
            .shadow(color: Color.themeOrange, radius: 1, x: -2, y: -2)
            .shadow(color: Color.themeOrange, radius: 1, x: 2, y: -2)
            .shadow(color: Color.themeOrange, radius: 1, x: -2, y: 2)
    }
    
    /// Timer text color — turns red when under 60 seconds.
    private var timerColor: Color {
        matchManager.timerSystem.remainingTime <= 60 ? .red : .white
    }
}

// Helper view for the circular action buttons
struct ActionButton: View {
    let iconName: String
    let color: Color
    
    var body: some View {
        Circle()
            .fill(Color.themeOrange)
            .frame(width: 70, height: 70)
            .overlay(
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                    
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(color)
                }
            )
            .shadow(radius: 4)
    }
}


#Preview {
    ZStack {
        Color.black
        HUD()
            .environmentObject(MatchManager())
    }
}
