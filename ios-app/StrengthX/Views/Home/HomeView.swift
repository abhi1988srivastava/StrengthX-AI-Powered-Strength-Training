import SwiftUI
import CoreData

// MARK: - Home View

struct HomeView: View {
    let onStartWorkout: () -> Void
    @Environment(\.managedObjectContext) private var context
    @StateObject private var progressVM = ProgressViewModel()

    private var userProfile: UserProfile {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return UserProfile()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("StrengthX")
                            .font(SXFont.heavy(28))
                            .foregroundColor(.sxTextPrimary)

                        Text(Date().dayOfWeek)
                            .font(SXFont.caption)
                            .foregroundColor(.sxTextSecondary)
                    }

                    Spacer()

                    // Streak badge
                    if progressVM.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.sxWarning)
                            Text("\(progressVM.currentStreak)w")
                                .font(SXFont.semibold(14))
                                .foregroundColor(.sxWarning)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.sxWarning.opacity(0.12))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Quick Start Card
                Button(action: onStartWorkout) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ready to train?")
                                .font(SXFont.heading)
                                .foregroundColor(.white)

                            Text("\(userProfile.preferredMode.displayName) workout")
                                .font(SXFont.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(20)
                    .background(Color.sxGradient)
                    .cornerRadius(20)
                }
                .padding(.horizontal, 20)

                // Stats Row
                HStack(spacing: 12) {
                    StatCard(
                        title: "This Week",
                        value: "\(progressVM.thisWeekSessions)",
                        subtitle: "sessions",
                        icon: "calendar",
                        color: .sxAccent
                    )

                    StatCard(
                        title: "Total",
                        value: "\(progressVM.totalWorkouts)",
                        subtitle: "workouts",
                        icon: "figure.strengthtraining.traditional",
                        color: .sxSuccess
                    )

                    StatCard(
                        title: "Streak",
                        value: "\(progressVM.currentStreak)",
                        subtitle: "weeks",
                        icon: "flame.fill",
                        color: .sxWarning
                    )
                }
                .padding(.horizontal, 20)

                // Weekly Volume Chart
                if !progressVM.weeklyVolume.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week")
                            .font(SXFont.subheading)
                            .foregroundColor(.sxTextPrimary)

                        WeeklyVolumeChart(data: progressVM.weeklyVolume)
                    }
                    .sxCard()
                    .padding(.horizontal, 20)
                }

                // Muscle Group Distribution
                if !progressVM.muscleGroupVolume.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Muscle Focus")
                            .font(SXFont.subheading)
                            .foregroundColor(.sxTextPrimary)

                        ForEach(progressVM.muscleGroupVolume) { volume in
                            MuscleGroupRow(volume: volume, maxVolume: progressVM.muscleGroupVolume.first?.totalVolume ?? 1)
                        }
                    }
                    .sxCard()
                    .padding(.horizontal, 20)
                }

                // Recent Workouts
                if !progressVM.recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Workouts")
                            .font(SXFont.subheading)
                            .foregroundColor(.sxTextPrimary)

                        ForEach(progressVM.recentSessions.prefix(5), id: \.id) { session in
                            RecentSessionRow(session: session)
                        }
                    }
                    .sxCard()
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color.sxBackground)
        .onAppear {
            progressVM.loadData(context: context)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(SXFont.bold(22))
                .foregroundColor(.sxTextPrimary)

            Text(subtitle)
                .font(SXFont.small)
                .foregroundColor(.sxTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.sxSurface)
        .cornerRadius(14)
    }
}

// MARK: - Weekly Volume Chart

struct WeeklyVolumeChart: View {
    let data: [ProgressViewModel.DailyVolume]

    private var maxVolume: Double {
        data.map(\.volume).max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { day in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.volume > 0 ? Color.sxAccent : Color.sxSurfaceElevated)
                        .frame(height: max(4, CGFloat(day.volume / max(maxVolume, 1)) * 80))

                    Text(day.label)
                        .font(SXFont.small)
                        .foregroundColor(.sxTextTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 110)
    }
}

// MARK: - Muscle Group Row

struct MuscleGroupRow: View {
    let volume: ProgressViewModel.MuscleGroupVolume
    let maxVolume: Double

    private var barWidth: CGFloat {
        CGFloat(volume.totalVolume / max(maxVolume, 1))
    }

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
        HStack(spacing: 12) {
            Text(volume.muscleGroup.displayName)
                .font(SXFont.medium(14))
                .foregroundColor(.sxTextSecondary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * barWidth)
            }
            .frame(height: 8)

            Text("\(volume.totalSets) sets")
                .font(SXFont.small)
                .foregroundColor(.sxTextTertiary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: CDWorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.sxAccent.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 16))
                        .foregroundColor(.sxAccent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name ?? "Workout")
                    .font(SXFont.medium(15))
                    .foregroundColor(.sxTextPrimary)

                Text(session.startedAt?.relativeFormat ?? "")
                    .font(SXFont.small)
                    .foregroundColor(.sxTextTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.durationSeconds / 60)m")
                    .font(SXFont.medium(14))
                    .foregroundColor(.sxTextSecondary)

                Text("\(session.totalVolume.cleanWeight)kg")
                    .font(SXFont.small)
                    .foregroundColor(.sxTextTertiary)
            }
        }
    }
}
