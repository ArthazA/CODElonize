
import Foundation
import Combine

final class LobbyManager: ObservableObject {

    @Published var lobby: LobbyModel?
    @Published var didStartGame = false

    let hostManager = HostManager()
    let clientManager = ClientManager()

    init() {
        hostManager.lobbyManager = self
        clientManager.lobbyManager = self
    }

    func createLobby(hostID: UUID, hostName: String) {
        let host = Player(
            id: hostID,
            name: hostName,
            avatar: "player_1",
            isHost: true,
            isReady: false
        )

        lobby = LobbyModel(
            roomCode: generateRoomCode(),
            hostID: hostID,
            players: [host]
        )

        guard let lobby else {
            return
        }

        hostManager.startHosting(
            roomCode: lobby.roomCode
        )
    }

    func joinLobby(roomCode: String, playerID: UUID, playerName: String) {
        clientManager.connect(
            roomCode: roomCode,
            playerID: playerID,
            playerName: playerName
        )
    }

    private func generateRoomCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }

    func updateLobby(_ lobby: LobbyModel) {
        DispatchQueue.main.async {
            self.lobby = lobby
        }
    }

    func setReady(playerID: UUID, isReady: Bool, isHost: Bool) {
        if isHost {
            hostManager.setPlayerReady(playerID: playerID, isReady: isReady)
        } else {
            clientManager.sendReady(playerID: playerID, isReady: isReady)
        }
    }

    func startGame() {
        hostManager.startGame()
        didStartGame = true
    }

    func notifyGameStarted() {
        DispatchQueue.main.async {
            self.didStartGame = true
        }
    }
}
