import SwiftUI
import PhotosUI // For PhotosPicker

struct WorkoutDetailView: View {
    // MARK: - Properties

    let workout: StravaWorkout // Data for the workout being detailed

    // MARK: - State Variables

    // UI State for Canvas Background
    @State private var useImageBackground: Bool = false
    @State private var backgroundColor: Color = .blue // Default solid color
    @State private var backgroundImage: UIImage?

    // UI State for Feedback & Selection
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem? // For PhotosPicker
    @State private var statusMessage: String?

    // Canvas Options State (Managed by this View)
    @State private var selectedAspectRatio: AspectRatioOption = .oneByOne // Default 1:1
    @State private var selectedTextAlignment: TextAlignmentOption = .left // Default left align
    @State private var selectedWorkoutType: WorkoutType = .run // Default Run type
    @State private var selectedFontName: String = "HelveticaNeue" // Default font name string

    // Canvas Interaction State (Managed by this View, Passed as Bindings)
    @State private var canvasOffset: CGSize = .zero // Text block's offset from center
    @State private var canvasScale: CGFloat = 1.0   // Text block's scale factor

    // --- Font Selection Data ---
    // Load all available system font names once statically
    private static let allFontNames: [String] = {
        var names: [String] = []
        // Iterate through font families and their respective font names
        for familyName in UIFont.familyNames.sorted() {
            names.append(contentsOf: UIFont.fontNames(forFamilyName: familyName).sorted())
        }
        print("Loaded \(names.count) font names.") // Log how many fonts were found
        return names
    }()
    // --- End Font Selection Data ---


    // MARK: - Computed Properties

    // Creates the CanvasView instance to be displayed on screen, passing current state
    private var displayedCanvasView: some View {
        CanvasView(
            workout: workout,
            useImageBackground: useImageBackground,
            backgroundColor: backgroundColor,
            backgroundImage: backgroundImage,
            aspectRatio: selectedAspectRatio.ratio,
            textAlignment: selectedTextAlignment.horizontalAlignment,
            workoutType: selectedWorkoutType,
            selectedFontName: selectedFontName, // Pass the selected font name string
            accumulatedOffset: $canvasOffset, // Pass offset binding
            finalScale: $canvasScale         // Pass scale binding
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) { // Main container stack
            // 1. Canvas Display Area
            displayedCanvasView
                .padding() // Padding around the canvas

            // 2. Feedback Messages Area
            VStack {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .lineLimit(1) // Limit message lines
                }
                if let statusMessage = statusMessage {
                    Text(statusMessage)
                        .foregroundColor(statusMessage == "Saved successfully" ? .green : .red)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(height: 30) // Fixed height for messages
            .padding(.horizontal)

            // 3. Controls Area (Scrollable)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) { // Spacing between control sections

                    // Workout Type Picker
                    Picker("운동 종류", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu) // Dropdown menu style

                    // Font Picker (using all system fonts)
                    Picker("폰트", selection: $selectedFontName) {
                        // Iterate through all found font names
                        ForEach(Self.allFontNames, id: \.self) { fontName in
                            Text(fontName).tag(fontName)
                                // Apply the font itself in the picker row for preview
                                .font(.custom(fontName, size: 14))
                                .truncationMode(.tail) // Truncate long names if needed
                        }
                    }
                    // Use NavigationLink style for better handling of very long lists
                    .pickerStyle(.navigationLink)

                    // Aspect Ratio Picker
                    VStack(alignment: .leading, spacing: 4) { // Label + Picker
                        Text("비율").font(.caption).foregroundColor(.secondary)
                        Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                            ForEach(AspectRatioOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented) // Segmented control style
                    }

                    // Text Alignment Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("정렬").font(.caption).foregroundColor(.secondary)
                        Picker("텍스트 정렬", selection: $selectedTextAlignment) {
                            ForEach(TextAlignmentOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented) // Segmented control style
                    }
                }
                .padding(.horizontal) // Padding for the control group
                .padding(.top) // Padding above the control group
                .padding(.bottom) // Padding below the control group
            } // End of ScrollView

            // 4. Action Buttons Area (Bottom Fixed)
            HStack(spacing: 10) { // Spacing between buttons
                // Solid Color Button
                Button {
                    useImageBackground = false
                    backgroundColor = Color( // Pick a slightly different blue
                        red: .random(in: 0...1),
                        green: .random(in: 0...1),
                        blue: .random(in: 0...1)
                    )
                    errorMessage = nil
                    statusMessage = nil
                } label: {
                    Label("단색", systemImage: "paintpalette")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                        .font(.footnote)
                }

                // Image Background Button (PhotosPicker)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("이미지", systemImage: "photo")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        .font(.footnote)
                }
                .onChange(of: selectedPhotoItem) { newItem in // Handle image selection
                    Task { // Load image asynchronously
                        guard let newItem = newItem,
                              let data = try? await newItem.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            await MainActor.run { errorMessage = "Failed to load image." }
                            return
                        }
                        // Update state on main thread
                        await MainActor.run {
                            self.backgroundImage = image
                            self.useImageBackground = true
                            self.errorMessage = nil
                            self.statusMessage = nil // Clear previous status
                        }
                    }
                }

                // Save Button
                Button {
                    saveCanvas() // Trigger save action
                } label: {
                    Label("저장", systemImage: "square.and.arrow.down")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                        .font(.footnote)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal) // Padding around buttons
            .padding(.vertical, 10) // Padding above/below buttons
            .background(.thinMaterial) // Subtle background for button area

        } // End of main VStack
        .navigationTitle("Workout Details") // Set navigation bar title
        .navigationBarTitleDisplayMode(.inline) // Center title
        .onAppear {
            // Ensure a valid default font is selected when the view appears
            if !Self.allFontNames.contains(selectedFontName), let fallbackFont = Self.allFontNames.first {
                 selectedFontName = fallbackFont
                 print("Default font '\(selectedFontName)' not found, using '\(fallbackFont)'")
            } else if Self.allFontNames.isEmpty {
                 // Handle edge case where no fonts are found (very unlikely)
                 print("Error: No system fonts found!")
                 errorMessage = "Error: No fonts available."
                 selectedFontName = UIFont.systemFont(ofSize: 1).fontName // Absolute fallback
            }
        }
    } // End of body

    // MARK: - Save Function

    private func saveCanvas() {
        statusMessage = "Rendering..." // Indicate saving process started
        errorMessage = nil

        // Create the CanvasView instance specifically for snapshotting,
        // passing the current state values (via bindings).
        let viewToSnapshot = CanvasView(
            workout: workout,
            useImageBackground: useImageBackground,
            backgroundColor: backgroundColor,
            backgroundImage: backgroundImage,
            aspectRatio: selectedAspectRatio.ratio,
            textAlignment: selectedTextAlignment.horizontalAlignment,
            workoutType: selectedWorkoutType,
            selectedFontName: selectedFontName, // Pass current font name
            accumulatedOffset: $canvasOffset, // Pass current offset binding
            finalScale: $canvasScale         // Pass current scale binding
        )

        // Generate the snapshot (uses the extension method)
        guard let image = viewToSnapshot.snapshot(aspectRatio: selectedAspectRatio.ratio) else {
            print("Failed to render canvas as image")
            statusMessage = "Failed to render canvas"
            return
        }
        print("Rendered image size: \(image.size), scale: \(image.scale)")

        // Request photo library authorization and save the image
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async { // Ensure UI updates are on the main thread
                switch status {
                case .authorized, .limited: // Permission granted (full or limited)
                    PHPhotoLibrary.shared().performChanges({
                        // Create a request to save the image to the photo library
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        // Handle save result on the main thread
                        DispatchQueue.main.async {
                            if success {
                                self.statusMessage = "Saved successfully"
                                print("Successfully saved canvas")
                            } else {
                                let errorMsg = error?.localizedDescription ?? "Unknown error"
                                self.statusMessage = "Failed to save: \(errorMsg)"
                                print("Failed to save canvas: \(errorMsg)")
                            }
                        }
                    }
                default: // .denied, .restricted, .notDetermined
                    self.statusMessage = "Photo library access denied."
                    print("Photo library access denied or restricted.")
                }
            }
        }
    } // End of saveCanvas
} // End of struct WorkoutDetailView

// MARK: - Preview

#Preview {
    NavigationView { // Wrap in NavigationView for preview context
        WorkoutDetailView(
            workout: StravaWorkout( // Sample workout data for preview
                id: 1, name: "Afternoon Jog Example", distance: 5230.0, movingTime: 1950,
                type: "Run", startDate: Date().addingTimeInterval(-3600 * 24), // Yesterday
                totalElevationGain: 25.5
            )
        )
    }
}
