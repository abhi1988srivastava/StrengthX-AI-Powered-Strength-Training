import SwiftUI

// MARK: - Active Workout View
// The main "in the gym" screen for logging sets, reps, and weight in real-time.

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.managedObjectContext) private var context
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var showCancelConfirmation = false

    var body: some View {
        ZStack {
            Color.sxBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                ActiveWorkoutHeader(
                    planName: viewModel.currentPlan?.name ?? "Workout",
                    timer: viewModel.formattedTimer,
                    progress: viewModel.workoutProgress,
                    onCancel: { showCancelConfirmation = true }
                )

                // Exercise pager
                if let plan = viewModel.currentPlan {
                    TabView(selection: $viewModel.activeExerciseIndex) {
                        ForEach(Array(plan.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ActiveExerciseCard(
                                exercise: exercise,
                                sets: Binding(
                                    get: { viewModel.exerciseLogs[exercise.exerciseId] ?? [] },
                                    set: { viewModel.exerciseLogs[exercise.exerciseId] = $0 }
                                ),
                                exerciseNumber: index + 1,
                                totalExercises: plan.exercises.count,
                                adaptation: viewModel.getAdaptation(for: exercise.exerciseId, context: context),
                                onCompleteSet: { setIndex, weight, reps, rpe in
                                    viewModel.completeSet(
                                        exerciseId: exercise.exerciseId,
                                        setIndex: setIndex,
                                        weight: weight,
                                        reps: reps,
                                        rpe: rpe
                                    )
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }

                // Rest timer overlay
                if viewModel.isResting {
                    RestTimerView(
                        timeRemaining: viewModel.formattedRestTimer,
                        onSkip: { viewModel.skipRest() }
                    )
                }

                // Bottom bar
                ActiveWorkoutFooter(
                    viewModel: viewModel,
                    onComplete: onComplete
                )
            }
        }
        .alert("Cancel Workout?", isPresented: $showCancelConfirmation) {
            Button("Cancel Workout", role: .destructive) {
                onCancel()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be lost.")
        }
    }
}

// MARK: - Active Workout Header

struct ActiveWorkoutHeader: View {
    let planName: String
    let timer: String
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.sxTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.sxSurface)
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(planName)
                        .font(SXFont.semibold(16))
                        .foregroundColor(.sxTextPrimary)

                    Text(timer)
                        .font(SXFont.medium(14))
                        .foregroundColor(.sxAccent)
                }

                Spacer()

                // Placeholder for symmetry
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)

            ProgressView(value: progress)
                .tint(Color.sxAccent)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(Color.sxBackground)
    }
}

// MARK: - Active Exercise Card

struct ActiveExerciseCard: View {
    let exercise: PlannedExercise
    @Binding var sets: [LoggedSet]
    let exerciseNumber: Int
    let totalExercises: Int
    let adaptation: AdaptationResult?
    let onCompleteSet: (Int, Double, Int, Double?) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Exercise header
                VStack(spacing: 6) {
                    Text("\(exerciseNumber) / \(totalExercises)")
                        .font(SXFont.small)
                        .foregroundColor(.sxTextTertiary)

                    Text(exercise.name)
                        .font(SXFont.heading)
                        .foregroundColor(.sxTextPrimary)

                    HStack(spacing: 16) {
                        Label("\(exercise.sets)x\(exercise.reps)", systemImage: "square.stack.fill")
                        Label("RPE \(String(format: "%.0f", exercise.rpeTarget))", systemImage: "gauge.medium")
                    }
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
                }

                // Adaptation insight
                if let adaptation = adaptation {
                    AdaptationInsightView(result: adaptation)
                }

                // Set logging
                VStack(spacing: 8) {
                    // Column headers
                    HStack {
                        Text("SET")
                            .frame(width: 40)
                        Text("WEIGHT")
                            .frame(maxWidth: .infinity)
                        Text("REPS")
                            .frame(maxWidth: .infinity)
                        Text("")
                            .frame(width: 50)
                    }
                    .font(SXFont.small)
                    .foregroundColor(.sxTextTertiary)

                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        SetLogRow(
                            setNumber: index + 1,
                            set: $sets[index],
                            targetReps: exercise.reps,
                            onComplete: {
                                onCompleteSet(index, sets[index].weight, sets[index].reps, sets[index].rpe)
                            }
                        )
                    }

                    // Add set button
                    Button {
                        let lastSet = sets.last
                        sets.append(LoggedSet(
                            weight: lastSet?.weight ?? 0,
                            reps: lastSet?.reps ?? exercise.reps
                        ))
                        SXHaptics.light()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Set")
                        }
                        .font(SXFont.medium(14))
                        .foregroundColor(.sxAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.sxAccent.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .sxCard()

                // Notes
                if let notes = exercise.notes {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.sxAccent)
                        Text(notes)
                            .font(SXFont.caption)
                            .foregroundColor(.sxTextSecondary)
                    }
                    .sxCard()
                }

                Spacer(minLength: 140)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

// MARK: - Set Log Row

struct SetLogRow: View {
    let setNumber: Int
    @Binding var set: LoggedSet
    let targetReps: Int
    let onComplete: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            // Set number
            Text("\(setNumber)")
                .font(SXFont.semibold(15))
                .foregroundColor(set.isCompleted ? .sxSuccess : .sxTextSecondary)
                .frame(width: 40)

            // Weight input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .font(SXFont.semibold(16))
                .foregroundColor(.sxTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .background(Color.sxSurfaceElevated)
                .cornerRadius(8)
                .onChange(of: weightText) { value in
                    set.weight = Double(value) ?? 0
                }

            // Reps input
            TextField("\(targetReps)", text: $repsText)
                .keyboardType(.numberPad)
                .font(SXFont.semibold(16))
                .foregroundColor(.sxTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .background(Color.sxSurfaceElevated)
                .cornerRadius(8)
                .onChange(of: repsText) { value in
                    set.reps = Int(value) ?? 0
                }

            // Complete button
            Button {
                if !set.isCompleted {
                    if set.weight == 0 { set.weight = Double(weightText) ?? 0 }
                    if set.reps == 0 { set.reps = Int(repsText) ?? targetReps }
                    onComplete()
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(set.isCompleted ? .sxSuccess : .sxTextTertiary)
            }
            .frame(width: 50)
        }
        .padding(.vertical, 4)
        .opacity(set.isCompleted ? 0.7 : 1.0)
        .onAppear {
            if set.weight > 0 { weightText = set.weight.cleanWeight }
            if set.reps > 0 { repsText = "\(set.reps)" }
        }
    }
}

// MARK: - Adaptation Insight

struct AdaptationInsightView: View {
    let result: AdaptationResult

    private var color: Color {
        switch result.action {
        case .increase: return .sxSuccess
        case .maintain: return .sxAccent
        case .deload: return .sxWarning
        case .swapExercise: return .sxAccentSecondary
        }
    }

    private var icon: String {
        switch result.action {
        case .increase: return "arrow.up.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .deload: return "arrow.down.circle.fill"
        case .swapExercise: return "arrow.triangle.2.circlepath"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.reason)
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)

                if let weight = result.suggestedWeight {
                    Text("Suggested: \(weight.cleanWeight)kg")
                        .font(SXFont.semibold(13))
                        .foregroundColor(color)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Rest Timer

struct RestTimerView: View {
    let timeRemaining: String
    let onSkip: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.sxAccent)

            Text("Rest: \(timeRemaining)")
                .font(SXFont.semibold(16))
                .foregroundColor(.sxTextPrimary)

            Spacer()

            Button("Skip") {
                onSkip()
            }
            .font(SXFont.medium(14))
            .foregroundColor(.sxAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.sxAccent.opacity(0.12))
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.sxSurface)
    }
}

// MARK: - Active Workout Footer

struct ActiveWorkoutFooter: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Navigation
            HStack(spacing: 16) {
                Button {
                    viewModel.previousExercise()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(viewModel.activeExerciseIndex > 0 ? .sxTextPrimary : .sxTextTertiary)
                        .frame(width: 48, height: 48)
                        .background(Color.sxSurface)
                        .clipShape(Circle())
                }
                .disabled(viewModel.activeExerciseIndex == 0)

                // Volume display
                VStack(spacing: 2) {
                    Text("Volume")
                        .font(SXFont.small)
                        .foregroundColor(.sxTextTertiary)
                    Text("\(viewModel.totalVolume.cleanWeight) kg")
                        .font(SXFont.semibold(16))
                        .foregroundColor(.sxTextPrimary)
                }
                .frame(maxWidth: .infinity)

                Button {
                    viewModel.nextExercise()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(
                            viewModel.activeExerciseIndex < (viewModel.currentPlan?.exercises.count ?? 1) - 1
                            ? .sxTextPrimary : .sxTextTertiary
                        )
                        .frame(width: 48, height: 48)
                        .background(Color.sxSurface)
                        .clipShape(Circle())
                }
                .disabled(viewModel.activeExerciseIndex >= (viewModel.currentPlan?.exercises.count ?? 1) - 1)
            }

            // Finish button
            Button("Finish Workout") {
                onComplete()
            }
            .buttonStyle(SXPrimaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
        .padding(.top, 8)
        .background(Color.sxBackground)
    }
}
