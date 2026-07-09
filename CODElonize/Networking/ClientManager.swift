//
//  ClientManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Network

final class ClientManager {

    weak var lobbyManager: LobbyManager?
    private var browser: NWBrowser?
    private var discoveredRooms: [NWBrowser.Result] = []
    private var connection: NWConnection?
    
    func browseHosts() {
        browser?.cancel()
        browser = NWBrowser(
            for: .bonjour(type: "_codelonize._tcp", domain: nil),
            using: .tcp
        )
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            self?.discoveredRooms = Array(results)
            print("Found Rooms:")
            for result in results {
                print(result)
            }
        }
        browser?.start(queue: .main)
    }
    
    func connect(roomCode: String, playerID: UUID, playerName: String, attemptsLeft: Int = 5) {
        print("Trying to match roomCode: '\(roomCode)' against \(discoveredRooms.count) discovered rooms")
        for room in discoveredRooms {
            switch room.endpoint {
            case .service(let name, _, _, _):
                print("Comparing discovered name: '\(name)' vs target: '\(roomCode)'")
                if name == roomCode {
                    connection = NWConnection(to: room.endpoint, using: .tcp)
                    connection?.stateUpdateHandler = { [weak self] state in
                        guard let self else { return }
                        switch state {
                        case .ready:
                            print("Socket Ready")
                            self.sendJoin(playerID: playerID, playerName: playerName)
                            self.receive()
                        case .waiting(let error):
                            print("Connection waiting: \(error)")
                        case .failed(let error):
                            print("Connection failed: \(error)")
                        case .cancelled:
                            print("Connection cancelled")
                        case .preparing:
                            print("Connection preparing...")
                        default:
                            break
                        }
                    }
                    connection?.start(queue: .main)
                    print("Connected!")
                    return
                }
            default:
                break
            }
        }

        if attemptsLeft > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.connect(
                    roomCode: roomCode,
                    playerID: playerID,
                    playerName: playerName,
                    attemptsLeft: attemptsLeft - 1
                )
            }
        } else {
            print("Room not found after retries")
        }
    }
    
    private func send<T: Codable>(_ message: NetworkMessage<T>) {
        guard let connection else { return }
        do {
            let data = try JSONEncoder().encode(message)
            connection.send(
                content: data,
                completion: .contentProcessed { error in
                    if let error {
                        print(error)
                    } else {
                        print("Message Sent")
                    }
                }
            )
        } catch {
            print(error)
        }
    }
    
    func sendJoin(playerID: UUID, playerName: String) {
        let join = JoinMessage(
            playerID: playerID,
            playerName: playerName
        )
        let message = NetworkMessage<JoinMessage>(
            type: .join,
            payload: join
        )
        send(message)
    }
    
    private func receive() {
        connection?.receive(
            minimumIncompleteLength: 1,
            maximumLength: 65536
        ) { [weak self] data, _, complete, error in
            guard let self else { return }
            
            if let data {
                self.handle(data)
            }
            if error == nil && !complete {
                self.receive()
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
            case .lobbyUpdate:
                let wrapper = try JSONDecoder().decode(
                    NetworkMessage<LobbyUpdateMessage>.self,
                    from: data
                )
                let payload = wrapper.payload
                let lobby = LobbyModel(
                    roomCode: payload.roomCode,
                    hostID: payload.hostID,
                    players: payload.players,
                    maxPlayers: payload.maxPlayers
                )

                lobbyManager?.updateLobby(lobby)
                print("Lobby Synced")

                for player in lobby.players {
                    print(player.name)
                }
                print("Lobby Updated")
            case .startGame:
                let wrapper = try JSONDecoder().decode(
                    NetworkMessage<StartGameMessage>.self,
                    from: data
                )
                handleStartGame(wrapper.payload)
            default:
                break
            }
        } catch {
            print(error)
        }
    }
    
    func sendReady(playerID: UUID, isReady: Bool) {
        let payload = ReadyMessage(
            playerID: playerID,
            isReady: isReady
        )
        let message = NetworkMessage<ReadyMessage>(
            type: .ready,
            payload: payload
        )
        guard connection != nil else {
            print("No Connection")
            return
        }
        send(message)
    }
    
    /// Receives the host's match-start payload (shared start time + question
    /// seeds + final roster) and forwards it to `LobbyManager` so the client
    /// can start its own `MatchManager` in sync with the host (README §6.3).
    private func handleStartGame(
        _ message: StartGameMessage
    ) {
        print("Game Started")
        lobbyManager?.applyMatchStart(message)
    }
}
