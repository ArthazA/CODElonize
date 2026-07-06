//
//  TimerSystem.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import Combine
import os

/// Manages the match countdown timer.
///
/// The timer counts down from `GameConstants.matchDuration` (5 minutes) to zero.
/// When it expires, it notifies via the `onExpired` callback so the match can end.
class TimerSystem: ObservableObject {
    
    /// Remaining time in seconds.
    @Published private(set) var remainingTime: TimeInterval
    
    /// Whether the timer has reached zero.
    @Published private(set) var isExpired: Bool = false
    
    /// Whether the timer is currently running.
    @Published private(set) var isRunning: Bool = false
    
    /// Callback fired when the timer expires.
    var onExpired: (() -> Void)?
    
    /// Timer subscription.
    private var timerCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    init(duration: TimeInterval = GameConstants.matchDuration) {
        self.remainingTime = duration
    }
    
    // MARK: - Formatted Output
    
    /// Formatted time string (MM:SS).
    var formattedTime: String {
        let totalSeconds = max(0, Int(remainingTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Control
    
    /// Starts the countdown timer.
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
    
    /// Stops the countdown timer.
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false
        
        AppLogger.gameplay.info("Match timer stopped at \(self.formattedTime)")
    }
    
    /// Resets the timer to the full match duration.
    func resetTimer(duration: TimeInterval = GameConstants.matchDuration) {
        stopTimer()
        remainingTime = duration
        isExpired = false
        
        AppLogger.gameplay.info("Match timer reset to \(self.formattedTime)")
    }
    
    // MARK: - Private
    
    /// Called every second to decrement the timer.
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
