//
//  AttemptResultMessage.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 10/07/26.
//

import Foundation
struct AttemptResultMessage: Codable {
    let areaIndex: Int
    let playerID: UUID
    let time: TimeInterval
}
