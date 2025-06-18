import SwiftUI
import CoreGraphics

struct CanvasView: View {
    // MARK: - Properties
    let workout: StravaWorkout
    let useImageBackground: Bool
    let backgroundColor: Color
    let backgroundImage: UIImage?
    let aspectRatio: CGFloat
    let textAlignment: HorizontalAlignment
    let workoutType: WorkoutType
    let selectedFontName: String
    let baseFontSize: CGFloat
    let scaleFactor: CGFloat
    
    // 스냅샷 생성용인지 여부를 구분하는 프로퍼티
    let isForSnapshot: Bool
    
    @Binding var textColorValue: CGFloat

    @Binding var showDistance: Bool
    @Binding var showDuration: Bool
    @Binding var showPace: Bool
    @Binding var showSpeed: Bool
    @Binding var showElevation: Bool
    @Binding var showLabels: Bool
    @Binding var layoutDirection: LayoutDirectionOption
    @Binding var showTitle: Bool
    @Binding var showDateTime: Bool

    @Binding var accumulatedOffset: CGSize
    @Binding var rotationAngle: Angle

    @State private var currentDragOffset: CGSize = .zero
    @State private var textSize: CGSize = .zero

    private let baseLabelFootnoteSize: CGFloat = 13.0
    private let baseLabelCaptionSize: CGFloat = 12.0

    init(
        workout: StravaWorkout,
        useImageBackground: Bool,
        backgroundColor: Color,
        backgroundImage: UIImage?,
        aspectRatio: CGFloat,
        textAlignment: HorizontalAlignment,
        workoutType: WorkoutType,
        selectedFontName: String,
        baseFontSize: CGFloat,
        scaleFactor: CGFloat,
        isForSnapshot: Bool = false,
        textColorValue: Binding<CGFloat>,
        showDistance: Binding<Bool>,
        showDuration: Binding<Bool>,
        showPace: Binding<Bool>,
        showSpeed: Binding<Bool>,
        showElevation: Binding<Bool>,
        showLabels: Binding<Bool>,
        layoutDirection: Binding<LayoutDirectionOption>,
        showTitle: Binding<Bool>,
        showDateTime: Binding<Bool>,
        accumulatedOffset: Binding<CGSize>,
        rotationAngle: Binding<Angle>
    ) {
        self.workout = workout
        self.useImageBackground = useImageBackground
        self.backgroundColor = backgroundColor
        self.backgroundImage = backgroundImage
        self.aspectRatio = aspectRatio
        self.textAlignment = textAlignment
        self.workoutType = workoutType
        self.selectedFontName = selectedFontName
        self.baseFontSize = baseFontSize
        self.scaleFactor = scaleFactor
        self.isForSnapshot = isForSnapshot
        self._textColorValue = textColorValue
        self._showDistance = showDistance
        self._showDuration = showDuration
        self._showPace = showPace
        self._showSpeed = showSpeed
        self._showElevation = showElevation
        self._showLabels = showLabels
        self._layoutDirection = layoutDirection
        self._showTitle = showTitle
        self._showDateTime = showDateTime
        self._accumulatedOffset = accumulatedOffset
        self._rotationAngle = rotationAngle
    }


    private var textAlign: TextAlignment {
        switch textAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yy @ h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    private func dragGesture(in canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                self.currentDragOffset = value.translation
            }
            .onEnded { value in
                let potentialViewOffset = CGSize(
                    width: (self.accumulatedOffset.width * self.scaleFactor) + value.translation.width,
                    height: (self.accumulatedOffset.height * self.scaleFactor) + value.translation.height
                )
                let clampedViewOffset = self.clampOffset(
                    potentialOffset: potentialViewOffset,
                    canvasSize: canvasSize
                )
                let newAccumulatedOffset = self.scaleFactor > 0 ? CGSize(
                    width: clampedViewOffset.width / self.scaleFactor,
                    height: clampedViewOffset.height / self.scaleFactor
                ) : .zero
                self.accumulatedOffset = newAccumulatedOffset
                self.currentDragOffset = .zero
            }
    }

    private func clampOffset(potentialOffset: CGSize, canvasSize: CGSize) -> CGSize {
        let currentBorderMargin: CGFloat = rotationAngle.degrees.isZero ? 5.0 : 0.0
        let originalWidth = textSize.width
        let originalHeight = textSize.height
        let angleRadians = rotationAngle.radians
        let transform = CGAffineTransform(rotationAngle: angleRadians)
        let halfOriginalWidth = originalWidth / 2
        let halfOriginalHeight = originalHeight / 2
        let p1 = CGPoint(x: -halfOriginalWidth, y: -halfOriginalHeight).applying(transform)
        let p2 = CGPoint(x: halfOriginalWidth, y: -halfOriginalHeight).applying(transform)
        let p3 = CGPoint(x: -halfOriginalWidth, y: halfOriginalHeight).applying(transform)
        let p4 = CGPoint(x: halfOriginalWidth, y: halfOriginalHeight).applying(transform)
        let rotatedMinX = min(p1.x, p2.x, p3.x, p4.x)
        let rotatedMaxX = max(p1.x, p2.x, p3.x, p4.x)
        let rotatedMinY = min(p1.y, p2.y, p3.y, p4.y)
        let rotatedMaxY = max(p1.y, p2.y, p3.y, p4.y)
        let rotatedBlockWidth = rotatedMaxX - rotatedMinX
        let rotatedBlockHeight = rotatedMaxY - rotatedMinY
        let halfCanvasWidth = canvasSize.width / 2
        let halfCanvasHeight = canvasSize.height / 2
        let maxX = halfCanvasWidth - (rotatedBlockWidth / 2) - currentBorderMargin
        let minX = -halfCanvasWidth + (rotatedBlockWidth / 2) + currentBorderMargin
        let maxY = halfCanvasHeight - (rotatedBlockHeight / 2) - currentBorderMargin
        let minY = -halfCanvasHeight + (rotatedBlockHeight / 2) + currentBorderMargin
        if rotatedBlockWidth + 2 * currentBorderMargin > canvasSize.width || rotatedBlockHeight + 2 * currentBorderMargin > canvasSize.height {
            return potentialOffset
        }
        return CGSize(
            width: max(minX, min(potentialOffset.width, maxX)),
            height: max(minY, min(potentialOffset.height, maxY))
        )
    }

    private func applyFont(baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = max(1, (baseSize * baseFontSize / 17.0) * scaleFactor)
        if let _ = UIFont(name: selectedFontName, size: scaledSize) {
             return Font.custom(selectedFontName, size: scaledSize)
        } else {
             print("Warning: Font '\(selectedFontName)' not found. Using system font.")
             return Font.system(size: scaledSize, weight: weight)
        }
    }

    var body: some View {
        let primaryColor = Color(white: textColorValue)
        let secondaryColor = primaryColor.opacity(0.8)

        ZStack(alignment: .center) {
            // MARK: - Background Layer
            // 이 로직은 편집/저장 모두에 적용됩니다.
            // useImageBackground 값에 따라 이미지 또는 단색/투명 배경을 설정합니다.
            if useImageBackground, let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // 단색(backgroundColor)과 투명(Color.clear) 배경을 모두 처리합니다.
                backgroundColor
            }
            
            // MARK: - UI Helper Layer
            // 이 격자무늬는 편집 시에만 보이고, 저장 시에는 렌더링되지 않습니다.
            if !isForSnapshot && !useImageBackground && backgroundColor == .clear {
                CheckerboardView()
            }

            // MARK: - Content Layer
            GeometryReader { canvasGeometry in
                VStack(alignment: textAlignment, spacing: 0) {
                    if showDateTime {
                        Text(workout.startDate, formatter: dateFormatter)
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(secondaryColor)
                            .padding(.bottom, showTitle ? 0 : 2 * scaleFactor)
                    }

                    if showTitle {
                        Text(workout.name)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(primaryColor)
                    }

                    if showTitle || showDateTime {
                        Spacer().frame(height: 4 * scaleFactor)
                    }

                    if layoutDirection == .horizontal {
                        HStack(alignment: .top, spacing: 15 * scaleFactor) {
                            workoutInfoItems
                        }
                    } else {
                        VStack(alignment: textAlignment, spacing: 4 * scaleFactor) {
                            workoutInfoItems
                        }
                    }
                }
                .padding(.horizontal, max(5 * scaleFactor, 15 * scaleFactor))
                .padding(.vertical, max(5 * scaleFactor, 10 * scaleFactor))
                .background(
                    GeometryReader { textBlockGeometry in
                        Color.clear
                            .onAppear {
                                self.textSize = textBlockGeometry.size
                            }
                            .onChange(of: textBlockGeometry.size) { _, newSize in
                                self.textSize = newSize
                            }
                    }
                )
                .rotationEffect(rotationAngle, anchor: .center)
                .position(
                    x: canvasGeometry.size.width / 2 + (accumulatedOffset.width * scaleFactor) + currentDragOffset.width,
                    y: canvasGeometry.size.height / 2 + (accumulatedOffset.height * scaleFactor) + currentDragOffset.height
                )
                .gesture(dragGesture(in: canvasGeometry.size))
            }
        }
        .clipped()
    }

    @ViewBuilder
    private var workoutInfoItems: some View {
        let primaryColor = Color(white: textColorValue)
        let secondaryColor = primaryColor.opacity(0.8)

        if showDistance && workout.distance > 0 {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("거리").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(secondaryColor) }
                Text(workout.formattedDistance).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(primaryColor)
            }
        }
        if showDuration {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("시간").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(secondaryColor) }
                Text(workout.formattedDuration).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(primaryColor)
            }
        }
        if showPace && workoutType.showsPace {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("페이스").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(secondaryColor) }
                Text(workout.formattedPace).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(primaryColor)
            }
        }
        if showSpeed && workoutType.showsSpeed {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("속도").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(secondaryColor) }
                Text(workout.formattedSpeed).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(primaryColor)
            }
        }
        if showElevation && workoutType.showsElevation {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("상승고도").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(secondaryColor) }
                Text(workout.formattedElevationGain).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(primaryColor)
            }
        }
    }
}
