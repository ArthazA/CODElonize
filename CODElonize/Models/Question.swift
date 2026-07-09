//
//  Question.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation

/// The type of quiz question.
///
/// Each area attempt consists of 3 MCQ questions followed by 2 Code Arrangement questions.
enum QuestionType: String, Codable, Equatable {
    /// A multiple-choice question with 4 options and 1 correct answer.
    case mcq
    /// A code arrangement question with 3 blank slots, 4 draggable options, and 1 distractor.
    case codeArrangement = "code_arrangement"
}

/// Represents a single quiz question that can be either MCQ or Code Arrangement.
///
/// Questions are loaded from topic-specific JSON files in the app bundle
/// and presented to players when they attempt to conquer an area.
///
/// ## MCQ Questions
/// Have `choices` (4 options) and `correctIndex` (0–3).
///
/// ## Code Arrangement Questions
/// Have `codeTemplate` (code lines with `"_____"` as blank slot markers),
/// `options` (4 draggable code blocks), and `correctAnswer` (ordered array of 3 correct options).
struct Question: Identifiable, Codable, Equatable {
    
    /// Unique identifier for the question.
    let id: UUID
    
    /// The type of question (MCQ or Code Arrangement).
    let type: QuestionType
    
    /// The question prompt displayed to the player.
    let text: String
    
    // MARK: - MCQ Fields
    
    /// Exactly 4 answer options (MCQ only).
    let choices: [String]?
    
    /// The index (0–3) of the correct choice in the `choices` array (MCQ only).
    let correctIndex: Int?
    
    // MARK: - Code Arrangement Fields
    
    /// The code template with `"_____"` marking blank slots (Code Arrangement only).
    /// Example: `["Text(\"Hello\")", "_____", ".font(.title)", "_____"]`
    let codeTemplate: [String]?
    
    /// Exactly 4 draggable code block options — 3 correct + 1 distractor (Code Arrangement only).
    let options: [String]?
    
    /// The correct answer as an ordered array of 3 strings (Code Arrangement only).
    /// `correctAnswer[0]` fills the first `"_____"`, `correctAnswer[1]` fills the second, etc.
    let correctAnswer: [String]?
    
    // MARK: - Computed Properties
    
    /// Whether this is a multiple-choice question.
    var isMCQ: Bool { type == .mcq }
    
    /// Whether this is a code arrangement question.
    var isCodeArrangement: Bool { type == .codeArrangement }
    
    /// The number of blank slots in a Code Arrangement question.
    /// Returns 0 for MCQ questions.
    var slotCount: Int {
        codeTemplate?.filter { $0 == "_____" }.count ?? 0
    }
}

/// Wrapper for decoding a topic's JSON file.
///
/// Each JSON file contains a topic name and an array of questions (both MCQ and Code Arrangement).
/// Example structure:
/// ```json
/// {
///   "topic": "algorithms",
///   "questions": [
///     { "id": "...", "type": "mcq", ... },
///     { "id": "...", "type": "code_arrangement", ... }
///   ]
/// }
/// ```
struct QuestionBank: Codable {
    
    /// The topic name (e.g. "algorithms", "swiftui").
    let topic: String
    
    /// All questions available for this topic (both MCQ and Code Arrangement).
    let questions: [Question]
}
