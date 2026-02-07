import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.managedObjectContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.sxBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if viewModel.currentStep != .welcome && viewModel.currentStep != .ready {
                    ProgressView(value: viewModel.currentStep.progress)
                        .tint(Color.sxAccent)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.welcome)

                    GoalStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.goal)

                    ExperienceStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.experience)

                    EquipmentStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.equipment)

                    ModeStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.mode)

                    ScheduleStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.schedule)

                    ReadyStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                // Bottom buttons
                VStack(spacing: 12) {
                    if viewModel.currentStep == .ready {
                        Button("Start Training") {
                            viewModel.completeOnboarding(context: context)
                            hasCompletedOnboarding = true
                        }
                        .buttonStyle(SXPrimaryButtonStyle())
                    } else {
                        Button("Continue") {
                            viewModel.nextStep()
                        }
                        .buttonStyle(SXPrimaryButtonStyle(isEnabled: viewModel.canProceed))
                        .disabled(!viewModel.canProceed)
                    }

                    if viewModel.currentStep.rawValue > 0 && viewModel.currentStep != .ready {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .font(SXFont.medium(16))
                        .foregroundColor(.sxTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(Color.sxAccent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.sxGradient)
            }

            VStack(spacing: 12) {
                Text("StrengthX")
                    .font(SXFont.heavy(36))
                    .foregroundColor(.sxTextPrimary)

                Text("Adaptive training.\nZero friction.")
                    .font(SXFont.medium(18))
                    .foregroundColor(.sxTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Feature highlights
            VStack(spacing: 16) {
                FeatureRow(icon: "brain.head.profile", text: "AI-powered workout adaptation")
                FeatureRow(icon: "iphone", text: "Everything runs on-device")
                FeatureRow(icon: "lock.shield", text: "No account, no cloud, no tracking")
                FeatureRow(icon: "camera", text: "Scan workouts from photos")
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.sxAccent)
                .frame(width: 32)

            Text(text)
                .font(SXFont.medium(15))
                .foregroundColor(.sxTextSecondary)

            Spacer()
        }
    }
}

// MARK: - Goal Step

struct GoalStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("What's your goal?")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("This shapes your rep ranges, rest times, and progression")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(TrainingGoal.allCases) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.selectedGoal == goal
                    ) {
                        viewModel.selectedGoal = goal
                        SXHaptics.selection()
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct GoalCard: View {
    let goal: TrainingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .sxAccent : .sxTextSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.sxAccent.opacity(0.15) : Color.sxSurfaceElevated)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(SXFont.semibold(17))
                        .foregroundColor(.sxTextPrimary)

                    Text(goal.description)
                        .font(SXFont.caption)
                        .foregroundColor(.sxTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.sxAccent)
                        .font(.system(size: 22))
                }
            }
            .sxBorderedCard(isSelected: isSelected)
        }
    }
}

// MARK: - Experience Step

struct ExperienceStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("Experience level?")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("This adjusts exercise complexity and volume")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
            }

            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases) { level in
                    Button {
                        viewModel.selectedExperience = level
                        SXHaptics.selection()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(SXFont.semibold(17))
                                    .foregroundColor(.sxTextPrimary)

                                Text(level.description)
                                    .font(SXFont.caption)
                                    .foregroundColor(.sxTextSecondary)
                            }

                            Spacer()

                            if viewModel.selectedExperience == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sxAccent)
                                    .font(.system(size: 22))
                            }
                        }
                        .sxBorderedCard(isSelected: viewModel.selectedExperience == level)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Equipment Step

struct EquipmentStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("Available equipment?")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("Select everything you have access to")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Equipment.allCases) { equipment in
                    Button {
                        viewModel.toggleEquipment(equipment)
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: equipment.icon)
                                .font(.system(size: 28))
                                .foregroundColor(
                                    viewModel.selectedEquipment.contains(equipment) ? .sxAccent : .sxTextTertiary
                                )

                            Text(equipment.displayName)
                                .font(SXFont.medium(14))
                                .foregroundColor(.sxTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(viewModel.selectedEquipment.contains(equipment)
                                      ? Color.sxAccent.opacity(0.12)
                                      : Color.sxSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    viewModel.selectedEquipment.contains(equipment)
                                    ? Color.sxAccent : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Mode Step

struct ModeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("Training style?")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("You can change this anytime")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
            }

            VStack(spacing: 12) {
                ForEach(WorkoutMode.allCases) { mode in
                    Button {
                        viewModel.selectedMode = mode
                        SXHaptics.selection()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 22))
                                .foregroundColor(viewModel.selectedMode == mode ? .sxAccent : .sxTextSecondary)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.displayName)
                                    .font(SXFont.semibold(17))
                                    .foregroundColor(.sxTextPrimary)

                                Text(mode.description)
                                    .font(SXFont.caption)
                                    .foregroundColor(.sxTextSecondary)
                            }

                            Spacer()

                            if viewModel.selectedMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sxAccent)
                                    .font(.system(size: 22))
                            }
                        }
                        .sxBorderedCard(isSelected: viewModel.selectedMode == mode)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Schedule Step

struct ScheduleStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            VStack(spacing: 8) {
                Text("Days per week?")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("How many days can you train?")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
            }

            // Day selector
            VStack(spacing: 16) {
                Text("\(viewModel.daysPerWeek)")
                    .font(SXFont.metric)
                    .foregroundColor(.sxAccent)

                Text("days per week")
                    .font(SXFont.body)
                    .foregroundColor(.sxTextSecondary)

                HStack(spacing: 8) {
                    ForEach(2...7, id: \.self) { day in
                        Button {
                            viewModel.daysPerWeek = day
                            SXHaptics.selection()
                        } label: {
                            Text("\(day)")
                                .font(SXFont.semibold(18))
                                .foregroundColor(viewModel.daysPerWeek == day ? .white : .sxTextSecondary)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(viewModel.daysPerWeek == day ? Color.sxAccent : Color.sxSurface)
                                )
                        }
                    }
                }
            }

            // Optional bodyweight
            VStack(spacing: 8) {
                Text("Bodyweight (optional)")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextTertiary)

                HStack {
                    TextField("kg", text: $viewModel.bodyweight)
                        .keyboardType(.decimalPad)
                        .font(SXFont.body)
                        .foregroundColor(.sxTextPrimary)
                        .padding(12)
                        .background(Color.sxSurface)
                        .cornerRadius(10)
                        .frame(width: 120)

                    Text("kg")
                        .font(SXFont.caption)
                        .foregroundColor(.sxTextTertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Ready Step

struct ReadyStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.sxSuccess.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.sxSuccess)
            }

            VStack(spacing: 12) {
                Text("You're all set")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("Your training is personalized and ready")
                    .font(SXFont.body)
                    .foregroundColor(.sxTextSecondary)
            }

            // Summary
            VStack(spacing: 12) {
                SummaryRow(label: "Goal", value: viewModel.selectedGoal.displayName)
                SummaryRow(label: "Experience", value: viewModel.selectedExperience.displayName)
                SummaryRow(label: "Style", value: viewModel.selectedMode.displayName)
                SummaryRow(label: "Schedule", value: "\(viewModel.daysPerWeek) days/week")
                SummaryRow(label: "Equipment", value: "\(viewModel.selectedEquipment.count) types")
            }
            .sxCard()

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(SXFont.caption)
                .foregroundColor(.sxTextTertiary)
            Spacer()
            Text(value)
                .font(SXFont.semibold(15))
                .foregroundColor(.sxTextPrimary)
        }
    }
}
