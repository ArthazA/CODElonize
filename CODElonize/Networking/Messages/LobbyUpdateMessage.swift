//
//  LobbyUpdateMessage.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 07/07/26.
//

import Foundation

struct LobbyUpdateMessage: Codable {
    let roomCode: String
    let hostID: UUID
    let players: [Player]
    let maxPlayers: Int
}
