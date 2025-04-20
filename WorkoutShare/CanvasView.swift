import SwiftUI

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
    let baseFontSize: CGFloat // 폰트 크기 조절용

    // 드래그 관련 상태
    @Binding var accumulatedOffset: CGSize
    @State private var currentDragOffset: CGSize = .zero
    @State private var textSize: CGSize = .zero

    // MARK: - Constants
    private let borderMargin: CGFloat = 10.0
    private let baseLabelFootnoteSize: CGFloat = 13.0
    private let baseLabelCaptionSize: CGFloat = 12.0

    // MARK: - Computed Properties
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

    // MARK: - Gestures
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let potentialOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                self.currentDragOffset = CGSize(
                    width: clampOffset(potentialOffset: potentialOffset).width - accumulatedOffset.width,
                    height: clampOffset(potentialOffset: potentialOffset).height - accumulatedOffset.height
                )
            }
            .onEnded { value in
                let finalOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                self.accumulatedOffset = clampOffset(potentialOffset: finalOffset)
                self.currentDragOffset = .zero
            }
    }

    // MARK: - Helper Functions
    private func clampOffset(potentialOffset: CGSize) -> CGSize {
        let textHalfWidth = textSize.width / 2
        let textHalfHeight = textSize.height / 2
        let canvasHalfWidth = canvasWidth / 2
        let canvasHalfHeight = canvasHeight / 2
        let currentBorderMargin = borderMargin

        let maxX = canvasHalfWidth - textHalfWidth - currentBorderMargin
        let minX = -canvasHalfWidth + textHalfWidth + currentBorderMargin
        let maxY = canvasHalfHeight - textHalfHeight - currentBorderMargin
        let minY = -canvasHalfHeight + textHalfHeight + currentBorderMargin

        if textSize.width <= 0 || textSize.height <= 0 || textSize.width + 2 * currentBorderMargin > canvasWidth || textSize.height + 2 * currentBorderMargin > canvasHeight {
             return potentialOffset
        }

        return CGSize(width: max(minX, min(potentialOffset.width, maxX)), height: max(minY, min(potentialOffset.height, maxY)))
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

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .center) {
            // 배경 설정
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

            GeometryReader { geometry in
                // 운동 정보 텍스트 블록
                VStack(alignment: textAlignment, spacing: 0) {
                    // 운동 종류 및 이름
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text(workoutType.displayName.uppercased())
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.name)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // 거리
                    Spacer().frame(height: 4)
                    if workoutType.showsDistance {
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("거리")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedDistance)
                                .font(applyFont(baseSize: 17.0, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    
                    // 시간
                    Spacer().frame(height: 4)
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text("시간")
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.formattedDuration)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // 페이스
                    if workoutType.showsPace {
                        Spacer().frame(height: 4)
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("페이스")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedPace)
                                .font(applyFont(baseSize: 17.0, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    // 속도
                    if workoutType.showsSpeed {
                        Spacer().frame(height: 4)
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("속도")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedSpeed)
                                .font(applyFont(baseSize: 17.0, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    // 상승고도
                    if workoutType.showsElevation {
                        Spacer().frame(height: 4)
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("상승고도")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedElevationGain)
                                .font(applyFont(baseSize: 17.0, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    // <<<--- 칼로리 정보 표시 블록 삭제됨 ---<<<
                    // if let kj = workout.kilojoules, kj > 0 { ... } 부분이 제거되었습니다.
                    // >>>----------------------------------->>>

                }
                .padding(.horizontal, max(5, 15))
                .padding(.vertical, max(5, 10))
                .background(
                    GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                self.textSize = textGeometry.size
                                self.accumulatedOffset = clampOffset(potentialOffset: self.accumulatedOffset)
                            }
                            .onChange(of: textGeometry.size) { oldSize, newSize in
                                self.textSize = newSize
                                self.accumulatedOffset = clampOffset(potentialOffset: self.accumulatedOffset)
                            }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .offset(x: accumulatedOffset.width + currentDragOffset.width, y: accumulatedOffset.height + currentDragOffset.height)
                .gesture(dragGesture)
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .clipped()
        .onAppear {
            print("CanvasView loaded. Target Size: \(canvasWidth)x\(canvasHeight)")
        }
        .onChange(of: selectedFontName) { oldFont, newFont in
             if UIFont(name: newFont, size: 10) == nil {
                 print("Warning: Selected font '\(newFont)' might not be available.")
             }
         }
    }
}

// Preview 부분
#Preview {
    CanvasView(
        workout: StravaWorkout(
            id: 1, name: "Preview Hike", distance: 10000, movingTime: 7200, type: "Hike", startDate: Date(), totalElevationGain: 500, kilojoules: 2500
        ),
        useImageBackground: true, backgroundColor: .clear, backgroundImage: UIImage(systemName: "mountain.2.fill"),
        aspectRatio: 1.0, textAlignment: .center, workoutType: .hike, selectedFontName: "Futura-Bold", // Preview에서도 기본값 반영
        baseFontSize: 14.0, accumulatedOffset: .constant(CGSize(width: 10, height: -5)) // Preview에서도 기본값 반영
    )
    .padding()
}
