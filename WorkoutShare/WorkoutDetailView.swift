import SwiftUI
import PhotosUI

struct WorkoutDetailView: View {
    let workout: StravaWorkout
    @State private var useImageBackground: Bool = false
    @State private var backgroundColor: Color = .blue
    @State private var backgroundImage: UIImage?
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var statusMessage: String?

    private var canvasView: CanvasView {
        CanvasView(
            workout: workout,
            useImageBackground: useImageBackground,
            backgroundColor: backgroundColor,
            backgroundImage: backgroundImage,
            aspectRatio: 1.0
        )
    }

    var body: some View {
        VStack {
            canvasView
                .padding() // 배경과 둥근 모서리는 CanvasView에서 처리

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            if let statusMessage = statusMessage {
                Text(statusMessage)
                    .foregroundColor(statusMessage == "Saved successfully" ? .green : .red)
                    .padding()
            }

            HStack {
                Button(action: {
                    print("Use Solid Color button tapped")
                    useImageBackground = false
                    backgroundColor = .blue
                    errorMessage = nil
                }) {
                    Text("Use Solid Color")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Text("Use Image")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .onChange(of: selectedPhotoItem) { newItem in
                    print("PhotosPicker selection changed: \(String(describing: newItem))")
                    if let newItem = newItem {
                        Task {
                            do {
                                if let data = try await newItem.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        self.backgroundImage = image
                                        self.useImageBackground = true
                                        self.errorMessage = nil
                                        print("Successfully loaded image from PhotosPicker")
                                    }
                                } else {
                                    await MainActor.run {
                                        self.errorMessage = "Failed to load image: Invalid data"
                                        print("Failed to create UIImage from data")
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                                    print("Failed to load image from PhotosPicker: \(error)")
                                }
                            }
                        }
                    }
                }

                Button(action: {
                    print("Save Canvas button tapped")
                    saveCanvas()
                }) {
                    Text("Save Canvas")
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            Text("Debug: useImageBackground = \(useImageBackground.description)")
                .foregroundColor(.gray)
                .padding()

            Text("Date: \(workout.startDate, formatter: dateFormatter)")
                .padding()
        }
        .navigationTitle("Workout Details")
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func saveCanvas() {
        guard #available(iOS 16.0, *) else {
            print("ImageRenderer is only available on iOS 16.0 or later")
            statusMessage = "Image saving is not supported on this iOS version"
            return
        }

        guard let image = canvasView.snapshot(aspectRatio: 1.0) else {
            print("Failed to render canvas as image")
            statusMessage = "Failed to render canvas"
            return
        }

        print("Rendered image size: \(image.size)")

        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Successfully saved canvas to photo library")
                            self.statusMessage = "Saved successfully"
                        } else if let error = error {
                            print("Failed to save canvas to photo library: \(error.localizedDescription)")
                            self.statusMessage = "Failed to save: \(error.localizedDescription)"
                        }
                    }
                }
            case .denied, .restricted, .notDetermined:
                DispatchQueue.main.async {
                    print("Photo library access denied")
                    self.statusMessage = "Photo library access denied"
                }
            @unknown default:
                DispatchQueue.main.async {
                    print("Unknown authorization status")
                    self.statusMessage = "Unknown authorization status"
                }
            }
        }
    }
}

#Preview {
    WorkoutDetailView(
        workout: StravaWorkout(
            id: 1,
            name: "Morning Run",
            distance: 5000.0,
            movingTime: 1800,
            type: "Run",
            startDate: Date()
        )
    )
}
