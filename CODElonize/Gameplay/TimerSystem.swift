
import Foundation
import Combine
import os

class TimerSystem: ObservableObject {

    @Published private(set) var remainingTime: TimeInterval

    @Published private(set) var isExpired: Bool = false

    @Published private(set) var isRunning: Bool = false

    var onExpired: (() -> Void)?

    private var timerCancellable: AnyCancellable?

    init(duration: TimeInterval = GameConstants.matchDuration) {
        self.remainingTime = duration
    }

    var formattedTime: String {
        let totalSeconds = max(0, Int(remainingTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startTimer() {
        guard !isRunning else { return }

        isRunning = true
        isExpired = false

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }

        AppLogger.gameplay.info("Match timer started: \(self.formattedTime)")
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false

        AppLogger.gameplay.info("Match timer stopped at \(self.formattedTime)")
    }

    func resetTimer(duration: TimeInterval = GameConstants.matchDuration) {
        stopTimer()
        remainingTime = duration
        isExpired = false

        AppLogger.gameplay.info("Match timer reset to \(self.formattedTime)")
    }

    private func tick() {
        remainingTime -= 1

        if remainingTime <= 0 {
            remainingTime = 0
            isExpired = true
            stopTimer()
            onExpired?()

            AppLogger.gameplay.info("Match timer expired!")
        }
    }
}
