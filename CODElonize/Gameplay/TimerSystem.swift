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
///
/// FIX (README §6.2): in multiplayer, per-device independent decrementing
/// timers drift out of sync with each other over a few minutes. Instead,
/// `start(from:duration:)` takes a single shared `startTime` (e.g. from
/// `StartGameMessage`) and recomputes `remainingTime` from
/// `duration - Date().timeIntervalSince(startTime)` on every local tick.
/// This is self-correcting (no drift accumulates) and requires no extra
/// network traffic — every device just needs to agree on one epoch.
/// `startTimer()` is kept as-is for the local single-player/dev fallback
/// (README §5.8/§8.5), where there's no shared epoch to synchronize against.
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
    
    /// The shared match-start epoch, when running in shared-timestamp mode.
    /// `nil` while running in the local decrement mode (`startTimer()`).
    private var sharedStartTime: Date?
    
    /// The total match duration used for the shared-timestamp calculation.
    private var totalDuration: TimeInterval
    
    // MARK: - Initialization
    
    init(duration: TimeInterval = GameConstants.matchDuration) {
        self.remainingTime = duration
        self.totalDuration = duration
    }
    
    // MARK: - Formatted Output
    
    /// Formatted time string (MM:SS).
    var formattedTime: String {
        let totalSeconds = max(0, Int(remainingTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Shared-Timestamp Mode (multiplayer)
    
    /// Starts the countdown recomputed from a shared start timestamp.
    ///
    /// Every device calls this with the *same* `startTime` (distributed via
    /// `StartGameMessage`) so all clocks agree without any per-tick network
    /// traffic and without drifting relative to one another.
    ///
    /// - Parameters:
    ///   - startTime: The shared epoch all devices agree the match began at.
    ///   - duration: The total match duration (defaults to `GameConstants.matchDuration`).
    func start(from startTime: Date, duration: TimeInterval = GameConstants.matchDuration) {
        stopTimer()
        
        sharedStartTime = startTime
        totalDuration = duration
        isRunning = true
        isExpired = false
        
        recomputeFromSharedStart()
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recomputeFromSharedStart()
            }
        
        AppLogger.gameplay.info("Match timer started from shared start time: \(self.formattedTime)")
    }
    
    /// Recomputes `remainingTime` from the shared start timestamp. Self-correcting —
    /// never accumulates drift regardless of how long the app has been running.
    private func recomputeFromSharedStart() {
        guard let sharedStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(sharedStartTime)
        let remaining = max(0, totalDuration - elapsed)
        remainingTime = remaining
        
        if remaining <= 0 && !isExpired {
            isExpired = true
            stopTimer()
            onExpired?()
            AppLogger.gameplay.info("Match timer expired! (shared-timestamp mode)")
        }
    }
    
    // MARK: - Local Decrement Mode (single-player / dev fallback)
    
    /// Starts the countdown timer using simple per-second local decrement.
    /// Kept for the single-player/dev fallback where there is no shared
    /// epoch to synchronize against (README §5.8/§8.5).
    func startTimer() {
        guard !isRunning else { return }
        
        sharedStartTime = nil
        isRunning = true
        isExpired = false
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
        
        AppLogger.gameplay.info("Match timer started (local decrement mode): \(self.formattedTime)")
    }
    
    /// Stops the countdown timer.
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false
        
        AppLogger.gameplay.info("Match timer stopped at \(self.formattedTime)")
    }
    
    /// Resets the timer to the full match duration (local decrement mode).
    func resetTimer(duration: TimeInterval = GameConstants.matchDuration) {
        stopTimer()
        sharedStartTime = nil
        totalDuration = duration
        remainingTime = duration
        isExpired = false
        
        AppLogger.gameplay.info("Match timer reset to \(self.formattedTime)")
    }
    
    // MARK: - Private
    
    /// Called every second to decrement the timer (local decrement mode only).
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
