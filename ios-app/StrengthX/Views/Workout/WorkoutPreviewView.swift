import SwiftUI

// MARK: - Workout Preview View

struct WorkoutPreviewView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onStart: () -> Void
    let onBack: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                if let plan = viewModel.currentPlan {
                    VStack(spacing: 8) {
                        Text(plan.name)
                            .font(SXFont.title)
                            .foregroundColor(.sxTextPrimary)

                        HStack(spacing: 16) {
                            Label("\(plan.exercises.count) exercises", systemImage: "list.bullet")
                            Label("~\(plan.estimatedDuration)min", systemImage: "clock")
                        }
                        .font(SXFont.caption)
                        .foregroundColor(.sxTextSecondary)
                    }
                    .padding(.top, 24)

                    // Target muscles
                    HStack(spacing: 8) {
                        ForEach(plan.targetMuscles) { muscle in
                            HStack(spacing: 4) {
                                Image(systemName: muscle.icon)
                                    .font(.system(size: 12))
                                Text(muscle.displayName)
                                    .font(SXFont.small)
                            }
                            .foregroundColor(.sxAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.sxAccent.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }

                    // Exercise list
                    VStack(spacing: 12) {
                        ForEach(Array(plan.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExercisePreviewRow(exercise: exercise, index: index + 1)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 120)
            }
        }
        .background(Color.sxBackground)
        .overlay(alignment: .bottom) {
            // Bottom action buttons
            VStack(spacing: 12) {
                Button("Start Workout") {
                    onStart()
                }
                .buttonStyle(SXPrimaryButtonStyle())

                HStack(spacing: 16) {
                    Button("Regenerate") {
                        onRegenerate()
                        SXHaptics.light()
                    }
                    .font(SXFont.medium(15))
                    .foregroundColor(.sxAccent)

                    Button("Back") {
                        onBack()
                    }
                    .font(SXFont.medium(15))
                    .foregroundColor(.sxTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
            .padding(.top, 16)
            .background(
                LinearGradient(
                    colors: [Color.sxBackground, Color.sxBackground.opacity(0.9), Color.clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
    }
}

// MARK: - Exercise Preview Row

struct ExercisePreviewRow: View {
    let exercise: PlannedExercise
    let index: Int

    var body: some View {
        HStack(spacing: 14) {
            // Number
            Text("\(index)")
                .font(SXFont.semibold(14))
                .foregroundColor(.sxTextTertiary)
                .frame(width: 24)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(SXFont.semibold(16))
                    .foregroundColor(.sxTextPrimary)

                HStack(spacing: 12) {
                    Label("\(exercise.sets) sets", systemImage: "square.stack.fill")
                    Label("\(exercise.reps) reps", systemImage: "repeat")
                    Label("\(exercise.restSeconds)s rest", systemImage: "timer")
                }
                .font(SXFont.small)
                .foregroundColor(.sxTextSecondary)
            }

            Spacer()

            // Muscle tag
            Text(exercise.muscleGroup.displayName)
                .font(SXFont.small)
                .foregroundColor(.sxAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.sxAccent.opacity(0.12))
                .cornerRadius(6)
        }
        .sxCard()
    }
}
