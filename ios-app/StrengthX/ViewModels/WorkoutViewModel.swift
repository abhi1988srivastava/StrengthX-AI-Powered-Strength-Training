import SwiftUI
import CoreData

// MARK: - Workout ViewModel

class WorkoutViewModel: ObservableObject {
    @Published var currentPlan: WorkoutPlan?
    @Published var selectedMode: WorkoutMode = .pushPull
    @Published var focusDistribution = FocusDistribution()
    @Published var focusMuscle: MuscleGroup = .chest
    @Published var isWorkoutActive = false
    @Published var dayIndex: Int = 0

    // Active workout state
    @Published var activeExerciseIndex: Int = 0
    @Published var exerciseLogs: [String: [LoggedSet]] = [:] // exerciseId -> sets
    @Published var workoutStartTime: Date?
    @Published var workoutTimer: Int = 0
    @Published var restTimer: Int = 0
    @Published var isResting = false

    private let engine = WorkoutEngine.shared
    private let adaptation = AdaptationEngine.shared
    private var timer: Timer?

    var userProfile: UserProfile {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return UserProfile()
    }

    var currentExercise: PlannedExercise? {
        guard let plan = currentPlan,
              activeExerciseIndex < plan.exercises.count else { return nil }
        return plan.exercises[activeExerciseIndex]
    }

    var workoutProgress: Double {
        guard let plan = currentPlan, !plan.exercises.isEmpty else { return 0 }
        let completedExercises = exerciseLogs.values.filter { sets in
            sets.allSatisfy { $0.isCompleted }
        }.count
        return Double(completedExercises) / Double(plan.exercises.count)
    }

    var totalVolume: Double {
        exerciseLogs.values.flatMap { $0 }.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }

    var formattedTimer: String {
        let minutes = workoutTimer / 60
        let seconds = workoutTimer % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedRestTimer: String {
        let minutes = restTimer / 60
        let seconds = restTimer % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Generate Workout

    func generateWorkout() {
        var profile = userProfile
        profile.focusDistribution = focusDistribution

        currentPlan = engine.generateWorkout(
            mode: selectedMode,
            profile: profile,
            dayIndex: dayIndex,
            focusMuscle: selectedMode == .muscleFocus ? focusMuscle : nil
        )
    }

    // MARK: - Start Workout

    func startWorkout() {
        guard currentPlan != nil else { return }

        isWorkoutActive = true
        workoutStartTime = Date()
        activeExerciseIndex = 0
        exerciseLogs = [:]
        workoutTimer = 0

        // Initialize empty sets for each exercise
        if let plan = currentPlan {
            for exercise in plan.exercises {
                var sets: [LoggedSet] = []
                for _ in 0..<exercise.sets {
                    sets.append(LoggedSet(
                        weight: exercise.suggestedWeight ?? 0,
                        reps: exercise.reps
                    ))
                }
                exerciseLogs[exercise.exerciseId] = sets
            }
        }

        startTimer()
        SXHaptics.medium()
    }

    // MARK: - Complete Set

    func completeSet(exerciseId: String, setIndex: Int, weight: Double, reps: Int, rpe: Double?) {
        guard var sets = exerciseLogs[exerciseId], setIndex < sets.count else { return }

        sets[setIndex].weight = weight
        sets[setIndex].reps = reps
        sets[setIndex].rpe = rpe
        sets[setIndex].isCompleted = true
        exerciseLogs[exerciseId] = sets

        SXHaptics.medium()

        // Auto-start rest timer
        if let exercise = currentPlan?.exercises.first(where: { $0.exerciseId == exerciseId }) {
            startRestTimer(seconds: exercise.restSeconds)
        }
    }

    // MARK: - Navigation

    func nextExercise() {
        guard let plan = currentPlan else { return }
        if activeExerciseIndex < plan.exercises.count - 1 {
            activeExerciseIndex += 1
            SXHaptics.light()
        }
    }

    func previousExercise() {
        if activeExerciseIndex > 0 {
            activeExerciseIndex -= 1
            SXHaptics.light()
        }
    }

    // MARK: - Complete Workout

    func completeWorkout(context: NSManagedObjectContext) {
        guard let plan = currentPlan else { return }

        stopTimer()

        // Save to Core Data
        let session = CDWorkoutSession(context: context)
        session.id = UUID()
        session.name = plan.name
        session.mode = plan.mode.rawValue
        session.startedAt = workoutStartTime
        session.completedAt = Date()
        session.durationSeconds = Int32(workoutTimer)
        session.totalVolume = totalVolume

        for (index, exercise) in plan.exercises.enumerated() {
            let exerciseLog = CDExerciseLog(context: context)
            exerciseLog.id = UUID()
            exerciseLog.exerciseId = exercise.exerciseId
            exerciseLog.name = exercise.name
            exerciseLog.muscleGroup = exercise.muscleGroup.rawValue
            exerciseLog.order = Int16(index)
            exerciseLog.session = session

            if let sets = exerciseLogs[exercise.exerciseId] {
                for (setIndex, set) in sets.enumerated() where set.isCompleted {
                    let setLog = CDSetLog(context: context)
                    setLog.id = UUID()
                    setLog.setNumber = Int16(setIndex + 1)
                    setLog.weight = set.weight
                    setLog.reps = Int16(set.reps)
                    setLog.rpe = set.rpe ?? 0
                    setLog.isWarmup = set.isWarmup
                    setLog.isCompleted = true
                    setLog.exerciseLog = exerciseLog
                }
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save workout: \(error)")
        }

        // Update day index
        dayIndex += 1
        isWorkoutActive = false

        SXHaptics.success()
    }

    // MARK: - Cancel Workout

    func cancelWorkout() {
        stopTimer()
        isWorkoutActive = false
        currentPlan = nil
        exerciseLogs = [:]
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.workoutTimer += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func startRestTimer(seconds: Int) {
        isResting = true
        restTimer = seconds

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if self.restTimer > 0 {
                self.restTimer -= 1
            } else {
                self.isResting = false
                timer.invalidate()
                SXHaptics.light()
            }
        }
    }

    func skipRest() {
        isResting = false
        restTimer = 0
    }

    // MARK: - Adaptation

    func getAdaptation(for exerciseId: String, context: NSManagedObjectContext) -> AdaptationResult? {
        let fetchRequest: NSFetchRequest<CDExerciseLog> = NSFetchRequest(entityName: "CDExerciseLog")
        fetchRequest.predicate = NSPredicate(format: "exerciseId == %@", exerciseId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "session.startedAt", ascending: false)]
        fetchRequest.fetchLimit = 10

        guard let logs = try? context.fetch(fetchRequest), !logs.isEmpty else { return nil }

        let history: [ExerciseHistory] = logs.compactMap { log in
            guard let session = log.session else { return nil }
            let sets = log.setLogsArray
            let completedSets = sets.filter { $0.isCompleted }

            return ExerciseHistory(
                date: session.startedAt ?? Date(),
                exerciseId: exerciseId,
                muscleGroup: MuscleGroup(rawValue: log.muscleGroup ?? "chest") ?? .chest,
                targetReps: 10,
                completedReps: completedSets.reduce(0) { $0 + Int($1.reps) },
                targetSets: sets.count,
                completedSets: completedSets.count,
                avgWeight: completedSets.isEmpty ? 0 : completedSets.reduce(0.0) { $0 + $1.weight } / Double(completedSets.count),
                avgReps: completedSets.isEmpty ? 0 : Double(completedSets.reduce(0) { $0 + Int($1.reps) }) / Double(completedSets.count),
                maxWeight: completedSets.map { $0.weight }.max() ?? 0
            )
        }

        return adaptation.analyzeExercise(
            exerciseId: exerciseId,
            recentSessions: history.reversed(),
            userGoal: userProfile.goal,
            experience: userProfile.experience
        )
    }
}
