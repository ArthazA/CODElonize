//
//  QuestionLoader.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import os

/// Loads and decodes quiz questions from the bundled JSON files.
///
/// Each JSON file corresponds to one learning topic and follows the `QuestionBank` schema.
/// The loader resolves topic names (e.g. "Algorithms") to their JSON filenames
/// using `GameConstants.topicFileMapping`.
enum QuestionLoader {
    
    /// Loads all questions for the given topic from the app bundle.
    ///
    /// - Parameter topic: The display name of the topic (e.g. "Algorithms", "AI").
    ///   Must match a key in `GameConstants.topicFileMapping`.
    /// - Returns: An array of `Question` objects, or an empty array if loading fails.
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
    
    /// Loads all questions across every topic.
    ///
    /// Useful for diagnostics or validating that all JSON files are properly formatted.
    /// - Returns: A dictionary mapping topic names to their question arrays.
    static func loadAllTopics() -> [String: [Question]] {
        var result: [String: [Question]] = [:]
        for topic in GameConstants.areaTopics {
            result[topic] = loadQuestions(for: topic)
        }
        return result
    }
}
