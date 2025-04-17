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
    @State private var selectedAspectRatio: AspectRatioOption = .fourByFive // 기본값
    @State private var selectedTextAlignment: TextAlignmentOption = .left
    @State private var selectedWorkoutType: WorkoutType = .run
    @State private var selectedFontName: String = "Futura-Bold" // 기본값
    @State private var canvasOffset: CGSize = .zero
    // <<<--- 기본 폰트 크기 변경 ---<<<
    @State private var baseFontSize: CGFloat = 14.0 // 13.0 에서 14.0 으로 변경
    // >>>---------------------->>>

    // 사용 가능한 모든 폰트 이름 로드
    private static let allFontNames: [String] = {
        var names: [String] = []
        for familyName in UIFont.familyNames.sorted() {
            names.append(contentsOf: UIFont.fontNames(forFamilyName: familyName).sorted())
        }
        print("Loaded \(names.count) font names.")
        return names
    }()

    // MARK: - Computed Properties
    // CanvasView에 전달되는 부분
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
            baseFontSize: baseFontSize, // 변경된 기본값 14.0 전달
            accumulatedOffset: $canvasOffset
        )
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // 캔버스 표시 부분
            displayedCanvasView
                .padding()

            // 상태 메시지 표시 부분
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

            // 옵션 설정 스크롤 뷰
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    // 운동 종류 선택
                    Picker("운동 종류", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    // 폰트 선택 Picker (스크롤 기능은 기본 제공 안 됨)
                    Picker("폰트", selection: $selectedFontName) {
                        ForEach(Self.allFontNames, id: \.self) { fontName in
                            Text(fontName).tag(fontName)
                                .font(.custom(fontName, size: 14))
                                .truncationMode(.tail)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedFontName) { oldValue, newValue in
                        print("Font selection changed!")
                        print(" - Old value: \(oldValue)")
                        print(" - New value: \(newValue)")
                    }

                    // 폰트 크기 슬라이더 (기본값 14.0으로 시작)
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

                    // 비율 선택
                    VStack(alignment: .leading, spacing: 4) {
                        Text("비율").font(.caption).foregroundColor(.secondary)
                        Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                            ForEach(AspectRatioOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // 정렬 선택
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

            // 하단 버튼 영역
            HStack(spacing: 10) {
                // 단색 배경 버튼
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

                // 이미지 선택 버튼 (PhotosPicker)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("이미지", systemImage: "photo")
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        .font(.footnote)
                }
                .onChange(of: selectedPhotoItem) { oldItem, newItem in
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

                // 저장 버튼
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
        .onAppear { // 뷰가 나타날 때 실행
            selectedWorkoutType = WorkoutType(rawValue: workout.type) ?? .run
            // 선택된 폰트 유효성 검사
            if !Self.allFontNames.contains(selectedFontName), let fallbackFont = Self.allFontNames.first {
                let originalFont = selectedFontName
                selectedFontName = fallbackFont
                print("Default font '\(originalFont)' not found or invalid, using fallback '\(fallbackFont)'")
            } else {
                 print("Current font on appear: \(selectedFontName)")
            }
            
            // <<<--- 칼로리 디버깅 로그 추가 ---<<<
            print("---------- Workout Detail Log ----------")
            print("Workout Name: \(workout.name)")
            print("Workout ID: \(workout.id)") // 어떤 운동인지 확인용
            print("Raw Kilojoules received: \(workout.kilojoules ?? -1.0)") // API에서 받은 원본 값 확인 (nil이면 -1.0 출력)
            if let kj = workout.kilojoules {
                let calculatedKcal = kj / 4.184
                print("Calculated kcal (before format): \(calculatedKcal)") // 서식 적용 전 계산값
            }
            print("Formatted Calories (displayed): \(workout.formattedCalories)") // 최종 표시될 값
            print("--------------------------------------")
            // >>>---------------------------------->>>
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

        // 스냅샷 생성
        guard let image = viewToSnapshot.snapshot(aspectRatio: selectedAspectRatio.ratio) else {
            print("Failed to render canvas as image")
            statusMessage = "Failed to render canvas"
            return
        }
        print("Rendered image size: \(image.size), scale: \(image.scale)")

        // 사진 라이브러리 접근 권한 요청 및 저장
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

// Preview 부분
#Preview {
    NavigationView { // Preview에서도 NavigationView 필요
        WorkoutDetailView(
            workout: StravaWorkout(
                id: 1,
                name: "Afternoon Jog",
                distance: 5230.0,
                movingTime: 1950,
                type: "Run",
                startDate: Date().addingTimeInterval(-3600 * 24),
                totalElevationGain: 25.5,
                kilojoules: 1500.0
            )
        )
    }
}
