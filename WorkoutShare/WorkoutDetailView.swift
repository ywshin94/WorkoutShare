import SwiftUI

struct WorkoutDetailView: View {
    let workout: StravaWorkout
    
    var body: some View {
        VStack {
            Text(workout.name)
                .font(.title)
            Text("Distance: \(workout.formattedDistance)")
            Text("Duration: \(workout.formattedDuration)") // 이제 오류가 발생하지 않음
            Text("Type: \(workout.type)")
            Text("Date: \(workout.startDate, formatter: dateFormatter)")
        }
        .padding()
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
