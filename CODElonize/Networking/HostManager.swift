//
//  HostManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Network
import Combine

final class HostManager: ObservableObject {
    weak var lobbyManager: LobbyManager?
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    func startHosting(roomCode: String) {
        listener?.cancel()
            connections.forEach { $0.cancel() }
            connections.removeAll()

        do {
            listener = try NWListener(using: .tcp, on: 5555)
            listener?.service = NWListener.Service(
                name: roomCode,
                type: "_codelonize._tcp"
            )
            listener?.stateUpdateHandler = {
                print("Listener:", $0)
            }
            listener?.newConnectionHandler = { [weak self] connection in
                guard let self else { return }
                self.connections.append(connection)
                connection.start(queue: .main)
                self.receive(on: connection)
                print("Client Connected")
            }
            listener?.start(queue: .main)
        } catch {
            print(error)
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 65536
        ) { [weak self] data, _, complete, error in

            guard let self else { return }

            if let data {
                self.handle(data)
            }

            if error == nil && !complete {
                self.receive(on: connection)
            }
        }
    }

    private func handle(_ data: Data) {
        do {
            let base = try JSONDecoder().decode(
                BaseMessage.self,
                from: data
            )
            switch base.type {
            case .join:
                let wrapper = try JSONDecoder().decode(
                    NetworkMessage<JoinMessage>.self,
                    from: data
                )
                handleJoin(wrapper.payload)
            case .ready:
                let wrapper = try JSONDecoder().decode(
                    NetworkMessage<ReadyMessage>.self,
                    from: data
                )
                handleReady(wrapper.payload)
            default:
                break
            }
        } catch {
            print(error)
        }
    }
    
    private func broadcast<T: Codable>(_ message: NetworkMessage<T>) {

            do {
                let data = try JSONEncoder().encode(message)
                for connection in connections {
                    connection.send(
                        content: data,
                        completion: .contentProcessed { error in
                            if let error {
                                print(error)
                            }
                        }
                    )
                }

            } catch {
                print(error)
            }

        }
    private func broadcastLobby(_ lobby: LobbyModel) {
        let payload = LobbyUpdateMessage(
            roomCode: lobby.roomCode,
            hostID: lobby.hostID,
            players: lobby.players,
            maxPlayers: lobby.maxPlayers
        )
        let message = NetworkMessage<LobbyUpdateMessage>(
            type: .lobbyUpdate,
            payload: payload
        )
        broadcast(message)
    }
    
    func setPlayerReady(playerID: UUID, isReady: Bool) {
        guard var lobby = lobbyManager?.lobby else {
            return
        }

        guard let index = lobby.players.firstIndex(
            where: { $0.id == playerID }
        ) else {
            return
        }

        lobby.players[index].isReady = isReady
        
        lobbyManager?.updateLobby(lobby)
        print("Lobby Synced")
        for player in lobby.players {
            print(player.name)
        }
        broadcastLobby(lobby)
    }
    
    private func handleReady(_ ready: ReadyMessage) {
        setPlayerReady(playerID: ready.playerID, isReady: ready.isReady)
    }
    
    private func handleJoin(_ join: JoinMessage) {
        guard var lobby = lobbyManager?.lobby else {
            return
        }
        let animals = [
            "🦊","🐻","🐰","🐸","🐼",
            "🐨","🐧","🐙","🦁","🐯"
        ]

        let used = lobby.players.map(\.avatar)

        let available = animals.filter {
            !used.contains($0)
        }

        let avatar = available.randomElement() ?? "🐶"
        let player = Player(
            id: join.playerID,
            name: join.playerName,
            avatar: avatar,
            isHost: false,
            isReady: false
        )
        
        if lobby.players.contains(where: { $0.id == player.id }) {
            return
        }
        lobby.players.append(player)
        
        print("Player Joined:")
        lobby.players.forEach {
            print($0.name)
        }

        lobbyManager?.updateLobby(lobby)
        print("Lobby Synced")

        for player in lobby.players {
            print(player.name)
        }

        broadcastLobby(lobby)
    }
    
    /// Starts the match: generates the shared start time and per-area
    /// question seeds, broadcasts them to every client, and applies the
    /// same payload locally so the host itself starts in sync (README §6.3).
    func startGame() {
        guard let lobby = lobbyManager?.lobby else {
            print("Cannot start game — no lobby")
            return
        }
        
        // Host generates one seed per area so every device's Randomizer
        // produces identical question sets for that area (fairness requirement).
        let seeds = (0..<GameConstants.areaCount).map { _ in Randomizer.generateSeed() }
        
        let payload = StartGameMessage(
            startTime: Date(),
            questionSeeds: seeds,
            players: lobby.players
        )
        let message = NetworkMessage<StartGameMessage>(
            type: .startGame,
            payload: payload
        )
        broadcast(message)
        handleStartGame(payload)
    }
    
    private func handleStartGame(
        _ message: StartGameMessage
    ) {
        print("Host Start")
        lobbyManager?.applyMatchStart(message)
    }
}
