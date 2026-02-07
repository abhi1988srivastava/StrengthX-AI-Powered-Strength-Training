import SwiftUI
import CoreData

// MARK: - Progress ViewModel

class ProgressViewModel: ObservableObject {
    @Published var recentSessions: [CDWorkoutSession] = []
    @Published var weeklyVolume: [DailyVolume] = []
    @Published var muscleGroupVolume: [MuscleGroupVolume] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var totalWorkouts: Int = 0
    @Published var currentStreak: Int = 0
    @Published var thisWeekSessions: Int = 0

    struct DailyVolume: Identifiable {
        let id = UUID()
        let date: Date
        let volume: Double
        let label: String
    }

    struct MuscleGroupVolume: Identifiable {
        let id = UUID()
        let muscleGroup: MuscleGroup
        let totalSets: Int
        let totalVolume: Double
    }

    struct PersonalRecord: Identifiable {
        let id = UUID()
        let exerciseName: String
        let exerciseId: String
        let weight: Double
        let reps: Int
        let date: Date
    }

    // MARK: - Load Data

    func loadData(context: NSManagedObjectContext) {
        loadRecentSessions(context: context)
        loadWeeklyVolume(context: context)
        loadMuscleGroupVolume(context: context)
        loadPersonalRecords(context: context)
        calculateStreak(context: context)
    }

    private func loadRecentSessions(context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDWorkoutSession> = NSFetchRequest(entityName: "CDWorkoutSession")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        request.fetchLimit = 20

        do {
            recentSessions = try context.fetch(request)
            totalWorkouts = recentSessions.count
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }

    private func loadWeeklyVolume(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()
        var volumes: [DailyVolume] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let request: NSFetchRequest<CDWorkoutSession> = NSFetchRequest(entityName: "CDWorkoutSession")
            request.predicate = NSPredicate(
                format: "startedAt >= %@ AND startedAt < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )

            let sessions = (try? context.fetch(request)) ?? []
            let totalVolume = sessions.reduce(0.0) { $0 + $1.totalVolume }

            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"

            volumes.append(DailyVolume(
                date: date,
                volume: totalVolume,
                label: formatter.string(from: date)
            ))
        }

        weeklyVolume = volumes

        // Count this week
        let weekStart = today.startOfWeek
        thisWeekSessions = recentSessions.filter { ($0.startedAt ?? Date.distantPast) >= weekStart }.count
    }

    private func loadMuscleGroupVolume(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }

        let request: NSFetchRequest<CDExerciseLog> = NSFetchRequest(entityName: "CDExerciseLog")
        request.predicate = NSPredicate(format: "session.startedAt >= %@", weekAgo as NSDate)

        guard let logs = try? context.fetch(request) else { return }

        var volumeByGroup: [MuscleGroup: (sets: Int, volume: Double)] = [:]

        for log in logs {
            guard let groupStr = log.muscleGroup,
                  let group = MuscleGroup(rawValue: groupStr) else { continue }

            let sets = log.setLogsArray
            let completedSets = sets.filter { $0.isCompleted }
            let volume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }

            let current = volumeByGroup[group] ?? (sets: 0, volume: 0)
            volumeByGroup[group] = (sets: current.sets + completedSets.count, volume: current.volume + volume)
        }

        muscleGroupVolume = MuscleGroup.allCases.compactMap { group in
            guard let data = volumeByGroup[group] else { return nil }
            return MuscleGroupVolume(
                muscleGroup: group,
                totalSets: data.sets,
                totalVolume: data.volume
            )
        }.sorted { $0.totalVolume > $1.totalVolume }
    }

    private func loadPersonalRecords(context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDSetLog> = NSFetchRequest(entityName: "CDSetLog")
        request.predicate = NSPredicate(format: "isCompleted == YES AND isWarmup == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "weight", ascending: false)]

        guard let sets = try? context.fetch(request) else { return }

        var prByExercise: [String: CDSetLog] = [:]

        for set in sets {
            guard let exerciseLog = set.exerciseLog,
                  let exerciseId = exerciseLog.exerciseId else { continue }

            if let existing = prByExercise[exerciseId] {
                if set.weight > existing.weight ||
                   (set.weight == existing.weight && set.reps > existing.reps) {
                    prByExercise[exerciseId] = set
                }
            } else {
                prByExercise[exerciseId] = set
            }
        }

        personalRecords = prByExercise.compactMap { exerciseId, set in
            guard let exerciseLog = set.exerciseLog,
                  let session = exerciseLog.session else { return nil }

            return PersonalRecord(
                exerciseName: exerciseLog.name ?? exerciseId,
                exerciseId: exerciseId,
                weight: set.weight,
                reps: Int(set.reps),
                date: session.startedAt ?? Date()
            )
        }.sorted { $0.weight > $1.weight }
    }

    private func calculateStreak(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<365 {
            let startOfDay = calendar.startOfDay(for: checkDate)
            let startOfWeek = startOfDay.startOfWeek
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { break }

            let request: NSFetchRequest<CDWorkoutSession> = NSFetchRequest(entityName: "CDWorkoutSession")
            request.predicate = NSPredicate(
                format: "startedAt >= %@ AND startedAt < %@",
                startOfWeek as NSDate,
                endOfWeek as NSDate
            )

            let count = (try? context.count(for: request)) ?? 0
            if count > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -7, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        currentStreak = streak
    }
}
