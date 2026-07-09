
import Foundation
import os

enum QuestionLoader {

    static func loadQuestions(for topic: String) -> [Question] {
        guard let filename = GameConstants.topicFileMapping[topic] else {
            AppLogger.quiz.error("No file mapping found for topic: \(topic)")
            return []
        }

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            AppLogger.quiz.error("JSON file not found in bundle: \(filename).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let bank = try JSONDecoder().decode(QuestionBank.self, from: data)

            AppLogger.quiz.info("Loaded \(bank.questions.count) questions for topic '\(topic)'")
            return bank.questions

        } catch {
            AppLogger.quiz.error("Failed to decode \(filename).json: \(error.localizedDescription)")
            return []
        }
    }

    static func loadMCQQuestions(for topic: String) -> [Question] {
        loadQuestions(for: topic).filter { $0.type == .mcq }
    }

    static func loadArrangementQuestions(for topic: String) -> [Question] {
        loadQuestions(for: topic).filter { $0.type == .codeArrangement }
    }

    static func loadAllTopics() -> [String: [Question]] {
        var result: [String: [Question]] = [:]
        for topic in GameConstants.areaTopics {
            result[topic] = loadQuestions(for: topic)
        }
        return result
    }

    static func hasEnoughQuestions(for topic: String) -> Bool {
        let all = loadQuestions(for: topic)
        let mcqCount = all.filter { $0.type == .mcq }.count
        let arrangementCount = all.filter { $0.type == .codeArrangement }.count

        let hasMCQ = mcqCount >= GameConstants.mcqPerAttempt
        let hasArrangement = arrangementCount >= GameConstants.arrangementPerAttempt

        if !hasMCQ {
            AppLogger.quiz.warning("Topic '\(topic)' has only \(mcqCount) MCQ questions (need \(GameConstants.mcqPerAttempt))")
        }
        if !hasArrangement {
            AppLogger.quiz.warning("Topic '\(topic)' has only \(arrangementCount) arrangement questions (need \(GameConstants.arrangementPerAttempt))")
        }

        return hasMCQ && hasArrangement
    }
}
