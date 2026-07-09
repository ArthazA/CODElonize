
import Foundation

struct NetworkMessage<T: Codable>: Codable {

    let type: MessageType
    let payload: T

}
