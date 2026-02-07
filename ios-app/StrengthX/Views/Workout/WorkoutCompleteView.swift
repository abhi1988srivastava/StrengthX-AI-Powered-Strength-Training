import SwiftUI

// MARK: - Workout Complete View

struct WorkoutCompleteView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration
            ZStack {
                Circle()
                    .fill(Color.sxSuccess.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.sxSuccess)
            }

            VStack(spacing: 8) {
                Text("Workout Complete!")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text(viewModel.currentPlan?.name ?? "Great session")
                    .font(SXFont.body)
                    .foregroundColor(.sxTextSecondary)
            }

            // Stats
            HStack(spacing: 24) {
                WorkoutStatBubble(
                    value: viewModel.formattedTimer,
                    label: "Duration",
                    icon: "clock"
                )

                WorkoutStatBubble(
                    value: "\(viewModel.totalVolume.cleanWeight)",
                    label: "Volume (kg)",
                    icon: "scalemass.fill"
                )

                WorkoutStatBubble(
                    value: "\(viewModel.exerciseLogs.count)",
                    label: "Exercises",
                    icon: "list.bullet"
                )
            }

            // Set completion summary
            VStack(spacing: 8) {
                let totalSets = viewModel.exerciseLogs.values.flatMap { $0 }.count
                let completedSets = viewModel.exerciseLogs.values.flatMap { $0 }.filter { $0.isCompleted }.count

                HStack {
                    Text("Sets Completed")
                        .font(SXFont.caption)
                        .foregroundColor(.sxTextSecondary)
                    Spacer()
                    Text("\(completedSets) / \(totalSets)")
                        .font(SXFont.semibold(15))
                        .foregroundColor(.sxTextPrimary)
                }

                ProgressView(value: totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0)
                    .tint(Color.sxSuccess)
            }
            .sxCard()
            .padding(.horizontal, 20)

            Spacer()

            Button("Done") {
                onDismiss()
            }
            .buttonStyle(SXPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Stat Bubble

struct WorkoutStatBubble: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.sxAccent)

            Text(value)
                .font(SXFont.bold(18))
                .foregroundColor(.sxTextPrimary)

            Text(label)
                .font(SXFont.small)
                .foregroundColor(.sxTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
