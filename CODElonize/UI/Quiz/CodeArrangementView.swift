import SwiftUI
import os

/// The Code Arrangement quiz interaction — Duolingo-style sentence builder.
///
/// Tapping a word-bank chip always fills the *next open blank* in order;
/// tapping a filled blank removes it and shifts later chips back, so the
/// answer is always a contiguous ordered sequence — the classic Duolingo flow.
struct CodeArrangementView: View {
    @ObservedObject var quizManager: QuizManager
    let question: Question

    private var slotMapping: [Int: Int] {
        guard let template = question.codeTemplate else { return [:] }
        var mapping: [Int: Int] = [:]
        var slotIndex = 0
        for (lineIndex, line) in template.enumerated() {
            if line == "_____" {
                mapping[lineIndex] = slotIndex
                slotIndex += 1
            }
        }
        return mapping
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.text)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            CodeTemplateSection(
                quizManager: quizManager,
                template: question.codeTemplate ?? [],
                slotMapping: slotMapping
            )

            WordBankSection(quizManager: quizManager, options: question.options ?? [])

            submitButton
        }
        .opacity(quizManager.isFrozen ? 0.5 : 1.0)
    }

    private var submitButton: some View {
        Button {
            quizManager.submitArrangementAnswer()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                Text("Submit")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(quizManager.isAnswerComplete ? Color.themeOrange : Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
        .disabled(!quizManager.isAnswerComplete || quizManager.isFrozen)
    }
}

// MARK: - Template Section (blanks fill in order)
struct CodeTemplateSection: View {
    @ObservedObject var quizManager: QuizManager
    let template: [String]
    let slotMapping: [Int: Int]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(template.enumerated()), id: \.offset) { lineIndex, line in
                    if line == "_____" {
                        if let slotIndex = slotMapping[lineIndex] {
                            SlotView(quizManager: quizManager, slotIndex: slotIndex)
                        }
                    } else {
                        Text(line)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
        }
        .frame(maxHeight: 220)
    }
}
// MARK: - Pressable Chip Style
/// Gives immediate visual feedback on touch-down, independent of any
/// state change — fixes chips/slots feeling unresponsive under `.plain`.
struct PressableChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.65 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Slot View (tap a filled blank to remove & shift back)
struct SlotView: View {
    @ObservedObject var quizManager: QuizManager
    let slotIndex: Int

    @State private var justTapped = false

    private var content: String? {
        quizManager.arrangementAnswer.indices.contains(slotIndex) ? quizManager.arrangementAnswer[slotIndex] : nil
    }

    var body: some View {
        HStack {
            Text("\(slotIndex + 1)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(content != nil ? Color.themeOrange : Color.white.opacity(0.2)))

            if let content {
                Text(content)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(slotTextColor)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 14))
            } else {
                Text("···")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(slotBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(slotBorderColor, style: StrokeStyle(lineWidth: 2, dash: content == nil ? [4, 4] : []))
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .scaleEffect(justTapped ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.15), value: justTapped)
        .contentShape(Rectangle())
        .onTapGesture {
            guard content != nil, !quizManager.isFrozen else { return }
            justTapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                justTapped = false
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = quizManager.removeArrangementOption(at: slotIndex)
            }
        }
    }

    private var slotBackground: Color {
        if quizManager.answerState == .correct { return Color.green.opacity(0.3) }
        if quizManager.answerState == .incorrect { return Color.red.opacity(0.3) }
        return content != nil ? Color.themeOrange.opacity(0.15) : Color.white.opacity(0.05)
    }

    private var slotBorderColor: Color {
        if quizManager.answerState == .correct { return Color.green }
        if quizManager.answerState == .incorrect { return Color.red }
        return content != nil ? Color.themeOrange.opacity(0.6) : Color.white.opacity(0.2)
    }

    private var slotTextColor: Color {
        if quizManager.answerState == .correct { return .green }
        if quizManager.answerState == .incorrect { return .red }
        return Color.themeOrange
    }
}

// MARK: - Word Bank (tap a chip to add it to the next open blank)
struct WordBankSection: View {
    @ObservedObject var quizManager: QuizManager
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Word Bank (Tap to Add)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeOrange)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let order = quizManager.arrangementAnswer.firstIndex(of: option)
                    WordChip(option: option, order: order) {
                        guard order == nil, !quizManager.isFrozen else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            _ = quizManager.appendArrangementOption(option)
                        }
                    }
                }
            }
        }
    }
}

struct WordChip: View {
    let option: String
    let order: Int?
    let action: () -> Void

    @State private var justTapped = false

    private var isPlaced: Bool { order != nil }

    var body: some View {
        HStack(spacing: 6) {
            if let order {
                Text("\(order + 1)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.themeOrange))
            }

            Text(option)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(isPlaced ? .white.opacity(0.5) : .white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(isPlaced ? Color.themeOrange.opacity(0.12) : Color.themeOrange.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPlaced ? Color.themeOrange.opacity(0.9) : Color.themeOrange.opacity(0.6), lineWidth: isPlaced ? 2 : 1.5)
        )
        .opacity(isPlaced ? 0.85 : 1.0)
        .scaleEffect(justTapped ? 0.9 : 1.0)
        .animation(.easeOut(duration: 0.15), value: justTapped)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isPlaced else { return }
            justTapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                justTapped = false
            }
            action()
        }
    }
}

//struct WordChip: View {
//    let option: String
//    let order: Int?
//    let action: () -> Void
//
//    @State private var debugFlash = false
//
//    private var isPlaced: Bool { order != nil }
//
//    var body: some View {
//        Text(option)
//            .font(.system(size: 12, weight: .semibold, design: .monospaced))
//            .foregroundColor(.white)
//            .padding(.horizontal, 10)
//            .padding(.vertical, 8)
//            .frame(maxWidth: .infinity, minHeight: 40)
//            .background(debugFlash ? Color.red : Color.themeOrange.opacity(0.3))
//            .cornerRadius(8)
//            .contentShape(Rectangle())
//            .onTapGesture {
//                print("🟢 CHIP TAPPED: \(option)")
//                debugFlash = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    debugFlash = false
//                }
//                guard !isPlaced else { return }
//                action()
//            }
//    }
//}

#Preview("Code Arrangement View") {
    let quizManager = QuizManager()
    let sampleQuestion = Question(
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
    )

    quizManager.startQuiz(topic: "Algorithms", questions: [sampleQuestion])

    return ZStack {
        Color.themeDarkTeal.edgesIgnoringSafeArea(.all)
        CodeArrangementView(quizManager: quizManager, question: sampleQuestion)
            .padding()
    }
}
