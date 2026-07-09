import SwiftUI

/// The heads-up display shown during gameplay.
struct HUD: View {
    @EnvironmentObject var matchManager: MatchManager
    @State private var isLeaderboardExpanded = false
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Top Left: Leaderboard Dropdown
                leaderboardPanel
                
                Spacer()
                
                // Top Right: Live Timer
                timerDisplay
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            
            Spacer()
            
            // Armageddon Phase banner
            if matchManager.gameState.isArmageddonActive {
                armageddonBanner
            }
            
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
            
            // Bottom: Power-up Inventory Bar (1 slot)
            inventoryBar
        }
        .animation(.easeInOut(duration: 0.3), value: matchManager.powerUpFeedback)
        .animation(.easeInOut(duration: 0.3), value: matchManager.gameState.isArmageddonActive)
    }
    
    // MARK: - Leaderboard Panel
    
    private var leaderboardPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isLeaderboardExpanded.toggle()
                }
            } label: {
                VStack(spacing: 4) {
                    Text("Area Conquer")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "8A5C1E")) // Brown text
                    Image(systemName: isLeaderboardExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "8A5C1E"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.themePaper)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 4)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            
            if isLeaderboardExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if matchManager.leaderboard.isEmpty {
                        Text("No players")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "8A5C1E").opacity(0.6))
                    } else {
                        ForEach(Array(matchManager.leaderboard.enumerated()), id: \.element.playerID) { index, score in
                            HStack {
                                Text(score.displayName)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.black)
                                Spacer()
                                Text("\(score.conqueredAreas) area\(score.conqueredAreas == 1 ? "" : "s")")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            if index < matchManager.leaderboard.count - 1 {
                                Divider().background(Color(hex: "8A5C1E").opacity(0.2))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(width: 200)
                .background(Color.themePaper)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 4)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        Text(matchManager.timerSystem.formattedTime)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.themeOrange)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 4)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
    
    // MARK: - Armageddon Banner
    
    private var armageddonBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.red)
            Text("ARMAGEDDON")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.red)
            Image(systemName: "flame.fill")
                .foregroundColor(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.15))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
        .transition(.scale.combined(with: .opacity))
        .padding(.bottom, 4)
    }
    
    // MARK: - Inventory Bar (1 slot)
    
    private var inventoryBar: some View {
        HStack(spacing: 16) {
            if let player = matchManager.gameState.localPlayer {
                if let powerUp = player.inventory.first {
                    // Filled inventory slot
                    InventoryButton(type: powerUp) {
                        matchManager.startAreaPicker(for: powerUp)
                    }
                } else {
                    // Empty inventory slot
                    emptySlot
                }
            } else {
                emptySlot
            }
        }
        .padding(.bottom, 30)
    }
    
    /// An empty inventory slot placeholder.
    private var emptySlot: some View {
        Circle()
            .fill(Color.themePaper)
            .frame(width: 80, height: 80)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

/// A tappable circular button representing a collected power-up in the inventory.
struct InventoryButton: View {
    let type: PowerUpType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.themePaper)
                .frame(width: 80, height: 80)
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                        
                        Circle()
                            .fill(Color(hex: "3FA9CD")) // Mock wave button color
                            .padding(8)
                        
                        Image(systemName: type.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                )
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
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
        Color.black.edgesIgnoringSafeArea(.all)
        HUD()
            .environmentObject(MatchManager())
    }
}
