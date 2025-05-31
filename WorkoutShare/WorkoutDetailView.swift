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
    @State private var selectedWorkoutType: WorkoutType
    @State private var selectedFontName: String = "Futura-Bold"
    @State private var canvasOffset: CGSize = .zero
    @State private var baseFontSize: CGFloat = 13.0

    // 각 운동 정보 항목의 표시 여부를 제어하는 State 변수
    @State private var showDistance: Bool
    @State private var showDuration: Bool
    @State private var showPace: Bool
    @State private var showSpeed: Bool
    @State private var showElevation: Bool
    // @State private var showCalories: Bool // ✨ 제거
    @State private var showLabels: Bool = true

    // MARK: - Initializer
    // 외부에서 workout을 받아올 때 초기값 설정
    init(workout: StravaWorkout) {
        self.workout = workout
        let initialWorkoutType = WorkoutType.fromStravaType(workout.type)
        
        _selectedWorkoutType = State(initialValue: initialWorkoutType)
        
        _showDistance = State(initialValue: initialWorkoutType.showsDistance)
        _showDuration = State(initialValue: initialWorkoutType.showsDuration)
        _showElevation = State(initialValue: initialWorkoutType.showsElevation)
        // _showCalories = State(initialValue: initialWorkoutType.showsCalories) // ✨ 제거
        _showLabels = State(initialValue: true) // 제목 표시 기본값 true

        // 페이스와 속도 초기값 설정 로직 변경
        if initialWorkoutType.isPacePrimary {
            _showPace = State(initialValue: true)
            _showSpeed = State(initialValue: false)
        } else if initialWorkoutType.isSpeedPrimary {
            _showPace = State(initialValue: false)
            _showSpeed = State(initialValue: true)
        } else { // 기타 (예: Weight)
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

        return ZStack(alignment: .center) {
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
                showDistance: $showDistance,
                showDuration: $showDuration,
                showPace: $showPace,
                showSpeed: $showSpeed,
                showElevation: $showElevation,
                // showCalories: $showCalories, // ✨ 제거
                showLabels: $showLabels,
                accumulatedOffset: $canvasOffset
            )
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
                    Picker("운동 타입", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedWorkoutType) { _, newType in
                        showDistance = newType.showsDistance
                        showDuration = newType.showsDuration
                        showElevation = newType.showsElevation
                        // showCalories = newType.showsCalories // ✨ 제거
                        showLabels = true // 운동 타입 변경 시 제목은 다시 표시

                        // 페이스/속도 토글 상태 업데이트 로직
                        if newType.isPacePrimary {
                            showPace = true
                            showSpeed = false
                        } else if newType.isSpeedPrimary {
                            showPace = false
                            showSpeed = true
                        } else {
                            showPace = false
                            showSpeed = false
                        }
                    }

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
                        // Toggle(isOn: $showCalories) { // ✨ 제거
                        //     Text("칼로리 표시")
                        // }
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
            workoutType: selectedWorkoutType,
            selectedFontName: selectedFontName,
            baseFontSize: baseFontSize,
            showDistance: $showDistance,
            showDuration: $showDuration,
            showPace: $showPace,
            showSpeed: $showSpeed,
            showElevation: $showElevation,
            // showCalories: $showCalories, // ✨ 제거
            showLabels: $showLabels,
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
