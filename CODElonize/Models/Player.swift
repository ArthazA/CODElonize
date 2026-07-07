//
//  Player.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

struct Player: Codable, Identifiable {
    let id: UUID
    var name: String
    var avatar: String
    var isHost: Bool
    var isReady: Bool
}
