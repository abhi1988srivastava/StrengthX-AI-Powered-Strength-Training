import Foundation

// MARK: - Muscle Groups

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .legs: return "Legs"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .legs: return "figure.run"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        }
    }

    var subGroups: [SubMuscleGroup] {
        switch self {
        case .chest: return [.upperChest, .midChest, .lowerChest]
        case .back: return [.upperBack, .lats, .lowerBack]
        case .legs: return [.quads, .hamstrings, .glutes, .calves]
        case .shoulders: return [.frontDelt, .sideDelt, .rearDelt]
        case .arms: return [.biceps, .triceps, .forearms]
        case .core: return [.abs, .obliques]
        }
    }
}

enum SubMuscleGroup: String, Codable {
    case upperChest, midChest, lowerChest
    case upperBack, lats, lowerBack
    case quads, hamstrings, glutes, calves
    case frontDelt, sideDelt, rearDelt
    case biceps, triceps, forearms
    case abs, obliques
}

// MARK: - Workout Modes

enum WorkoutMode: String, CaseIterable, Codable, Identifiable {
    case pushPull = "push_pull"
    case broSplit = "bro_split"
    case fullBody = "full_body"
    case muscleFocus = "muscle_focus"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pushPull: return "Push / Pull"
        case .broSplit: return "Bro Split"
        case .fullBody: return "Full Body"
        case .muscleFocus: return "Muscle Focus"
        }
    }

    var description: String {
        switch self {
        case .pushPull: return "Alternate pushing and pulling movements"
        case .broSplit: return "Dedicate each day to a muscle group"
        case .fullBody: return "Hit everything in one session"
        case .muscleFocus: return "Target a specific muscle group"
        }
    }

    var icon: String {
        switch self {
        case .pushPull: return "arrow.left.arrow.right"
        case .broSplit: return "calendar"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .muscleFocus: return "scope"
        }
    }

    var daysPerWeek: ClosedRange<Int> {
        switch self {
        case .pushPull: return 4...6
        case .broSplit: return 4...6
        case .fullBody: return 3...4
        case .muscleFocus: return 3...6
        }
    }
}

// MARK: - Training Goals

enum TrainingGoal: String, CaseIterable, Codable, Identifiable {
    case strength
    case hypertrophy
    case fatLoss = "fat_loss"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Hypertrophy"
        case .fatLoss: return "Fat Loss"
        }
    }

    var description: String {
        switch self {
        case .strength: return "Lift heavier, get stronger"
        case .hypertrophy: return "Build muscle size"
        case .fatLoss: return "Burn fat, maintain muscle"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "bolt.fill"
        case .hypertrophy: return "scalemass.fill"
        case .fatLoss: return "flame.fill"
        }
    }

    // Training parameter ranges
    var repRange: ClosedRange<Int> {
        switch self {
        case .strength: return 3...6
        case .hypertrophy: return 8...12
        case .fatLoss: return 12...20
        }
    }

    var setRange: ClosedRange<Int> {
        switch self {
        case .strength: return 4...6
        case .hypertrophy: return 3...4
        case .fatLoss: return 3...4
        }
    }

    var restSeconds: ClosedRange<Int> {
        switch self {
        case .strength: return 180...300
        case .hypertrophy: return 60...120
        case .fatLoss: return 30...60
        }
    }

    var rpeTarget: ClosedRange<Double> {
        switch self {
        case .strength: return 8.0...9.5
        case .hypertrophy: return 7.0...9.0
        case .fatLoss: return 6.0...8.0
        }
    }
}

// MARK: - Experience Level

enum ExperienceLevel: String, CaseIterable, Codable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Less than 1 year of training"
        case .intermediate: return "1-3 years of consistent training"
        case .advanced: return "3+ years of serious training"
        }
    }

    var volumeMultiplier: Double {
        switch self {
        case .beginner: return 0.7
        case .intermediate: return 1.0
        case .advanced: return 1.3
        }
    }

    var exercisesPerSession: ClosedRange<Int> {
        switch self {
        case .beginner: return 4...5
        case .intermediate: return 5...7
        case .advanced: return 6...8
        }
    }
}

// MARK: - Equipment

enum Equipment: String, CaseIterable, Codable, Identifiable {
    case barbell
    case dumbbell
    case cables
    case machines
    case bodyweight
    case kettlebell
    case resistanceBands = "resistance_bands"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbells"
        case .cables: return "Cables"
        case .machines: return "Machines"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebells"
        case .resistanceBands: return "Bands"
        }
    }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .cables: return "cable.connector"
        case .machines: return "gearshape.fill"
        case .bodyweight: return "figure.stand"
        case .kettlebell: return "scalemass.fill"
        case .resistanceBands: return "circle.dashed"
        }
    }
}

// MARK: - Exercise Definition

struct ExerciseDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let primaryMuscle: MuscleGroup
    let secondaryMuscles: [MuscleGroup]
    let subMuscles: [SubMuscleGroup]
    let equipment: [Equipment]
    let isCompound: Bool
    let difficulty: ExperienceLevel
    let instructions: String

    static func == (lhs: ExerciseDefinition, rhs: ExerciseDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Workout Plan

struct WorkoutPlan: Identifiable, Codable {
    let id: UUID
    let name: String
    let mode: WorkoutMode
    let exercises: [PlannedExercise]
    let estimatedDuration: Int // minutes
    let targetMuscles: [MuscleGroup]
    let createdAt: Date

    init(name: String, mode: WorkoutMode, exercises: [PlannedExercise], targetMuscles: [MuscleGroup]) {
        self.id = UUID()
        self.name = name
        self.mode = mode
        self.exercises = exercises
        self.estimatedDuration = exercises.reduce(0) { total, exercise in
            let setTime = exercise.sets * 2 // ~2 min per set including rest
            return total + setTime
        }
        self.targetMuscles = targetMuscles
        self.createdAt = Date()
    }
}

struct PlannedExercise: Identifiable, Codable {
    let id: UUID
    let exerciseId: String
    let name: String
    let sets: Int
    let reps: Int
    let restSeconds: Int
    let suggestedWeight: Double?
    let rpeTarget: Double
    let notes: String?
    let muscleGroup: MuscleGroup

    init(
        exerciseId: String,
        name: String,
        sets: Int,
        reps: Int,
        restSeconds: Int,
        suggestedWeight: Double? = nil,
        rpeTarget: Double = 8.0,
        notes: String? = nil,
        muscleGroup: MuscleGroup
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.name = name
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.suggestedWeight = suggestedWeight
        self.rpeTarget = rpeTarget
        self.notes = notes
        self.muscleGroup = muscleGroup
    }
}

// MARK: - Logged Set

struct LoggedSet: Identifiable, Codable {
    let id: UUID
    var weight: Double
    var reps: Int
    var rpe: Double?
    var isWarmup: Bool
    var isCompleted: Bool

    init(weight: Double = 0, reps: Int = 0, rpe: Double? = nil, isWarmup: Bool = false) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isCompleted = false
    }
}

// MARK: - Focus Distribution

struct FocusDistribution: Codable, Equatable {
    var chest: Double
    var back: Double
    var legs: Double
    var shoulders: Double
    var arms: Double

    init(chest: Double = 0.2, back: Double = 0.2, legs: Double = 0.2, shoulders: Double = 0.2, arms: Double = 0.2) {
        self.chest = chest
        self.back = back
        self.legs = legs
        self.shoulders = shoulders
        self.arms = arms
    }

    /// Normalize values to sum to 1.0
    mutating func normalize() {
        let total = chest + back + legs + shoulders + arms
        guard total > 0 else {
            self = FocusDistribution()
            return
        }
        chest /= total
        back /= total
        legs /= total
        shoulders /= total
        arms /= total
    }

    func value(for group: MuscleGroup) -> Double {
        switch group {
        case .chest: return chest
        case .back: return back
        case .legs: return legs
        case .shoulders: return shoulders
        case .arms: return arms
        case .core: return 0.0 // Core is always included as accessory
        }
    }

    mutating func setValue(_ value: Double, for group: MuscleGroup) {
        switch group {
        case .chest: chest = value
        case .back: back = value
        case .legs: legs = value
        case .shoulders: shoulders = value
        case .arms: arms = value
        case .core: break
        }
    }
}

// MARK: - User Profile (Local)

struct UserProfile: Codable {
    var goal: TrainingGoal
    var experience: ExperienceLevel
    var availableEquipment: [Equipment]
    var preferredMode: WorkoutMode
    var daysPerWeek: Int
    var focusDistribution: FocusDistribution
    var bodyweight: Double? // kg
    var createdAt: Date

    init(
        goal: TrainingGoal = .hypertrophy,
        experience: ExperienceLevel = .intermediate,
        availableEquipment: [Equipment] = Equipment.allCases,
        preferredMode: WorkoutMode = .pushPull,
        daysPerWeek: Int = 4,
        focusDistribution: FocusDistribution = FocusDistribution(),
        bodyweight: Double? = nil
    ) {
        self.goal = goal
        self.experience = experience
        self.availableEquipment = availableEquipment
        self.preferredMode = preferredMode
        self.daysPerWeek = daysPerWeek
        self.focusDistribution = focusDistribution
        self.bodyweight = bodyweight
        self.createdAt = Date()
    }
}

// MARK: - Parsed Workout (from OCR)

struct ParsedWorkout: Identifiable, Codable {
    let id: UUID
    let rawText: String
    let exercises: [ParsedExercise]
    let confidence: Double
    let parsedAt: Date

    init(rawText: String, exercises: [ParsedExercise], confidence: Double) {
        self.id = UUID()
        self.rawText = rawText
        self.exercises = exercises
        self.confidence = confidence
        self.parsedAt = Date()
    }
}

struct ParsedExercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let matchedExerciseId: String?
    let sets: Int?
    let reps: Int?
    let weight: Double?
    let muscleGroup: MuscleGroup?

    init(name: String, matchedExerciseId: String? = nil, sets: Int? = nil, reps: Int? = nil, weight: Double? = nil, muscleGroup: MuscleGroup? = nil) {
        self.id = UUID()
        self.name = name
        self.matchedExerciseId = matchedExerciseId
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.muscleGroup = muscleGroup
    }
}

// MARK: - Adaptation Decision

enum AdaptationAction: String, Codable {
    case increase      // Progress - bump weight/reps
    case maintain      // Keep current parameters
    case deload        // Reduce load temporarily
    case swapExercise  // Change exercise variety
}

struct AdaptationResult: Identifiable, Codable {
    let id: UUID
    let exerciseId: String
    let action: AdaptationAction
    let reason: String
    let suggestedWeight: Double?
    let suggestedReps: Int?

    init(exerciseId: String, action: AdaptationAction, reason: String, suggestedWeight: Double? = nil, suggestedReps: Int? = nil) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.action = action
        self.reason = reason
        self.suggestedWeight = suggestedWeight
        self.suggestedReps = suggestedReps
    }
}
