
import Foundation
import GameplayKit
import os

enum Randomizer {

    static func selectQuestions(from pool: [Question], count: Int, seed: UInt64) -> [Question] {
        guard !pool.isEmpty else {
            AppLogger.quiz.warning("Empty question pool provided to Randomizer")
            return []
        }

        let selectionCount = min(count, pool.count)

        let source = GKMersenneTwisterRandomSource(seed: seed)

        let shuffled = source.arrayByShufflingObjects(in: pool) as! [Question]

        let selected = Array(shuffled.prefix(selectionCount))

        AppLogger.quiz.info(
            "Selected \(selected.count) questions from pool of \(pool.count) (seed: \(seed))"
        )

        return selected
    }

    static func selectMixedQuestions(
        mcqPool: [Question],
        arrangementPool: [Question],
        mcqCount: Int = GameConstants.mcqPerAttempt,
        arrangementCount: Int = GameConstants.arrangementPerAttempt,
        seed: UInt64
    ) -> [Question] {

        let mcqSeed = seed
        let arrangementSeed = seed &+ 1  

        let selectedMCQ = selectQuestions(from: mcqPool, count: mcqCount, seed: mcqSeed)
        let selectedArrangement = selectQuestions(from: arrangementPool, count: arrangementCount, seed: arrangementSeed)

        let mixed = selectedMCQ + selectedArrangement

        AppLogger.quiz.info(
            "Mixed selection: \(selectedMCQ.count) MCQ + \(selectedArrangement.count) arrangement = \(mixed.count) total (seed: \(seed))"
        )

        return mixed
    }

    static func generateSeed() -> UInt64 {
        return UInt64.random(in: UInt64.min...UInt64.max)
    }
}
