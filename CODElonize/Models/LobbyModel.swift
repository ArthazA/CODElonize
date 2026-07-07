//
//  Lobby.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 06/07/26.
//

import Foundation

struct LobbyModel: Codable {
    var roomCode: String
    var hostID: UUID
    var players: [Player]
    var maxPlayers: Int = 5
    
    var host: Player? {
        players.first {
            $0.id == hostID
        }
    }
}
