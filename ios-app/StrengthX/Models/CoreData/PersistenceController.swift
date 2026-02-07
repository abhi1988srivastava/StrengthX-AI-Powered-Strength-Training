import CoreData

// MARK: - Core Data Stack

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StrengthX", managedObjectModel: Self.createModel())

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic Core Data Model

    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // --- CDUserProfile Entity ---
        let userProfileEntity = NSEntityDescription()
        userProfileEntity.name = "CDUserProfile"
        userProfileEntity.managedObjectClassName = "CDUserProfile"

        let upGoal = NSAttributeDescription()
        upGoal.name = "goal"
        upGoal.attributeType = .stringAttributeType

        let upExperience = NSAttributeDescription()
        upExperience.name = "experience"
        upExperience.attributeType = .stringAttributeType

        let upEquipment = NSAttributeDescription()
        upEquipment.name = "equipmentData"
        upEquipment.attributeType = .binaryDataAttributeType

        let upMode = NSAttributeDescription()
        upMode.name = "preferredMode"
        upMode.attributeType = .stringAttributeType

        let upDays = NSAttributeDescription()
        upDays.name = "daysPerWeek"
        upDays.attributeType = .integer16AttributeType
        upDays.defaultValue = 4

        let upFocus = NSAttributeDescription()
        upFocus.name = "focusData"
        upFocus.attributeType = .binaryDataAttributeType

        let upBodyweight = NSAttributeDescription()
        upBodyweight.name = "bodyweight"
        upBodyweight.attributeType = .doubleAttributeType
        upBodyweight.isOptional = true

        let upCreatedAt = NSAttributeDescription()
        upCreatedAt.name = "createdAt"
        upCreatedAt.attributeType = .dateAttributeType

        userProfileEntity.properties = [upGoal, upExperience, upEquipment, upMode, upDays, upFocus, upBodyweight, upCreatedAt]

        // --- CDWorkoutSession Entity ---
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "CDWorkoutSession"
        sessionEntity.managedObjectClassName = "CDWorkoutSession"

        let sessionId = NSAttributeDescription()
        sessionId.name = "id"
        sessionId.attributeType = .UUIDAttributeType

        let sessionName = NSAttributeDescription()
        sessionName.name = "name"
        sessionName.attributeType = .stringAttributeType

        let sessionMode = NSAttributeDescription()
        sessionMode.name = "mode"
        sessionMode.attributeType = .stringAttributeType

        let sessionStartedAt = NSAttributeDescription()
        sessionStartedAt.name = "startedAt"
        sessionStartedAt.attributeType = .dateAttributeType

        let sessionCompletedAt = NSAttributeDescription()
        sessionCompletedAt.name = "completedAt"
        sessionCompletedAt.attributeType = .dateAttributeType
        sessionCompletedAt.isOptional = true

        let sessionDuration = NSAttributeDescription()
        sessionDuration.name = "durationSeconds"
        sessionDuration.attributeType = .integer32AttributeType
        sessionDuration.defaultValue = 0

        let sessionTotalVolume = NSAttributeDescription()
        sessionTotalVolume.name = "totalVolume"
        sessionTotalVolume.attributeType = .doubleAttributeType
        sessionTotalVolume.defaultValue = 0.0

        let sessionNotes = NSAttributeDescription()
        sessionNotes.name = "notes"
        sessionNotes.attributeType = .stringAttributeType
        sessionNotes.isOptional = true

        // --- CDExerciseLog Entity ---
        let exerciseLogEntity = NSEntityDescription()
        exerciseLogEntity.name = "CDExerciseLog"
        exerciseLogEntity.managedObjectClassName = "CDExerciseLog"

        let elId = NSAttributeDescription()
        elId.name = "id"
        elId.attributeType = .UUIDAttributeType

        let elExerciseId = NSAttributeDescription()
        elExerciseId.name = "exerciseId"
        elExerciseId.attributeType = .stringAttributeType

        let elName = NSAttributeDescription()
        elName.name = "name"
        elName.attributeType = .stringAttributeType

        let elMuscleGroup = NSAttributeDescription()
        elMuscleGroup.name = "muscleGroup"
        elMuscleGroup.attributeType = .stringAttributeType

        let elOrder = NSAttributeDescription()
        elOrder.name = "order"
        elOrder.attributeType = .integer16AttributeType
        elOrder.defaultValue = 0

        // --- CDSetLog Entity ---
        let setLogEntity = NSEntityDescription()
        setLogEntity.name = "CDSetLog"
        setLogEntity.managedObjectClassName = "CDSetLog"

        let slId = NSAttributeDescription()
        slId.name = "id"
        slId.attributeType = .UUIDAttributeType

        let slSetNumber = NSAttributeDescription()
        slSetNumber.name = "setNumber"
        slSetNumber.attributeType = .integer16AttributeType

        let slWeight = NSAttributeDescription()
        slWeight.name = "weight"
        slWeight.attributeType = .doubleAttributeType
        slWeight.defaultValue = 0.0

        let slReps = NSAttributeDescription()
        slReps.name = "reps"
        slReps.attributeType = .integer16AttributeType
        slReps.defaultValue = 0

        let slRpe = NSAttributeDescription()
        slRpe.name = "rpe"
        slRpe.attributeType = .doubleAttributeType
        slRpe.isOptional = true

        let slIsWarmup = NSAttributeDescription()
        slIsWarmup.name = "isWarmup"
        slIsWarmup.attributeType = .booleanAttributeType
        slIsWarmup.defaultValue = false

        let slIsCompleted = NSAttributeDescription()
        slIsCompleted.name = "isCompleted"
        slIsCompleted.attributeType = .booleanAttributeType
        slIsCompleted.defaultValue = false

        // --- Relationships ---

        // Session -> ExerciseLogs (one-to-many)
        let sessionToExercises = NSRelationshipDescription()
        sessionToExercises.name = "exerciseLogs"
        sessionToExercises.destinationEntity = exerciseLogEntity
        sessionToExercises.deleteRule = .cascadeDeleteRule
        sessionToExercises.maxCount = 0 // to-many
        sessionToExercises.minCount = 0

        let exerciseToSession = NSRelationshipDescription()
        exerciseToSession.name = "session"
        exerciseToSession.destinationEntity = sessionEntity
        exerciseToSession.deleteRule = .nullifyDeleteRule
        exerciseToSession.maxCount = 1

        sessionToExercises.inverseRelationship = exerciseToSession
        exerciseToSession.inverseRelationship = sessionToExercises

        // ExerciseLog -> SetLogs (one-to-many)
        let exerciseToSets = NSRelationshipDescription()
        exerciseToSets.name = "setLogs"
        exerciseToSets.destinationEntity = setLogEntity
        exerciseToSets.deleteRule = .cascadeDeleteRule
        exerciseToSets.maxCount = 0
        exerciseToSets.minCount = 0

        let setToExercise = NSRelationshipDescription()
        setToExercise.name = "exerciseLog"
        setToExercise.destinationEntity = exerciseLogEntity
        setToExercise.deleteRule = .nullifyDeleteRule
        setToExercise.maxCount = 1

        exerciseToSets.inverseRelationship = setToExercise
        setToExercise.inverseRelationship = exerciseToSets

        sessionEntity.properties += [sessionId, sessionName, sessionMode, sessionStartedAt, sessionCompletedAt, sessionDuration, sessionTotalVolume, sessionNotes, sessionToExercises]
        exerciseLogEntity.properties = [elId, elExerciseId, elName, elMuscleGroup, elOrder, exerciseToSession, exerciseToSets]
        setLogEntity.properties = [slId, slSetNumber, slWeight, slReps, slRpe, slIsWarmup, slIsCompleted, setToExercise]

        model.entities = [userProfileEntity, sessionEntity, exerciseLogEntity, setLogEntity]
        return model
    }

    // MARK: - Save Context

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Preview Helper

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
}

// MARK: - NSManagedObject Subclasses

@objc(CDUserProfile)
class CDUserProfile: NSManagedObject {
    @NSManaged var goal: String?
    @NSManaged var experience: String?
    @NSManaged var equipmentData: Data?
    @NSManaged var preferredMode: String?
    @NSManaged var daysPerWeek: Int16
    @NSManaged var focusData: Data?
    @NSManaged var bodyweight: Double
    @NSManaged var createdAt: Date?

    func toUserProfile() -> UserProfile {
        let decoder = JSONDecoder()

        let equipment: [Equipment] = (try? decoder.decode([Equipment].self, from: equipmentData ?? Data())) ?? Equipment.allCases
        let focus: FocusDistribution = (try? decoder.decode(FocusDistribution.self, from: focusData ?? Data())) ?? FocusDistribution()

        return UserProfile(
            goal: TrainingGoal(rawValue: goal ?? "hypertrophy") ?? .hypertrophy,
            experience: ExperienceLevel(rawValue: experience ?? "intermediate") ?? .intermediate,
            availableEquipment: equipment,
            preferredMode: WorkoutMode(rawValue: preferredMode ?? "push_pull") ?? .pushPull,
            daysPerWeek: Int(daysPerWeek),
            focusDistribution: focus,
            bodyweight: bodyweight > 0 ? bodyweight : nil
        )
    }

    func update(from profile: UserProfile) {
        let encoder = JSONEncoder()

        goal = profile.goal.rawValue
        experience = profile.experience.rawValue
        equipmentData = try? encoder.encode(profile.availableEquipment)
        preferredMode = profile.preferredMode.rawValue
        daysPerWeek = Int16(profile.daysPerWeek)
        focusData = try? encoder.encode(profile.focusDistribution)
        bodyweight = profile.bodyweight ?? 0
        createdAt = profile.createdAt
    }
}

@objc(CDWorkoutSession)
class CDWorkoutSession: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var mode: String?
    @NSManaged var startedAt: Date?
    @NSManaged var completedAt: Date?
    @NSManaged var durationSeconds: Int32
    @NSManaged var totalVolume: Double
    @NSManaged var notes: String?
    @NSManaged var exerciseLogs: NSSet?

    var exerciseLogsArray: [CDExerciseLog] {
        let set = exerciseLogs as? Set<CDExerciseLog> ?? []
        return set.sorted { ($0.order) < ($1.order) }
    }
}

@objc(CDExerciseLog)
class CDExerciseLog: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var exerciseId: String?
    @NSManaged var name: String?
    @NSManaged var muscleGroup: String?
    @NSManaged var order: Int16
    @NSManaged var session: CDWorkoutSession?
    @NSManaged var setLogs: NSSet?

    var setLogsArray: [CDSetLog] {
        let set = setLogs as? Set<CDSetLog> ?? []
        return set.sorted { $0.setNumber < $1.setNumber }
    }
}

@objc(CDSetLog)
class CDSetLog: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var setNumber: Int16
    @NSManaged var weight: Double
    @NSManaged var reps: Int16
    @NSManaged var rpe: Double
    @NSManaged var isWarmup: Bool
    @NSManaged var isCompleted: Bool
    @NSManaged var exerciseLog: CDExerciseLog?
}
