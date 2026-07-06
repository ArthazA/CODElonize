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
/// This is a pure, stateless utility. The `QuizManager` uses it to check
/// whether a submitted answer index matches the question's `correctIndex`.
enum AnswerValidator {
    
    /// Checks whether the selected choice index is the correct answer.
    ///
    /// - Parameters:
    ///   - selectedIndex: The index (0–3) of the choice the player tapped.
    ///   - question: The question being answered.
    /// - Returns: `true` if the answer is correct.
    static func validate(selectedIndex: Int, for question: Question) -> Bool {
        let isCorrect = selectedIndex == question.correctIndex
        
        AppLogger.quiz.debug(
            "Answer validation: selected=\(selectedIndex), correct=\(question.correctIndex), result=\(isCorrect ? "CORRECT" : "INCORRECT")"
        )
        
        return isCorrect
    }
}
