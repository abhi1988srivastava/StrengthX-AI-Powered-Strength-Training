import Foundation
import CoreData

// MARK: - Adaptation Engine
// Rule-driven ML logic for workout progression and deloading.
// Analyzes workout history to make deterministic decisions about load management.

final class AdaptationEngine {
    static let shared = AdaptationEngine()

    private init() {}

    // MARK: - Configuration Constants

    private enum Config {
        // Progression triggers
        static let progressionStreakThreshold = 3          // Sessions hitting all reps → increase weight
        static let weightIncrementUpper = 2.5              // kg for upper body
        static let weightIncrementLower = 5.0              // kg for lower body
        static let repProgressionIncrement = 1             // Reps to add before weight jump

        // Deload triggers
        static let missedRepThreshold = 2                  // Sessions missing reps → consider deload
        static let deloadPercentage = 0.10                 // Reduce load by 10%
        static let consecutiveMissThreshold = 3            // Consecutive misses → forced deload
        static let deloadDurationWeeks = 1                 // Deload lasts 1 week

        // Consistency scoring
        static let weeklyConsistencyTarget = 4             // Target sessions per week
        static let consistencyStreakBonus = 5              // After 5-week streak, enable auto-progression
    }

    // MARK: - Analyze & Adapt

    /// Analyze recent workout history for a specific exercise and produce adaptation recommendations
    func analyzeExercise(
        exerciseId: String,
        recentSessions: [ExerciseHistory],
        userGoal: TrainingGoal,
        experience: ExperienceLevel
    ) -> AdaptationResult {

        guard !recentSessions.isEmpty else {
            return AdaptationResult(
                exerciseId: exerciseId,
                action: .maintain,
                reason: "No history yet. Complete a few sessions to enable adaptation."
            )
        }

        // Calculate metrics
        let completionRates = recentSessions.map { $0.completionRate }
        let avgCompletion = completionRates.reduce(0, +) / Double(completionRates.count)
        let recentTrend = calculateTrend(completionRates)
        let lastSession = recentSessions.last!
        let consecutiveCompletions = countConsecutiveCompletions(recentSessions)
        let consecutiveMisses = countConsecutiveMisses(recentSessions)

        // Decision tree
        if consecutiveMisses >= Config.consecutiveMissThreshold {
            return deloadRecommendation(
                exerciseId: exerciseId,
                lastWeight: lastSession.avgWeight,
                reason: "Missed target reps for \(consecutiveMisses) consecutive sessions. Time for a deload."
            )
        }

        if consecutiveCompletions >= Config.progressionStreakThreshold && avgCompletion >= 0.95 {
            return progressionRecommendation(
                exerciseId: exerciseId,
                lastWeight: lastSession.avgWeight,
                lastReps: lastSession.avgReps,
                goal: userGoal,
                experience: experience,
                muscleGroup: lastSession.muscleGroup
            )
        }

        if avgCompletion < 0.80 && recentTrend == .declining {
            return deloadRecommendation(
                exerciseId: exerciseId,
                lastWeight: lastSession.avgWeight,
                reason: "Performance declining. A strategic deload will help recovery."
            )
        }

        if avgCompletion >= 0.90 && consecutiveCompletions >= 2 {
            return AdaptationResult(
                exerciseId: exerciseId,
                action: .maintain,
                reason: "Solid performance. Keep pushing — progression is close.",
                suggestedWeight: lastSession.avgWeight,
                suggestedReps: Int(lastSession.avgReps)
            )
        }

        return AdaptationResult(
            exerciseId: exerciseId,
            action: .maintain,
            reason: "Building consistency. Keep hitting your targets.",
            suggestedWeight: lastSession.avgWeight,
            suggestedReps: Int(lastSession.avgReps)
        )
    }

    // MARK: - Weekly Consistency Analysis

    func analyzeConsistency(sessionsThisWeek: Int, streakWeeks: Int) -> ConsistencyInsight {
        let onTrack = sessionsThisWeek >= Config.weeklyConsistencyTarget
        let hasStreak = streakWeeks >= Config.consistencyStreakBonus

        if hasStreak && onTrack {
            return ConsistencyInsight(
                message: "Incredible \(streakWeeks)-week streak! Auto-progression enabled.",
                level: .excellent,
                streakWeeks: streakWeeks,
                enableAutoProgression: true
            )
        }

        if onTrack {
            return ConsistencyInsight(
                message: "On track this week. \(Config.weeklyConsistencyTarget - sessionsThisWeek) more to hit your target.",
                level: .good,
                streakWeeks: streakWeeks,
                enableAutoProgression: false
            )
        }

        if sessionsThisWeek > 0 {
            return ConsistencyInsight(
                message: "Showing up counts. Aim for \(Config.weeklyConsistencyTarget) sessions this week.",
                level: .fair,
                streakWeeks: 0,
                enableAutoProgression: false
            )
        }

        return ConsistencyInsight(
            message: "Time to get moving. Start with just one session today.",
            level: .needsWork,
            streakWeeks: 0,
            enableAutoProgression: false
        )
    }

    // MARK: - Volume Adjustment

    func adjustVolume(
        baseVolume: Int,
        recentFatigue: FatigueLevel,
        goal: TrainingGoal
    ) -> Int {
        switch recentFatigue {
        case .low:
            // Can handle more volume
            return min(baseVolume + 1, baseVolume + 2)
        case .moderate:
            return baseVolume
        case .high:
            // Reduce volume
            return max(2, baseVolume - 1)
        case .overreaching:
            // Significant reduction
            return max(2, Int(Double(baseVolume) * 0.7))
        }
    }

    // MARK: - Private Helpers

    private func progressionRecommendation(
        exerciseId: String,
        lastWeight: Double,
        lastReps: Double,
        goal: TrainingGoal,
        experience: ExperienceLevel,
        muscleGroup: MuscleGroup
    ) -> AdaptationResult {

        let isUpperBody = [MuscleGroup.chest, .back, .shoulders, .arms].contains(muscleGroup)
        let weightIncrement = isUpperBody ? Config.weightIncrementUpper : Config.weightIncrementLower

        // For strength: prioritize weight increase
        // For hypertrophy: try rep increase first, then weight
        // For fat loss: increase reps
        switch goal {
        case .strength:
            let newWeight = lastWeight + weightIncrement
            return AdaptationResult(
                exerciseId: exerciseId,
                action: .increase,
                reason: "Great consistency! Time to add \(weightIncrement.cleanWeight)kg.",
                suggestedWeight: newWeight,
                suggestedReps: Int(lastReps)
            )

        case .hypertrophy:
            if Int(lastReps) < goal.repRange.upperBound {
                return AdaptationResult(
                    exerciseId: exerciseId,
                    action: .increase,
                    reason: "Add 1 rep before bumping weight.",
                    suggestedWeight: lastWeight,
                    suggestedReps: Int(lastReps) + Config.repProgressionIncrement
                )
            } else {
                let newWeight = lastWeight + weightIncrement
                return AdaptationResult(
                    exerciseId: exerciseId,
                    action: .increase,
                    reason: "Rep cap reached! Increase weight by \(weightIncrement.cleanWeight)kg and reset reps.",
                    suggestedWeight: newWeight,
                    suggestedReps: goal.repRange.lowerBound
                )
            }

        case .fatLoss:
            return AdaptationResult(
                exerciseId: exerciseId,
                action: .increase,
                reason: "Great work! Add reps to increase metabolic demand.",
                suggestedWeight: lastWeight,
                suggestedReps: min(goal.repRange.upperBound, Int(lastReps) + 2)
            )
        }
    }

    private func deloadRecommendation(
        exerciseId: String,
        lastWeight: Double,
        reason: String
    ) -> AdaptationResult {
        let deloadWeight = lastWeight * (1.0 - Config.deloadPercentage)
        return AdaptationResult(
            exerciseId: exerciseId,
            action: .deload,
            reason: reason,
            suggestedWeight: (deloadWeight / 2.5).rounded() * 2.5 // Round to nearest 2.5
        )
    }

    private func countConsecutiveCompletions(_ sessions: [ExerciseHistory]) -> Int {
        var count = 0
        for session in sessions.reversed() {
            if session.completionRate >= 0.95 {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private func countConsecutiveMisses(_ sessions: [ExerciseHistory]) -> Int {
        var count = 0
        for session in sessions.reversed() {
            if session.completionRate < 0.80 {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private func calculateTrend(_ values: [Double]) -> Trend {
        guard values.count >= 3 else { return .stable }

        let recent = Array(values.suffix(3))
        let diffs = zip(recent, recent.dropFirst()).map { $1 - $0 }
        let avgDiff = diffs.reduce(0, +) / Double(diffs.count)

        if avgDiff > 0.02 { return .improving }
        if avgDiff < -0.02 { return .declining }
        return .stable
    }
}

// MARK: - Supporting Types

struct ExerciseHistory {
    let date: Date
    let exerciseId: String
    let muscleGroup: MuscleGroup
    let targetReps: Int
    let completedReps: Int
    let targetSets: Int
    let completedSets: Int
    let avgWeight: Double
    let avgReps: Double
    let maxWeight: Double

    var completionRate: Double {
        guard targetSets > 0 && targetReps > 0 else { return 0 }
        let totalTargetReps = targetSets * targetReps
        return min(1.0, Double(completedReps) / Double(totalTargetReps))
    }
}

enum Trend {
    case improving
    case stable
    case declining
}

enum FatigueLevel {
    case low
    case moderate
    case high
    case overreaching
}

struct ConsistencyInsight {
    let message: String
    let level: ConsistencyLevel
    let streakWeeks: Int
    let enableAutoProgression: Bool
}

enum ConsistencyLevel {
    case excellent
    case good
    case fair
    case needsWork

    var color: String {
        switch self {
        case .excellent: return "sxSuccess"
        case .good: return "sxAccent"
        case .fair: return "sxWarning"
        case .needsWork: return "sxDanger"
        }
    }
}
