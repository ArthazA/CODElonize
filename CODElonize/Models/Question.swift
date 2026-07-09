
import Foundation

enum QuestionType: String, Codable, Equatable {

    case mcq

    case codeArrangement = "code_arrangement"
}

struct Question: Identifiable, Codable, Equatable {

    let id: UUID

    let type: QuestionType

    let text: String

    let choices: [String]?

    let correctIndex: Int?

    let codeTemplate: [String]?

    let options: [String]?

    let correctAnswer: [String]?

    var isMCQ: Bool { type == .mcq }

    var isCodeArrangement: Bool { type == .codeArrangement }

    var slotCount: Int {
        codeTemplate?.filter { $0 == "_____" }.count ?? 0
    }
}

struct QuestionBank: Codable {

    let topic: String

    let questions: [Question]
}
