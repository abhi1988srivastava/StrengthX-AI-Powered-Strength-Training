import SwiftUI

// MARK: - Workout Flow View
// Entry point for workout setup: mode selection → focus slider → generate → start

struct WorkoutFlowView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @Environment(\.managedObjectContext) private var context

    enum Step {
        case modeSelection
        case focusSlider
        case preview
        case active
        case complete
    }

    @State private var currentStep: Step = .modeSelection

    var body: some View {
        ZStack {
            Color.sxBackground.ignoresSafeArea()

            switch currentStep {
            case .modeSelection:
                WorkoutModeSelectionView(viewModel: viewModel) {
                    withAnimation { currentStep = .focusSlider }
                }

            case .focusSlider:
                FocusSliderView(viewModel: viewModel) {
                    viewModel.generateWorkout()
                    withAnimation { currentStep = .preview }
                } onBack: {
                    withAnimation { currentStep = .modeSelection }
                }

            case .preview:
                WorkoutPreviewView(viewModel: viewModel) {
                    viewModel.startWorkout()
                    withAnimation { currentStep = .active }
                } onBack: {
                    withAnimation { currentStep = .focusSlider }
                } onRegenerate: {
                    viewModel.generateWorkout()
                }

            case .active:
                ActiveWorkoutView(viewModel: viewModel) {
                    viewModel.completeWorkout(context: context)
                    withAnimation { currentStep = .complete }
                } onCancel: {
                    viewModel.cancelWorkout()
                    withAnimation { currentStep = .modeSelection }
                }

            case .complete:
                WorkoutCompleteView(viewModel: viewModel) {
                    withAnimation { currentStep = .modeSelection }
                }
            }
        }
    }
}

// MARK: - Workout Mode Selection

struct WorkoutModeSelectionView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Choose Your Workout")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("Select a training style for today")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
            }
            .padding(.top, 24)

            // Mode cards
            VStack(spacing: 12) {
                ForEach(WorkoutMode.allCases) { mode in
                    WorkoutModeCard(
                        mode: mode,
                        isSelected: viewModel.selectedMode == mode
                    ) {
                        viewModel.selectedMode = mode
                        SXHaptics.selection()
                    }
                }
            }
            .padding(.horizontal, 20)

            // Muscle focus selector (shown only for muscle focus mode)
            if viewModel.selectedMode == .muscleFocus {
                VStack(spacing: 12) {
                    Text("Target Muscle")
                        .font(SXFont.subheading)
                        .foregroundColor(.sxTextPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MuscleGroup.allCases.filter { $0 != .core }) { group in
                                MuscleChip(
                                    group: group,
                                    isSelected: viewModel.focusMuscle == group
                                ) {
                                    viewModel.focusMuscle = group
                                    SXHaptics.selection()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            Spacer()

            Button("Next: Set Focus") {
                onContinue()
            }
            .buttonStyle(SXPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

struct WorkoutModeCard: View {
    let mode: WorkoutMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .sxAccent : .sxTextSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.sxAccent.opacity(0.15) : Color.sxSurfaceElevated)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(SXFont.semibold(17))
                        .foregroundColor(.sxTextPrimary)

                    Text(mode.description)
                        .font(SXFont.small)
                        .foregroundColor(.sxTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.sxAccent)
                        .font(.system(size: 20))
                }
            }
            .sxBorderedCard(isSelected: isSelected)
        }
    }
}

struct MuscleChip: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: group.icon)
                    .font(.system(size: 14))
                Text(group.displayName)
                    .font(SXFont.medium(14))
            }
            .foregroundColor(isSelected ? .white : .sxTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.sxAccent : Color.sxSurface)
            )
        }
    }
}
