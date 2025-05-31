import SwiftUI

struct MainCanvasView: View {
    @EnvironmentObject private var stravaService: StravaService
    @State private var selectedWorkout: StravaWorkout? = nil
    @State private var showingWorkoutSelector = false

    var body: some View {
        NavigationStack {
            WorkoutDetailView(workout: selectedWorkout ?? defaultWorkout)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("운동 가져오기") {
                            if stravaService.accessToken == nil {
                                stravaService.startOAuthFlow()
                            } else {
                                showingWorkoutSelector = true
                            }
                        }
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
        .onChange(of: stravaService.accessToken) { newToken in
            if newToken != nil {
                // 로그인 성공 시 자동으로 운동 선택 리스트 표시
                showingWorkoutSelector = true
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
