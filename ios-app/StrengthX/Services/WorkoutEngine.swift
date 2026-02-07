import Foundation

// MARK: - Workout Generation Engine
// Generates structured workouts based on mode, focus distribution, and user profile.
// Deterministic, rule-driven logic — no randomness, no cloud calls.

final class WorkoutEngine {
    static let shared = WorkoutEngine()
    private let db = ExerciseDatabase.shared

    private init() {}

    // MARK: - Generate Workout

    func generateWorkout(
        mode: WorkoutMode,
        profile: UserProfile,
        dayIndex: Int = 0,
        focusMuscle: MuscleGroup? = nil
    ) -> WorkoutPlan {
        switch mode {
        case .pushPull:
            return generatePushPull(profile: profile, dayIndex: dayIndex)
        case .broSplit:
            return generateBroSplit(profile: profile, dayIndex: dayIndex)
        case .fullBody:
            return generateFullBody(profile: profile)
        case .muscleFocus:
            return generateMuscleFocus(profile: profile, muscle: focusMuscle ?? .chest)
        }
    }

    // MARK: - Push / Pull

    private func generatePushPull(profile: UserProfile, dayIndex: Int) -> WorkoutPlan {
        let isPushDay = dayIndex % 2 == 0
        let focus = profile.focusDistribution

        if isPushDay {
            let exercises = buildPushDay(profile: profile, focus: focus)
            return WorkoutPlan(
                name: "Push Day",
                mode: .pushPull,
                exercises: exercises,
                targetMuscles: [.chest, .shoulders, .arms]
            )
        } else {
            let exercises = buildPullDay(profile: profile, focus: focus)
            return WorkoutPlan(
                name: "Pull Day",
                mode: .pushPull,
                exercises: exercises,
                targetMuscles: [.back, .arms]
            )
        }
    }

    private func buildPushDay(profile: UserProfile, focus: FocusDistribution) -> [PlannedExercise] {
        var exercises: [PlannedExercise] = []
        let goal = profile.goal
        let equipment = profile.availableEquipment

        // Chest exercises (scaled by focus)
        let chestCount = volumeCount(for: focus.chest, range: 2...4, experience: profile.experience)
        let chestExercises = selectExercises(
            muscle: .chest,
            count: chestCount,
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: true
        )
        exercises += chestExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        // Shoulder exercises
        let shoulderCount = volumeCount(for: focus.shoulders, range: 1...3, experience: profile.experience)
        let shoulderExercises = selectExercises(
            muscle: .shoulders,
            count: shoulderCount,
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: true
        )
        exercises += shoulderExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        // Triceps (push accessory)
        let tricepExercises = selectExercises(
            muscle: .arms,
            count: max(1, Int(focus.arms * 3)),
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: false,
            filter: { $0.subMuscles.contains(.triceps) }
        )
        exercises += tricepExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        return exercises
    }

    private func buildPullDay(profile: UserProfile, focus: FocusDistribution) -> [PlannedExercise] {
        var exercises: [PlannedExercise] = []
        let goal = profile.goal
        let equipment = profile.availableEquipment

        // Back exercises (scaled by focus)
        let backCount = volumeCount(for: focus.back, range: 3...5, experience: profile.experience)
        let backExercises = selectExercises(
            muscle: .back,
            count: backCount,
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: true
        )
        exercises += backExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        // Biceps (pull accessory)
        let bicepExercises = selectExercises(
            muscle: .arms,
            count: max(1, Int(focus.arms * 3)),
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: false,
            filter: { $0.subMuscles.contains(.biceps) }
        )
        exercises += bicepExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        // Rear delts
        let rearDeltExercises = selectExercises(
            muscle: .shoulders,
            count: 1,
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: false,
            filter: { $0.subMuscles.contains(.rearDelt) }
        )
        exercises += rearDeltExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        return exercises
    }

    // MARK: - Bro Split

    private func generateBroSplit(profile: UserProfile, dayIndex: Int) -> WorkoutPlan {
        let muscles: [MuscleGroup] = [.chest, .back, .legs, .shoulders, .arms]
        let targetMuscle = muscles[dayIndex % muscles.count]
        let focus = profile.focusDistribution

        let exerciseCount = volumeCount(
            for: focus.value(for: targetMuscle),
            range: 4...7,
            experience: profile.experience
        )

        let selectedExercises = selectExercises(
            muscle: targetMuscle,
            count: exerciseCount,
            equipment: profile.availableEquipment,
            experience: profile.experience,
            compoundFirst: true
        )

        var planned = selectedExercises.map { plan(exercise: $0, goal: profile.goal, profile: profile) }

        // Add core finisher on non-core days
        if targetMuscle != .core {
            let coreExercise = selectExercises(
                muscle: .core,
                count: 1,
                equipment: profile.availableEquipment,
                experience: profile.experience,
                compoundFirst: false
            )
            planned += coreExercise.map { plan(exercise: $0, goal: profile.goal, profile: profile) }
        }

        return WorkoutPlan(
            name: "\(targetMuscle.displayName) Day",
            mode: .broSplit,
            exercises: planned,
            targetMuscles: [targetMuscle]
        )
    }

    // MARK: - Full Body

    private func generateFullBody(profile: UserProfile) -> WorkoutPlan {
        var exercises: [PlannedExercise] = []
        let goal = profile.goal
        let focus = profile.focusDistribution
        let equipment = profile.availableEquipment

        // One compound per major muscle group, volume scaled by focus
        let majorGroups: [MuscleGroup] = [.chest, .back, .legs, .shoulders]

        for group in majorGroups {
            let count = max(1, Int(focus.value(for: group) * 4))
            let selected = selectExercises(
                muscle: group,
                count: count,
                equipment: equipment,
                experience: profile.experience,
                compoundFirst: true
            )
            exercises += selected.map { plan(exercise: $0, goal: goal, profile: profile) }
        }

        // Arms accessory
        if focus.arms > 0.15 {
            let armExercises = selectExercises(
                muscle: .arms,
                count: 1,
                equipment: equipment,
                experience: profile.experience,
                compoundFirst: false
            )
            exercises += armExercises.map { plan(exercise: $0, goal: goal, profile: profile) }
        }

        // Core finisher
        let coreExercise = selectExercises(
            muscle: .core,
            count: 1,
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: false
        )
        exercises += coreExercise.map { plan(exercise: $0, goal: goal, profile: profile) }

        return WorkoutPlan(
            name: "Full Body",
            mode: .fullBody,
            exercises: exercises,
            targetMuscles: majorGroups
        )
    }

    // MARK: - Muscle Focus

    private func generateMuscleFocus(profile: UserProfile, muscle: MuscleGroup) -> WorkoutPlan {
        let exerciseCount = profile.experience.exercisesPerSession.upperBound
        let equipment = profile.availableEquipment
        let goal = profile.goal

        // Primary focus — more volume
        let primaryCount = Int(Double(exerciseCount) * 0.7)
        let primaryExercises = selectExercises(
            muscle: muscle,
            count: primaryCount,
            equipment: equipment,
            experience: profile.experience,
            compoundFirst: true
        )

        // Secondary — supporting work
        let secondaryMuscles = supportingMuscles(for: muscle)
        var secondaryExercises: [ExerciseDefinition] = []
        for secondary in secondaryMuscles {
            let selected = selectExercises(
                muscle: secondary,
                count: 1,
                equipment: equipment,
                experience: profile.experience,
                compoundFirst: true
            )
            secondaryExercises += selected
        }

        var planned = primaryExercises.map { plan(exercise: $0, goal: goal, profile: profile) }
        planned += secondaryExercises.map { plan(exercise: $0, goal: goal, profile: profile) }

        return WorkoutPlan(
            name: "\(muscle.displayName) Focus",
            mode: .muscleFocus,
            exercises: planned,
            targetMuscles: [muscle]
        )
    }

    // MARK: - Exercise Selection

    private func selectExercises(
        muscle: MuscleGroup,
        count: Int,
        equipment: [Equipment],
        experience: ExperienceLevel,
        compoundFirst: Bool,
        filter: ((ExerciseDefinition) -> Bool)? = nil
    ) -> [ExerciseDefinition] {
        var available = db.exercises(for: muscle, equipment: equipment)

        // Apply custom filter
        if let filter = filter {
            available = available.filter(filter)
        }

        // Filter by difficulty
        available = available.filter { ex in
            switch experience {
            case .beginner:
                return ex.difficulty == .beginner
            case .intermediate:
                return ex.difficulty != .advanced
            case .advanced:
                return true
            }
        }

        // Sort: compounds first (if requested), then by variety of sub-muscles
        if compoundFirst {
            available.sort { a, b in
                if a.isCompound != b.isCompound {
                    return a.isCompound
                }
                return a.subMuscles.count > b.subMuscles.count
            }
        }

        // Select diverse exercises (avoid hitting same sub-muscle repeatedly)
        var selected: [ExerciseDefinition] = []
        var coveredSubMuscles: Set<SubMuscleGroup> = []

        for exercise in available {
            if selected.count >= count { break }

            // Prefer exercises that cover new sub-muscles
            let newSubMuscles = Set(exercise.subMuscles).subtracting(coveredSubMuscles)
            if !newSubMuscles.isEmpty || selected.count < max(1, count / 2) {
                selected.append(exercise)
                coveredSubMuscles.formUnion(exercise.subMuscles)
            }
        }

        // If we still need more, fill from remaining
        if selected.count < count {
            let remaining = available.filter { !selected.contains($0) }
            for exercise in remaining {
                if selected.count >= count { break }
                selected.append(exercise)
            }
        }

        return Array(selected.prefix(count))
    }

    // MARK: - Planning Helpers

    private func plan(exercise: ExerciseDefinition, goal: TrainingGoal, profile: UserProfile) -> PlannedExercise {
        let sets: Int
        let reps: Int
        let rest: Int

        // Compounds get more sets, isolations get more reps
        if exercise.isCompound {
            sets = goal.setRange.upperBound
            reps = goal.repRange.lowerBound + 1
            rest = goal.restSeconds.upperBound
        } else {
            sets = goal.setRange.lowerBound
            reps = goal.repRange.upperBound
            rest = goal.restSeconds.lowerBound
        }

        // Adjust volume by experience
        let adjustedSets = max(2, Int(Double(sets) * profile.experience.volumeMultiplier))

        return PlannedExercise(
            exerciseId: exercise.id,
            name: exercise.name,
            sets: adjustedSets,
            reps: reps,
            restSeconds: rest,
            rpeTarget: (goal.rpeTarget.lowerBound + goal.rpeTarget.upperBound) / 2,
            muscleGroup: exercise.primaryMuscle
        )
    }

    private func volumeCount(for focusValue: Double, range: ClosedRange<Int>, experience: ExperienceLevel) -> Int {
        let base = Double(range.lowerBound) + focusValue * Double(range.upperBound - range.lowerBound)
        let adjusted = base * experience.volumeMultiplier
        return max(range.lowerBound, min(range.upperBound, Int(adjusted.rounded())))
    }

    private func supportingMuscles(for primary: MuscleGroup) -> [MuscleGroup] {
        switch primary {
        case .chest: return [.shoulders, .arms]
        case .back: return [.arms]
        case .legs: return [.core]
        case .shoulders: return [.arms]
        case .arms: return [.chest, .back]
        case .core: return [.legs]
        }
    }
}
