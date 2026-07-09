import SwiftUI

struct AreaAttemptsView: View {
    @EnvironmentObject var matchManager: MatchManager
    let areaIndex: Int

    private var attemptsList: [AreaAttempt] {
        matchManager.attempts(forArea: areaIndex)
    }

    private var topic: String {
        GameConstants.areaTopics[safe: areaIndex] ?? "Area \(areaIndex + 1)"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { matchManager.closeAreaInfo() }

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(Color.themeOrange)
                    Text(topic)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Attempts")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                if attemptsList.isEmpty {
                    Text("No attempts yet")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(attemptsList.enumerated()), id: \.element.id) { index, attempt in
                            attemptRow(rank: index + 1, attempt: attempt)
                        }
                    }
                }

                Button {
                    matchManager.closeAreaInfo()
                } label: {
                    Text("Close")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color.themeDarkTeal)
            .cornerRadius(16)
            .padding(.horizontal, 30)
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        }
    }

    private func attemptRow(rank: Int, attempt: AreaAttempt) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(attempt.isFastest ? Color.themeOrange : .white.opacity(0.6))
                .frame(width: 24)

            Text(attempt.player?.avatar ?? "❓")
                .font(.system(size: 20))

            Text(attempt.player?.name ?? "Unknown")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            if attempt.isFastest {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
            }

            Text(String(format: "%.1fs", attempt.time))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 4)
    }
}
