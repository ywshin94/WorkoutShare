import SwiftUI

struct CanvasView: View {
    // MARK: - Properties

    // Passed from parent view
    let workout: StravaWorkout
    let useImageBackground: Bool
    let backgroundColor: Color
    let backgroundImage: UIImage?
    let aspectRatio: CGFloat
    let textAlignment: HorizontalAlignment
    let workoutType: WorkoutType
    let selectedFontName: String // Name of the selected font

    // State shared with parent view (Bindings)
    @Binding var accumulatedOffset: CGSize // Position offset
    @Binding var finalScale: CGFloat       // Size scale

    // Internal state for gestures and measurements
    @State private var currentDragOffset: CGSize = .zero // Temporary drag offset during gesture
    @State private var currentScale: CGFloat = 1.0   // Temporary scale during pinch gesture
    @State private var textSize: CGSize = .zero // Measured size of the text content VStack

    // MARK: - Constants

    private let borderMargin: CGFloat = 10.0 // Minimum margin from canvas edges
    // Base font sizes (adjust as needed)
    private let baseTitleSize: CGFloat = 17.0 // Reference size for .headline
    private let baseDataSize: CGFloat = 17.0  // Reference size for .headline
    private let baseLabelFootnoteSize: CGFloat = 13.0 // Reference size for .footnote
    private let baseLabelCaptionSize: CGFloat = 12.0  // Reference size for .caption
    // Scale limits
    private let minScale: CGFloat = 0.5 // Minimum zoom out
    private let maxScale: CGFloat = 3.0 // Maximum zoom in

    // MARK: - Computed Properties

    // Canvas dimensions based on aspect ratio
    private var canvasWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        // Important: Keep this consistent with the snapshot function
        return min(screenWidth - 40, 350)
    }
    private var canvasHeight: CGFloat {
        return canvasWidth / aspectRatio
    }

    // The final scale applied to fonts, spacing, padding (including ongoing gesture)
    var currentAppliedScale: CGFloat {
        // Ensure scale doesn't become zero or negative during gesture
        max(0.1, finalScale * currentScale)
    }

    // Helper to convert HorizontalAlignment to TextAlignment
    private var textAlign: TextAlignment {
        switch textAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }

    // MARK: - Gestures

    // Combined Gesture using SimultaneousGesture with correct handling
    var combinedGesture: some Gesture {
        // Define the individual gestures first
        let drag = DragGesture()
            .onChanged { value in
                let potentialOffsetX = accumulatedOffset.width + value.translation.width
                let potentialOffsetY = accumulatedOffset.height + value.translation.height
                let clampedOffset = clampOffset(potentialOffset: CGSize(width: potentialOffsetX, height: potentialOffsetY))
                self.currentDragOffset = CGSize(
                    width: clampedOffset.width - accumulatedOffset.width,
                    height: clampedOffset.height - accumulatedOffset.height
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

        let magnification = MagnificationGesture()
            .onChanged { value in
                self.currentScale = value
            }
            .onEnded { value in
                self.finalScale *= value
                self.finalScale = max(minScale, min(finalScale, maxScale))
                self.currentScale = 1.0
            }

        return SimultaneousGesture(drag, magnification)
    }

    // MARK: - Helper Functions

    // Clamps the offset to keep the text block within canvas bounds
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

        let clampedX = max(minX, min(potentialOffset.width, maxX))
        let clampedY = max(minY, min(potentialOffset.height, maxY))

        if textSize.width <= 0 || textSize.height <= 0 || textSize.width + 2 * currentBorderMargin > canvasWidth || textSize.height + 2 * currentBorderMargin > canvasHeight {
             return potentialOffset
         }
        return CGSize(width: clampedX, height: clampedY)
    }

    // Applies the selected font name and scale
    private func applyFont(baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = max(1, baseSize * currentAppliedScale) // Ensure font size is at least 1
        return Font.custom(selectedFontName, size: scaledSize)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .center) { // Base layer for background and text
            // Background Layer (Solid color or Image)
            if useImageBackground, let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill() // Fill the frame, cropping if necessary
                    .frame(width: canvasWidth, height: canvasHeight)
                    .clipped() // Clip to frame
                    .overlay(Color.black.opacity(0.3)) // Dark overlay for text readability
            } else {
                backgroundColor // Solid color background
                    .frame(width: canvasWidth, height: canvasHeight)
            }

            // Text Content Layer (with size measurement and gestures)
            GeometryReader { geometry in // Access container size
                VStack(alignment: textAlignment, spacing: 0) { // Main text container
                    // 1. Workout Type Label
                    Text(workoutType.displayName.uppercased())
                        .font(applyFont(baseSize: baseLabelCaptionSize * 0.9, weight: .medium)) // Caption based
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4 * currentAppliedScale) // Scaled spacing

                    // 2. Workout Name (Title)
                    Text(workout.name)
                        .font(applyFont(baseSize: baseDataSize, weight: .bold)) // Use helper (was baseTitleSize, reverted based on user's last code)
                        .foregroundColor(.white).shadow(radius: 2).lineLimit(2) // Style
                        .minimumScaleFactor(minScale / finalScale) // Allow shrinking, considering base scale
                        .multilineTextAlignment(textAlign) // Align multi-line text

                    Spacer().frame(height: 4 * currentAppliedScale) // Scaled spacing

                    // 3. Common Data: Distance, Duration
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text("거리")
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9)) // Use helper
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.formattedDistance)
                            .font(applyFont(baseSize: baseDataSize, weight: .semibold)) // Use helper
                            .foregroundColor(.white)
                    }
                    Spacer().frame(height: 4 * currentAppliedScale)
                    VStack(alignment: textAlignment, spacing: 0) {
                        Text("시간")
                            .font(applyFont(baseSize: baseLabelCaptionSize * 0.9)) // Use helper
                            .foregroundColor(.white.opacity(0.8))
                        Text(workout.formattedDuration)
                            .font(applyFont(baseSize: baseDataSize, weight: .semibold)) // Use helper
                            .foregroundColor(.white)
                    }

                    // 4. Conditional Data: Pace, Speed, Elevation
                    // Pace (Show for running types)
                    if workoutType.showsPace {
                        Spacer().frame(height: 4 * currentAppliedScale)
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("페이스")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9)) // Use helper
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedPace)
                                .font(applyFont(baseSize: baseDataSize, weight: .semibold)) // Use helper
                                .foregroundColor(.white)
                        }
                    }

                    // Speed (Show for walking/hiking types)
                    if workoutType.showsSpeed {
                        Spacer().frame(height: 4 * currentAppliedScale)
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("속도")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9)) // Use helper
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedSpeed)
                                .font(applyFont(baseSize: baseDataSize, weight: .semibold)) // Use helper
                                .foregroundColor(.white)
                        }
                    }

                    // Elevation Gain (Show for trail run/hiking types)
                    if workoutType.showsElevation {
                        Spacer().frame(height: 4 * currentAppliedScale)
                        VStack(alignment: textAlignment, spacing: 0) {
                            Text("상승고도")
                                .font(applyFont(baseSize: baseLabelCaptionSize * 0.9)) // Use helper
                                .foregroundColor(.white.opacity(0.8))
                            Text(workout.formattedElevationGain)
                                .font(applyFont(baseSize: baseDataSize, weight: .semibold)) // Use helper
                                .foregroundColor(.white)
                        }
                    }
                } // End of main text VStack
                .padding(.horizontal, max(5, 15 * currentAppliedScale)) // Apply scaled padding (min 5)
                .padding(.vertical, max(5, 10 * currentAppliedScale))   // Apply scaled padding (min 5)
                .background( // Use background for size measurement
                    GeometryReader { textGeometry in
                        Color.clear // Transparent background doesn't affect appearance
                            .onAppear { // Measure initial size
                                self.textSize = textGeometry.size
                                print("Initial text block size: \(self.textSize)")
                                self.accumulatedOffset = clampOffset(potentialOffset: self.accumulatedOffset)
                            }
                            .onChange(of: textGeometry.size) { newSize in // Measure size on change
                                self.textSize = newSize
                                print("Updated text block size: \(self.textSize)")
                                self.accumulatedOffset = clampOffset(potentialOffset: self.accumulatedOffset)
                            }
                    }
                )
                // Positioning and Offset
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow VStack to naturally size
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Position in center before offset
                .offset( // Apply the combined offset from state and current drag
                    x: accumulatedOffset.width + currentDragOffset.width,
                    y: accumulatedOffset.height + currentDragOffset.height
                )
                // Apply the combined drag and pinch gesture recognizer
                .gesture(combinedGesture)

            } // End of GeometryReader
        } // End of ZStack
        // Final canvas styling
        .frame(width: canvasWidth, height: canvasHeight)
        // --- .cornerRadius(10) REMOVED ---
        .clipped() // Clip content outside the frame (important without corner radius too)
        .onAppear {
            print("CanvasView loaded. Target Size: \(canvasWidth)x\(canvasHeight)")
        }
    } // End of body
} // End of struct CanvasView

// MARK: - Preview

#Preview {
    CanvasView(
        workout: StravaWorkout(
            id: 1, name: "Preview Hike Long Name\nSecond Line", distance: 10000, movingTime: 7200,
            type: "Hike", startDate: Date(), totalElevationGain: 500
        ),
        useImageBackground: true, backgroundColor: .clear, backgroundImage: UIImage(systemName: "mountain.2.fill"),
        aspectRatio: 1.0, textAlignment: .center, workoutType: .hike,
        selectedFontName: "TimesNewRomanPSMT",
        accumulatedOffset: .constant(CGSize(width: 10, height: -5)),
        finalScale: .constant(0.8)
    )
    .padding()
}

// --- Helper Extensions (Optional - keep if used elsewhere, or embed clampOffset) ---
// extension CanvasView { ... clampOffset implementation ... }
// extension CanvasView { ... measurementBackground implementation ... }
// extension CanvasView { ... gestureImplementation ... }
// extension CanvasView { ... applyFontImplementation ... }
// It's generally better to keep helper functions inside the struct if not reused.
