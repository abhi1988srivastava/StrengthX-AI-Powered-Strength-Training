import SwiftUI
import CoreData

// MARK: - Progress Dashboard View

struct ProgressDashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Progress")
                        .font(SXFont.title)
                        .foregroundColor(.sxTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Overview cards
                HStack(spacing: 12) {
                    ProgressStatCard(
                        title: "Workouts",
                        value: "\(viewModel.totalWorkouts)",
                        icon: "figure.strengthtraining.traditional",
                        color: .sxAccent
                    )

                    ProgressStatCard(
                        title: "Streak",
                        value: "\(viewModel.currentStreak)w",
                        icon: "flame.fill",
                        color: .sxWarning
                    )

                    ProgressStatCard(
                        title: "This Week",
                        value: "\(viewModel.thisWeekSessions)",
                        icon: "calendar",
                        color: .sxSuccess
                    )
                }
                .padding(.horizontal, 20)

                // Weekly Volume Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Volume")
                        .font(SXFont.subheading)
                        .foregroundColor(.sxTextPrimary)

                    if viewModel.weeklyVolume.isEmpty || viewModel.weeklyVolume.allSatisfy({ $0.volume == 0 }) {
                        EmptyStateView(
                            icon: "chart.bar",
                            message: "Complete workouts to see volume trends"
                        )
                    } else {
                        DetailedVolumeChart(data: viewModel.weeklyVolume)
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                // Muscle Group Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Muscle Distribution")
                        .font(SXFont.subheading)
                        .foregroundColor(.sxTextPrimary)

                    if viewModel.muscleGroupVolume.isEmpty {
                        EmptyStateView(
                            icon: "figure.arms.open",
                            message: "Train to see muscle group breakdown"
                        )
                    } else {
                        ForEach(viewModel.muscleGroupVolume) { vol in
                            DetailedMuscleRow(volume: vol, maxVolume: viewModel.muscleGroupVolume.first?.totalVolume ?? 1)
                        }
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                // Personal Records
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personal Records")
                        .font(SXFont.subheading)
                        .foregroundColor(.sxTextPrimary)

                    if viewModel.personalRecords.isEmpty {
                        EmptyStateView(
                            icon: "trophy.fill",
                            message: "Hit the gym to set personal records"
                        )
                    } else {
                        ForEach(viewModel.personalRecords.prefix(10)) { pr in
                            PersonalRecordRow(record: pr)
                        }
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                // Recent Workout History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout History")
                        .font(SXFont.subheading)
                        .foregroundColor(.sxTextPrimary)

                    if viewModel.recentSessions.isEmpty {
                        EmptyStateView(
                            icon: "clock",
                            message: "No workouts logged yet"
                        )
                    } else {
                        ForEach(viewModel.recentSessions, id: \.id) { session in
                            WorkoutHistoryRow(session: session)
                        }
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
        }
        .background(Color.sxBackground)
        .onAppear {
            viewModel.loadData(context: context)
        }
    }
}

// MARK: - Progress Stat Card

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(SXFont.bold(24))
                .foregroundColor(.sxTextPrimary)

            Text(title)
                .font(SXFont.small)
                .foregroundColor(.sxTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.sxSurface)
        .cornerRadius(14)
    }
}

// MARK: - Detailed Volume Chart

struct DetailedVolumeChart: View {
    let data: [ProgressViewModel.DailyVolume]

    private var maxVolume: Double {
        max(data.map(\.volume).max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data) { day in
                    VStack(spacing: 6) {
                        if day.volume > 0 {
                            Text(day.volume.cleanWeight)
                                .font(SXFont.small)
                                .foregroundColor(.sxTextSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                day.volume > 0
                                ? LinearGradient(colors: [.sxAccent, .sxAccentSecondary], startPoint: .bottom, endPoint: .top)
                                : LinearGradient(colors: [Color.sxSurfaceElevated], startPoint: .bottom, endPoint: .top)
                            )
                            .frame(height: max(4, CGFloat(day.volume / maxVolume) * 100))

                        Text(day.label)
                            .font(SXFont.small)
                            .foregroundColor(.sxTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
    }
}

// MARK: - Detailed Muscle Row

struct DetailedMuscleRow: View {
    let volume: ProgressViewModel.MuscleGroupVolume
    let maxVolume: Double

    private var color: Color {
        switch volume.muscleGroup {
        case .chest: return .sxChest
        case .back: return .sxBack
        case .legs: return .sxLegs
        case .shoulders: return .sxShoulders
        case .arms: return .sxArms
        case .core: return .sxCore
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: volume.muscleGroup.icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)

                    Text(volume.muscleGroup.displayName)
                        .font(SXFont.medium(14))
                        .foregroundColor(.sxTextPrimary)
                }

                Spacer()

                Text("\(volume.totalSets) sets  ·  \(volume.totalVolume.cleanWeight)kg")
                    .font(SXFont.small)
                    .foregroundColor(.sxTextSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sxSurfaceElevated)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(volume.totalVolume / max(maxVolume, 1)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Personal Record Row

struct PersonalRecordRow: View {
    let record: ProgressViewModel.PersonalRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14))
                .foregroundColor(.sxWarning)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.exerciseName)
                    .font(SXFont.medium(15))
                    .foregroundColor(.sxTextPrimary)

                Text(record.date.shortFormat)
                    .font(SXFont.small)
                    .foregroundColor(.sxTextTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(record.weight.cleanWeight) kg")
                    .font(SXFont.semibold(15))
                    .foregroundColor(.sxTextPrimary)

                Text("\(record.reps) reps")
                    .font(SXFont.small)
                    .foregroundColor(.sxTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let session: CDWorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name ?? "Workout")
                    .font(SXFont.medium(15))
                    .foregroundColor(.sxTextPrimary)

                HStack(spacing: 8) {
                    Text(session.startedAt?.relativeFormat ?? "")
                    Text("·")
                    Text("\(session.durationSeconds / 60) min")
                    Text("·")
                    Text("\(session.exerciseLogsArray.count) exercises")
                }
                .font(SXFont.small)
                .foregroundColor(.sxTextTertiary)
            }

            Spacer()

            Text("\(session.totalVolume.cleanWeight) kg")
                .font(SXFont.semibold(14))
                .foregroundColor(.sxAccent)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.sxTextTertiary)

            Text(message)
                .font(SXFont.caption)
                .foregroundColor(.sxTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
