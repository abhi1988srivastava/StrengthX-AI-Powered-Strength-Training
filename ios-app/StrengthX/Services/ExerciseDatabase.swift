import Foundation

// MARK: - Exercise Database
// Comprehensive, curated exercise library with muscle group mappings

final class ExerciseDatabase {
    static let shared = ExerciseDatabase()

    private(set) var exercises: [ExerciseDefinition] = []
    private var exerciseMap: [String: ExerciseDefinition] = [:]

    private init() {
        buildDatabase()
        for exercise in exercises {
            exerciseMap[exercise.id] = exercise
        }
    }

    func exercise(byId id: String) -> ExerciseDefinition? {
        exerciseMap[id]
    }

    func exercises(for muscleGroup: MuscleGroup) -> [ExerciseDefinition] {
        exercises.filter { $0.primaryMuscle == muscleGroup }
    }

    func exercises(for muscleGroup: MuscleGroup, equipment: [Equipment]) -> [ExerciseDefinition] {
        exercises.filter { exercise in
            exercise.primaryMuscle == muscleGroup &&
            !exercise.equipment.filter({ equipment.contains($0) }).isEmpty
        }
    }

    func compounds(for muscleGroup: MuscleGroup) -> [ExerciseDefinition] {
        exercises.filter { $0.primaryMuscle == muscleGroup && $0.isCompound }
    }

    func isolations(for muscleGroup: MuscleGroup) -> [ExerciseDefinition] {
        exercises.filter { $0.primaryMuscle == muscleGroup && !$0.isCompound }
    }

    func search(_ query: String) -> [ExerciseDefinition] {
        let lowered = query.lowercased()
        return exercises.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.primaryMuscle.displayName.lowercased().contains(lowered)
        }
    }

    // MARK: - Fuzzy Match for OCR parsing
    func fuzzyMatch(_ input: String) -> ExerciseDefinition? {
        let cleaned = input.lowercased()
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Exact match first
        if let exact = exercises.first(where: { $0.name.lowercased() == cleaned }) {
            return exact
        }

        // Contains match
        if let contains = exercises.first(where: { $0.name.lowercased().contains(cleaned) || cleaned.contains($0.name.lowercased()) }) {
            return contains
        }

        // Keyword match - check for common exercise name patterns
        let keywords = cleaned.components(separatedBy: " ")
        var bestMatch: ExerciseDefinition?
        var bestScore = 0

        for exercise in exercises {
            let exerciseWords = exercise.name.lowercased().components(separatedBy: " ")
            let score = keywords.filter { keyword in
                exerciseWords.contains(where: { $0.contains(keyword) || keyword.contains($0) })
            }.count

            if score > bestScore && score >= max(1, keywords.count / 2) {
                bestScore = score
                bestMatch = exercise
            }
        }

        return bestMatch
    }

    // MARK: - Build Database

    private func buildDatabase() {
        exercises = [
            // ═══════════════════════════════════════════
            // CHEST EXERCISES
            // ═══════════════════════════════════════════

            ExerciseDefinition(
                id: "bench_press_flat",
                name: "Flat Bench Press",
                primaryMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms],
                subMuscles: [.midChest, .frontDelt, .triceps],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Lie on flat bench, grip bar slightly wider than shoulders. Lower to mid-chest, press up explosively."
            ),
            ExerciseDefinition(
                id: "bench_press_incline",
                name: "Incline Bench Press",
                primaryMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms],
                subMuscles: [.upperChest, .frontDelt, .triceps],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Set bench to 30-45 degrees. Lower bar to upper chest, press up."
            ),
            ExerciseDefinition(
                id: "bench_press_decline",
                name: "Decline Bench Press",
                primaryMuscle: .chest,
                secondaryMuscles: [.arms],
                subMuscles: [.lowerChest, .triceps],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Set bench to slight decline. Lower bar to lower chest, press up."
            ),
            ExerciseDefinition(
                id: "dumbbell_press_flat",
                name: "Flat Dumbbell Press",
                primaryMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms],
                subMuscles: [.midChest, .frontDelt, .triceps],
                equipment: [.dumbbell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Lie flat, press dumbbells up from chest level with slight arc."
            ),
            ExerciseDefinition(
                id: "dumbbell_press_incline",
                name: "Incline Dumbbell Press",
                primaryMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms],
                subMuscles: [.upperChest, .frontDelt, .triceps],
                equipment: [.dumbbell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Set bench to 30-45 degrees. Press dumbbells from shoulder level."
            ),
            ExerciseDefinition(
                id: "cable_fly_mid",
                name: "Cable Fly",
                primaryMuscle: .chest,
                secondaryMuscles: [],
                subMuscles: [.midChest],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand between cables set at shoulder height. Bring handles together in front of chest with slight bend in elbows."
            ),
            ExerciseDefinition(
                id: "cable_fly_low",
                name: "Low Cable Fly",
                primaryMuscle: .chest,
                secondaryMuscles: [],
                subMuscles: [.upperChest],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Set cables at lowest position. Bring handles up and together in front of upper chest."
            ),
            ExerciseDefinition(
                id: "dumbbell_fly_flat",
                name: "Dumbbell Fly",
                primaryMuscle: .chest,
                secondaryMuscles: [],
                subMuscles: [.midChest],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Lie flat, lower dumbbells in a wide arc with slight elbow bend, squeeze to return."
            ),
            ExerciseDefinition(
                id: "chest_dip",
                name: "Chest Dip",
                primaryMuscle: .chest,
                secondaryMuscles: [.arms, .shoulders],
                subMuscles: [.lowerChest, .triceps, .frontDelt],
                equipment: [.bodyweight],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Lean forward on dip bars, lower until upper arms are parallel to floor, press up."
            ),
            ExerciseDefinition(
                id: "pushup",
                name: "Push-Up",
                primaryMuscle: .chest,
                secondaryMuscles: [.arms, .shoulders, .core],
                subMuscles: [.midChest, .triceps, .frontDelt, .abs],
                equipment: [.bodyweight],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Hands shoulder-width apart, lower chest to floor, push up. Keep core tight."
            ),
            ExerciseDefinition(
                id: "machine_chest_press",
                name: "Machine Chest Press",
                primaryMuscle: .chest,
                secondaryMuscles: [.arms, .shoulders],
                subMuscles: [.midChest, .triceps],
                equipment: [.machines],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit with handles at chest height. Push forward until arms are extended."
            ),
            ExerciseDefinition(
                id: "pec_deck",
                name: "Pec Deck",
                primaryMuscle: .chest,
                secondaryMuscles: [],
                subMuscles: [.midChest],
                equipment: [.machines],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Sit with arms on pads. Squeeze pads together in front of chest."
            ),

            // ═══════════════════════════════════════════
            // BACK EXERCISES
            // ═══════════════════════════════════════════

            ExerciseDefinition(
                id: "deadlift",
                name: "Deadlift",
                primaryMuscle: .back,
                secondaryMuscles: [.legs, .core],
                subMuscles: [.lowerBack, .upperBack, .glutes, .hamstrings],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Stand with feet hip-width, grip bar outside knees. Drive through heels, extend hips and knees simultaneously."
            ),
            ExerciseDefinition(
                id: "barbell_row",
                name: "Barbell Row",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.upperBack, .lats, .biceps],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Hinge at hips, grip bar shoulder-width. Pull bar to lower chest, squeeze shoulder blades."
            ),
            ExerciseDefinition(
                id: "pullup",
                name: "Pull-Up",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.lats, .upperBack, .biceps],
                equipment: [.bodyweight],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Hang with palms facing away, wider than shoulders. Pull chin above bar."
            ),
            ExerciseDefinition(
                id: "chinup",
                name: "Chin-Up",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.lats, .biceps],
                equipment: [.bodyweight],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Hang with palms facing you, shoulder-width. Pull chin above bar."
            ),
            ExerciseDefinition(
                id: "lat_pulldown",
                name: "Lat Pulldown",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.lats, .biceps],
                equipment: [.cables],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit at lat pulldown, grip bar wide. Pull to upper chest, squeeze lats."
            ),
            ExerciseDefinition(
                id: "seated_cable_row",
                name: "Seated Cable Row",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.upperBack, .lats, .biceps],
                equipment: [.cables],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit with feet on platform. Pull handle to abdomen, squeeze shoulder blades."
            ),
            ExerciseDefinition(
                id: "dumbbell_row",
                name: "Dumbbell Row",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.lats, .upperBack, .biceps],
                equipment: [.dumbbell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "One hand on bench, other holds dumbbell. Pull to hip, squeeze lat."
            ),
            ExerciseDefinition(
                id: "tbar_row",
                name: "T-Bar Row",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.upperBack, .lats],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Straddle T-bar, grip handles. Pull to chest, squeeze upper back."
            ),
            ExerciseDefinition(
                id: "face_pull",
                name: "Face Pull",
                primaryMuscle: .back,
                secondaryMuscles: [.shoulders],
                subMuscles: [.upperBack, .rearDelt],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Set cable at face height. Pull rope to face, separating hands. Squeeze rear delts."
            ),
            ExerciseDefinition(
                id: "straight_arm_pulldown",
                name: "Straight Arm Pulldown",
                primaryMuscle: .back,
                secondaryMuscles: [],
                subMuscles: [.lats],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand facing cable at high position. With straight arms, pull bar to thighs."
            ),
            ExerciseDefinition(
                id: "machine_row",
                name: "Machine Row",
                primaryMuscle: .back,
                secondaryMuscles: [.arms],
                subMuscles: [.upperBack, .lats],
                equipment: [.machines],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit at machine, grip handles. Pull to torso, squeeze shoulder blades."
            ),
            ExerciseDefinition(
                id: "hyperextension",
                name: "Back Extension",
                primaryMuscle: .back,
                secondaryMuscles: [.legs],
                subMuscles: [.lowerBack, .glutes],
                equipment: [.bodyweight],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Position on hyperextension bench. Lower upper body, extend back to straight position."
            ),

            // ═══════════════════════════════════════════
            // LEG EXERCISES
            // ═══════════════════════════════════════════

            ExerciseDefinition(
                id: "barbell_squat",
                name: "Barbell Squat",
                primaryMuscle: .legs,
                secondaryMuscles: [.core],
                subMuscles: [.quads, .glutes, .abs],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Bar on upper back, feet shoulder-width. Squat until thighs parallel, drive up through heels."
            ),
            ExerciseDefinition(
                id: "front_squat",
                name: "Front Squat",
                primaryMuscle: .legs,
                secondaryMuscles: [.core],
                subMuscles: [.quads, .abs],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .advanced,
                instructions: "Bar on front delts in clean grip. Squat deep, keep torso upright."
            ),
            ExerciseDefinition(
                id: "leg_press",
                name: "Leg Press",
                primaryMuscle: .legs,
                secondaryMuscles: [],
                subMuscles: [.quads, .glutes],
                equipment: [.machines],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit in leg press, feet shoulder-width on platform. Lower until 90 degrees, press up."
            ),
            ExerciseDefinition(
                id: "romanian_deadlift",
                name: "Romanian Deadlift",
                primaryMuscle: .legs,
                secondaryMuscles: [.back],
                subMuscles: [.hamstrings, .glutes, .lowerBack],
                equipment: [.barbell, .dumbbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Hold bar at hips, slight knee bend. Hinge at hips, lower along legs until stretch in hamstrings."
            ),
            ExerciseDefinition(
                id: "bulgarian_split_squat",
                name: "Bulgarian Split Squat",
                primaryMuscle: .legs,
                secondaryMuscles: [.core],
                subMuscles: [.quads, .glutes],
                equipment: [.dumbbell, .bodyweight],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Rear foot on bench. Lower until front thigh is parallel, push up through front heel."
            ),
            ExerciseDefinition(
                id: "leg_extension",
                name: "Leg Extension",
                primaryMuscle: .legs,
                secondaryMuscles: [],
                subMuscles: [.quads],
                equipment: [.machines],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Sit at machine, pad on shins. Extend legs fully, squeeze quads at top."
            ),
            ExerciseDefinition(
                id: "leg_curl",
                name: "Leg Curl",
                primaryMuscle: .legs,
                secondaryMuscles: [],
                subMuscles: [.hamstrings],
                equipment: [.machines],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Lie face down, pad on calves. Curl weight up, squeeze hamstrings."
            ),
            ExerciseDefinition(
                id: "hip_thrust",
                name: "Hip Thrust",
                primaryMuscle: .legs,
                secondaryMuscles: [],
                subMuscles: [.glutes, .hamstrings],
                equipment: [.barbell, .bodyweight],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Upper back on bench, bar on hips. Drive hips up, squeeze glutes at top."
            ),
            ExerciseDefinition(
                id: "walking_lunge",
                name: "Walking Lunge",
                primaryMuscle: .legs,
                secondaryMuscles: [.core],
                subMuscles: [.quads, .glutes],
                equipment: [.dumbbell, .bodyweight],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Step forward into lunge, lower until back knee nearly touches ground. Alternate legs."
            ),
            ExerciseDefinition(
                id: "calf_raise",
                name: "Calf Raise",
                primaryMuscle: .legs,
                secondaryMuscles: [],
                subMuscles: [.calves],
                equipment: [.machines, .bodyweight, .dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand on edge of platform. Rise onto toes, pause, lower below platform level."
            ),
            ExerciseDefinition(
                id: "goblet_squat",
                name: "Goblet Squat",
                primaryMuscle: .legs,
                secondaryMuscles: [.core],
                subMuscles: [.quads, .glutes],
                equipment: [.dumbbell, .kettlebell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Hold dumbbell at chest. Squat deep between legs, keep torso upright."
            ),
            ExerciseDefinition(
                id: "hack_squat",
                name: "Hack Squat",
                primaryMuscle: .legs,
                secondaryMuscles: [],
                subMuscles: [.quads, .glutes],
                equipment: [.machines],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Position in hack squat machine. Lower until thighs parallel, press up."
            ),

            // ═══════════════════════════════════════════
            // SHOULDER EXERCISES
            // ═══════════════════════════════════════════

            ExerciseDefinition(
                id: "overhead_press",
                name: "Overhead Press",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.arms, .core],
                subMuscles: [.frontDelt, .sideDelt, .triceps],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Bar at collarbone, grip just outside shoulders. Press overhead to lockout."
            ),
            ExerciseDefinition(
                id: "dumbbell_shoulder_press",
                name: "Dumbbell Shoulder Press",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.arms],
                subMuscles: [.frontDelt, .sideDelt, .triceps],
                equipment: [.dumbbell],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit or stand, dumbbells at shoulder height. Press overhead until arms extended."
            ),
            ExerciseDefinition(
                id: "lateral_raise",
                name: "Lateral Raise",
                primaryMuscle: .shoulders,
                secondaryMuscles: [],
                subMuscles: [.sideDelt],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand with dumbbells at sides. Raise to shoulder height with slight elbow bend."
            ),
            ExerciseDefinition(
                id: "cable_lateral_raise",
                name: "Cable Lateral Raise",
                primaryMuscle: .shoulders,
                secondaryMuscles: [],
                subMuscles: [.sideDelt],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand beside low cable. Raise handle to shoulder height across body."
            ),
            ExerciseDefinition(
                id: "front_raise",
                name: "Front Raise",
                primaryMuscle: .shoulders,
                secondaryMuscles: [],
                subMuscles: [.frontDelt],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand with dumbbells in front of thighs. Raise one or both arms to shoulder height."
            ),
            ExerciseDefinition(
                id: "reverse_fly",
                name: "Reverse Fly",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.back],
                subMuscles: [.rearDelt, .upperBack],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Bend at hips, dumbbells hanging down. Raise arms out to sides, squeeze shoulder blades."
            ),
            ExerciseDefinition(
                id: "arnold_press",
                name: "Arnold Press",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.arms],
                subMuscles: [.frontDelt, .sideDelt, .triceps],
                equipment: [.dumbbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Start with palms facing you at chest. Rotate and press overhead in one smooth motion."
            ),
            ExerciseDefinition(
                id: "machine_shoulder_press",
                name: "Machine Shoulder Press",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.arms],
                subMuscles: [.frontDelt, .sideDelt, .triceps],
                equipment: [.machines],
                isCompound: true,
                difficulty: .beginner,
                instructions: "Sit at machine, grip handles at shoulder height. Press overhead."
            ),
            ExerciseDefinition(
                id: "upright_row",
                name: "Upright Row",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.arms],
                subMuscles: [.sideDelt, .frontDelt, .biceps],
                equipment: [.barbell, .dumbbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Hold bar with narrow grip. Pull up along body to chin height, elbows leading."
            ),
            ExerciseDefinition(
                id: "barbell_shrug",
                name: "Barbell Shrug",
                primaryMuscle: .shoulders,
                secondaryMuscles: [.back],
                subMuscles: [.upperBack],
                equipment: [.barbell, .dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Hold bar at hips. Shrug shoulders straight up, hold, lower."
            ),

            // ═══════════════════════════════════════════
            // ARM EXERCISES
            // ═══════════════════════════════════════════

            ExerciseDefinition(
                id: "barbell_curl",
                name: "Barbell Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.biceps],
                equipment: [.barbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand with bar at arm's length. Curl to shoulders, squeeze biceps, lower controlled."
            ),
            ExerciseDefinition(
                id: "dumbbell_curl",
                name: "Dumbbell Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.biceps],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand with dumbbells at sides. Curl alternating or together to shoulders."
            ),
            ExerciseDefinition(
                id: "hammer_curl",
                name: "Hammer Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.biceps, .forearms],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Neutral grip (palms facing each other). Curl to shoulders."
            ),
            ExerciseDefinition(
                id: "cable_curl",
                name: "Cable Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.biceps],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand facing low cable. Curl handle to shoulders with elbows pinned."
            ),
            ExerciseDefinition(
                id: "preacher_curl",
                name: "Preacher Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.biceps],
                equipment: [.barbell, .dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Sit at preacher bench, arms on pad. Curl weight up, lower slowly."
            ),
            ExerciseDefinition(
                id: "tricep_pushdown",
                name: "Tricep Pushdown",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.triceps],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Stand at high cable with bar. Push down until arms extended, squeeze triceps."
            ),
            ExerciseDefinition(
                id: "skull_crusher",
                name: "Skull Crusher",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.triceps],
                equipment: [.barbell, .dumbbell],
                isCompound: false,
                difficulty: .intermediate,
                instructions: "Lie on bench, arms extended. Lower weight to forehead by bending elbows, extend back."
            ),
            ExerciseDefinition(
                id: "overhead_tricep_extension",
                name: "Overhead Tricep Extension",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.triceps],
                equipment: [.dumbbell, .cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Hold weight overhead. Lower behind head by bending elbows, extend back up."
            ),
            ExerciseDefinition(
                id: "close_grip_bench",
                name: "Close Grip Bench Press",
                primaryMuscle: .arms,
                secondaryMuscles: [.chest],
                subMuscles: [.triceps, .midChest],
                equipment: [.barbell],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Lie on bench, grip bar shoulder-width or narrower. Press up, elbows close to body."
            ),
            ExerciseDefinition(
                id: "tricep_dip",
                name: "Tricep Dip",
                primaryMuscle: .arms,
                secondaryMuscles: [.chest, .shoulders],
                subMuscles: [.triceps, .lowerChest, .frontDelt],
                equipment: [.bodyweight],
                isCompound: true,
                difficulty: .intermediate,
                instructions: "Upright on dip bars, elbows close. Lower until 90 degrees, press up."
            ),
            ExerciseDefinition(
                id: "wrist_curl",
                name: "Wrist Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.forearms],
                equipment: [.dumbbell, .barbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Forearms on thighs, palms up. Curl wrists up, lower slowly."
            ),
            ExerciseDefinition(
                id: "concentration_curl",
                name: "Concentration Curl",
                primaryMuscle: .arms,
                secondaryMuscles: [],
                subMuscles: [.biceps],
                equipment: [.dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Sit, elbow on inner thigh. Curl dumbbell, squeeze bicep at top."
            ),

            // ═══════════════════════════════════════════
            // CORE EXERCISES
            // ═══════════════════════════════════════════

            ExerciseDefinition(
                id: "plank",
                name: "Plank",
                primaryMuscle: .core,
                secondaryMuscles: [.shoulders],
                subMuscles: [.abs, .obliques],
                equipment: [.bodyweight],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Forearms and toes on ground. Hold body straight, brace core."
            ),
            ExerciseDefinition(
                id: "hanging_leg_raise",
                name: "Hanging Leg Raise",
                primaryMuscle: .core,
                secondaryMuscles: [],
                subMuscles: [.abs],
                equipment: [.bodyweight],
                isCompound: false,
                difficulty: .intermediate,
                instructions: "Hang from bar. Raise legs to 90 degrees or higher, lower controlled."
            ),
            ExerciseDefinition(
                id: "cable_crunch",
                name: "Cable Crunch",
                primaryMuscle: .core,
                secondaryMuscles: [],
                subMuscles: [.abs],
                equipment: [.cables],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Kneel at high cable with rope. Crunch down, bringing elbows to knees."
            ),
            ExerciseDefinition(
                id: "russian_twist",
                name: "Russian Twist",
                primaryMuscle: .core,
                secondaryMuscles: [],
                subMuscles: [.obliques, .abs],
                equipment: [.bodyweight, .dumbbell],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Sit with torso leaning back, feet off ground. Rotate side to side."
            ),
            ExerciseDefinition(
                id: "ab_wheel_rollout",
                name: "Ab Wheel Rollout",
                primaryMuscle: .core,
                secondaryMuscles: [.shoulders],
                subMuscles: [.abs],
                equipment: [.bodyweight],
                isCompound: false,
                difficulty: .intermediate,
                instructions: "Kneel with ab wheel. Roll forward extending body, pull back using core."
            ),
            ExerciseDefinition(
                id: "bicycle_crunch",
                name: "Bicycle Crunch",
                primaryMuscle: .core,
                secondaryMuscles: [],
                subMuscles: [.abs, .obliques],
                equipment: [.bodyweight],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Lie on back, hands behind head. Alternate bringing elbow to opposite knee."
            ),
            ExerciseDefinition(
                id: "dead_bug",
                name: "Dead Bug",
                primaryMuscle: .core,
                secondaryMuscles: [],
                subMuscles: [.abs],
                equipment: [.bodyweight],
                isCompound: false,
                difficulty: .beginner,
                instructions: "Lie on back, arms up, knees at 90 degrees. Extend opposite arm and leg, alternate."
            ),
        ]
    }
}
