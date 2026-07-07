import SwiftUI

/// Area selection overlay displayed when a player activates a power-up.
///
/// Shows all 6 areas as selectable buttons. Some areas may be disabled
/// depending on the power-up type (e.g., Pocket Watch disables unconquered areas).
/// The player taps an area to confirm activation, or cancels.
struct AreaPicker: View {
    @EnvironmentObject var matchManager: MatchManager
    
    /// The power-up type being activated (determines which areas are valid targets).
    let powerUpType: PowerUpType
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    matchManager.cancelAreaPicker()
                }
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: powerUpType.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(iconColor)
                    
                    Text("Use \(powerUpType.displayName)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Select a target area")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Area grid (2×3)
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        areaButton(index: 0)
                        areaButton(index: 1)
                    }
                    HStack(spacing: 12) {
                        areaButton(index: 2)
                        areaButton(index: 3)
                    }
                    HStack(spacing: 12) {
                        areaButton(index: 4)
                        areaButton(index: 5)
                    }
                }
                
                // Cancel button
                Button {
                    matchManager.cancelAreaPicker()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color.themeDarkTeal)
            .cornerRadius(16)
            .padding(.horizontal, 30)
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        }
    }
    
    // MARK: - Area Button
    
    /// A button representing one area as a potential target.
    private func areaButton(index: Int) -> some View {
        let isValid = isValidTarget(index: index)
        let area = matchManager.gameState.areas[safe: index]
        
        return Button {
            matchManager.handlePowerUpActivation(targetArea: index)
        } label: {
            VStack(spacing: 4) {
                Text(GameConstants.areaTopics[safe: index] ?? "Area \(index)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(isValid ? .white : .white.opacity(0.3))
                
                // Status line
                HStack(spacing: 4) {
                    if let area, area.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Locked")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    } else if let area, area.isConquered {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10))
                        let ownerName = area.ownerID.flatMap { matchManager.gameState.player(byID: $0)?.displayName } ?? "?"
                        Text(ownerName)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    } else {
                        Text("Unconquered")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundColor(isValid ? .white.opacity(0.7) : .white.opacity(0.2))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isValid ? iconColor.opacity(0.3) : Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isValid ? iconColor.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(!isValid)
    }
    
    // MARK: - Helpers
    
    /// Whether the given area is a valid target for this power-up type.
    private func isValidTarget(index: Int) -> Bool {
        let reason = PowerUpManager.validateActivation(
            type: powerUpType,
            playerID: matchManager.gameState.localPlayerID,
            targetArea: index,
            gameState: matchManager.gameState
        )
        return reason == nil
    }
    
    /// Color associated with the current power-up type.
    private var iconColor: Color {
        switch powerUpType {
        case .earthquake: return .orange
        case .tsunami: return .blue
        case .pocketWatch: return .purple
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    /// Safe subscript that returns nil for out-of-bounds indices.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    AreaPicker(powerUpType: .earthquake)
        .environmentObject(MatchManager())
}
