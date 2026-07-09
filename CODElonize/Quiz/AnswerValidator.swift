//
//  AnswerValidator.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import os

/// Validates player answers against the correct answer for each question.
///
/// Supports both MCQ (index-based) and Code Arrangement (ordered array comparison).
/// This is a pure, stateless utility. The `QuizManager` uses it to check
/// whether submitted answers are correct.
enum AnswerValidator {
    
    /// Checks whether the selected choice index is the correct answer (MCQ).
    ///
    /// - Parameters:
    ///   - selectedIndex: The index (0–3) of the choice the player tapped.
    ///   - question: The MCQ question being answered.
    /// - Returns: `true` if the answer is correct.
    static func validate(selectedIndex: Int, for question: Question) -> Bool {
        guard question.isMCQ, let correctIndex = question.correctIndex else {
            AppLogger.quiz.error("validate(selectedIndex:) called on non-MCQ question")
            return false
        }
        
        let isCorrect = selectedIndex == correctIndex
        
        AppLogger.quiz.debug(
            "MCQ validation: selected=\(selectedIndex), correct=\(correctIndex), result=\(isCorrect ? "CORRECT" : "INCORRECT")"
        )
        
        return isCorrect
    }
    
    /// Checks whether the player's arrangement matches the correct answer (Code Arrangement).
    ///
    /// The comparison is **order-sensitive**: `userAnswer[0]` must match `correctAnswer[0]`,
    /// `userAnswer[1]` must match `correctAnswer[1]`, etc.
    ///
    /// - Parameters:
    ///   - userAnswer: The player's ordered arrangement of code blocks in the slots.
    ///   - question: The Code Arrangement question being answered.
    /// - Returns: `true` if the arrangement is correct.
    static func validateArrangement(userAnswer: [String], for question: Question) -> Bool {
        guard question.isCodeArrangement, let correctAnswer = question.correctAnswer else {
            AppLogger.quiz.error("validateArrangement called on non-arrangement question")
            return false
        }
        
        // Must have the same number of answers as slots
        guard userAnswer.count == correctAnswer.count else {
            AppLogger.quiz.debug(
                "Arrangement validation: wrong slot count \(userAnswer.count) vs \(correctAnswer.count)"
            )
            return false
        }
        
        let isCorrect = userAnswer == correctAnswer
        
        AppLogger.quiz.debug(
            "Arrangement validation: result=\(isCorrect ? "CORRECT" : "INCORRECT")"
        )
        
        return isCorrect
    }
}
