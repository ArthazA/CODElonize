//
//  QuizManager.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine
import os

/// The state of the player's current answer submission.
enum AnswerState: Equatable {
    /// No answer has been submitted yet for the current question.
    case unanswered
    /// The submitted answer was correct.
    case correct
    /// The submitted answer was incorrect. The UI freezes for the penalty duration.
    case incorrect
}

/// Central state machine that drives a single quiz attempt session.
///
/// `QuizManager` is an `ObservableObject` used by `QuestionView` to display
/// questions, handle answer submissions, enforce the wrong-answer penalty,
/// track elapsed time, and report completion.
///
/// ## Lifecycle
/// 1. Call `startQuiz(topic:seed:)` to load questions and begin the timer.
/// 2. The player taps answers via `submitAnswer(_:)`.
/// 3. Correct answers advance to the next question. Wrong answers freeze for 3 seconds.
/// 4. After all questions are answered correctly, `isComplete` becomes `true`
///    and `completionTime` records the elapsed duration.
/// 5. Call `cancelQuiz()` to abort (e.g. Tsunami, disconnect).
class QuizManager: ObservableObject {
    
    // MARK: - Published State
    
    /// The questions for this quiz attempt (typically 3).
    @Published private(set) var currentQuestions: [Question] = []
    
    /// Index of the question currently being displayed (0-based).
    @Published private(set) var currentQuestionIndex: Int = 0
    
    /// The player's selected answer index, or nil if not yet selected.
    @Published private(set) var selectedAnswer: Int? = nil
    
    /// Current answer validation state.
    @Published private(set) var answerState: AnswerState = .unanswered
    
    /// Whether all questions have been answered correctly.
    @Published private(set) var isComplete: Bool = false
    
    /// Whether the UI is frozen due to a wrong answer penalty.
    @Published private(set) var isFrozen: Bool = false
    
    /// Elapsed time since the quiz started, in seconds.
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    /// The topic name for the current quiz (e.g. "Algorithms").
    @Published private(set) var topic: String = ""
    
    /// Whether a quiz session is currently active.
    @Published private(set) var isActive: Bool = false
    
    /// The recorded completion time (set when the quiz finishes).
    /// This is the value used for area conquest time comparison.
    private(set) var completionTime: TimeInterval? = nil
    
    /// The seed used for this quiz session (for networking sync).
    private(set) var currentSeed: UInt64 = 0
    
    // MARK: - Private
    
    /// Timer that ticks the elapsed clock.
    private var timerCancellable: AnyCancellable?
    
    /// Timer that unfreezes the UI after a wrong-answer penalty.
    private var freezeCancellable: AnyCancellable?
    
    /// Timestamp when the quiz started.
    private var startTime: Date?
    
    // MARK: - Computed Properties
    
    /// The current question being displayed, or nil if the quiz is not active.
    var currentQuestion: Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }
    
    /// Total number of questions in this attempt.
    var totalQuestions: Int {
        currentQuestions.count
    }
    
    /// Formatted elapsed time string (MM:SS.d).
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
    
    // MARK: - Quiz Lifecycle
    
    /// Starts a new quiz session for the given topic.
    ///
    /// Loads questions from the JSON file, selects a randomized subset using the
    /// provided seed, and begins the elapsed timer.
    ///
    /// - Parameters:
    ///   - topic: The display name of the topic (e.g. "Algorithms").
    ///   - seed: A shared seed for deterministic question selection.
    ///     Pass `nil` to auto-generate a seed (single-player or host-side).
    func startQuiz(topic: String, seed: UInt64? = nil) {
        // Reset any previous session
        resetState()
        
        self.topic = topic
        self.currentSeed = seed ?? Randomizer.generateSeed()
        
        // Load and randomize questions
        let allQuestions = QuestionLoader.loadQuestions(for: topic)
        
        guard !allQuestions.isEmpty else {
            AppLogger.quiz.error("Cannot start quiz: no questions available for '\(topic)'")
            return
        }
        
        currentQuestions = Randomizer.selectQuestions(
            from: allQuestions,
            count: GameConstants.questionsPerAttempt,
            seed: currentSeed
        )
        
        guard !currentQuestions.isEmpty else {
            AppLogger.quiz.error("Randomizer returned empty question set for '\(topic)'")
            return
        }
        
        // Start the session
        isActive = true
        startTime = Date()
        startTimer()
        
        AppLogger.quiz.info(
            "Quiz started: topic=\(self.topic), questions=\(self.currentQuestions.count), seed=\(self.currentSeed)"
        )
    }
    
    /// Starts a quiz with pre-selected questions (for clients receiving questions from the host).
    ///
    /// - Parameters:
    ///   - topic: The display name of the topic.
    ///   - questions: The exact questions to use (already randomized by the host).
    func startQuiz(topic: String, questions: [Question]) {
        resetState()
        
        self.topic = topic
        self.currentQuestions = questions
        
        guard !currentQuestions.isEmpty else {
            AppLogger.quiz.error("Cannot start quiz: empty question set provided for '\(topic)'")
            return
        }
        
        isActive = true
        startTime = Date()
        startTimer()
        
        AppLogger.quiz.info(
            "Quiz started (preset questions): topic=\(topic), questions=\(questions.count)"
        )
    }
    
    /// Submits an answer for the current question.
    ///
    /// - Parameter choiceIndex: The index (0–3) of the selected answer choice.
    ///
    /// ## Behavior
    /// - If **correct**: briefly shows green feedback, then advances to the next question
    ///   (or completes the quiz if this was the last question).
    /// - If **incorrect**: shows red feedback and freezes the UI for the penalty duration
    ///   (`GameConstants.wrongAnswerPenalty`, 3 seconds). After the freeze, the player
    ///   can try again on the same question.
    func submitAnswer(_ choiceIndex: Int) {
        guard isActive, !isComplete, !isFrozen else { return }
        guard let question = currentQuestion else { return }
        
        selectedAnswer = choiceIndex
        
        let isCorrect = AnswerValidator.validate(selectedIndex: choiceIndex, for: question)
        
        if isCorrect {
            answerState = .correct
            
            // Brief delay to show the correct feedback before advancing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.advanceToNextQuestion()
            }
        } else {
            answerState = .incorrect
            applyFreezePenalty()
        }
    }
    
    /// Cancels the current quiz session.
    ///
    /// Used when a Tsunami power-up locks the area, the player disconnects,
    /// or other external events force the quiz to end prematurely.
    func cancelQuiz() {
        AppLogger.quiz.info("Quiz cancelled for topic '\(self.topic)'")
        stopTimer()
        resetState()
    }
    
    // MARK: - Private Methods
    
    /// Advances to the next question, or completes the quiz if all are answered.
    private func advanceToNextQuestion() {
        let nextIndex = currentQuestionIndex + 1
        
        if nextIndex >= currentQuestions.count {
            // All questions answered correctly — quiz complete
            completeQuiz()
        } else {
            // Move to next question
            currentQuestionIndex = nextIndex
            selectedAnswer = nil
            answerState = .unanswered
            
            AppLogger.quiz.info("Advanced to question \(nextIndex + 1)/\(self.totalQuestions)")
        }
    }
    
    /// Records the completion time and marks the quiz as finished.
    private func completeQuiz() {
        stopTimer()
        
        // Record final elapsed time
        if let start = startTime {
            completionTime = Date().timeIntervalSince(start)
            elapsedTime = completionTime!
        }
        
        isComplete = true
        isActive = false
        
        AppLogger.quiz.info(
            "Quiz completed: topic=\(self.topic), time=\(String(format: "%.1f", self.completionTime ?? 0))s"
        )
    }
    
    /// Freezes the UI for the wrong-answer penalty duration.
    private func applyFreezePenalty() {
        isFrozen = true
        
        AppLogger.quiz.debug("Wrong answer penalty applied (\(GameConstants.wrongAnswerPenalty)s freeze)")
        
        freezeCancellable = Just(())
            .delay(for: .seconds(GameConstants.wrongAnswerPenalty), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.unfreezeAfterPenalty()
            }
    }
    
    /// Unfreezes the UI after the wrong-answer penalty, allowing the player to retry.
    private func unfreezeAfterPenalty() {
        isFrozen = false
        selectedAnswer = nil
        answerState = .unanswered
        
        AppLogger.quiz.debug("Wrong answer penalty expired, UI unfrozen")
    }
    
    /// Starts the elapsed time ticker.
    private func startTimer() {
        timerCancellable = Timer.publish(
            every: GameConstants.quizTimerUpdateInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    /// Stops the elapsed time ticker.
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        freezeCancellable?.cancel()
        freezeCancellable = nil
    }
    
    /// Resets all state to initial values.
    private func resetState() {
        stopTimer()
        currentQuestions = []
        currentQuestionIndex = 0
        selectedAnswer = nil
        answerState = .unanswered
        isComplete = false
        isFrozen = false
        elapsedTime = 0
        topic = ""
        isActive = false
        completionTime = nil
        startTime = nil
    }
}
