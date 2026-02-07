import SwiftUI
import PhotosUI

// MARK: - Image Parser ViewModel

class ImageParserViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var parsedWorkout: ParsedWorkout?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showImagePicker = false
    @Published var showCamera = false

    private let ocrService = OCRService.shared

    // MARK: - Process Image

    func processImage() {
        guard let image = selectedImage else {
            errorMessage = "No image selected"
            return
        }

        isProcessing = true
        errorMessage = nil
        parsedWorkout = nil

        ocrService.parseWorkoutImage(image) { [weak self] result in
            guard let self = self else { return }
            self.isProcessing = false

            switch result {
            case .success(let workout):
                if workout.exercises.isEmpty {
                    self.errorMessage = "Could not identify any exercises. Try a clearer image."
                } else {
                    self.parsedWorkout = workout
                    SXHaptics.success()
                }

            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Convert to Workout Plan

    func convertToWorkoutPlan() -> WorkoutPlan? {
        guard let parsed = parsedWorkout else { return nil }

        let exercises = parsed.exercises.compactMap { exercise -> PlannedExercise? in
            return PlannedExercise(
                exerciseId: exercise.matchedExerciseId ?? exercise.name.lowercased().replacingOccurrences(of: " ", with: "_"),
                name: exercise.name,
                sets: exercise.sets ?? 3,
                reps: exercise.reps ?? 10,
                restSeconds: 90,
                suggestedWeight: exercise.weight,
                muscleGroup: exercise.muscleGroup ?? .chest
            )
        }

        guard !exercises.isEmpty else { return nil }

        let targetMuscles = Array(Set(exercises.compactMap { $0.muscleGroup }))

        return WorkoutPlan(
            name: "Imported Workout",
            mode: .muscleFocus,
            exercises: exercises,
            targetMuscles: targetMuscles
        )
    }

    // MARK: - Reset

    func reset() {
        selectedImage = nil
        parsedWorkout = nil
        errorMessage = nil
        isProcessing = false
    }
}
