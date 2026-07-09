import SwiftUI

struct Lobby: View {
    @EnvironmentObject var appState: AppState
    @State var isHost: Bool = true 

    private var players: [Player] {
        appState.lobbyManager.lobby?.players ?? []
    }

    private var myself: Player? {
        players.first(where: { $0.id == appState.playerID })
    }

    private var isMyselfReady: Bool {
        myself?.isReady ?? false
    }

    private var roomCode: [String] {
        guard let lobby = appState.lobbyManager.lobby else {
            return []
        }
        return lobby.roomCode.map(String.init)
    }

    var body: some View {
        ZStack {
            Color.themeCream.edgesIgnoringSafeArea(.all)

            VStack {

                VStack(spacing: 12) {
                    Text("ROOM CODE")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeDarkTeal)
                        .padding(.top, 40)

                    HStack(spacing: 16) {
                        if roomCode.count == 4 {
                            HStack(spacing: 16) {
                                ForEach(0..<4) { index in
                                    RoomCodeBox(
                                        character: roomCode[index]
                                    )
                                }
                            }
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

                VStack(spacing: 20) {
                    Text("Players Joining (\(players.count)/\(appState.lobbyManager.lobby?.maxPlayers ?? 5))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeTeal)
                        .underline(true, color: Color.themeTeal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                        ForEach(players) { player in
                            PlayerAvatar(
                                imageName: player.avatar,
                                name: player.name,
                                isReady: player.isReady,
                                isHost: player.isHost,
                                isSelf: player.id == appState.playerID
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                if !isMyselfReady {
                    VStack(spacing: 16) {
                        Text("Preview the island before you're ready.")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.themeTeal)

                        PrimaryButton(title: "Preview Island") {
                            appState.navigate(to: .islandPreview)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)

                } else if appState.isHost {
                    VStack(spacing: 16) {
                        Text("Preview the island before starting.")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.themeTeal)

                        SecondaryButton(title: "Start Game") {
                            appState.navigate(to: .arPlacement)
                            appState.lobbyManager.startGame()
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)

                } else {
                    Text("Waiting the host to start the game...")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeDarkTeal)
                        .padding(.bottom, 60)
                }
            }
        }
        .onChange(of: appState.lobbyManager.didStartGame) { _, started in
            if started, !appState.isHost {
                appState.navigate(to: .arPlacement)
            }
        }
    }
}

#Preview("Host View") {
    let appState = AppState()
    let hostID = UUID()

    appState.playerID = hostID
    appState.isHost = true

    appState.lobbyManager.lobby = LobbyModel(
        roomCode: "1234",
        hostID: hostID,
        players: [
            Player(
                id: hostID,
                name: "Host",
                avatar: "player_1",
                isHost: true,
                isReady: true
            ),
            Player(
                id: UUID(),
                name: "Player",
                avatar: "player_3",
                isHost: false,
                isReady: false
            )
        ],
        maxPlayers: 5
    )

    return Lobby(isHost: true)
        .environmentObject(appState)
}
