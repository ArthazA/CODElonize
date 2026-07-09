//
//  Randomizer.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import Foundation
import GameplayKit
import os

/// Provides deterministic, seeded randomization for quiz question selection.
///
/// The host generates a random seed when a player begins a quiz attempt and shares
/// it with all players attempting the same area. This guarantees that every player
/// receives the exact same questions in the same order (fairness requirement).
enum Randomizer {
    
    /// Selects a deterministic subset of questions from the pool using the provided seed.
    ///
    /// The seed ensures all players get the same randomized selection. The selected
    /// questions are also shuffled deterministically based on the same seed.
    ///
    /// - Parameters:
    ///   - pool: All available questions for the topic.
    ///   - count: Number of questions to select (typically `GameConstants.questionsPerAttempt`).
    ///   - seed: A shared seed value to ensure deterministic results across devices.
    /// - Returns: An array of exactly `count` questions, or all questions if the pool is smaller.
    static func selectQuestions(from pool: [Question], count: Int, seed: UInt64) -> [Question] {
        guard !pool.isEmpty else {
            AppLogger.quiz.warning("Empty question pool provided to Randomizer")
            return []
        }
        
        // Clamp count to available pool size
        let selectionCount = min(count, pool.count)
        
        // Use GKMersenneTwisterRandomSource for cross-platform deterministic shuffling
        let source = GKMersenneTwisterRandomSource(seed: seed)
        
        // Shuffle the entire pool deterministically
        let shuffled = source.arrayByShufflingObjects(in: pool) as! [Question]
        
        // Take the first `count` items
        let selected = Array(shuffled.prefix(selectionCount))
        
        AppLogger.quiz.info(
            "Selected \(selected.count) questions from pool of \(pool.count) (seed: \(seed))"
        )
        
        return selected
    }
    
    /// Selects a mixed set of MCQ and Code Arrangement questions deterministically.
    ///
    /// Guarantees the returned array is ordered: MCQ questions first, then Code Arrangement.
    /// Both subsets are independently shuffled using the same seed for determinism.
    ///
    /// - Parameters:
    ///   - mcqPool: All available MCQ questions for the topic.
    ///   - arrangementPool: All available Code Arrangement questions for the topic.
    ///   - mcqCount: Number of MCQ questions to select (default: `GameConstants.mcqPerAttempt`).
    ///   - arrangementCount: Number of arrangement questions (default: `GameConstants.arrangementPerAttempt`).
    ///   - seed: A shared seed value to ensure deterministic results across devices.
    /// - Returns: An ordered array of MCQ questions followed by Code Arrangement questions.
    static func selectMixedQuestions(
        mcqPool: [Question],
        arrangementPool: [Question],
        mcqCount: Int = GameConstants.mcqPerAttempt,
        arrangementCount: Int = GameConstants.arrangementPerAttempt,
        seed: UInt64
    ) -> [Question] {
        // Use the same seed but different derived seeds for each pool
        // to ensure independence while maintaining determinism
        let mcqSeed = seed
        let arrangementSeed = seed &+ 1  // Overflow-safe increment for a distinct but derived seed
        
        let selectedMCQ = selectQuestions(from: mcqPool, count: mcqCount, seed: mcqSeed)
        let selectedArrangement = selectQuestions(from: arrangementPool, count: arrangementCount, seed: arrangementSeed)
        
        let mixed = selectedMCQ + selectedArrangement
        
        AppLogger.quiz.info(
            "Mixed selection: \(selectedMCQ.count) MCQ + \(selectedArrangement.count) arrangement = \(mixed.count) total (seed: \(seed))"
        )
        
        return mixed
    }
    
    /// Generates a random seed value.
    ///
    /// The host calls this when starting a quiz session, then shares the seed
    /// with all players so they can reproduce the same question selection.
    /// - Returns: A random `UInt64` seed.
    static func generateSeed() -> UInt64 {
        return UInt64.random(in: UInt64.min...UInt64.max)
    }
}
