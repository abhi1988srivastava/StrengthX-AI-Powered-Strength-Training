import SwiftUI

// MARK: - Image Upload & OCR Parsing View
// Upload gym whiteboards, trainer notes, or screenshots → structured workout data

struct ImageUploadView: View {
    @StateObject private var viewModel = ImageParserViewModel()
    @State private var showingImageSource = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Scan Workout")
                        .font(SXFont.title)
                        .foregroundColor(.sxTextPrimary)

                    Text("Upload a photo of a workout plan to convert it to structured data")
                        .font(SXFont.caption)
                        .foregroundColor(.sxTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Image area
                if let image = viewModel.selectedImage {
                    // Show selected image
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.sxSurfaceElevated, lineWidth: 1)
                            )

                        HStack(spacing: 16) {
                            Button {
                                viewModel.processImage()
                            } label: {
                                HStack {
                                    if viewModel.isProcessing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "doc.text.viewfinder")
                                    }
                                    Text(viewModel.isProcessing ? "Processing..." : "Parse Workout")
                                }
                            }
                            .buttonStyle(SXPrimaryButtonStyle(isEnabled: !viewModel.isProcessing))
                            .disabled(viewModel.isProcessing)

                            Button {
                                viewModel.reset()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.sxTextTertiary)
                            }
                        }
                    }
                } else {
                    // Upload prompt
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    Color.sxSurfaceElevated,
                                    style: StrokeStyle(lineWidth: 2, dash: [8])
                                )
                                .frame(height: 200)

                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.sxAccent)

                                Text("Tap to upload a workout photo")
                                    .font(SXFont.medium(15))
                                    .foregroundColor(.sxTextSecondary)

                                Text("Whiteboards, trainer notes, screenshots")
                                    .font(SXFont.small)
                                    .foregroundColor(.sxTextTertiary)
                            }
                        }
                        .onTapGesture {
                            showingImageSource = true
                        }

                        // Supported formats
                        HStack(spacing: 24) {
                            ScanFeature(icon: "doc.text", label: "Whiteboards")
                            ScanFeature(icon: "note.text", label: "Trainer Plans")
                            ScanFeature(icon: "iphone", label: "Screenshots")
                        }
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.sxDanger)
                        Text(error)
                            .font(SXFont.caption)
                            .foregroundColor(.sxDanger)
                    }
                    .padding(12)
                    .background(Color.sxDanger.opacity(0.08))
                    .cornerRadius(10)
                }

                // Parsed results
                if let workout = viewModel.parsedWorkout {
                    ParsedWorkoutResultView(workout: workout)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.sxBackground)
        .sheet(isPresented: $showingImageSource) {
            ImageSourceSheet(
                onCamera: {
                    showingImageSource = false
                    viewModel.showCamera = true
                },
                onLibrary: {
                    showingImageSource = false
                    viewModel.showImagePicker = true
                }
            )
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
        }
    }
}

// MARK: - Scan Feature

struct ScanFeature: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.sxAccent)
            Text(label)
                .font(SXFont.small)
                .foregroundColor(.sxTextTertiary)
        }
    }
}

// MARK: - Image Source Sheet

struct ImageSourceSheet: View {
    let onCamera: () -> Void
    let onLibrary: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Source")
                .font(SXFont.subheading)
                .foregroundColor(.sxTextPrimary)
                .padding(.top, 20)

            HStack(spacing: 20) {
                Button(action: onCamera) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                        Text("Camera")
                            .font(SXFont.medium(14))
                    }
                    .foregroundColor(.sxAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.sxSurface)
                    .cornerRadius(14)
                }

                Button(action: onLibrary) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 28))
                        Text("Photo Library")
                            .font(SXFont.medium(14))
                    }
                    .foregroundColor(.sxAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.sxSurface)
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.sxBackground)
    }
}

// MARK: - Parsed Workout Result

struct ParsedWorkoutResultView: View {
    let workout: ParsedWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parsed Workout")
                        .font(SXFont.subheading)
                        .foregroundColor(.sxTextPrimary)

                    Text("\(workout.exercises.count) exercises found")
                        .font(SXFont.caption)
                        .foregroundColor(.sxTextSecondary)
                }

                Spacer()

                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: confidenceIcon)
                        .foregroundColor(confidenceColor)
                    Text("\(Int(workout.confidence * 100))%")
                        .font(SXFont.semibold(13))
                        .foregroundColor(confidenceColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(confidenceColor.opacity(0.12))
                .cornerRadius(8)
            }

            // Exercise list
            ForEach(workout.exercises) { exercise in
                ParsedExerciseRow(exercise: exercise)
            }

            // Raw text (collapsible)
            DisclosureGroup {
                Text(workout.rawText)
                    .font(SXFont.small)
                    .foregroundColor(.sxTextTertiary)
                    .padding(.top, 8)
            } label: {
                Text("Raw OCR Text")
                    .font(SXFont.caption)
                    .foregroundColor(.sxTextSecondary)
            }
        }
        .sxCard()
    }

    private var confidenceColor: Color {
        if workout.confidence >= 0.8 { return .sxSuccess }
        if workout.confidence >= 0.5 { return .sxWarning }
        return .sxDanger
    }

    private var confidenceIcon: String {
        if workout.confidence >= 0.8 { return "checkmark.circle.fill" }
        if workout.confidence >= 0.5 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }
}

// MARK: - Parsed Exercise Row

struct ParsedExerciseRow: View {
    let exercise: ParsedExercise

    var body: some View {
        HStack(spacing: 12) {
            // Match indicator
            Circle()
                .fill(exercise.matchedExerciseId != nil ? Color.sxSuccess : Color.sxWarning)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(SXFont.medium(15))
                    .foregroundColor(.sxTextPrimary)

                HStack(spacing: 12) {
                    if let sets = exercise.sets, let reps = exercise.reps {
                        Text("\(sets)x\(reps)")
                            .font(SXFont.small)
                            .foregroundColor(.sxAccent)
                    }

                    if let weight = exercise.weight {
                        Text("\(weight.cleanWeight)kg")
                            .font(SXFont.small)
                            .foregroundColor(.sxTextSecondary)
                    }

                    if let muscle = exercise.muscleGroup {
                        Text(muscle.displayName)
                            .font(SXFont.small)
                            .foregroundColor(.sxTextTertiary)
                    }
                }
            }

            Spacer()

            if exercise.matchedExerciseId != nil {
                Image(systemName: "checkmark")
                    .font(.system(size: 12))
                    .foregroundColor(.sxSuccess)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Image Picker (UIKit Bridge)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
