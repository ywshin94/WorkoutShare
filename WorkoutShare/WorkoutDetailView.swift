import SwiftUI
import PhotosUI

struct WorkoutDetailView: View {
    // MARK: - Properties and State
    
    enum ActivePanel: Identifiable {
        case style, layout, items, color
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
    @State private var showingSettings = false
    
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
                
                activePanelView(maxHeight: geometry.size.height * 0.5)
                
                bottomMenuBar(geometry: geometry)
            }
            .animation(.easeInOut(duration: 0.35), value: activePanel?.id)
            .edgesIgnoringSafeArea(.bottom)
            .background(Color(.systemGray6))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("비율", selection: $configuration.aspectRatio) {
                            ForEach(AspectRatioOption.allCases) { option in Text(option.rawValue).tag(option) }
                        }
                    } label: { Label("비율", systemImage: "aspectratio") }
                    Button { activePanel = (activePanel == .color) ? nil : .color } label: { Label("단색", systemImage: "paintpalette") }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) { Label("이미지", systemImage: "photo") }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(stravaService)
            }
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
                Color(.systemGray6).edgesIgnoringSafeArea(.all)
                displayedCanvasView(canvasAreaHeight: contentGeometry.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // ✅ [수정] activePanelView의 로직을 명확하게 분리하여 높이를 제어합니다.
    @ViewBuilder
    func activePanelView(maxHeight: CGFloat) -> some View {
        if let panel = activePanel {
            let dragToDismiss = DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        activePanel = nil
                    }
                }

            switch panel {
            case .style, .items:
                // '스타일', '항목'은 고정 높이를 가집니다.
                CanvasEditorView(configuration: $configuration, mode: panel)
                    .frame(height: maxHeight)
                    .gesture(dragToDismiss)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                
            case .layout:
                // '레이아웃'은 프레임을 지정하지 않아 내용물에 맞게 높이가 조절됩니다.
                CanvasEditorView(configuration: $configuration, mode: panel)
                    .gesture(dragToDismiss)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

            case .color:
                // '색상' 패널도 내용물에 맞게 조절됩니다.
                ColorPickerView(selectedColor: $configuration.backgroundColor, useImageBackground: $configuration.useImageBackground, onClose: { activePanel = nil })
                    .gesture(dragToDismiss)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    func bottomMenuBar(geometry: GeometryProxy) -> some View {
        let bottomBarHeight: CGFloat = 72
        
        HStack(alignment: .top) {
            Button(action: onFetchWorkout) {
                BottomBarButtonLabel(iconName: "list.bullet", text: "운동 선택")
            }
            
            Button(action: { activePanel = (activePanel == .style) ? nil : .style }) {
                BottomBarButtonLabel(iconName: "textformat.size", text: "스타일")
                    .foregroundColor(activePanel == .style ? .accentColor : .primary)
            }
            Button(action: { activePanel = (activePanel == .layout) ? nil : .layout }) {
                BottomBarButtonLabel(iconName: "rectangle.grid.2x2", text: "레이아웃")
                    .foregroundColor(activePanel == .layout ? .accentColor : .primary)
            }
            Button(action: { activePanel = (activePanel == .items) ? nil : .items }) {
                BottomBarButtonLabel(iconName: "checkmark.square.fill", text: "항목")
                    .foregroundColor(activePanel == .items ? .accentColor : .primary)
            }
            
            Button(action: saveCanvas) {
                BottomBarButtonLabel(iconName: "square.and.arrow.down", text: "저장")
            }
        }
        .padding(.horizontal, 8)
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
                    textColor: $configuration.textColor,
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
                    Text(text).font(.system(size: 10))
                case .customImage(let imageName):
                    Image(imageName).resizable().scaledToFit().frame(height: 24)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    func saveCanvas() {
        statusMessage = "이미지 생성 중..."
        errorMessage = nil
        
        let designWidth: CGFloat = 350.0
        let exportWidth: CGFloat = 1080.0
        let exportHeight = exportWidth / configuration.aspectRatio.ratio
        let exportSize = CGSize(width: exportWidth, height: exportHeight)
        let exportScaleFactor = exportWidth / designWidth
        
        let viewToSnapshot = CanvasView(
            workout: workout, useImageBackground: configuration.useImageBackground,
            backgroundColor: configuration.backgroundColor, backgroundImage: configuration.backgroundImage,
            aspectRatio: configuration.aspectRatio.ratio, textAlignment: configuration.textAlignment.horizontalAlignment,
            workoutType: workoutType, selectedFontName: configuration.fontName, baseFontSize: configuration.baseFontSize,
            scaleFactor: exportScaleFactor, isForSnapshot: true,
            textColor: .constant(configuration.textColor),
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

        guard let image = viewToSnapshot.snapshot(size: exportSize) else {
            DispatchQueue.main.async { self.statusMessage = "이미지 생성 실패" }
            return
        }

        guard let pngData = image.pngData() else {
            DispatchQueue.main.async { self.statusMessage = "PNG 데이터 변환 실패" }
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        do {
            try pngData.write(to: tempURL)
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "임시 파일 저장 실패: \(error.localizedDescription)"
            }
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            let capturedTempURL = tempURL
            
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: capturedTempURL)
                    }) { success, error in
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
