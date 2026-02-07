import Foundation
import Vision
import UIKit

// MARK: - OCR Service
// Uses Apple Vision framework for on-device text recognition.
// Converts workout images (whiteboards, screenshots, trainer notes) → structured data.
// NO cloud calls. NO recommendations. Only deterministic text parsing.

final class OCRService {
    static let shared = OCRService()
    private let exerciseDB = ExerciseDatabase.shared

    private init() {}

    // MARK: - Public Interface

    /// Recognize text from a UIImage and parse it into a structured workout
    func parseWorkoutImage(_ image: UIImage, completion: @escaping (Result<ParsedWorkout, OCRError>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(.invalidImage))
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.recognitionFailed(error.localizedDescription)))
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(.failure(.noTextFound))
                }
                return
            }

            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            if recognizedText.isEmpty {
                DispatchQueue.main.async {
                    completion(.failure(.noTextFound))
                }
                return
            }

            let rawText = recognizedText.joined(separator: "\n")
            let parsedWorkout = self.parseRawText(rawText)

            DispatchQueue.main.async {
                completion(.success(parsedWorkout))
            }
        }

        // Configure for best accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.recognitionFailed(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Text Parsing (NLP Rules Engine)

    /// Parse raw OCR text into structured exercise data using rule-based NLP
    func parseRawText(_ text: String) -> ParsedWorkout {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var parsedExercises: [ParsedExercise] = []
        var totalConfidence: Double = 0

        for line in lines {
            if let parsed = parseLine(line) {
                parsedExercises.append(parsed)
                totalConfidence += parsed.matchedExerciseId != nil ? 1.0 : 0.5
            }
        }

        let avgConfidence = parsedExercises.isEmpty ? 0 : totalConfidence / Double(parsedExercises.count)

        return ParsedWorkout(
            rawText: text,
            exercises: parsedExercises,
            confidence: avgConfidence
        )
    }

    // MARK: - Line Parsing

    private func parseLine(_ line: String) -> ParsedExercise? {
        let cleaned = cleanLine(line)
        guard !cleaned.isEmpty else { return nil }

        // Skip header/title lines
        if isHeaderLine(cleaned) { return nil }

        // Extract sets x reps pattern
        let setsReps = extractSetsAndReps(from: cleaned)
        let weight = extractWeight(from: cleaned)

        // Extract exercise name (remove numbers and units)
        let exerciseName = extractExerciseName(from: cleaned)
        guard !exerciseName.isEmpty else { return nil }

        // Fuzzy match against exercise database
        let matchedExercise = exerciseDB.fuzzyMatch(exerciseName)

        return ParsedExercise(
            name: exerciseName,
            matchedExerciseId: matchedExercise?.id,
            sets: setsReps?.sets,
            reps: setsReps?.reps,
            weight: weight,
            muscleGroup: matchedExercise?.primaryMuscle ?? inferMuscleGroup(from: exerciseName)
        )
    }

    // MARK: - Text Extraction Helpers

    private func cleanLine(_ line: String) -> String {
        var cleaned = line
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "●", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "→", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove leading numbers/bullets (e.g., "1.", "1)", "A.")
        if let range = cleaned.range(of: #"^[\d]+[.)\]]?\s*"#, options: .regularExpression) {
            cleaned = String(cleaned[range.upperBound...])
        }
        if let range = cleaned.range(of: #"^[A-Za-z][.)\]]\s*"#, options: .regularExpression) {
            cleaned = String(cleaned[range.upperBound...])
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isHeaderLine(_ line: String) -> Bool {
        let headerPatterns = [
            "workout", "routine", "program", "plan", "day \\d",
            "week \\d", "monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday", "warm up", "warmup",
            "cool down", "cooldown", "date:", "name:", "client:"
        ]

        let lowered = line.lowercased()
        return headerPatterns.contains { pattern in
            lowered.range(of: pattern, options: .regularExpression) != nil && lowered.count < 20
        }
    }

    private struct SetsReps {
        let sets: Int
        let reps: Int
    }

    private func extractSetsAndReps(from text: String) -> SetsReps? {
        let lowered = text.lowercased()

        // Pattern: "3x10", "3 x 10", "3×10"
        if let match = lowered.range(of: #"(\d+)\s*[x×]\s*(\d+)"#, options: .regularExpression) {
            let matchStr = String(lowered[match])
            let numbers = matchStr.components(separatedBy: CharacterSet(charactersIn: "x× "))
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if numbers.count == 2 {
                return SetsReps(sets: numbers[0], reps: numbers[1])
            }
        }

        // Pattern: "3 sets 10 reps", "3 sets of 10"
        if let match = lowered.range(of: #"(\d+)\s*sets?\s*(?:of\s*)?(\d+)\s*reps?"#, options: .regularExpression) {
            let matchStr = String(lowered[match])
            let numbers = matchStr.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            if numbers.count >= 2 {
                return SetsReps(sets: numbers[0], reps: numbers[1])
            }
        }

        // Pattern: just "10 reps" (assume 3 sets)
        if let match = lowered.range(of: #"(\d+)\s*reps?"#, options: .regularExpression) {
            let matchStr = String(lowered[match])
            let numbers = matchStr.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            if let reps = numbers.first {
                return SetsReps(sets: 3, reps: reps)
            }
        }

        return nil
    }

    private func extractWeight(from text: String) -> Double? {
        let lowered = text.lowercased()

        // Pattern: "135lbs", "135 lbs", "60kg", "60 kg"
        let patterns = [
            #"(\d+\.?\d*)\s*(?:lbs?|pounds?)"#,
            #"(\d+\.?\d*)\s*(?:kgs?|kilos?)"#
        ]

        for pattern in patterns {
            if let match = lowered.range(of: pattern, options: .regularExpression) {
                let matchStr = String(lowered[match])
                let numbers = matchStr.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted)
                    .compactMap { Double($0) }
                if let weight = numbers.first {
                    // Convert lbs to kg if needed
                    if matchStr.contains("lb") || matchStr.contains("pound") {
                        return weight * 0.453592
                    }
                    return weight
                }
            }
        }

        return nil
    }

    private func extractExerciseName(from text: String) -> String {
        var name = text

        // Remove sets x reps patterns
        name = name.replacingOccurrences(of: #"\d+\s*[x×]\s*\d+"#, with: "", options: .regularExpression)

        // Remove weight patterns
        name = name.replacingOccurrences(of: #"\d+\.?\d*\s*(?:lbs?|kgs?|pounds?|kilos?)"#, with: "", options: .regularExpression)

        // Remove "sets/reps" words with numbers
        name = name.replacingOccurrences(of: #"\d+\s*sets?\s*(?:of\s*)?\d*\s*reps?"#, with: "", options: .regularExpression)
        name = name.replacingOccurrences(of: #"\d+\s*reps?"#, with: "", options: .regularExpression)

        // Remove RPE/RIR patterns
        name = name.replacingOccurrences(of: #"(?:rpe|rir)\s*\d+"#, with: "", options: [.regularExpression, .caseInsensitive])

        // Remove standalone numbers
        name = name.replacingOccurrences(of: #"\b\d+\b"#, with: "", options: .regularExpression)

        // Clean up whitespace
        name = name.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name
    }

    // MARK: - Muscle Group Inference (Keyword-based)

    private func inferMuscleGroup(from exerciseName: String) -> MuscleGroup? {
        let lowered = exerciseName.lowercased()

        let muscleKeywords: [(MuscleGroup, [String])] = [
            (.chest, ["bench", "chest", "pec", "fly", "push up", "pushup", "press flat", "press incline", "press decline"]),
            (.back, ["row", "pull up", "pullup", "pull down", "pulldown", "lat", "deadlift", "chin up", "chinup", "back"]),
            (.legs, ["squat", "leg", "lunge", "calf", "hamstring", "quad", "glute", "hip thrust", "deadlift"]),
            (.shoulders, ["shoulder", "overhead", "ohp", "lateral", "delt", "military", "shrug", "face pull"]),
            (.arms, ["curl", "tricep", "bicep", "arm", "extension", "pushdown", "skull", "hammer"]),
            (.core, ["ab", "core", "plank", "crunch", "twist", "dead bug"]),
        ]

        for (group, keywords) in muscleKeywords {
            if keywords.contains(where: { lowered.contains($0) }) {
                return group
            }
        }

        return nil
    }
}

// MARK: - OCR Error Types

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process image. Try a clearer photo."
        case .noTextFound:
            return "No text detected in image. Try a photo with visible text."
        case .recognitionFailed(let detail):
            return "Text recognition failed: \(detail)"
        }
    }
}
