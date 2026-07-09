import SwiftUI

struct QuestionView: View {
    @ObservedObject var quizManager: QuizManager

    var onComplete: ((TimeInterval) -> Void)? = nil

    var body: some View {
        ZStack {

            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)

            if quizManager.isComplete {
                completionCard
            } else if let question = quizManager.currentQuestion {

                if question.isMCQ {
                    mcqCard(for: question)
                } else if question.isCodeArrangement {
                    arrangementCard(for: question)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quizManager.currentQuestionIndex)
        .animation(.easeInOut(duration: 0.3), value: quizManager.isComplete)
    }

    @ViewBuilder
    private func mcqCard(for question: Question) -> some View {
        VStack(alignment: .center, spacing: 24) {

            quizHeader

            Text(question.text)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeDarkTeal)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 20)

            answerGrid(for: question)
        }
        .padding(24)
        .background(Color.themePaper)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white, lineWidth: 6)
        )
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .overlay(freezeOverlay)
    }

    @ViewBuilder
    private func arrangementCard(for question: Question) -> some View {
        VStack(alignment: .center, spacing: 16) {

            quizHeader

            CodeArrangementView(quizManager: quizManager, question: question)

        }
        .padding(24)
        .background(Color.themePaper)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white, lineWidth: 6)
        )
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .overlay(freezeOverlay)
    }

    private var quizHeader: some View {
        VStack(spacing: 20) {

            Text(GameConstants.areaTopics.firstIndex(of: quizManager.topic).map { areaName(for: $0) } ?? quizManager.topic)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeDarkTeal)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 12))
                        Text(quizManager.topic)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color.themeDarkTeal)

                    Text("Question \(quizManager.currentQuestionIndex + 1)/\(quizManager.totalQuestions)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(quizManager.formattedElapsedTime)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.themeDarkTeal)
                    .monospacedDigit()
            }
        }
    }

    private func answerGrid(for question: Question) -> some View {
        let choices = question.choices ?? []

        return VStack(spacing: 16) {
            if choices.count >= 4 {
                HStack(spacing: 16) {
                    answerButton(index: 0, text: choices[0])
                    answerButton(index: 1, text: choices[1])
                }
                HStack(spacing: 16) {
                    answerButton(index: 2, text: choices[2])
                    answerButton(index: 3, text: choices[3])
                }
            }
        }
    }

    private func answerButton(index: Int, text: String) -> some View {
        Button {
            quizManager.submitAnswer(index)
        } label: {
            Text(text)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(answerTextColor(for: index))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(answerBackgroundColor(for: index))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(answerBorderColor(for: index), lineWidth: 2)
                )
                .cornerRadius(12)
        }
        .disabled(quizManager.isFrozen || quizManager.answerState == .correct)
    }

    private func answerBackgroundColor(for index: Int) -> Color {
        guard let selected = quizManager.selectedAnswer, selected == index else {
            return .white
        }
        switch quizManager.answerState {
        case .correct: return Color.green.opacity(0.2)
        case .incorrect: return Color.red.opacity(0.2)
        case .unanswered: return .white
        }
    }

    private func answerBorderColor(for index: Int) -> Color {
        guard let selected = quizManager.selectedAnswer, selected == index else {
            return Color.themeDarkTeal
        }
        switch quizManager.answerState {
        case .correct: return .green
        case .incorrect: return .red
        case .unanswered: return Color.themeDarkTeal
        }
    }

    private func answerTextColor(for index: Int) -> Color {
        guard let selected = quizManager.selectedAnswer, selected == index else {
            return Color.themeDarkTeal
        }
        switch quizManager.answerState {
        case .correct: return .green
        case .incorrect: return .red
        case .unanswered: return Color.themeDarkTeal
        }
    }

    @ViewBuilder
    private var freezeOverlay: some View {
        if quizManager.isFrozen {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.15))
                .allowsHitTesting(false)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: quizManager.isFrozen)
        }
    }

    private var completionCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)

            Text("Quiz Complete!")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeDarkTeal)

            Text(quizManager.topic)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color.themeOrange)

            VStack(spacing: 8) {
                Text("Completion Time")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.themeDarkTeal.opacity(0.8))

                Text(quizManager.formattedElapsedTime)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.themeOrange)
                    .monospacedDigit()
            }
            .padding(.top, 10)
        }
        .padding(32)
        .background(Color.themePaper)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white, lineWidth: 6)
        )
        .cornerRadius(16)
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .onAppear {
            if let time = quizManager.completionTime {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    onComplete?(time)
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func areaName(for index: Int) -> String {
        let names = ["Mountain", "Forest East", "Forest West", "River", "Village", "Center", "Armageddon Isle"]
        guard index < names.count else { return "Area \(index + 1)" }
        return names[index]
    }
}

#Preview("Quiz In Progress") {
    QuizPreviewWrapper()
}

private struct QuizPreviewWrapper: View {
    @StateObject private var quizManager = QuizManager()

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            QuestionView(quizManager: quizManager) { time in
                print("Quiz completed in \(time)s")
            }
        }
        .onAppear {

            let sampleQuestions: [Question] = [
                Question(
                    id: UUID(),
                    type: .mcq,
                    text: "What is the time complexity of binary search?",
                    choices: ["O(n)", "O(log n)", "O(n log n)", "O(1)"],
                    correctIndex: 1,
                    codeTemplate: nil,
                    options: nil,
                    correctAnswer: nil
                ),
                Question(
                    id: UUID(),
                    type: .mcq,
                    text: "Which sorting algorithm has the best average-case time complexity?",
                    choices: ["Bubble Sort", "Selection Sort", "Merge Sort", "Insertion Sort"],
                    correctIndex: 2,
                    codeTemplate: nil,
                    options: nil,
                    correctAnswer: nil
                ),
                Question(
                    id: UUID(),
                    type: .mcq,
                    text: "What data structure does BFS use?",
                    choices: ["Stack", "Queue", "Heap", "Tree"],
                    correctIndex: 1,
                    codeTemplate: nil,
                    options: nil,
                    correctAnswer: nil
                ),
                Question(
                    id: UUID(),
                    type: .codeArrangement,
                    text: "Complete the binary search midpoint calculation.",
                    choices: nil,
                    correctIndex: nil,
                    codeTemplate: [
                        "func binarySearch(_ arr: [Int], _ target: Int) {",
                        "    var low = 0, high = arr.count - 1",
                        "    while low <= high {",
                        "        _____",
                        "        if arr[mid] == target {",
                        "            _____",
                        "        } else if arr[mid] < target {",
                        "            _____",
                        "        }",
                        "    }",
                        "}"
                    ],
                    options: [
                        "let mid = (low + high) / 2",
                        "return mid",
                        "low = mid + 1",
                        "high = mid - 1"
                    ],
                    correctAnswer: [
                        "let mid = (low + high) / 2",
                        "return mid",
                        "low = mid + 1"
                    ]
                ),
                Question(
                    id: UUID(),
                    type: .codeArrangement,
                    text: "Complete the swap function.",
                    choices: nil,
                    correctIndex: nil,
                    codeTemplate: [
                        "func swap(_ a: inout Int, _ b: inout Int) {",
                        "    _____",
                        "    _____",
                        "    _____",
                        "}"
                    ],
                    options: [
                        "let temp = a",
                        "a = b",
                        "b = temp",
                        "a = a + b"
                    ],
                    correctAnswer: [
                        "let temp = a",
                        "a = b",
                        "b = temp"
                    ]
                )
            ]
            quizManager.startQuiz(topic: "Algorithms", questions: sampleQuestions)
        }
    }
}
