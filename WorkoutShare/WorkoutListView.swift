import SwiftUI

struct WorkoutListView: View {
    let workouts: [StravaWorkout]

    var body: some View {
        if workouts.isEmpty {
            Text("No workouts found or still loading...")
                .foregroundColor(.gray)
        } else {
            List(workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout, onFetchWorkout: {})) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name).font(.headline)
                        HStack {
                            Text("거리: \(workout.formattedDistance)")
                            Spacer()
                            Text("시간: \(workout.formattedDuration)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        HStack {
                            Text("종류: \(workout.type)")
                            Spacer()
                            Text("날짜: \(workout.startDate, formatter: dateFormatter)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationView {
        WorkoutListView(workouts: [
            StravaWorkout(id: 1, name: "Morning Run", distance: 5000, movingTime: 1800, type: "Run", startDate: Date().addingTimeInterval(-86400), totalElevationGain: 50, kilojoules: 1500.0),
            StravaWorkout(id: 2, name: "Evening Walk", distance: 3000, movingTime: 2400, type: "Walk", startDate: Date(), totalElevationGain: 10, kilojoules: 1500.0)
        ])
        .navigationTitle("Sample Workouts")
    }
}
