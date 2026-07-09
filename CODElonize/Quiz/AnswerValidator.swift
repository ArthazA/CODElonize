
import Foundation
import os

enum AnswerValidator {

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

    static func validateArrangement(userAnswer: [String], for question: Question) -> Bool {
        guard question.isCodeArrangement, let correctAnswer = question.correctAnswer else {
            AppLogger.quiz.error("validateArrangement called on non-arrangement question")
            return false
        }

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
