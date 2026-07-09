//
//  GameStateSyncMessage.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 10/07/26.
//

import Foundation

struct GameStateSyncMessage: Codable {
    let areas: [Area]
    let players: [Player]
}
