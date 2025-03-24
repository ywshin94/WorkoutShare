import SwiftUI

struct CanvasView: View {
    let workout: StravaWorkout
    let useImageBackground: Bool
    let backgroundColor: Color
    let backgroundImage: UIImage?
    let aspectRatio: CGFloat

    private var canvasWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(screenWidth - 40, 300)
    }

    private var canvasHeight: CGFloat {
        return canvasWidth / aspectRatio
    }

    var body: some View {
        ZStack(alignment: .center) {
            // 배경
            if useImageBackground, let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: canvasWidth, height: canvasHeight)
                    .clipped()
            } else {
                backgroundColor
                    .frame(width: canvasWidth, height: canvasHeight)
            }

            // 텍스트
            VStack(spacing: 8) {
                Text(workout.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                Text("Distance: \(workout.formattedDistance)")
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                Text("Duration: \(workout.formattedDuration)")
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                Text("Type: \(workout.type)")
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            print("CanvasView size: \(canvasWidth)x\(canvasHeight)")
        }
    }
}

#Preview {
    CanvasView(
        workout: StravaWorkout(
            id: 1,
            name: "Morning Run",
            distance: 5000.0,
            movingTime: 1800,
            type: "Run",
            startDate: Date()
        ),
        useImageBackground: false,
        backgroundColor: .blue,
        backgroundImage: nil,
        aspectRatio: 1.0
    )
}
