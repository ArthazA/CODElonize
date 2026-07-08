import SwiftUI

/// The heads-up display shown during gameplay.
///
/// Displays the live leaderboard (top-left), match countdown timer (top-right),
/// power-up inventory bar (bottom), and feedback toast.
/// All data is driven by `MatchManager`.
struct HUD: View {
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Top Left: Leaderboard
                leaderboardPanel
                
                Spacer()
                
                // Top Right: Timer
                Text("05:00")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                    // Simple outline effect using shadows
                    .shadow(color: Color.themeOrange, radius: 1, x: 2, y: 2)
                    .shadow(color: Color.themeOrange, radius: 1, x: -2, y: -2)
                    .shadow(color: Color.themeOrange, radius: 1, x: 2, y: -2)
                    .shadow(color: Color.themeOrange, radius: 1, x: -2, y: 2)
            }
            
            Spacer()
            
            // Power-up feedback toast
            if let feedback = matchManager.powerUpFeedback {
                Text(feedback)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.themeDarkTeal.opacity(0.95))
                    .cornerRadius(20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
            
            // Bottom: Power-up Inventory Bar
            inventoryBar
        }
        .animation(.easeInOut(duration: 0.3), value: matchManager.powerUpFeedback)
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
    
    // MARK: - Inventory Bar
    
    private var inventoryBar: some View {
        HStack(spacing: 16) {
            if let player = matchManager.gameState.localPlayer, !player.inventory.isEmpty {
                ForEach(Array(player.inventory.enumerated()), id: \.offset) { _, type in
                    InventoryButton(type: type) {
                        matchManager.startAreaPicker(for: type)
                    }
                }
                
                // Fill remaining slots with empty placeholders
                let emptySlots = GameConstants.maxInventorySize - player.inventory.count
                if emptySlots > 0 {
                    ForEach(0..<emptySlots, id: \.self) { _ in
                        emptySlot
                    }
                }
            } else {
                // All empty slots
                ForEach(0..<GameConstants.maxInventorySize, id: \.self) { _ in
                    emptySlot
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .background(Color.themeDarkTeal.opacity(0.9))
        .cornerRadius(24)
        .padding(.bottom, 30)
    }
    
    /// An empty inventory slot placeholder.
    private var emptySlot: some View {
        Circle()
            .stroke(Color.white.opacity(0.2), lineWidth: 2)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "square.dashed")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.15))
            )
    }
}

/// A tappable circular button representing a collected power-up in the inventory.
struct InventoryButton: View {
    let type: PowerUpType
    let action: () -> Void
    
    /// Color for this power-up type.
    private var typeColor: Color {
        switch type {
        case .earthquake: return .orange
        case .tsunami: return .blue
        case .pocketWatch: return .purple
        }
    }
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(typeColor)
                .frame(width: 60, height: 60)
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                        
                        Image(systemName: type.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 26, height: 26)
                            .foregroundColor(.white)
                    }
                )
                .shadow(color: typeColor.opacity(0.5), radius: 6, y: 3)
        }
    }
}

#Preview {
    let appState = AppState()
    let hostID = UUID()

    appState.playerID = hostID

    appState.lobbyManager.lobby = LobbyModel(
        roomCode: "1234",
        hostID: hostID,
        players: [
            Player(
                id: hostID,
                name: "Adi",
                avatar: "player_1",
                isHost: true,
                isReady: true
            ),
            Player(
                id: UUID(),
                name: "Barra",
                avatar: "player_2",
                isHost: false,
                isReady: true
            )
        ],
        maxPlayers: 5
    )

    return ZStack {
        Color.black
        HUD()
            .environmentObject(MatchManager())
    }
}
