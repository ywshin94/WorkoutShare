// CanvasView.swift — ✅ .drawingGroup() 추가로 aliasing 제거 & GPU offload

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
    let baseFontSize: CGFloat

    @Binding var accumulatedOffset: CGSize
    @State private var currentDragOffset: CGSize = .zero
    @State private var textSize: CGSize = .zero

    // MARK: - Constants
    private let borderMargin: CGFloat = 10.0
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

    private func clampOffset(potentialOffset: CGSize) -> CGSize {
        let textHalfWidth = textSize.width / 2
        let textHalfHeight = textSize.height / 2
        let canvasHalfWidth = canvasWidth / 2
        let canvasHalfHeight = canvasHeight / 2

        let maxX = canvasHalfWidth - textHalfWidth - borderMargin
        let minX = -canvasHalfWidth + textHalfWidth + borderMargin
        let maxY = canvasHalfHeight - textHalfHeight - borderMargin
        let minY = -canvasHalfHeight + textHalfHeight + borderMargin

        if textSize.width <= 0 || textSize.height <= 0 || textSize.width + 2 * borderMargin > canvasWidth || textSize.height + 2 * borderMargin > canvasHeight {
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

            GeometryReader { geometry in
                VStack(alignment: textAlignment, spacing: 0) {
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text(workoutType.displayName.uppercased())
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.name)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

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

                    Spacer().frame(height: 4)
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text("시간")
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9))
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.formattedDuration)
                            .font(applyFont(baseSize: 17.0, weight: .semibold))
                            .foregroundColor(.white)
                    }

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
                            .onChange(of: textGeometry.size) { _, newSize in
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
        .drawingGroup() // ✅ GPU 렌더링 & aliasing 제거
        .onAppear {
            print("CanvasView loaded. Target Size: \(canvasWidth)x\(canvasHeight)")
        }
        .onChange(of: selectedFontName) { _, newFont in
            if UIFont(name: newFont, size: 10) == nil {
                print("Warning: Selected font '\(newFont)' might not be available.")
            }
        }
    }
}

