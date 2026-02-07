import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home
        case workout
        case scan
        case progress
        case settings

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .workout: return "figure.strengthtraining.traditional"
            case .scan: return "camera.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }

        var label: String {
            switch self {
            case .home: return "Home"
            case .workout: return "Train"
            case .scan: return "Scan"
            case .progress: return "Progress"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(onStartWorkout: { selectedTab = .workout })
                case .workout:
                    WorkoutFlowView()
                case .scan:
                    ImageUploadView()
                case .progress:
                    ProgressDashboardView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.rawValue) { tab in
                Button {
                    selectedTab = tab
                    SXHaptics.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: tab == .scan ? 24 : 20))
                            .foregroundColor(selectedTab == tab ? .sxAccent : .sxTextTertiary)

                        Text(tab.label)
                            .font(SXFont.small)
                            .foregroundColor(selectedTab == tab ? .sxAccent : .sxTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(Color.sxBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
