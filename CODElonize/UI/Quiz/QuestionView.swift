import SwiftUI

struct QuestionView: View {
    var body: some View {
        ZStack {
            // Blurred Background
            // Assuming this sits on top of the GameScreen
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            
            // Modal Container
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Math")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.themeOrange)
                        Text("Question 1/5")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text("00:10")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeOrange)
                }
                
                // Question text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mountain Area")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("What is 2 + 2?")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // Answers Grid
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        AnswerButton(text: "A. 1") { }
                        AnswerButton(text: "C. 3") { }
                    }
                    HStack(spacing: 12) {
                        AnswerButton(text: "B. 2") { }
                        AnswerButton(text: "D. 4") { }
                    }
                }
            }
            .padding(24)
            .background(Color.themeDarkTeal)
            .cornerRadius(16)
            .padding(.horizontal, 30)
            .shadow(radius: 10)
        }
    }
}

struct AnswerButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Color.themeDarkTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
        }
    }
}

#Preview {
    // Adding a placeholder background to simulate the game screen blur
    ZStack {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .blur(radius: 10)
            .edgesIgnoringSafeArea(.all)
        
        QuestionView()
    }
}
