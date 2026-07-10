import Foundation
import Combine
import os

enum AnswerState: Equatable {
    case unanswered
    case correct
    case incorrect
}

class QuizManager: ObservableObject {

    @Published private(set) var currentQuestions: [Question] = []
    @Published private(set) var currentQuestionIndex: Int = 0
    @Published private(set) var selectedAnswer: Int? = nil
    @Published private(set) var answerState: AnswerState = .unanswered
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var isFrozen: Bool = false
    @Published private(set) var freezeRemaining: TimeInterval = 0
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var topic: String = ""
    @Published private(set) var isActive: Bool = false

    /// The ordered chips the player has placed so far (Duolingo-style sentence
    /// builder — always a contiguous, ordered prefix of the final answer).
    @Published var arrangementAnswer: [String] = []

    private(set) var completionTime: TimeInterval? = nil
    private(set) var currentSeed: UInt64 = 0

    private var timerCancellable: AnyCancellable?
    private var freezeCancellable: AnyCancellable?
    private var freezeTickCancellable: AnyCancellable?
    private var startTime: Date?

    var currentQuestion: Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }

    var totalQuestions: Int { currentQuestions.count }

    var isCurrentQuestionArrangement: Bool {
        currentQuestion?.isCodeArrangement ?? false
    }

    /// Whether every blank has a chip placed (submit-readiness).
    var isAnswerComplete: Bool {
        guard let question = currentQuestion, question.isCodeArrangement else { return false }
        return arrangementAnswer.count == question.slotCount
    }

    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    var formattedFreezeRemaining: String {
        String(format: "%.1fs", freezeRemaining)
    }

    func startQuiz(topic: String, seed: UInt64? = nil) {
        resetState()
        self.topic = topic
        self.currentSeed = seed ?? Randomizer.generateSeed()

        let mcqPool = QuestionLoader.loadMCQQuestions(for: topic)
        let arrangementPool = QuestionLoader.loadArrangementQuestions(for: topic)

        guard !mcqPool.isEmpty else {
            AppLogger.quiz.error("Cannot start quiz: no MCQ questions available for '\(topic)'")
            return
        }

        if !arrangementPool.isEmpty {
            currentQuestions = Randomizer.selectMixedQuestions(
                mcqPool: mcqPool,
                arrangementPool: arrangementPool,
                seed: currentSeed
            )
        } else {
            AppLogger.quiz.warning("No arrangement questions for '\(topic)' — using MCQ only")
            currentQuestions = Randomizer.selectQuestions(
                from: mcqPool,
                count: GameConstants.questionsPerAttempt,
                seed: currentSeed
            )
        }

        guard !currentQuestions.isEmpty else {
            AppLogger.quiz.error("Randomizer returned empty question set for '\(topic)'")
            return
        }

        setupArrangementSlots()
        isActive = true
        startTime = Date()
        startTimer()

        AppLogger.quiz.info(
            "Quiz started: topic=\(self.topic), questions=\(self.currentQuestions.count), seed=\(self.currentSeed)"
        )
    }

    func startQuiz(topic: String, questions: [Question]) {
        resetState()
        self.topic = topic
        self.currentQuestions = questions

        guard !currentQuestions.isEmpty else {
            AppLogger.quiz.error("Cannot start quiz: empty question set provided for '\(topic)'")
            return
        }

        setupArrangementSlots()
        isActive = true
        startTime = Date()
        startTimer()

        AppLogger.quiz.info("Quiz started (preset questions): topic=\(topic), questions=\(questions.count)")
    }

    func submitAnswer(_ choiceIndex: Int) {
        guard isActive, !isComplete, !isFrozen else { return }
        guard let question = currentQuestion, question.isMCQ else { return }

        selectedAnswer = choiceIndex
        let isCorrect = AnswerValidator.validate(selectedIndex: choiceIndex, for: question)

        if isCorrect {
            answerState = .correct
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.advanceToNextQuestion()
            }
        } else {
            answerState = .incorrect
            applyFreezePenalty()
        }
    }

    func submitArrangementAnswer() {
        guard isActive, !isComplete, !isFrozen else { return }
        guard let question = currentQuestion, question.isCodeArrangement else { return }
        guard isAnswerComplete else { return }

        let isCorrect = AnswerValidator.validateArrangement(userAnswer: arrangementAnswer, for: question)

        if isCorrect {
            answerState = .correct
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.advanceToNextQuestion()
            }
        } else {
            answerState = .incorrect
            applyFreezePenalty()
        }
    }

    /// Appends a word-bank chip to the next open blank (Duolingo mechanic).
    @discardableResult
    func appendArrangementOption(_ option: String) -> Bool {
        guard !isFrozen else { return false }
        guard let question = currentQuestion, question.isCodeArrangement else { return false }
        guard arrangementAnswer.count < question.slotCount else { return false }
        guard !arrangementAnswer.contains(option) else { return false }
        arrangementAnswer.append(option)
        return true
    }

    /// Removes the chip at `slotIndex`, shifting any later chips back
    /// so the answer always stays a contiguous ordered prefix.
    @discardableResult
    func removeArrangementOption(at slotIndex: Int) -> String? {
        guard !isFrozen else { return nil }
        guard arrangementAnswer.indices.contains(slotIndex) else { return nil }
        return arrangementAnswer.remove(at: slotIndex)
    }

    var availableOptions: [String] {
        guard let question = currentQuestion, question.isCodeArrangement,
              let options = question.options else { return [] }
        return options.filter { !arrangementAnswer.contains($0) }
    }

    func cancelQuiz() {
        AppLogger.quiz.info("Quiz cancelled for topic '\(self.topic)'")
        stopTimer()
        resetState()
    }

    private func setupArrangementSlots() {
        arrangementAnswer = []
    }

    private func advanceToNextQuestion() {
        let nextIndex = currentQuestionIndex + 1
        if nextIndex >= currentQuestions.count {
            completeQuiz()
        } else {
            currentQuestionIndex = nextIndex
            selectedAnswer = nil
            answerState = .unanswered
            setupArrangementSlots()
            AppLogger.quiz.info("Advanced to question \(nextIndex + 1)/\(self.totalQuestions)")
        }
    }

    private func completeQuiz() {
        stopTimer()
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

    private func applyFreezePenalty() {
        isFrozen = true
        freezeRemaining = GameConstants.wrongAnswerPenalty

        AppLogger.quiz.debug("Wrong answer penalty applied (\(GameConstants.wrongAnswerPenalty)s freeze)")

        freezeTickCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.freezeRemaining = max(0, self.freezeRemaining - 0.1)
            }

        freezeCancellable = Just(())
            .delay(for: .seconds(GameConstants.wrongAnswerPenalty), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.unfreezeAfterPenalty()
            }
    }

    private func unfreezeAfterPenalty() {
        isFrozen = false
        selectedAnswer = nil
        answerState = .unanswered
        freezeRemaining = 0
        freezeTickCancellable?.cancel()
        freezeTickCancellable = nil

        AppLogger.quiz.debug("Wrong answer penalty expired, UI unfrozen")
    }

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

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        freezeCancellable?.cancel()
        freezeCancellable = nil
        freezeTickCancellable?.cancel()
        freezeTickCancellable = nil
    }

    private func resetState() {
        stopTimer()
        currentQuestions = []
        currentQuestionIndex = 0
        selectedAnswer = nil
        answerState = .unanswered
        isComplete = false
        isFrozen = false
        freezeRemaining = 0
        elapsedTime = 0
        topic = ""
        isActive = false
        completionTime = nil
        startTime = nil
        arrangementAnswer = []
    }
}
