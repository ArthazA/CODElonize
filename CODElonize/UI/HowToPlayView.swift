import SwiftUI

struct HowToPlayView: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {

            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    Spacer()
                    Text("HOW TO PLAY?")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "3FA9CD")) 
                        .shadow(color: .white, radius: 1, x: 2, y: 2)
                        .shadow(color: .white, radius: 1, x: -2, y: -2)
                        .shadow(color: .white, radius: 1, x: 2, y: -2)
                        .shadow(color: .white, radius: 1, x: -2, y: 2)
                    Spacer()
                }
                .overlay(
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "8A5C1E"))
                    }
                    , alignment: .topTrailing
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        howToRow(number: "1.", title: "Join the lobby", text: "Host a game or enter a room code to play with friends.")
                        howToRow(number: "2.", title: "Place the island", text: "Players place the AR island, then everyone taps Ready.")
                        howToRow(number: "3.", title: "Choose a territory", text: "Tap area to answer a question.")
                        howToRow(number: "4.", title: "Answer fast", text: "Answer correctly and quickly to conquer the territory.")
                        howToRow(number: "5.", title: "Conquer territories", text: "A faster correct answer can steal a territory from another player.")
                        howToRow(number: "6.", title: "Use power-ups", text: "Find one power-ups and use Earthquake, Tsunami, or Pocket Watch.")

                        Text("Important rules")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "8A5C1E"))
                            .padding(.top, 10)

                        ruleRow(title: "5-minute match", text: "Conquer as many territories as possible.")
                        ruleRow(title: "One attempt per territory", text: "Each player can answer each area only once.")
                        ruleRow(title: "Fastest correct answer wins", text: "speed matters!")
                    }
                }
            }
            .padding(24)
            .background(Color.themePaper)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 6)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private func howToRow(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "8A5C1E"))
                .frame(width: 24, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "8A5C1E"))
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "8A5C1E").opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func ruleRow(title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "8A5C1E"))
                .frame(width: 24, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "8A5C1E"))
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "8A5C1E").opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    HowToPlayView(onClose: {})
}
