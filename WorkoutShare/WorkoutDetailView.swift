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
    @State private var selectedFontName: String = "Futura-Bold"
    @State private var canvasOffset: CGSize = .zero
    @State private var baseFontSize: CGFloat = 13.0

    @State private var showDistance: Bool
    @State private var showDuration: Bool
    @State private var showPace: Bool
    @State private var showSpeed: Bool
    @State private var showElevation: Bool
    @State private var showLabels: Bool = true

    @State private var selectedLayoutDirection: LayoutDirectionOption = .vertical

    @State private var rotationAngle: Angle = .zero
    @State private var gestureRotation: Angle = .zero

    private let workoutType: WorkoutType

    init(workout: StravaWorkout) {
        self.workout = workout
        let initialWorkoutType = WorkoutType.fromStravaType(workout.type)
        self.workoutType = initialWorkoutType

        _showDistance = State(initialValue: initialWorkoutType.showsDistance)
        _showDuration = State(initialValue: initialWorkoutType.showsDuration)
        _showElevation = State(initialValue: initialWorkoutType.showsElevation)
        _showLabels = State(initialValue: true)
        _selectedLayoutDirection = State(initialValue: .vertical)
        _canvasOffset = State(initialValue: .zero)
        _rotationAngle = State(initialValue: .zero)

        if initialWorkoutType.isPacePrimary {
            _showPace = State(initialValue: true)
            _showSpeed = State(initialValue: false)
        } else if initialWorkoutType.isSpeedPrimary {
            _showPace = State(initialValue: false)
            _showSpeed = State(initialValue: true)
        } else {
            _showPace = State(initialValue: false)
            _showSpeed = State(initialValue: false)
        }
    }

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

        let rotationGesture = RotationGesture()
            .onChanged { angle in
                gestureRotation = angle
            }
            .onEnded { angle in
                rotationAngle += angle
                gestureRotation = .zero
            }

        return ZStack(alignment: .center) {
            CanvasView(
                workout: workout,
                useImageBackground: useImageBackground,
                backgroundColor: backgroundColor,
                backgroundImage: backgroundImage,
                aspectRatio: selectedAspectRatio.ratio,
                textAlignment: selectedTextAlignment.horizontalAlignment,
                workoutType: workoutType,
                selectedFontName: selectedFontName,
                baseFontSize: baseFontSize,
                showDistance: $showDistance,
                showDuration: $showDuration,
                showPace: $showPace,
                showSpeed: $showSpeed,
                showElevation: $showElevation,
                showLabels: $showLabels,
                layoutDirection: $selectedLayoutDirection,
                accumulatedOffset: $canvasOffset,
                rotationAngle: .constant(rotationAngle + gestureRotation)
            )
            .gesture(rotationGesture)
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
                        .foregroundColor(statusMessage == "Saved successfully" ? .green : .red)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(height: 30)
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
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

                    Picker("레이아웃", selection: $selectedLayoutDirection) {
                        ForEach(LayoutDirectionOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }.pickerStyle(.segmented)

                    // 회전 슬라이더 완전히 제거

                    Section("표시 항목 선택") {
                        Toggle(isOn: $showLabels) {
                            Text("항목 제목 표시 (예: '거리', '시간')")
                        }
                        Toggle(isOn: $showDistance) {
                            Text("거리 표시")
                        }
                        Toggle(isOn: $showDuration) {
                            Text("시간 표시")
                        }
                        Toggle(isOn: $showPace) {
                            Text("페이스 표시")
                        }
                        Toggle(isOn: $showSpeed) {
                            Text("속도 표시")
                        }
                        Toggle(isOn: $showElevation) {
                            Text("상승고도 표시")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            HStack(spacing: 10) {
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
            workoutType: workoutType,
            selectedFontName: selectedFontName,
            baseFontSize: baseFontSize,
            showDistance: $showDistance,
            showDuration: $showDuration,
            showPace: $showPace,
            showSpeed: $showSpeed,
            showElevation: $showElevation,
            showLabels: $showLabels,
            layoutDirection: $selectedLayoutDirection,
            accumulatedOffset: $canvasOffset,
            rotationAngle: .constant(rotationAngle)
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

