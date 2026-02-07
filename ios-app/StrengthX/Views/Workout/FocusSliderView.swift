import SwiftUI

// MARK: - Focus Slider View
// The key differentiator: lets users bias training toward specific muscles.
// AI adjusts exercise selection, volume, and frequency based on these values.

struct FocusSliderView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onContinue: () -> Void
    let onBack: () -> Void

    private let muscles: [MuscleGroup] = [.chest, .back, .legs, .shoulders, .arms]

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Set Your Focus")
                    .font(SXFont.title)
                    .foregroundColor(.sxTextPrimary)

                Text("Slide to bias training toward specific muscles")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            // Visual distribution
            FocusDistributionChart(distribution: viewModel.focusDistribution)
                .frame(height: 160)
                .padding(.horizontal, 20)

            // Sliders
            VStack(spacing: 20) {
                ForEach(muscles) { muscle in
                    FocusSliderRow(
                        muscle: muscle,
                        value: binding(for: muscle),
                        color: colorForMuscle(muscle)
                    )
                }
            }
            .padding(.horizontal, 20)

            // Presets
            VStack(spacing: 8) {
                Text("Quick Presets")
                    .font(SXFont.small)
                    .foregroundColor(.sxTextTertiary)

                HStack(spacing: 10) {
                    PresetButton(title: "Balanced", action: applyBalanced)
                    PresetButton(title: "Upper Focus", action: applyUpperFocus)
                    PresetButton(title: "Lower Focus", action: applyLowerFocus)
                    PresetButton(title: "Push Heavy", action: applyPushHeavy)
                }
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button("Generate Workout") {
                    // Normalize before generating
                    viewModel.focusDistribution.normalize()
                    onContinue()
                }
                .buttonStyle(SXPrimaryButtonStyle())

                Button("Back") {
                    onBack()
                }
                .font(SXFont.medium(16))
                .foregroundColor(.sxTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Binding Helper

    private func binding(for muscle: MuscleGroup) -> Binding<Double> {
        Binding(
            get: { viewModel.focusDistribution.value(for: muscle) },
            set: { viewModel.focusDistribution.setValue($0, for: muscle) }
        )
    }

    private func colorForMuscle(_ muscle: MuscleGroup) -> Color {
        switch muscle {
        case .chest: return .sxChest
        case .back: return .sxBack
        case .legs: return .sxLegs
        case .shoulders: return .sxShoulders
        case .arms: return .sxArms
        case .core: return .sxCore
        }
    }

    // MARK: - Presets

    private func applyBalanced() {
        withAnimation {
            viewModel.focusDistribution = FocusDistribution(chest: 0.2, back: 0.2, legs: 0.2, shoulders: 0.2, arms: 0.2)
        }
        SXHaptics.light()
    }

    private func applyUpperFocus() {
        withAnimation {
            viewModel.focusDistribution = FocusDistribution(chest: 0.25, back: 0.25, legs: 0.1, shoulders: 0.25, arms: 0.15)
        }
        SXHaptics.light()
    }

    private func applyLowerFocus() {
        withAnimation {
            viewModel.focusDistribution = FocusDistribution(chest: 0.1, back: 0.15, legs: 0.45, shoulders: 0.15, arms: 0.15)
        }
        SXHaptics.light()
    }

    private func applyPushHeavy() {
        withAnimation {
            viewModel.focusDistribution = FocusDistribution(chest: 0.35, back: 0.1, legs: 0.15, shoulders: 0.25, arms: 0.15)
        }
        SXHaptics.light()
    }
}

// MARK: - Focus Slider Row

struct FocusSliderRow: View {
    let muscle: MuscleGroup
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: muscle.icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(muscle.displayName)
                    .font(SXFont.medium(14))
                    .foregroundColor(.sxTextPrimary)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(SXFont.semibold(14))
                    .foregroundColor(color)
                    .frame(width: 44, alignment: .trailing)
            }

            Slider(value: $value, in: 0.05...0.6, step: 0.05)
                .tint(color)
                .onChange(of: value) { _ in
                    SXHaptics.selection()
                }
        }
    }
}

// MARK: - Focus Distribution Chart (Radar-style)

struct FocusDistributionChart: View {
    let distribution: FocusDistribution

    private let muscles: [MuscleGroup] = [.chest, .back, .legs, .shoulders, .arms]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2.5

            ZStack {
                // Background rings
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    RadarPolygon(sides: muscles.count, scale: scale)
                        .stroke(Color.sxSurfaceElevated, lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                // Data polygon
                let values = muscles.map { distribution.value(for: $0) }
                let maxVal = max(values.max() ?? 0.2, 0.2)
                let normalized = values.map { $0 / maxVal }

                RadarDataPolygon(values: normalized)
                    .fill(Color.sxAccent.opacity(0.2))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                RadarDataPolygon(values: normalized)
                    .stroke(Color.sxAccent, lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Labels
                ForEach(0..<muscles.count, id: \.self) { index in
                    let angle = (Double(index) / Double(muscles.count)) * .pi * 2 - .pi / 2
                    let labelRadius = radius + 24
                    let x = center.x + cos(angle) * labelRadius
                    let y = center.y + sin(angle) * labelRadius

                    Text(muscles[index].displayName)
                        .font(SXFont.small)
                        .foregroundColor(.sxTextSecondary)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Radar Shapes

struct RadarPolygon: Shape {
    let sides: Int
    let scale: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale

        for i in 0..<sides {
            let angle = (Double(i) / Double(sides)) * .pi * 2 - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct RadarDataPolygon: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for (i, value) in values.enumerated() {
            let angle = (Double(i) / Double(values.count)) * .pi * 2 - .pi / 2
            let r = radius * max(0.05, value)
            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SXFont.small)
                .foregroundColor(.sxTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.sxSurface)
                .cornerRadius(8)
        }
    }
}
