//
//  Question.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

/// Represents a single multiple-choice quiz question.
///
/// Questions are loaded from topic-specific JSON files in the app bundle
/// and presented to players when they attempt to conquer an area.
/// Each question has exactly 4 choices with one correct answer.
struct Question: Identifiable, Codable, Equatable {
    
    /// Unique identifier for the question.
    let id: UUID
    
    /// The question prompt displayed to the player.
    let text: String
    
    /// Exactly 4 answer options.
    let choices: [String]
    
    /// The index (0–3) of the correct choice in the `choices` array.
    let correctIndex: Int
}

/// Wrapper for decoding a topic's JSON file.
///
/// Each JSON file contains a topic name and an array of questions.
/// Example structure:
/// ```json
/// {
///   "topic": "algorithms",
///   "questions": [ ... ]
/// }
/// ```
struct QuestionBank: Codable {
    
    /// The topic name (e.g. "algorithms", "ai").
    let topic: String
    
    /// All questions available for this topic.
    let questions: [Question]
}
