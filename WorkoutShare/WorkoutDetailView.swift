import SwiftUI
import PhotosUI
// AVKit 대신 PhotosUI만 import합니다.

// VideoPlayerManager는 더 이상 필요 없으므로 제거합니다.

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

    // 비디오 관련 State 프로퍼티 제거
    // @State private var selectedVideoItem: PhotosPickerItem?
    // @State private var selectedVideoURL: URL?
    // @State private var showVideoPreview: Bool = false
    // @StateObject private var videoPlayerManager = VideoPlayerManager() // 제거

    private static let allFontNames: [String] = {
        var names: [String] = []
        for familyName in UIFont.familyNames.sorted() {
            names.append(contentsOf: UIFont.fontNames(forFamilyName: familyName).sorted())
        }
        return names
    }()

    private var displayedCanvasView: some View {
        let screenWidth = UIScreen.main.bounds.width
        let canvasWidth = min(screenWidth - 40, 350)
        let canvasHeight = canvasWidth / selectedAspectRatio.ratio

        return ZStack(alignment: .center) {
            // 비디오 미리보기 관련 로직 제거
            // if showVideoPreview, let player = videoPlayerManager.player {
            //     VideoPlayer(player: player)
            //         .aspectRatio(contentMode: .fill)
            //         .frame(width: canvasWidth, height: canvasHeight)
            //         .clipped()
            //
            //     CanvasView(
            //         workout: workout,
            //         useImageBackground: false,
            //         backgroundColor: .clear,
            //         backgroundImage: nil,
            //         aspectRatio: selectedAspectRatio.ratio,
            //         textAlignment: selectedTextAlignment.horizontalAlignment,
            //         workoutType: selectedWorkoutType,
            //         selectedFontName: selectedFontName,
            //         baseFontSize: baseFontSize,
            //         accumulatedOffset: $canvasOffset
            //     )
            //     .frame(width: canvasWidth, height: canvasHeight)
            //     .clipped()
            // } else {
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
            // }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .clipped()
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
                        .foregroundColor(statusMessage == "Saved successfully" ? .green : .red) // 비디오 저장 관련 문구 제거
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(height: 30)
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("운동 타입", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }.pickerStyle(.menu)

                    Picker("폰트 선택", selection: $selectedFontName) {
                        ForEach(Self.allFontNames, id: \.self) { font in
                            Text(font).font(.custom(font, size: 14)).tag(font)
                        }
                    }.pickerStyle(.menu)

                    VStack(alignment: .leading) {
                        Text("텍스트 크기: \(Int(baseFontSize))")
                        Slider(value: $baseFontSize, in: 10...30, step: 1)
                    }

                    Picker("정렬", selection: $selectedTextAlignment) {
                        ForEach(TextAlignmentOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }.pickerStyle(.segmented)

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
                Button {
                    self.useImageBackground = false
                    // self.showVideoPreview = false // 비디오 관련 로직 제거
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
                                // self.showVideoPreview = false // 비디오 관련 로직 제거
                            } else {
                                self.errorMessage = "이미지를 로드할 수 없습니다."
                            }
                        } catch {
                            self.errorMessage = "이미지 처리 오류: \(error.localizedDescription)"
                        }
                    }
                }

                // 비디오 PhotosPicker 제거
                // PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                //     Label("비디오", systemImage: "film")
                //         .padding(.vertical, 10)
                //         .frame(maxWidth: .infinity)
                //         .background(Color.orange.opacity(0.15))
                //         .foregroundColor(.orange)
                //         .cornerRadius(8)
                //         .font(.footnote)
                // }
                // .onChange(of: selectedVideoItem) { _, newItem in
                //     guard let item = newItem else { return }
                //     Task {
                //         do {
                //             if let videoData = try await item.loadTransferable(type: Data.self) {
                //                 let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("selected_video.mov")
                //                 try videoData.write(to: tempURL)
                //                 self.selectedVideoURL = tempURL
                //                 videoPlayerManager.loadVideo(from: tempURL)
                //                 self.showVideoPreview = true
                //                 self.statusMessage = "비디오 미리보기 중..."
                //             } else {
                //                 self.errorMessage = "비디오를 로드할 수 없습니다."
                //             }
                //         } catch {
                //             self.errorMessage = "비디오 처리 오류: \(error.localizedDescription)"
                //         }
                //     }
                // }

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
        // .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        //     if showVideoPreview {
        //         videoPlayerManager.resume()
        //     }
        // } // 비디오 관련 로직 제거
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
