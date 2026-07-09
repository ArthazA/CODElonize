import SwiftUI

struct AreaPicker: View {
    @EnvironmentObject var matchManager: MatchManager

    let powerUpType: PowerUpType

    var body: some View {
        ZStack {

            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    matchManager.cancelAreaPicker()
                }

            VStack(spacing: 20) {

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

    private func isValidTarget(index: Int) -> Bool {
        let reason = PowerUpManager.validateActivation(
            type: powerUpType,
            playerID: matchManager.gameState.localPlayerID,
            targetArea: index,
            gameState: matchManager.gameState
        )
        return reason == nil
    }

    private var iconColor: Color {
        switch powerUpType {
        case .earthquake: return .orange
        case .tsunami: return .blue
        case .pocketWatch: return .purple
        }
    }
}

extension Array {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    AreaPicker(powerUpType: .earthquake)
        .environmentObject(MatchManager())
}
