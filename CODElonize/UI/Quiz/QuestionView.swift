import SwiftUI

/// The quiz modal overlay displayed when a player attempts to conquer an area.
///
/// This view observes a `QuizManager` instance and renders the current question,
/// answer choices, elapsed timer, and feedback states (correct/incorrect/frozen).
///
/// ## Design Decisions
/// - **No dismiss button** (EC-011): The quiz cannot be closed mid-attempt;
///   it only dismisses on completion or external cancellation (e.g. Tsunami).
/// - **3-second freeze** (EC-015): Wrong answers freeze the UI, showing a red overlay
///   and a countdown before the player can retry.
/// - **Elapsed stopwatch**: Counts up from 0:00 to record fastest completion time.
struct QuestionView: View {
    @ObservedObject var quizManager: QuizManager
    
    /// Called when the quiz finishes (all questions answered correctly).
    /// The parent view uses this to record the completion time and dismiss the overlay.
    var onComplete: ((TimeInterval) -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop (blocks interaction with game behind)
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            if quizManager.isComplete {
                completionCard
            } else if let question = quizManager.currentQuestion {
                quizCard(for: question)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quizManager.currentQuestionIndex)
        .animation(.easeInOut(duration: 0.3), value: quizManager.isComplete)
    }
    
    // MARK: - Quiz Card
    
    /// The main quiz card showing the current question and answer choices.
    @ViewBuilder
    private func quizCard(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header: Topic, progress, and timer
            quizHeader
            
            // Question text
            questionBody(for: question)
            
            // Answer grid (2×2)
            answerGrid(for: question)
        }
        .padding(24)
        .background(Color.themeDarkTeal)
        .cornerRadius(16)
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .overlay(freezeOverlay)
    }
    
    /// Header showing topic name, question counter, and elapsed timer.
    private var quizHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quizManager.topic)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.themeOrange)
                
                Text("Question \(quizManager.currentQuestionIndex + 1)/\(quizManager.totalQuestions)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(quizManager.formattedElapsedTime)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeOrange)
                .monospacedDigit()
        }
    }
    
    /// The question prompt text.
    private func questionBody(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(GameConstants.areaTopics.firstIndex(of: quizManager.topic).map {
                areaName(for: $0)
            } ?? "")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Text(question.text)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
    
    /// The 2×2 answer button grid.
    private func answerGrid(for question: Question) -> some View {
        let labels = ["A", "B", "C", "D"]
        
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                answerButton(index: 0, label: labels[0], text: question.choices[0])
                answerButton(index: 1, label: labels[1], text: question.choices[1])
            }
            HStack(spacing: 12) {
                answerButton(index: 2, label: labels[2], text: question.choices[2])
                answerButton(index: 3, label: labels[3], text: question.choices[3])
            }
        }
    }
    
    // MARK: - Answer Button
    
    /// A single answer choice button with feedback coloring.
    private func answerButton(index: Int, label: String, text: String) -> some View {
        Button {
            quizManager.submitAnswer(index)
        } label: {
            Text("\(label). \(text)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(answerTextColor(for: index))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(answerBackgroundColor(for: index))
                .cornerRadius(12)
        }
        .disabled(quizManager.isFrozen || quizManager.answerState == .correct)
    }
    
    /// Determines the background color of an answer button based on current state.
    private func answerBackgroundColor(for index: Int) -> Color {
        guard let selected = quizManager.selectedAnswer, selected == index else {
            return .white
        }
        
        switch quizManager.answerState {
        case .correct:
            return Color.green.opacity(0.9)
        case .incorrect:
            return Color.red.opacity(0.9)
        case .unanswered:
            return .white
        }
    }
    
    /// Determines the text color of an answer button based on current state.
    private func answerTextColor(for index: Int) -> Color {
        guard let selected = quizManager.selectedAnswer, selected == index else {
            return Color.themeDarkTeal
        }
        
        switch quizManager.answerState {
        case .correct, .incorrect:
            return .white
        case .unanswered:
            return Color.themeDarkTeal
        }
    }
    
    // MARK: - Freeze Overlay
    
    /// Visual overlay shown during the 3-second wrong-answer penalty.
    @ViewBuilder
    private var freezeOverlay: some View {
        if quizManager.isFrozen {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.15))
                .padding(.horizontal, 30)
                .allowsHitTesting(false)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: quizManager.isFrozen)
        }
    }
    
    // MARK: - Completion Card
    
    /// Shown briefly after all questions are answered correctly.
    private var completionCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Quiz Complete!")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            
            Text(quizManager.topic)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color.themeOrange)
            
            VStack(spacing: 8) {
                Text("Completion Time")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(quizManager.formattedElapsedTime)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.themeOrange)
                    .monospacedDigit()
            }
            .padding(.top, 10)
        }
        .padding(32)
        .background(Color.themeDarkTeal)
        .cornerRadius(16)
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .onAppear {
            // Notify parent after a short delay so the player can see their time
            if let time = quizManager.completionTime {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    onComplete?(time)
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helpers
    
    /// Maps area index to a descriptive area name for the subheading.
    private func areaName(for index: Int) -> String {
        let names = ["Mountain Area", "Forest East", "Forest West", "River Area", "Village Area", "Center Area"]
        guard index < names.count else { return "" }
        return names[index]
    }
}

// MARK: - Preview

#Preview("Quiz In Progress") {
    QuizPreviewWrapper()
}

/// A wrapper that starts a live quiz session for SwiftUI Previews.
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
            // Use sample questions directly for preview (bundle not available in previews)
            let sampleQuestions = [
                Question(
                    id: UUID(),
                    text: "What is the time complexity of binary search?",
                    choices: ["O(n)", "O(log n)", "O(n log n)", "O(1)"],
                    correctIndex: 1
                ),
                Question(
                    id: UUID(),
                    text: "Which sorting algorithm has the best average-case time complexity?",
                    choices: ["Bubble Sort", "Selection Sort", "Merge Sort", "Insertion Sort"],
                    correctIndex: 2
                ),
                Question(
                    id: UUID(),
                    text: "What data structure does BFS use?",
                    choices: ["Stack", "Queue", "Heap", "Tree"],
                    correctIndex: 1
                )
            ]
            quizManager.startQuiz(topic: "Algorithms", questions: sampleQuestions)
        }
    }
}
