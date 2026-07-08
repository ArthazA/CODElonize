//
//  NetworkMessage.swift
//  CODElonize
//
//  Created by Nadila Rizky Amelia on 06/07/26.
//

import Foundation

struct NetworkMessage<T: Codable>: Codable {

    let type: MessageType
    let payload: T

}
