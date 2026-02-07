import SwiftUI
import CoreData

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var profile: UserProfile = UserProfile()
    @State private var showResetConfirmation = false
    @State private var showExportSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Settings")
                        .font(SXFont.title)
                        .foregroundColor(.sxTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Profile Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Your Profile")

                    // Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Training Goal")
                            .font(SXFont.caption)
                            .foregroundColor(.sxTextTertiary)

                        HStack(spacing: 8) {
                            ForEach(TrainingGoal.allCases) { goal in
                                Button {
                                    profile.goal = goal
                                    saveProfile()
                                    SXHaptics.selection()
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: goal.icon)
                                            .font(.system(size: 18))
                                        Text(goal.displayName)
                                            .font(SXFont.small)
                                    }
                                    .foregroundColor(profile.goal == goal ? .sxAccent : .sxTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(profile.goal == goal ? Color.sxAccent.opacity(0.12) : Color.sxSurfaceElevated)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(profile.goal == goal ? Color.sxAccent : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }

                    // Experience
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Experience Level")
                            .font(SXFont.caption)
                            .foregroundColor(.sxTextTertiary)

                        HStack(spacing: 8) {
                            ForEach(ExperienceLevel.allCases) { level in
                                Button {
                                    profile.experience = level
                                    saveProfile()
                                    SXHaptics.selection()
                                } label: {
                                    Text(level.displayName)
                                        .font(SXFont.medium(14))
                                        .foregroundColor(profile.experience == level ? .sxAccent : .sxTextSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(profile.experience == level ? Color.sxAccent.opacity(0.12) : Color.sxSurfaceElevated)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(profile.experience == level ? Color.sxAccent : Color.clear, lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                    }

                    // Preferred Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Training Style")
                            .font(SXFont.caption)
                            .foregroundColor(.sxTextTertiary)

                        ForEach(WorkoutMode.allCases) { mode in
                            Button {
                                profile.preferredMode = mode
                                saveProfile()
                                SXHaptics.selection()
                            } label: {
                                HStack {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(profile.preferredMode == mode ? .sxAccent : .sxTextTertiary)
                                        .frame(width: 28)

                                    Text(mode.displayName)
                                        .font(SXFont.medium(15))
                                        .foregroundColor(.sxTextPrimary)

                                    Spacer()

                                    if profile.preferredMode == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.sxAccent)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(profile.preferredMode == mode ? Color.sxAccent.opacity(0.08) : Color.clear)
                                )
                            }
                        }
                    }

                    // Days per week
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Training Days per Week")
                            .font(SXFont.caption)
                            .foregroundColor(.sxTextTertiary)

                        HStack(spacing: 6) {
                            ForEach(2...7, id: \.self) { day in
                                Button {
                                    profile.daysPerWeek = day
                                    saveProfile()
                                    SXHaptics.selection()
                                } label: {
                                    Text("\(day)")
                                        .font(SXFont.semibold(16))
                                        .foregroundColor(profile.daysPerWeek == day ? .white : .sxTextSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(profile.daysPerWeek == day ? Color.sxAccent : Color.sxSurfaceElevated)
                                        )
                                }
                            }
                        }
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                // Equipment Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Equipment")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Equipment.allCases) { equipment in
                            Button {
                                if profile.availableEquipment.contains(equipment) {
                                    profile.availableEquipment.removeAll { $0 == equipment }
                                } else {
                                    profile.availableEquipment.append(equipment)
                                }
                                saveProfile()
                                SXHaptics.selection()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: equipment.icon)
                                        .font(.system(size: 16))

                                    Text(equipment.displayName)
                                        .font(SXFont.medium(14))
                                }
                                .foregroundColor(
                                    profile.availableEquipment.contains(equipment) ? .sxAccent : .sxTextTertiary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            profile.availableEquipment.contains(equipment)
                                            ? Color.sxAccent.opacity(0.12) : Color.sxSurfaceElevated
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            profile.availableEquipment.contains(equipment)
                                            ? Color.sxAccent : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                        }
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                // App Info Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "About")

                    InfoRow(label: "Version", value: "1.0.0")
                    InfoRow(label: "Data Storage", value: "On-Device Only")
                    InfoRow(label: "Account", value: "No account needed")
                    InfoRow(label: "Privacy", value: "Zero tracking")

                    Divider()
                        .background(Color.sxSurfaceElevated)

                    // Reset
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Data")
                        }
                        .font(SXFont.medium(15))
                        .foregroundColor(.sxDanger)
                    }
                }
                .sxCard()
                .padding(.horizontal, 20)

                // Privacy note
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.sxTextTertiary)

                    Text("StrengthX stores all data on your device.\nNo accounts. No cloud. No tracking.")
                        .font(SXFont.small)
                        .foregroundColor(.sxTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)

                Spacer(minLength: 100)
            }
        }
        .background(Color.sxBackground)
        .onAppear { loadProfile() }
        .alert("Reset All Data?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all workout history, progress, and settings. This cannot be undone.")
        }
    }

    // MARK: - Profile Persistence

    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let loaded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = loaded
        }
    }

    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }

        // Also update Core Data
        let request: NSFetchRequest<CDUserProfile> = NSFetchRequest(entityName: "CDUserProfile")
        if let existing = try? context.fetch(request).first {
            existing.update(from: profile)
        } else {
            let new = CDUserProfile(context: context)
            new.update(from: profile)
        }

        try? context.save()
    }

    private func resetAllData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userProfile")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Clear Core Data
        let entities = ["CDUserProfile", "CDWorkoutSession", "CDExerciseLog", "CDSetLog"]
        for entity in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try? context.execute(deleteRequest)
        }

        try? context.save()
        hasCompletedOnboarding = false
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(SXFont.subheading)
            .foregroundColor(.sxTextPrimary)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(SXFont.medium(15))
                .foregroundColor(.sxTextSecondary)
            Spacer()
            Text(value)
                .font(SXFont.medium(15))
                .foregroundColor(.sxTextTertiary)
        }
    }
}
