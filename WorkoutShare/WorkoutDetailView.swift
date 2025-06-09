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

    @State private var showDistance: Bool
    @State private var showDuration: Bool
    @State private var showPace: Bool
    @State private var showSpeed: Bool
    @State private var showElevation: Bool
    @State private var showLabels: Bool = true
    @State private var selectedLayoutDirection: LayoutDirectionOption = .vertical

    // 회전 각도 상태
    @State private var rotationAngle: Angle = .zero
    @State private var gestureRotation: Angle = .zero

    // 편집 패널 표시 여부
    @State private var showEditorPanel: Bool = false

    // MARK: - Initializer
    init(workout: StravaWorkout) {
        self.workout = workout
        let initialWorkoutType = WorkoutType.fromStravaType(workout.type)
        _selectedWorkoutType = State(initialValue: initialWorkoutType)
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

    var body: some View {
        GeometryReader { geometry in
            // 전체 화면 높이
            let screenHeight = geometry.size.height
            // 메뉴 패널 높이 (40%)
            let menuPanelHeight = screenHeight * 0.4
            // 바텀 메뉴바 높이 (고정값)
            let bottomBarHeight: CGFloat = 72
            // 캔버스 영역 높이 (메뉴창이 올라오면 그만큼 줄임)
            let canvasAreaHeight = showEditorPanel
                ? screenHeight - menuPanelHeight - bottomBarHeight
                : screenHeight - bottomBarHeight

            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    displayedCanvasView(canvasAreaHeight: canvasAreaHeight)
                        .padding(.top)
                    Spacer(minLength: 0)
                }
                .navigationTitle("Workout Details")
                .navigationBarTitleDisplayMode(.inline)

                // 바텀 메뉴바 (항상 맨 아래 고정)
                bottomMenuBar
                    .frame(height: bottomBarHeight)
                    .background(.thinMaterial)
                    .ignoresSafeArea(edges: .bottom)
                    .zIndex(2)

                // 에디터 패널 바텀시트 (바텀바 위에, 내부 스크롤)
                BottomSheetEditorPanel(
                    isPresented: $showEditorPanel,
                    height: menuPanelHeight,
                    selectedFontName: $selectedFontName,
                    baseFontSize: $baseFontSize,
                    selectedTextAlignment: $selectedTextAlignment,
                    selectedAspectRatio: $selectedAspectRatio,
                    selectedLayoutDirection: $selectedLayoutDirection,
                    showLabels: $showLabels,
                    showDistance: $showDistance,
                    showDuration: $showDuration,
                    showPace: $showPace,
                    showSpeed: $showSpeed,
                    showElevation: $showElevation
                )
                .zIndex(3)
            }
        }
    }

    // 캔버스 뷰 (높이 조절)
    private func displayedCanvasView(canvasAreaHeight: CGFloat) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        let canvasWidth = min(screenWidth - 40, 350)
        // 캔버스 비율에 맞춰 최대 높이 제한
        let maxCanvasHeight = canvasWidth / selectedAspectRatio.ratio
        let canvasHeight = min(canvasAreaHeight - 16, maxCanvasHeight)

        // 회전 제스처
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
                workoutType: selectedWorkoutType,
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

    // 하단 메뉴바 (편집 버튼 포함, 항상 고정)
    private var bottomMenuBar: some View {
        HStack(spacing: 10) {
            Button {
                self.useImageBackground = false
            } label: {
                Label("단색", systemImage: "paintpalette")
                    .frame(maxWidth: .infinity)
            }
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("이미지", systemImage: "photo")
                    .frame(maxWidth: .infinity)
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

            // 편집 메뉴 버튼 (토글)
            Button {
                withAnimation(.easeInOut) {
                    showEditorPanel.toggle()
                }
            } label: {
                Label("편집", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }

            Button {
                saveCanvas()
            } label: {
                Label("저장", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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

// 바텀시트 편집툴 패널 (스크롤 지원, 바텀바 위에만 올라옴)
struct BottomSheetEditorPanel: View {
    @Binding var isPresented: Bool
    let height: CGFloat

    @Binding var selectedFontName: String
    @Binding var baseFontSize: CGFloat
    @Binding var selectedTextAlignment: TextAlignmentOption
    @Binding var selectedAspectRatio: AspectRatioOption
    @Binding var selectedLayoutDirection: LayoutDirectionOption
    @Binding var showLabels: Bool
    @Binding var showDistance: Bool
    @Binding var showDuration: Bool
    @Binding var showPace: Bool
    @Binding var showSpeed: Bool
    @Binding var showElevation: Bool

    private static let allFontNames: [String] = {
        var names: [String] = []
        for familyName in UIFont.familyNames.sorted() {
            names.append(contentsOf: UIFont.fontNames(forFamilyName: familyName).sorted())
        }
        return names
    }()

    var body: some View {
        Group {
            if isPresented {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 48, height: 6)
                            .padding(.top, 8)
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation { isPresented = false }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.trailing, 12)
                        }
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 16) {
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
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                    }
                    .frame(height: height)
                    .background(.ultraThinMaterial)
                    .cornerRadius(18, corners: [.topLeft, .topRight])
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
                .animation(.easeInOut, value: isPresented)
            }
        }
    }
}

// 바텀시트 라운드 코너 확장
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 10.0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

