import SwiftUI

struct Lobby: View {
    @EnvironmentObject var appState: AppState
    @State var isHost: Bool = true // Toggle this in Preview to see the different states
    
    // Dummy Data
    let players = [
        ("Adi", true, true),
        ("Arthaz", true, false),
        ("Kinah", true, false),
        ("Barra", true, false),
        ("Dila", true, false)
    ]
    let roomCode = ["5", "5", "5", "5"]
    
    var body: some View {
        ZStack {
            Color.themeCream.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                VStack(spacing: 12) {
                    Text("ROOM CODE")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeDarkTeal)
                        .padding(.top, 40)
                    
                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            RoomCodeBox(character: roomCode[index])
                        }
                    }
                    
                    Text("Tap to copy, share with friends nearby")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeTeal)
                }
                
                Divider()
                    .background(Color.themeTeal.opacity(0.5))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                
                // Players List
                VStack(spacing: 20) {
                    Text("Players Joining (5/5)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeTeal)
                        .underline(true, color: Color.themeTeal)
                    
                    // Grid of players
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                        ForEach(0..<players.count, id: \.self) { index in
                            let player = players[index]
                            PlayerAvatar(name: player.0, isReady: player.1, isHost: player.2)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Bottom Area
                if isHost {
                    // Preview text and Button for Host
                    VStack(spacing: 16) {
                        Text("Preview the island before starting.")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.themeTeal)
                        
                        SecondaryButton(title: "Start Game") {
                            appState.navigate(to: .arPlacement)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                } else {
                    // Waiting text for Player
                    Text("Waiting the host to start the game...")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeDarkTeal)
                        .padding(.bottom, 60)
                }
            }
        }
    }
}

#Preview("Host View") {
    Lobby(isHost: true)
        .environmentObject(AppState())
}

#Preview("Player View") {
    Lobby(isHost: false)
        .environmentObject(AppState())
}
