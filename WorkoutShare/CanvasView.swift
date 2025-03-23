import SwiftUI

struct CanvasView: View {
    let workout: StravaWorkout
    
    var body: some View {
        VStack {
            Text(workout.name)
                .font(.headline)
            Text("Distance: \(workout.formattedDistance)")
            Text("Duration: \(workout.formattedDuration)") // formattedDuration 사용
            Text("Type: \(workout.type)")
            Text("Date: \(workout.startDate, formatter: dateFormatter)")
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
