import SwiftUI
import CoreData

// MARK: - Onboarding ViewModel

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedGoal: TrainingGoal = .hypertrophy
    @Published var selectedExperience: ExperienceLevel = .intermediate
    @Published var selectedEquipment: Set<Equipment> = Set(Equipment.allCases)
    @Published var selectedMode: WorkoutMode = .pushPull
    @Published var daysPerWeek: Int = 4
    @Published var bodyweight: String = ""

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case goal = 1
        case experience = 2
        case equipment = 3
        case mode = 4
        case schedule = 5
        case ready = 6

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .goal: return "Your Goal"
            case .experience: return "Experience"
            case .equipment: return "Equipment"
            case .mode: return "Training Style"
            case .schedule: return "Schedule"
            case .ready: return "Ready"
            }
        }

        var progress: Double {
            Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome: return true
        case .goal: return true
        case .experience: return true
        case .equipment: return !selectedEquipment.isEmpty
        case .mode: return true
        case .schedule: return true
        case .ready: return true
        }
    }

    func nextStep() {
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
            SXHaptics.light()
        }
    }

    func previousStep() {
        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prev
            }
        }
    }

    func toggleEquipment(_ equipment: Equipment) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
        SXHaptics.selection()
    }

    func completeOnboarding(context: NSManagedObjectContext) {
        let profile = UserProfile(
            goal: selectedGoal,
            experience: selectedExperience,
            availableEquipment: Array(selectedEquipment),
            preferredMode: selectedMode,
            daysPerWeek: daysPerWeek,
            focusDistribution: FocusDistribution(),
            bodyweight: Double(bodyweight)
        )

        // Save to Core Data
        let cdProfile = CDUserProfile(context: context)
        cdProfile.update(from: profile)

        do {
            try context.save()
        } catch {
            print("Failed to save profile: \(error)")
        }

        // Save to UserDefaults for quick access
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }

        SXHaptics.success()
    }
}
