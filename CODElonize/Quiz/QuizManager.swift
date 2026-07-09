
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

    @Published private(set) var elapsedTime: TimeInterval = 0

    @Published private(set) var topic: String = ""

    @Published private(set) var isActive: Bool = false

    @Published var arrangementSlots: [String?] = []

    private(set) var completionTime: TimeInterval? = nil

    private(set) var currentSeed: UInt64 = 0

    private var timerCancellable: AnyCancellable?

    private var freezeCancellable: AnyCancellable?

    private var startTime: Date?

    var currentQuestion: Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }

    var totalQuestions: Int {
        currentQuestions.count
    }

    var isCurrentQuestionArrangement: Bool {
        currentQuestion?.isCodeArrangement ?? false
    }

    var allSlotsFilled: Bool {
        guard let question = currentQuestion, question.isCodeArrangement else { return false }
        return arrangementSlots.allSatisfy { $0 != nil } && arrangementSlots.count == question.slotCount
    }

    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
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

        // if !arrangementPool.isEmpty {
        //     currentQuestions = Randomizer.selectMixedQuestions(
        //         mcqPool: mcqPool,
        //         arrangementPool: arrangementPool,
        //         seed: currentSeed
        //     )
        // } else {

        //     AppLogger.quiz.warning("No arrangement questions for '\(topic)' — using MCQ only")
        //     currentQuestions = Randomizer.selectQuestions(
        //         from: mcqPool,
        //         count: GameConstants.mcqPerAttempt,
        //         seed: currentSeed
        //     )
        // }

        currentQuestions = Randomizer.selectQuestions(
            from: mcqPool,
            count: GameConstants.questionsPerAttempt,
            seed: currentSeed
        )


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

        AppLogger.quiz.info(
            "Quiz started (preset questions): topic=\(topic), questions=\(questions.count)"
        )
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
        guard allSlotsFilled else { return }

        let userAnswer = arrangementSlots.compactMap { $0 }
        let isCorrect = AnswerValidator.validateArrangement(userAnswer: userAnswer, for: question)

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

    @discardableResult
    func placeOption(_ option: String, inSlot slotIndex: Int) -> String? {
        guard slotIndex >= 0 && slotIndex < arrangementSlots.count else { return nil }
        guard !isFrozen else { return nil }

        if let existingSlot = arrangementSlots.firstIndex(where: { $0 == option }) {
            arrangementSlots[existingSlot] = nil
        }

        let displaced = arrangementSlots[slotIndex]

        arrangementSlots[slotIndex] = option

        return displaced
    }

    @discardableResult
    func removeFromSlot(_ slotIndex: Int) -> String? {
        guard slotIndex >= 0 && slotIndex < arrangementSlots.count else { return nil }
        guard !isFrozen else { return nil }

        let removed = arrangementSlots[slotIndex]
        arrangementSlots[slotIndex] = nil
        return removed
    }

    var availableOptions: [String] {
        guard let question = currentQuestion, question.isCodeArrangement,
              let options = question.options else { return [] }
        let placedOptions = Set(arrangementSlots.compactMap { $0 })
        return options.filter { !placedOptions.contains($0) }
    }

    func cancelQuiz() {
        AppLogger.quiz.info("Quiz cancelled for topic '\(self.topic)'")
        stopTimer()
        resetState()
    }

    private func setupArrangementSlots() {
        if let question = currentQuestion, question.isCodeArrangement {
            arrangementSlots = Array(repeating: nil, count: question.slotCount)
        } else {
            arrangementSlots = []
        }
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

        AppLogger.quiz.debug("Wrong answer penalty applied (\(GameConstants.wrongAnswerPenalty)s freeze)")

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
    }

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
        arrangementSlots = []
    }
}
