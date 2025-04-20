import SwiftUI

struct WorkoutSelectorView: View {
    @EnvironmentObject var stravaService: StravaService // ✅ EnvironmentObject로 변경
    var onWorkoutSelected: (StravaWorkout) -> Void

    var body: some View {
        NavigationStack {
            if stravaService.accessToken == nil {
                VStack {
                    Button("Strava 로그인") {
                        stravaService.startOAuthFlow()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()

                    if let error = stravaService.errorMessage {
                        Text("오류: \(error)")
                            .foregroundColor(.red)
                    }
                }
                .navigationTitle("Strava 로그인")
            } else {
                List(stravaService.workouts) { workout in
                    Button {
                        onWorkoutSelected(workout)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(workout.name).font(.headline)
                            Text("거리: \(workout.formattedDistance), 시간: \(workout.formattedDuration)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("운동 선택")
                .onAppear {
                    Task {
                        await stravaService.fetchRecentWorkouts()
                    }
                }
            }
        }
        .onChange(of: stravaService.accessToken) { _ in
            if stravaService.accessToken != nil {
                Task {
                    await stravaService.fetchRecentWorkouts()
                }
            }
        }
    }
}
