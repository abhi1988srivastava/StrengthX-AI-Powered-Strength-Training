
# StrengthX -- AI-Powered Adaptive Strength Training

A modern, minimalistic iOS workout app focused on adaptive training, not social fluff.  
Local-first. No login. No cloud. Just lift.

---

## Core Philosophy

- **Local-first**: No accounts, no cloud dependency, no OAuth/SSO
- **Production-ready**: No placeholders, no mock ML -- real rule-driven logic
- **AI as an assistant**: Deterministic adaptation within guardrails
- **Zero friction**: Open app, configure once, lift forever

---

## Features

### Workout Modes
| Mode | Description |
|------|-------------|
| **Push / Pull** | Alternate pushing and pulling movements across sessions |
| **Bro Split** | Dedicate each day to a specific muscle group |
| **Full Body** | Hit every major muscle group in one session |
| **Muscle Focus** | Target a specific muscle group with supporting work |

### Focus Slider
The key differentiator. A visual slider system that lets users bias training toward specific muscles:
- **Chest / Back / Legs / Shoulders / Arms** -- each independently adjustable
- Radar chart visualization of current distribution
- Quick presets: Balanced, Upper Focus, Lower Focus, Push Heavy
- AI automatically adjusts exercise selection, volume (sets/reps), and frequency

### AI Workout Adaptation (Rule-Driven ML)
During onboarding, users input goals, experience, and equipment. The adaptation engine then:
- Adjusts reps, sets, rest, and load ranges per goal
- Learns from logged workout history
- **Progresses** when hitting rep targets consistently (3+ sessions)
- **Deloads** when missing reps consecutively (3+ sessions)
- Tracks consistency streaks and enables auto-progression at 5+ weeks

### Image Upload -> Workout Parsing
Upload photos of gym whiteboards, trainer-written plans, or workout screenshots:
- **OCR** via Apple Vision framework (on-device, no cloud)
- **NLP rules engine** maps extracted text to exercises and muscle groups
- Fuzzy matching against 60+ exercise database
- Extracts sets, reps, weight from common patterns (3x10, 135lbs, etc.)
- Converts parsed data to structured workout plans

**Explicitly**: No "recommend workouts from image." Only deterministic text-to-data conversion.

### Progress Tracking
- Weekly volume charts with daily breakdown
- Muscle group distribution analysis
- Personal records tracking
- Workout history with duration and volume
- Consistency streak calculation

---

## Architecture

```
ios-app/StrengthX/
├── App/
│   └── StrengthXApp.swift              # App entry point with onboarding detection
├── Models/
│   ├── WorkoutModels.swift             # All enums, structs, and data types
│   └── CoreData/
│       └── PersistenceController.swift # Programmatic Core Data model + NSManagedObject subclasses
├── Services/
│   ├── ExerciseDatabase.swift          # 60+ exercises with muscle group mappings
│   ├── WorkoutEngine.swift             # Workout generation (modes, focus, profiles)
│   ├── AdaptationEngine.swift          # Rule-based progression/deload logic
│   └── OCRService.swift                # Vision OCR + NLP parsing
├── ViewModels/
│   ├── OnboardingViewModel.swift       # Onboarding flow state management
│   ├── WorkoutViewModel.swift          # Active workout state, timer, logging
│   ├── ProgressViewModel.swift         # Analytics queries and calculations
│   └── ImageParserViewModel.swift      # Image selection and OCR processing
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift        # 6-step onboarding flow
│   ├── Home/
│   │   ├── MainTabView.swift           # Tab bar with custom design
│   │   └── HomeView.swift              # Dashboard with stats and history
│   ├── Workout/
│   │   ├── WorkoutFlowView.swift       # Mode selection → focus → preview → train → complete
│   │   ├── FocusSliderView.swift       # Muscle focus sliders with radar chart
│   │   ├── WorkoutPreviewView.swift    # Generated workout preview
│   │   ├── ActiveWorkoutView.swift     # In-gym set logging with adaptation insights
│   │   └── WorkoutCompleteView.swift   # Post-workout summary
│   ├── ImageParser/
│   │   └── ImageUploadView.swift       # Camera/library upload + OCR results
│   ├── Progress/
│   │   └── ProgressDashboardView.swift # Charts, PRs, history
│   └── Settings/
│       └── SettingsView.swift          # Profile management, equipment, reset
└── Extensions/
    ├── Color+Theme.swift               # Design system (colors, typography, haptics)
    └── View+Extensions.swift           # View modifiers and formatters
```

---

## Data Models

| Model | Purpose |
|-------|---------|
| `MuscleGroup` | Chest, Back, Legs, Shoulders, Arms, Core with sub-groups |
| `WorkoutMode` | Push/Pull, Bro Split, Full Body, Muscle Focus |
| `TrainingGoal` | Strength, Hypertrophy, Fat Loss with parameter ranges |
| `ExperienceLevel` | Beginner, Intermediate, Advanced with volume multipliers |
| `Equipment` | Barbell, Dumbbell, Cables, Machines, Bodyweight, Kettlebell, Bands |
| `FocusDistribution` | Per-muscle bias percentages that drive workout generation |
| `ExerciseDefinition` | Exercise with primary/secondary muscles, equipment, difficulty |
| `WorkoutPlan` | Generated workout with planned exercises and metadata |
| `PlannedExercise` | Individual exercise with sets, reps, rest, RPE target |
| `LoggedSet` | Recorded set with weight, reps, RPE, completion status |
| `ParsedWorkout` | OCR result with extracted exercises and confidence score |
| `AdaptationResult` | Engine decision: increase, maintain, deload, or swap |

---

## Core Data Entities

| Entity | Description |
|--------|-------------|
| `CDUserProfile` | Goal, experience, equipment, mode, schedule, focus distribution |
| `CDWorkoutSession` | Completed workout with duration, total volume, exercises |
| `CDExerciseLog` | Exercise within a session with muscle group and order |
| `CDSetLog` | Individual set with weight, reps, RPE, warmup/completed flags |

All data stored on-device via Core Data. No cloud sync. No backend dependency.

---

## Setup Instructions

### Requirements
- **Xcode 15+** (iOS 17 SDK)
- **iOS 17.0+** deployment target
- **Swift 5.9+**
- No external dependencies (no CocoaPods, no SPM packages)

### Xcode Project Setup

1. **Open Xcode** and create a new project:
   - Template: **App**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (Core Data is defined programmatically)
   - Product Name: **StrengthX**
   - Bundle ID: `com.yourname.strengthx`

2. **Delete the generated files** (ContentView.swift, StrengthXApp.swift)

3. **Add source files**: Drag the entire `ios-app/StrengthX/` folder contents into the Xcode project navigator

4. **Verify structure**: Ensure all folders (App, Models, Services, ViewModels, Views, Extensions) are visible and files compile

5. **Set deployment target**: iOS 17.0

6. **Add required capabilities** (optional, for camera):
   - In `Info.plist`, add:
     - `NSCameraUsageDescription`: "StrengthX uses the camera to scan workout plans"
     - `NSPhotoLibraryUsageDescription`: "StrengthX accesses photos to scan workout plans"

7. **Build and run** on simulator or device

### No External Dependencies
The entire app runs on Apple frameworks:
- **SwiftUI** for UI
- **CoreData** for persistence
- **Vision** for OCR text recognition
- **UIKit** for image picker bridging

---

## App Store Readiness

| Concern | Status |
|---------|--------|
| Health claims | None -- no medical/health recommendations |
| Cloud data risks | None -- all data on-device |
| AI hallucinations | None -- deterministic rule-based logic only |
| Privacy posture | Zero tracking, no accounts, no analytics |
| Third-party SDKs | None -- pure Apple frameworks |
| Login/OAuth | Not needed -- local-first design |

---

## Design System

**Color Palette** (Dark-first, optimized for gym use):
- Background: `#0F0F14` / Surface: `#1C1C24` / Elevated: `#292930`
- Accent: Electric Blue `#59ADFF` / Secondary: Purple `#8C5CFF`
- Success: Green `#4DD98C` / Warning: Amber `#FFC247` / Danger: Red `#FF5959`
- Muscle colors: Chest (Red), Back (Blue), Legs (Purple), Shoulders (Amber), Arms (Green), Core (Orange)

**Typography**: System rounded font with weight hierarchy (Heavy → Regular)

**Haptics**: Contextual feedback on selection, completion, and navigation

---

## Why StrengthX Is Different

1. **OCR + NLP for user-owned workouts** is rare in fitness apps
2. **Focus slider** is a simple but powerful training bias control
3. **AI adapts within guardrails** -- no hallucinated recommendations
4. **Zero friction**: Open app → configure once → lift forever
5. **Privacy-first**: No accounts, no cloud, no tracking

---

MIT License | Built for serious lifters.
