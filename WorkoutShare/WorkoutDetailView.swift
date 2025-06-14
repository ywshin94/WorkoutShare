import SwiftUI
import PhotosUI

struct WorkoutDetailView: View {
    enum ActivePanel: Identifiable {
        case editor, color
        var id: Self { self }
    }
    
    let workout: StravaWorkout
    let workoutType: WorkoutType
    
    @State private var configuration: CanvasConfiguration
    
    @State private var gestureRotation: Angle = .zero
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    
    @State private var activePanel: ActivePanel? = nil
    
    init(workout: StravaWorkout) {
        self.workout = workout
        self.workoutType = WorkoutType.fromStravaType(workout.type)
        
        var initialConfig = CanvasConfiguration()
        initialConfig.initialize(for: self.workoutType)
        _configuration = State(initialValue: initialConfig)
    }

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let panelHeight = screenHeight * 0.5
            let bottomBarHeight: CGFloat = 72

            VStack(spacing: 0) {
                GeometryReader { contentGeometry in
                    ZStack {
                        Color(.secondarySystemBackground).edgesIgnoringSafeArea(.all)
                        displayedCanvasView(canvasAreaHeight: contentGeometry.size.height)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let panel = activePanel {
                    switch panel {
                    case .editor:
                        CanvasEditorView(
                            configuration: $configuration,
                            onClose: { activePanel = nil }
                        )
                        .frame(height: panelHeight)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .color:
                        ColorPickerView(
                            selectedColor: $configuration.backgroundColor,
                            useImageBackground: $configuration.useImageBackground,
                            onClose: { activePanel = nil }
                        )
                        .frame(height: panelHeight)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                bottomMenuBar(geometry: geometry)
                    .frame(height: bottomBarHeight)
                    .background(.thinMaterial)
            }
            .animation(.easeInOut(duration: 0.35), value: activePanel)
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.secondarySystemBackground))
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                do {
                    if let data = try await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        configuration.backgroundImage = image
                        configuration.useImageBackground = true
                    }
                } catch {
                    errorMessage = "이미지 처리 오류: \(error.localizedDescription)"
                }
            }
        }
    }

    private func displayedCanvasView(canvasAreaHeight: CGFloat) -> some View {
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
        let rotationGesture = RotationGesture()
            .onChanged { angle in gestureRotation = angle }
            .onEnded { angle in
                configuration.rotationAngle += angle
                gestureRotation = .zero
            }
        
        return CanvasView(
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
            rotationAngle: .constant(configuration.rotationAngle + gestureRotation)
        )
        .gesture(rotationGesture)
        .frame(width: finalCanvasWidth, height: finalCanvasHeight)
        .clipped()
    }
    
    private func bottomMenuBar(geometry: GeometryProxy) -> some View {
        HStack(spacing: 10) {
            Button {
                activePanel = .color
            } label: {
                Label("단색", systemImage: "paintpalette")
                    .frame(maxWidth: .infinity)
            }
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("이미지", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }

            Button {
                activePanel = activePanel == .editor ? nil : .editor
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
        .padding(.top, 10)
        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 10)
    }

    private func saveCanvas() {
        statusMessage = "Rendering..."
        errorMessage = nil

        let designWidth: CGFloat = 350.0
        let exportWidth: CGFloat = 1080.0
        let exportHeight = exportWidth / configuration.aspectRatio.ratio
        let exportSize = CGSize(width: exportWidth, height: exportHeight)
        let exportScaleFactor = exportWidth / designWidth

        let viewToSnapshot = CanvasView(
            workout: workout,
            useImageBackground: configuration.useImageBackground,
            // ✅ 이 부분을 원래대로 돌려놓아, 투명뿐만 아니라 다른 단색 배경도 올바르게 저장되도록 합니다.
            backgroundColor: configuration.backgroundColor,
            backgroundImage: configuration.backgroundImage,
            aspectRatio: configuration.aspectRatio.ratio,
            textAlignment: configuration.textAlignment.horizontalAlignment,
            workoutType: workoutType,
            selectedFontName: configuration.fontName,
            baseFontSize: configuration.baseFontSize,
            scaleFactor: exportScaleFactor,
            isForSnapshot: true,
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
        
        guard let image = viewToSnapshot.snapshot(size: exportSize) else {
            DispatchQueue.main.async {
                self.statusMessage = "이미지 생성 실패"
            }
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
                                self.statusMessage = "저장 완료!"
                            } else {
                                let errorMsg = error?.localizedDescription ?? "알 수 없는 오류"
                                self.statusMessage = "저장 실패: \(errorMsg)"
                            }
                        }
                    }
                default:
                    self.statusMessage = "사진첩 접근 권한이 없습니다."
                }
            }
        }
    }
}
