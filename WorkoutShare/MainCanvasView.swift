import SwiftUI

struct MainCanvasView: View {
    @EnvironmentObject private var stravaService: StravaService
    @State private var selectedWorkout: StravaWorkout? = nil
    @State private var showingWorkoutSelector = false

    var body: some View {
        NavigationStack {
            WorkoutDetailView(workout: selectedWorkout ?? defaultWorkout) {
                if stravaService.accessToken == nil {
                    stravaService.startOAuthFlow()
                } else {
                    showingWorkoutSelector = true
                }
            }
            .sheet(isPresented: $showingWorkoutSelector) {
                WorkoutSelectorView { workout in
                    selectedWorkout = workout
                    showingWorkoutSelector = false
                }
                .environmentObject(stravaService)
            }
        }
        .task(id: stravaService.accessToken) {
            if stravaService.accessToken != nil && selectedWorkout == nil {
                try? await Task.sleep(for: .seconds(0.5))
                await MainActor.run {
                    showingWorkoutSelector = true
                }
            }
        }
    }

    private var defaultWorkout: StravaWorkout {
        StravaWorkout(
            id: -1,
            name: "운동을 선택해주세요",
            distance: 0,
            movingTime: 0,
            type: "None",
            startDate: Date(),
            totalElevationGain: 0,
            kilojoules: nil
        )
    }
}

#Preview {
    MainCanvasView()
        .environmentObject(StravaService())
}
