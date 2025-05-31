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
    let workoutType: WorkoutType // WorkoutType enum 사용
    let selectedFontName: String
    let baseFontSize: CGFloat

    @Binding var showDistance: Bool
    @Binding var showDuration: Bool
    @Binding var showPace: Bool
    @Binding var showSpeed: Bool
    @Binding var showElevation: Bool
    @Binding var showLabels: Bool
    @Binding var layoutDirection: LayoutDirectionOption

    @Binding var accumulatedOffset: CGSize
    @Binding var rotationAngle: Angle

    @State private var currentDragOffset: CGSize = .zero
    @State private var textSize: CGSize = .zero // 텍스트 블록의 실제 크기

    // MARK: - Constants
    // borderMargin은 이제 clampOffset 내에서 동적으로 결정되므로, 여기서의 상수는 기본값으로 남겨두거나 제거할 수 있습니다.
    // 여기서는 사용되지 않으므로 제거합니다.
    // private let borderMargin: CGFloat = 0.0 // ✨ 제거
    private let baseLabelFootnoteSize: CGFloat = 13.0
    private let baseLabelCaptionSize: CGFloat = 12.0

    private var canvasWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(screenWidth - 40, 350)
    }
    private var canvasHeight: CGFloat {
        return canvasWidth / aspectRatio
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
        formatter.dateFormat = "MMM d, BBBB 'at' h:mm a" // 요청하신 포맷: "May 31, 2025 at 7:11 PM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // currentDragOffset은 임시 드래그 값
                self.currentDragOffset = value.translation
            }
            .onEnded { value in
                // 드래그 종료 시, 현재 누적된 오프셋에 최종 드래그 값을 더하고 클램프
                let newAccumulatedOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                self.accumulatedOffset = clampOffset(potentialOffset: newAccumulatedOffset)
                self.currentDragOffset = .zero // 드래그 종료 시 임시 오프셋 초기화
            }
    }

    // ✨ clampOffset 함수 수정: 회전 값에 따라 borderMargin 동적 적용
    private func clampOffset(potentialOffset: CGSize) -> CGSize {
        // 회전 각도에 따라 적용할 마진 값 결정
        let currentBorderMargin: CGFloat
        if rotationAngle.degrees.isZero { // 회전이 0도일 때 (허용 오차 범위 내)
            currentBorderMargin = 5.0 // 회전 없을 때 보더 영역 유지
        } else {
            currentBorderMargin = 0.0 // 회전 있을 때 보더 영역 제거
        }

        // 텍스트 블록의 원본 크기
        let originalWidth = textSize.width
        let originalHeight = textSize.height

        // 회전 변환 행렬 생성 (실제 회전 각도 사용)
        let angleRadians = rotationAngle.radians
        let transform = CGAffineTransform(rotationAngle: angleRadians)

        // 텍스트 블록의 네 꼭지점 (중심을 0,0으로 간주)
        let halfOriginalWidth = originalWidth / 2
        let halfOriginalHeight = originalHeight / 2

        let p1 = CGPoint(x: -halfOriginalWidth, y: -halfOriginalHeight).applying(transform)
        let p2 = CGPoint(x: halfOriginalWidth, y: -halfOriginalHeight).applying(transform)
        let p3 = CGPoint(x: -halfOriginalWidth, y: halfOriginalHeight).applying(transform)
        let p4 = CGPoint(x: halfOriginalWidth, y: halfOriginalHeight).applying(transform)

        // 회전 후의 최소/최대 X, Y 좌표를 찾아 바운딩 박스 크기 계산
        let rotatedMinX = min(p1.x, p2.x, p3.x, p4.x)
        let rotatedMaxX = max(p1.x, p2.x, p3.x, p4.x)
        let rotatedMinY = min(p1.y, p2.y, p3.y, p4.y)
        let rotatedMaxY = max(p1.y, p2.y, p3.y, p4.y)

        let rotatedBlockWidth = rotatedMaxX - rotatedMinX
        let rotatedBlockHeight = rotatedMaxY - rotatedMinY

        // 캔버스 중앙을 기준으로 제한 영역 계산
        let halfCanvasWidth = canvasWidth / 2
        let halfCanvasHeight = canvasHeight / 2

        // 회전된 블록의 중심이 캔버스 경계 내에 있도록 제한
        let maxX = halfCanvasWidth - (rotatedBlockWidth / 2) - currentBorderMargin
        let minX = -halfCanvasWidth + (rotatedBlockWidth / 2) + currentBorderMargin
        let maxY = halfCanvasHeight - (rotatedBlockHeight / 2) - currentBorderMargin
        let minY = -halfCanvasHeight + (rotatedBlockHeight / 2) + currentBorderMargin

        // 회전된 블록의 크기가 캔버스보다 크다면 제한하지 않음 (이 경우 움직임이 자유로움)
        if rotatedBlockWidth + 2 * currentBorderMargin > canvasWidth || rotatedBlockHeight + 2 * currentBorderMargin > canvasHeight {
            return potentialOffset
        }
        
        return CGSize(
            width: max(minX, min(potentialOffset.width, maxX)),
            height: max(minY, min(potentialOffset.height, maxY))
        )
    }

    private func applyFont(baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = max(1, baseSize * baseFontSize / 17.0)
        if let _ = UIFont(name: selectedFontName, size: scaledSize) {
             return Font.custom(selectedFontName, size: scaledSize)
        } else {
            print("Warning: Font '\(selectedFontName)' not found. Using system font.")
            return Font.system(size: scaledSize, weight: weight)
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            if useImageBackground, let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: canvasWidth, height: canvasHeight)
                    .clipped()
                    .overlay(Color.black.opacity(0.3))
            } else {
                backgroundColor
                    .frame(width: canvasWidth, height: canvasHeight)
            }

            // 캔버스 전체 GeometryReader (캔버스 크기 파악)
            GeometryReader { canvasGeometry in
                // 운동 정보 블록 (회전은 여기서 적용)
                VStack(alignment: textAlignment, spacing: 0) {
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text(workout.startDate, formatter: dateFormatter)
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.name)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer().frame(height: 4)

                    if layoutDirection == .horizontal {
                        HStack(alignment: .top, spacing: 15) {
                            workoutInfoItems
                        }
                    } else {
                        VStack(alignment: textAlignment, spacing: 4) {
                            workoutInfoItems
                        }
                    }
                }
                .padding(.horizontal, max(5, 15))
                .padding(.vertical, max(5, 10))
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
                // 변형(Transform) 효과들을 먼저 적용합니다.
                // 뷰의 로컬 중심을 기준으로 회전만 적용됩니다.
                .rotationEffect(-rotationAngle, anchor: .center) // 회전 방향 반전 유지
                // 이후에 위치를 조정합니다.
                .position(x: canvasGeometry.size.width / 2 + accumulatedOffset.width + currentDragOffset.width,
                          y: canvasGeometry.size.height / 2 + accumulatedOffset.height + currentDragOffset.height)
                .gesture(dragGesture)
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .clipped()
        .drawingGroup()
        .onAppear {
            print("CanvasView loaded. Target Size: \(canvasWidth)x\(canvasHeight)")
        }
        .onChange(of: selectedFontName) { _, newFont in
            if UIFont(name: newFont, size: 10) == nil {
                print("Warning: Selected font '\(newFont)' might not be available.")
            }
        }
    }

    @ViewBuilder
    private var workoutInfoItems: some View {
        if showDistance && workout.distance > 0 {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("거리").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(.white.opacity(0.8)) }
                Text(workout.formattedDistance).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(.white)
            }
        }
        if showDuration {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("시간").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(.white.opacity(0.8)) }
                Text(workout.formattedDuration).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(.white)
            }
        }
        if showPace && workoutType.showsPace {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("페이스").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(.white.opacity(0.8)) }
                Text(workout.formattedPace).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(.white)
            }
        }
        if showSpeed && workoutType.showsSpeed {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("속도").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(.white.opacity(0.8)) }
                Text(workout.formattedSpeed).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(.white)
            }
        }
        if showElevation && workoutType.showsElevation {
            VStack(alignment: textAlignment, spacing: 0) {
                if showLabels { Text("상승고도").font(applyFont(baseSize: baseLabelCaptionSize * 0.9)).foregroundColor(.white.opacity(0.8)) }
                Text(workout.formattedElevationGain).font(applyFont(baseSize: 17.0, weight: .semibold)).foregroundColor(.white)
            }
        }
    }
}
