import SwiftUI
import PhotosUI

struct WorkoutDetailView: View {
    // MARK: - Properties
    let workout: StravaWorkout

    // MARK: - State Variables
    @State private var useImageBackground: Bool = false
    @State private var backgroundColor: Color = .blue
    @State private var backgroundImage: UIImage?
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var statusMessage: String?
    @State private var selectedAspectRatio: AspectRatioOption = .oneByOne
    @State private var selectedTextAlignment: TextAlignmentOption = .left
    @State private var selectedWorkoutType: WorkoutType = .run
    @State private var selectedFontName: String = "HelveticaNeue"
    @State private var canvasOffset: CGSize = .zero
    @State private var baseFontSize: CGFloat = 17.0 // 새로 추가: 폰트 크기

    private static let allFontNames: [String] = {
        var names: [String] = []
        for familyName in UIFont.familyNames.sorted() {
            names.append(contentsOf: UIFont.fontNames(forFamilyName: familyName).sorted())
        }
        print("Loaded \(names.count) font names.")
        return names
    }()

    // MARK: - Computed Properties
    private var displayedCanvasView: some View {
        CanvasView(
            workout: workout,
            useImageBackground: useImageBackground,
            backgroundColor: backgroundColor,
            backgroundImage: backgroundImage,
            aspectRatio: selectedAspectRatio.ratio,
            textAlignment: selectedTextAlignment.horizontalAlignment,
            workoutType: selectedWorkoutType,
            selectedFontName: selectedFontName,
            baseFontSize: baseFontSize, // 폰트 크기 전달
            accumulatedOffset: $canvasOffset
        )
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            displayedCanvasView
                .padding()

            VStack {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .lineLimit(1)
                }
                if let statusMessage = statusMessage {
                    Text(statusMessage)
                        .foregroundColor(statusMessage == "Saved successfully" ? .green : .red)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(height: 30)
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    Picker("운동 종류", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("폰트", selection: $selectedFontName) {
                        ForEach(Self.allFontNames, id: \.self) { fontName in
                            Text(fontName).tag(fontName)
                                .font(.custom(fontName, size: 14))
                                .truncationMode(.tail)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("폰트 크기").font(.caption).foregroundColor(.secondary)
                        Slider(value: $baseFontSize, in: 10.0...30.0, step: 1.0) {
                            Text("폰트 크기")
                        } minimumValueLabel: {
                            Text("10")
                        } maximumValueLabel: {
                            Text("30")
                        }
                        Text("현재 크기: \(Int(baseFontSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("비율").font(.caption).foregroundColor(.secondary)
                        Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                            ForEach(AspectRatioOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("정렬").font(.caption).foregroundColor(.secondary)
                        Picker("텍스트 정렬", selection: $selectedTextAlignment) {
                            ForEach(TextAlignmentOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom)
            }

            HStack(spacing: 10) {
                Button {
                    useImageBackground = false
                    backgroundColor = Color(
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

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("이미지", systemImage: "photo")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        .font(.footnote)
                }
                .onChange(of: selectedPhotoItem) { newItem in
                    Task {
                        guard let newItem = newItem,
                              let data = try? await newItem.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            await MainActor.run { errorMessage = "Failed to load image." }
                            return
                        }
                        await MainActor.run {
                            self.backgroundImage = image
                            self.useImageBackground = true
                            self.errorMessage = nil
                            self.statusMessage = nil
                        }
                    }
                }

                Button {
                    saveCanvas()
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
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedWorkoutType = WorkoutType(rawValue: workout.type) ?? .run
            if !Self.allFontNames.contains(selectedFontName), let fallbackFont = Self.allFontNames.first {
                selectedFontName = fallbackFont
                print("Default font '\(selectedFontName)' not found, using '\(fallbackFont)'")
            }
        }
    }

    // MARK: - Save Function
    private func saveCanvas() {
        statusMessage = "Rendering..."
        errorMessage = nil

        let viewToSnapshot = CanvasView(
            workout: workout,
            useImageBackground: useImageBackground,
            backgroundColor: backgroundColor,
            backgroundImage: backgroundImage,
            aspectRatio: selectedAspectRatio.ratio,
            textAlignment: selectedTextAlignment.horizontalAlignment,
            workoutType: selectedWorkoutType,
            selectedFontName: selectedFontName,
            baseFontSize: baseFontSize,
            accumulatedOffset: $canvasOffset
        )

        guard let image = viewToSnapshot.snapshot(aspectRatio: selectedAspectRatio.ratio) else {
            print("Failed to render canvas as image")
            statusMessage = "Failed to render canvas"
            return
        }
        print("Rendered image size: \(image.size), scale: \(image.scale)")

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
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
                default:
                    self.statusMessage = "Photo library access denied."
                    print("Photo library access denied or restricted.")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(
            workout: StravaWorkout(
                id: 1, name: "Afternoon Jog", distance: 5230.0, movingTime: 1950, type: "Run", startDate: Date().addingTimeInterval(-3600 * 24), totalElevationGain: 25.5, kilojoules: 1500.0
            )
        )
    }
}
