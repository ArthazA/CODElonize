import SwiftUI

struct FreezeOverlay: View {
    let remaining: TimeInterval
    let total: TimeInterval

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, remaining / total))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.25))

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)

                    Image(systemName: "snowflake")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 64, height: 64)

                Text("Frozen!")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text(String(format: "%.1fs", remaining))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

#Preview {
    ZStack {
        Color.themeDarkTeal.edgesIgnoringSafeArea(.all)
        FreezeOverlay(remaining: 1.8, total: 3)
            .frame(width: 200, height: 200)
    }
}
