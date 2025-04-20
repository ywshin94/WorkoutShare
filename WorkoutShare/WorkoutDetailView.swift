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
    @State private var selectedAspectRatio: AspectRatioOption = .fourByFive
    @State private var selectedTextAlignment: TextAlignmentOption = .left
    @State private var selectedWorkoutType: WorkoutType = .run
    @State private var selectedFontName: String = "Futura-Bold"
    @State private var canvasOffset: CGSize = .zero
    @State private var baseFontSize: CGFloat = 13.0
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?

    private static let allFontNames: [String] = {
        var names: [String] = []
        for familyName in UIFont.familyNames.sorted() {
            names.append(contentsOf: UIFont.fontNames(forFamilyName: familyName).sorted())
        }
        return names
    }()

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
            baseFontSize: baseFontSize,
            accumulatedOffset: $canvasOffset
        )
    }

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
                        .foregroundColor(statusMessage == "Saved successfully" || statusMessage == "동영상 저장 완료!" ? .green : .red)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(height: 30)
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // 운동 타입
                    Picker("운동 타입", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }.pickerStyle(.menu)

                    // 폰트 선택
                    Picker("폰트 선택", selection: $selectedFontName) {
                        ForEach(Self.allFontNames, id: \.self) { font in
                            Text(font).font(.custom(font, size: 14)).tag(font)
                        }
                    }.pickerStyle(.menu)

                    // 텍스트 크기 조절
                    VStack(alignment: .leading) {
                        Text("텍스트 크기: \(Int(baseFontSize))")
                        Slider(value: $baseFontSize, in: 10...30, step: 1)
                    }

                    // 정렬
                    Picker("정렬", selection: $selectedTextAlignment) {
                        ForEach(TextAlignmentOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }.pickerStyle(.segmented)

                    // 캔버스 비율
                    Picker("비율", selection: $selectedAspectRatio) {
                        ForEach(AspectRatioOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }.pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            HStack(spacing: 10) {
                // 단색
                Button {
                    self.useImageBackground = false
                } label: {
                    Label("단색", systemImage: "paintpalette")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                        .font(.footnote)
                }

                // 이미지 선택
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("이미지", systemImage: "photo")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                        .font(.footnote)
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let item = newItem else { return }
                    Task {
                        do {
                            if let data = try await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                self.backgroundImage = image
                                self.useImageBackground = true
                            } else {
                                self.errorMessage = "이미지를 로드할 수 없습니다."
                            }
                        } catch {
                            self.errorMessage = "이미지 처리 오류: \(error.localizedDescription)"
                        }
                    }
                }

                // 비디오 선택
                PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                    Label("비디오", systemImage: "film")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                        .font(.footnote)
                }
                .onChange(of: selectedVideoItem) { _, newItem in
                    guard let item = newItem else { return }
                    Task {
                        do {
                            if let url = try await item.loadTransferable(type: URL.self) {
                                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                                try FileManager.default.copyItem(at: url, to: tmpURL)
                                self.selectedVideoURL = tmpURL
                                print("✅ 비디오 선택됨: \(tmpURL)")
                                if let overlayImage = displayedCanvasView.snapshot(aspectRatio: selectedAspectRatio.ratio) {
                                    VideoOverlayExporter.overlayImage(on: tmpURL, with: overlayImage) { success, error in
                                        if success {
                                            self.statusMessage = "동영상 저장 완료!"
                                        } else {
                                            self.errorMessage = error?.localizedDescription ?? "동영상 저장 실패"
                                        }
                                    }
                                } else {
                                    self.errorMessage = "커버 이미지를 만들 수 없습니다."
                                }
                            } else {
                                self.errorMessage = "비디오 URL을 로드할 수 없습니다."
                            }
                        } catch {
                            self.errorMessage = "비디오 처리 오류: \(error.localizedDescription)"
                        }
                    }
                }

                // 저장
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
    }

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
            statusMessage = "Failed to render canvas"
            return
        }

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
                            } else {
                                let errorMsg = error?.localizedDescription ?? "Unknown error"
                                self.statusMessage = "Failed to save: \(errorMsg)"
                            }
                        }
                    }
                default:
                    self.statusMessage = "Photo library access denied."
                }
            }
        }
    }
}
