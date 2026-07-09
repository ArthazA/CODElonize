import SwiftUI

/// The main gameplay screen shown during an active match.
///
/// Displays the AR camera feed (or placeholder island view) with the HUD overlay.
/// When a player taps a pinpoint and a quiz starts, the `QuestionView` is overlaid
/// on top of this screen. Spawned power-ups appear as collectible floating icons.
struct GameScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        ZStack {
            ARViewContainer(arSessionManager: appState.arSessionManager)
                .edgesIgnoringSafeArea(.all)
            
            spawnedPowerUpsOverlay
            
            // HUD Overlay
            HUD()
            
            // Quiz Overlay (shown when a quiz is active)
            if matchManager.isQuizActive {
                QuestionView(quizManager: matchManager.quizManager) { completionTime in
                    matchManager.handleQuizCompletion(time: completionTime)
                }
                .transition(.opacity)
            }
            
            // Area Picker Overlay (shown when activating a power-up)
            if matchManager.isAreaPickerActive, let type = matchManager.pendingPowerUpType {
                AreaPicker(powerUpType: type)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: matchManager.isQuizActive)
        .animation(.easeInOut(duration: 0.3), value: matchManager.isAreaPickerActive)
        .onAppear {
            if !appState.arSessionManager.islandPlacement.isPlaced {
                appState.arSessionManager.placeIslandUsingSavedTransformIfAvailable()
            }
            
            if !matchManager.gameState.isMatchActive && !matchManager.gameState.isMatchFinished {
                startMatchFromAvailableData()
            }
        }
        .onChange(of: matchManager.gameState.isMatchFinished) { _, isFinished in
            if isFinished {
                appState.navigate(to: .results)
            }
        }
    }
    
    /// Starts the match using real multiplayer data when available
    /// (`LobbyManager.pendingMatchStart`, populated via the host's broadcast
    /// `StartGameMessage` — README §6.3), otherwise falls back to a local
    /// single-player match for dev/testing (README §5.8/§8.5 — this fallback
    /// is intentionally kept, not removed).
    private func startMatchFromAvailableData() {
        if let matchStart = appState.lobbyManager.pendingMatchStart,
           let lobby = appState.lobbyManager.lobby {
            matchManager.startMatch(
                players: matchStart.players,
                localPlayerID: appState.playerID,
                isHost: appState.isHost,
                startTime: matchStart.startTime,
                questionSeeds: matchStart.questionSeeds
            )
        } else {
            matchManager.startSinglePlayerMatch(
                playerName: appState.playerName.isEmpty ? "Player" : appState.playerName
            )
        }
    }
    
    // MARK: - Spawned Power-ups
    
    /// Displays uncollected power-ups as floating collectible icons on the game screen.
    private var spawnedPowerUpsOverlay: some View {
        ForEach(matchManager.spawnManager.activePowerUps) { powerUp in
            SpawnedPowerUpView(powerUp: powerUp) {
                matchManager.handlePowerUpCollection(spawnID: powerUp.id)
            }
            .offset(spawnOffset(for: powerUp.spawnSlot))
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: matchManager.spawnManager.activePowerUps.count)
    }
    
    /// Maps a spawn slot index to a screen offset for mockup display.
    private func spawnOffset(for slot: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -120, height: -180),
            CGSize(width: 140, height: -100),
            CGSize(width: -140, height: 50),
            CGSize(width: 100, height: 170),
            CGSize(width: -30, height: -20),
        ]
        guard slot < offsets.count else { return .zero }
        return offsets[slot]
    }
}

/// A floating, tappable power-up collectible on the game screen.
struct SpawnedPowerUpView: View {
    let powerUp: SpawnedPowerUp
    let onCollect: () -> Void
    
    @State private var isBouncing = false
    
    /// Color for this power-up type.
    private var typeColor: Color {
        switch powerUp.type {
        case .earthquake: return .orange
        case .tsunami: return .blue
        case .pocketWatch: return .purple
        }
    }
    
    var body: some View {
        Button(action: onCollect) {
            ZStack {
                // Glow circle
                Circle()
                    .fill(typeColor.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .scaleEffect(isBouncing ? 1.2 : 1.0)
                
                // Inner circle
                Circle()
                    .fill(typeColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: powerUp.type.iconName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: typeColor.opacity(0.6), radius: 8, y: 4)
            }
            .offset(y: isBouncing ? -4 : 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isBouncing = true
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

struct PinpointBadge: View {
    let areaIndex: Int
    let fallbackName: String
    @EnvironmentObject var matchManager: MatchManager
    
    private var area: Area? {
        matchManager.gameState.area(byIndex: areaIndex)
    }
    
    /// Nama pemilik area — dicari dari ownerID lewat GameState.player(byID:)
    private var ownerDisplayName: String? {
        guard let area, let ownerID = area.ownerID else { return nil }
        return matchManager.gameState.player(byID: ownerID)?.name
    }
    
    private var badgeColor: Color {
        guard let area else { return Color.themeDarkTeal }
        if area.isLocked { return .gray }
        return area.isConquered ? Color.themeOrange : Color.themeDarkTeal
    }
    
    var body: some View {
        VStack(spacing: 1) {
            if let area, area.isConquered, let ownerName = ownerDisplayName {
                Text(ownerName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                
                // bestTime itu Optional<TimeInterval>, aman di-unwrap karena isConquered == true
                if let time = area.bestTime {
                    Text(String(format: "%.2f secs", time))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
            } else {
                Text(fallbackName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(badgeColor)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white, lineWidth: 1.5))
        .shadow(radius: 3, y: 2)
    }
}

#Preview {
    GameScreen()
        .environmentObject(AppState())
        .environmentObject(MatchManager())
}
