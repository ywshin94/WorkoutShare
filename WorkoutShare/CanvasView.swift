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
    @State private var textSize: CGSize = .zero

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
        formatter.dateFormat = "MMM d, yyyy @ h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                self.currentDragOffset = value.translation
            }
            .onEnded { value in
                let newAccumulatedOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                self.accumulatedOffset = clampOffset(potentialOffset: newAccumulatedOffset)
                self.currentDragOffset = .zero
            }
    }

    private func clampOffset(potentialOffset: CGSize) -> CGSize {
        let currentBorderMargin: CGFloat
        if rotationAngle.degrees.isZero {
            currentBorderMargin = 5.0
        } else {
            currentBorderMargin = 0.0
        }

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

        let halfCanvasWidth = canvasWidth / 2
        let halfCanvasHeight = canvasHeight / 2

        let maxX = halfCanvasWidth - (rotatedBlockWidth / 2) - currentBorderMargin
        let minX = -halfCanvasWidth + (rotatedBlockWidth / 2) + currentBorderMargin
        let maxY = halfCanvasHeight - (rotatedBlockHeight / 2) - currentBorderMargin
        let minY = -halfCanvasHeight + (rotatedBlockHeight / 2) + currentBorderMargin

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

            GeometryReader { canvasGeometry in
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
                .rotationEffect(rotationAngle, anchor: .center) // 회전 방향: 제스처와 일치
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

