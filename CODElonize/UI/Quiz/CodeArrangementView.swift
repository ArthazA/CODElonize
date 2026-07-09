import SwiftUI
internal import UniformTypeIdentifiers

struct CodeArrangementView: View {
    @ObservedObject var quizManager: QuizManager
    let question: Question

    @State private var selectedOption: String? = nil

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
                slotMapping: slotMapping,
                selectedOption: $selectedOption
            )

            OptionsSection(
                quizManager: quizManager,
                options: question.options ?? [],
                selectedOption: $selectedOption
            )

            submitButton
        }
        .opacity(quizManager.isFrozen ? 0.5 : 1.0)

        .onChange(of: quizManager.isFrozen) { frozen in
            if frozen { selectedOption = nil }
        }
    }

    private var submitButton: some View {
        Button {
            quizManager.submitArrangementAnswer()
            selectedOption = nil 
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
            .background(quizManager.allSlotsFilled ? Color.themeOrange : Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
        .disabled(!quizManager.allSlotsFilled || quizManager.isFrozen)
    }
}

struct CodeTemplateSection: View {
    @ObservedObject var quizManager: QuizManager
    let template: [String]
    let slotMapping: [Int: Int]
    @Binding var selectedOption: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(template.enumerated()), id: \.offset) { lineIndex, line in
                    if line == "_____" {
                        if let slotIndex = slotMapping[lineIndex] {
                            SlotView(
                                quizManager: quizManager,
                                slotIndex: slotIndex,
                                selectedOption: $selectedOption
                            )
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

struct SlotView: View {
    @ObservedObject var quizManager: QuizManager
    let slotIndex: Int
    @Binding var selectedOption: String?

    private var content: String? {
        quizManager.arrangementSlots.indices.contains(slotIndex) ? quizManager.arrangementSlots[slotIndex] : nil
    }

    var body: some View {
        Button {
            handleTap()
        } label: {
            HStack {
                if let content = content {
                    Text(content)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(slotTextColor)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            _ = quizManager.removeFromSlot(slotIndex)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 16))
                    }
                    .disabled(quizManager.isFrozen)
                } else {
                    Text(selectedOption != nil ? "Tap to place block" : "Select block below")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(selectedOption != nil ? Color.themeOrange : .white.opacity(0.3))
                        .italic()

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
        }
        .buttonStyle(.plain)
        .disabled(quizManager.isFrozen)
    }

    private func handleTap() {
        guard !quizManager.isFrozen else { return }

        if let option = selectedOption {

            withAnimation(.easeInOut(duration: 0.2)) {
                _ = quizManager.placeOption(option, inSlot: slotIndex)
                selectedOption = nil 
            }
        } else if content != nil {

            withAnimation(.easeInOut(duration: 0.2)) {
                _ = quizManager.removeFromSlot(slotIndex)
            }
        }
    }

    private var slotBackground: Color {
        if quizManager.answerState == .correct { return Color.green.opacity(0.3) }
        if quizManager.answerState == .incorrect { return Color.red.opacity(0.3) }
        if content != nil { return Color.themeOrange.opacity(0.15) }
        return selectedOption != nil ? Color.themeOrange.opacity(0.05) : Color.white.opacity(0.05)
    }

    private var slotBorderColor: Color {
        if quizManager.answerState == .correct { return Color.green }
        if quizManager.answerState == .incorrect { return Color.red }
        if content != nil { return Color.themeOrange.opacity(0.6) }
        return selectedOption != nil ? Color.themeOrange.opacity(0.5) : Color.white.opacity(0.2)
    }

    private var slotTextColor: Color {
        if quizManager.answerState == .correct { return .green }
        if quizManager.answerState == .incorrect { return .red }
        return Color.themeOrange
    }
}

struct OptionsSection: View {
    @ObservedObject var quizManager: QuizManager
    let options: [String]
    @Binding var selectedOption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Code Blocks (Tap to Select)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeOrange)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isPlaced = !quizManager.availableOptions.contains(option)
                    let isSelected = selectedOption == option

                    OptionBlock(
                        option: option,
                        isPlaced: isPlaced,
                        isSelected: isSelected
                    ) {
                        if !isPlaced && !quizManager.isFrozen {
                            if selectedOption == option {
                                selectedOption = nil 
                            } else {
                                selectedOption = option 
                            }
                        }
                    }
                }
            }
        }
    }
}

struct OptionBlock: View {
    let option: String
    let isPlaced: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(textColor)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(bgColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: isSelected ? 2.5 : 1.5)
                )
                .opacity(isPlaced ? 0.4 : 1.0)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isPlaced)
    }

    private var textColor: Color {
        if isPlaced { return .white.opacity(0.3) }
        return isSelected ? .black : .white
    }

    private var bgColor: Color {
        if isPlaced { return Color.white.opacity(0.05) }
        return isSelected ? Color.themeOrange : Color.themeOrange.opacity(0.3)
    }

    private var borderColor: Color {
        if isPlaced { return Color.white.opacity(0.1) }
        return isSelected ? .white : Color.themeOrange.opacity(0.6)
    }
}

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
