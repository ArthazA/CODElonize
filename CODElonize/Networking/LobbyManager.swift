//
//  LobbyManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine

final class LobbyManager: ObservableObject {

    @Published var lobby: LobbyModel?
    @Published var didStartGame = false
    
    /// The match-start payload (shared start time, question seeds, final
    /// roster) — set on the host when it starts the game, and on clients
    /// when they receive the host's broadcast. `GameScreen` reads this to
    /// start `MatchManager` with real multiplayer data instead of the
    /// single-player dev fallback (README §6.3, §5.8).
    @Published var pendingMatchStart: StartGameMessage?

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
            avatar: "🦊",
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
    
    /// Records the match-start payload (from either the host starting the
    /// game locally, or a client receiving the host's broadcast) and flags
    /// that the game has started (README §6.3).
    func applyMatchStart(_ message: StartGameMessage) {
        DispatchQueue.main.async {
            self.pendingMatchStart = message
            self.didStartGame = true
        }
    }
    
    /// Clears the stored match-start payload. Call when returning to home so
    /// a stale payload from a previous match isn't reused.
    func clearMatchStart() {
        pendingMatchStart = nil
        didStartGame = false
    }
}
