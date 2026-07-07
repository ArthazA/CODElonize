//
//  ReadyMessage.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 07/07/26.
//

import Foundation

struct ReadyMessage: Codable {
    let playerID: UUID
    let isReady: Bool
}
