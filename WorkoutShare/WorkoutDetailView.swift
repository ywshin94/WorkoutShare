import SwiftUI
import PhotosUI

struct WorkoutDetailView: View {
    // MARK: - Properties and State
    enum ActivePanel: Identifiable {
        case editor, color
        var id: Self { self }
    }
    
    let workout: StravaWorkout
    let workoutType: WorkoutType
    var onFetchWorkout: () -> Void
    
    @EnvironmentObject private var stravaService: StravaService
    
    @State private var configuration: CanvasConfiguration
    
    @State private var gestureRotation: Angle = .zero
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    
    @State private var activePanel: ActivePanel? = nil
    @State private var showingLogoutConfirm = false
    
    init(workout: StravaWorkout, onFetchWorkout: @escaping () -> Void) {
        self.workout = workout
        self.workoutType = WorkoutType.fromStravaType(workout.type)
        self.onFetchWorkout = onFetchWorkout
        
        var initialConfig = CanvasConfiguration()
        initialConfig.initialize(for: self.workoutType)
        _configuration = State(initialValue: initialConfig)
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                canvasArea
                
                if workout.id != -1 {
                    StravaAttributionView()
                }
                
                activePanelView(height: geometry.size.height * 0.5)
                
                bottomMenuBar(geometry: geometry)
            }
            .animation(.easeInOut(duration: 0.35), value: activePanel)
            .edgesIgnoringSafeArea(.bottom)
            // ✅ [수정] 앱 전체 배경색을 밝은 회색으로 변경
            .background(Color(.systemGray6))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingLogoutConfirm = true } label: { Image(systemName: "person.crop.circle.badge.xmark") }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("비율", selection: $configuration.aspectRatio) {
                            ForEach(AspectRatioOption.allCases) { option in Text(option.rawValue).tag(option) }
                        }
                    } label: { Label("비율", systemImage: "aspectratio") }
                    Button { activePanel = .color } label: { Label("단색", systemImage: "paintpalette") }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) { Label("이미지", systemImage: "photo") }
                }
            }
            .confirmationDialog("로그아웃", isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
                Button("Strava 연결 해제", role: .destructive) { Task { await stravaService.deauthorize() } }
                Button("취소", role: .cancel) {}
            } message: { Text("앱과 Strava의 연결을 해제하고 로그아웃합니다. 이 동작은 되돌릴 수 없습니다.") }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                do {
                    if let data = try await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        configuration.backgroundImage = image
                        configuration.useImageBackground = true
                    }
                } catch { errorMessage = "이미지 처리 오류: \(error.localizedDescription)" }
            }
        }
    }
}


// MARK: - Refactored Helper Views
private extension WorkoutDetailView {
    
    @ViewBuilder
    var canvasArea: some View {
        GeometryReader { contentGeometry in
            ZStack {
                // ✅ [수정] 캔버스 주변 배경색도 밝은 회색으로 변경
                Color(.systemGray6).edgesIgnoringSafeArea(.all)
                displayedCanvasView(canvasAreaHeight: contentGeometry.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func activePanelView(height: CGFloat) -> some View {
        if let panel = activePanel {
            switch panel {
            case .editor:
                CanvasEditorView(configuration: $configuration, onClose: { activePanel = nil })
                    .frame(height: height)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .color:
                ColorPickerView(selectedColor: $configuration.backgroundColor, useImageBackground: $configuration.useImageBackground, onClose: { activePanel = nil })
                    .frame(height: height)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    func bottomMenuBar(geometry: GeometryProxy) -> some View {
        let bottomBarHeight: CGFloat = 72
        
        HStack {
            Button(action: onFetchWorkout) {
                BottomBarButtonLabel(iconName: "list.bullet", text: "운동 선택")
            }
            Button(action: { activePanel = activePanel == .editor ? nil : .editor }) {
                BottomBarButtonLabel(iconName: "slider.horizontal.3", text: "편집")
            }
            Button(action: saveCanvas) {
                BottomBarButtonLabel(iconName: "square.and.arrow.down", text: "저장")
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .frame(height: bottomBarHeight)
        .padding(.bottom, geometry.safeAreaInsets.bottom)
        .background(.thinMaterial)
    }
    
    func displayedCanvasView(canvasAreaHeight: CGFloat) -> some View {
        if canvasAreaHeight > 20 {
            let screenWidth = UIScreen.main.bounds.width
            let availableWidth = screenWidth - 40
            let availableHeight = canvasAreaHeight - 20
            let designWidth: CGFloat = 350.0
            var finalCanvasWidth: CGFloat
            var finalCanvasHeight: CGFloat
            
            if availableWidth / configuration.aspectRatio.ratio <= availableHeight {
                finalCanvasWidth = availableWidth
                finalCanvasHeight = availableWidth / configuration.aspectRatio.ratio
            } else {
                finalCanvasHeight = availableHeight
                finalCanvasWidth = availableHeight * configuration.aspectRatio.ratio
            }
            
            let scaleFactor = finalCanvasWidth / designWidth
            
            return AnyView(
                CanvasView(
                    workout: workout,
                    useImageBackground: configuration.useImageBackground,
                    backgroundColor: configuration.backgroundColor,
                    backgroundImage: configuration.backgroundImage,
                    aspectRatio: configuration.aspectRatio.ratio,
                    textAlignment: configuration.textAlignment.horizontalAlignment,
                    workoutType: workoutType,
                    selectedFontName: configuration.fontName,
                    baseFontSize: configuration.baseFontSize,
                    scaleFactor: scaleFactor,
                    isForSnapshot: false,
                    textColorValue: $configuration.textColorValue,
                    showDistance: $configuration.showDistance,
                    showDuration: $configuration.showDuration,
                    showPace: $configuration.showPace,
                    showSpeed: $configuration.showSpeed,
                    showElevation: $configuration.showElevation,
                    showLabels: $configuration.showLabels,
                    layoutDirection: $configuration.layoutDirection,
                    showTitle: $configuration.showTitle,
                    showDateTime: $configuration.showDateTime,
                    accumulatedOffset: $configuration.accumulatedOffset,
                    rotationAngle: $configuration.rotationAngle
                )
                .gesture(RotationGesture().onEnded { angle in
                    configuration.rotationAngle += angle
                })
                .frame(width: finalCanvasWidth, height: finalCanvasHeight)
                .clipped()
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    struct BottomBarButtonLabel: View {
        enum Content {
            case iconAndText(iconName: String, text: String)
            case customImage(imageName: String)
        }
        let content: Content
        init(iconName: String, text: String) { self.content = .iconAndText(iconName: iconName, text: text) }
        init(imageName: String) { self.content = .customImage(imageName: imageName) }
        var body: some View {
            VStack(spacing: 4) {
                switch content {
                case .iconAndText(let iconName, let text):
                    Image(systemName: iconName).font(.title3)
                    Text(text).font(.caption)
                case .customImage(let imageName):
                    Image(imageName).resizable().scaledToFit().frame(height: 24)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    // ✅ [최종 수정] 투명 배경 이미지 저장을 위해 임시 파일을 사용하는 방식으로 변경
    func saveCanvas() {
        statusMessage = "이미지 생성 중..."
        errorMessage = nil
        
        // 1. 저장할 이미지의 크기와 스케일 팩터 설정
        let designWidth: CGFloat = 350.0
        let exportWidth: CGFloat = 1080.0
        let exportHeight = exportWidth / configuration.aspectRatio.ratio
        let exportSize = CGSize(width: exportWidth, height: exportHeight)
        let exportScaleFactor = exportWidth / designWidth
        
        // 2. 렌더링할 CanvasView 생성
        let viewToSnapshot = CanvasView(
            workout: workout, useImageBackground: configuration.useImageBackground,
            backgroundColor: configuration.backgroundColor, backgroundImage: configuration.backgroundImage,
            aspectRatio: configuration.aspectRatio.ratio, textAlignment: configuration.textAlignment.horizontalAlignment,
            workoutType: workoutType, selectedFontName: configuration.fontName, baseFontSize: configuration.baseFontSize,
            scaleFactor: exportScaleFactor, isForSnapshot: true,
            textColorValue: .constant(configuration.textColorValue),
            showDistance: .constant(configuration.showDistance),
            showDuration: .constant(configuration.showDuration),
            showPace: .constant(configuration.showPace),
            showSpeed: .constant(configuration.showSpeed),
            showElevation: .constant(configuration.showElevation),
            showLabels: .constant(configuration.showLabels),
            layoutDirection: .constant(configuration.layoutDirection),
            showTitle: .constant(configuration.showTitle),
            showDateTime: .constant(configuration.showDateTime),
            accumulatedOffset: .constant(configuration.accumulatedOffset),
            rotationAngle: .constant(configuration.rotationAngle)
        )

        // 3. 뷰를 UIImage로 캡처
        guard let image = viewToSnapshot.snapshot(size: exportSize) else {
            DispatchQueue.main.async { self.statusMessage = "이미지 생성 실패" }
            return
        }

        // 4. UIImage를 PNG 데이터로 변환 (투명도 유지를 위해 필수)
        guard let pngData = image.pngData() else {
            DispatchQueue.main.async { self.statusMessage = "PNG 데이터 변환 실패" }
            return
        }

        // 5. PNG 데이터를 저장할 임시 파일 경로 생성
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        // 6. PNG 데이터를 임시 파일로 디스크에 저장
        do {
            try pngData.write(to: tempURL)
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "임시 파일 저장 실패: \(error.localizedDescription)"
            }
            return
        }

        // 7. 사진 앨범 접근 권한 요청
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            // 권한 처리 후 임시 파일을 정리하기 위해 URL을 캡처
            let capturedTempURL = tempURL
            
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // 8. 사진 앨범에 저장
                    PHPhotoLibrary.shared().performChanges({
                        // UIImage 객체 대신, 임시 파일 URL을 사용하여 저장 요청
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: capturedTempURL)
                    }) { success, error in
                        // 9. 작업 완료 후 임시 파일 삭제 (성공/실패 무관)
                        try? FileManager.default.removeItem(at: capturedTempURL)
                        
                        DispatchQueue.main.async {
                            if success {
                                self.statusMessage = "사진 앨범에 저장 완료!"
                            } else {
                                self.statusMessage = "저장 실패: \(error?.localizedDescription ?? "알 수 없는 오류")"
                            }
                        }
                    }
                default:
                    // 10. 권한이 없는 경우에도 임시 파일 삭제
                    try? FileManager.default.removeItem(at: capturedTempURL)
                    self.statusMessage = "사진첩 접근 권한이 없습니다."
                }
            }
        }
    }
}

struct StravaAttributionView: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://www.strava.com") {
                UIApplication.shared.open(url)
            }
        }) {
            Image("powered_by_strava")
                .resizable()
                .scaledToFit()
                .frame(height: 12)
        }
        .padding(.vertical, 4)
    }
}
