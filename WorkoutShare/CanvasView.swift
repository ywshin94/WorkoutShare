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

        // 텍스트 블록이 캔버스보다 크거나 같으면 이동 제한하지 않음 (또는 최소한의 패딩만 남김)
        if textSize.width <= 0 || textSize.height <= 0 || textSize.width + 2 * currentBorderMargin > canvasWidth || textSize.height + 2 * currentBorderMargin > canvasHeight {
             // return .zero // 가운데 고정 옵션
             return potentialOffset // 이동은 허용하되, 제한은 걸지 않음
        }
        
        return CGSize(width: max(minX, min(potentialOffset.width, maxX)), height: max(minY, min(potentialOffset.height, maxY)))
    }


    private func applyFont(baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = max(1, baseSize * baseFontSize / 17.0) // 17.0을 기준으로 비례 조정
        // 폰트 이름이 유효한지 확인하고, 없으면 시스템 기본 폰트 사용
        if let _ = UIFont(name: selectedFontName, size: scaledSize) {
             return Font.custom(selectedFontName, size: scaledSize)
        } else {
            print("Warning: Font '\(selectedFontName)' not found. Using system font.")
            return Font.system(size: scaledSize, weight: weight) // Fallback
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .center) {
            // 배경 설정 (이미지 또는 단색)
            if useImageBackground, let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: canvasWidth, height: canvasHeight)
                    .clipped()
                    .overlay(Color.black.opacity(0.3)) // 이미지 위에 약간 어두운 오버레이
            } else {
                backgroundColor
                    .frame(width: canvasWidth, height: canvasHeight)
            }

            GeometryReader { geometry in
                // 운동 정보 텍스트 블록
                VStack(alignment: textAlignment, spacing: 0) { // 메인 V 스택 (텍스트 그룹)
                    // 운동 종류 및 이름
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text(workoutType.displayName.uppercased())
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.name)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer().frame(height: 4) // 항목 간 간격

                    // 거리
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text("거리")
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.formattedDistance)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer().frame(height: 4) // 항목 간 간격

                    // 시간
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text("시간")
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.formattedDuration)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // 페이스 (운동 종류에 따라 조건부 표시)
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

                    // 속도 (운동 종류에 따라 조건부 표시)
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

                    // 상승고도 (운동 종류에 따라 조건부 표시)
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

                    // <<<--- 칼로리 정보 (마지막으로 이동 및 라벨 변경) ---<<<
                    if let kj = workout.kilojoules, kj > 0 { // 칼로리 데이터가 있을 때만 표시
                        Spacer().frame(height: 4) // 항목 간 간격
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("칼로리") // 라벨 변경: "소모 칼로리" -> "칼로리"
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedCalories)
                                .font(applyFont(baseSize: 17.0, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    // >>>------------------------------------------->>>
                }
                .padding(.horizontal, max(5, 15)) // 텍스트 좌우 여백
                .padding(.vertical, max(5, 10))   // 텍스트 상하 여백
                .background(
                    // 텍스트 블록 크기 계산용 GeometryReader
                    GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                self.textSize = textGeometry.size
                                // 텍스트 크기 변경 시 위치 재조정 (Clamp)
                                self.accumulatedOffset = clampOffset(potentialOffset: self.accumulatedOffset)
                            }
                            .onChange(of: textGeometry.size) { oldSize, newSize in
                                self.textSize = newSize
                                // 텍스트 크기 변경 시 위치 재조정 (Clamp)
                                self.accumulatedOffset = clampOffset(potentialOffset: self.accumulatedOffset)
                            }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity) // VStack이 가능한 최대 크기 차지하도록
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 부모 ZStack 중앙에 위치
                .offset(x: accumulatedOffset.width + currentDragOffset.width, y: accumulatedOffset.height + currentDragOffset.height) // 드래그 오프셋 적용
                .gesture(dragGesture) // 드래그 제스처 적용
            }
        }
        .frame(width: canvasWidth, height: canvasHeight) // 캔버스 전체 크기 고정
        .clipped() // 프레임 밖으로 나가는 내용 자르기
        .onAppear {
            print("CanvasView loaded. Target Size: \(canvasWidth)x\(canvasHeight)")
        }
        // フォントが見つからない場合の警告をハンドリングするための改善
        .onChange(of: selectedFontName) { oldFont, newFont in
             if UIFont(name: newFont, size: 10) == nil {
                 print("Warning: Selected font '\(newFont)' might not be available.")
             }
         }
    }
}

// Preview 부분은 변경하지 않음
#Preview {
    CanvasView(
        workout: StravaWorkout(
            id: 1, name: "Preview Hike", distance: 10000, movingTime: 7200, type: "Hike", startDate: Date(), totalElevationGain: 500, kilojoules: 2500
        ),
        useImageBackground: true, backgroundColor: .clear, backgroundImage: UIImage(systemName: "mountain.2.fill"),
        aspectRatio: 1.0, textAlignment: .center, workoutType: .hike, selectedFontName: "TimesNewRomanPSMT", // 예시 폰트
        baseFontSize: 17.0, accumulatedOffset: .constant(CGSize(width: 10, height: -5))
    )
    .padding()
}
