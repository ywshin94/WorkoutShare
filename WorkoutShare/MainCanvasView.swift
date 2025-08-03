import SwiftUI

struct MainCanvasView: View {
    @EnvironmentObject private var stravaService: StravaService
    @State private var selectedWorkout: StravaWorkout? = nil
    @State private var showingWorkoutSelector = false

    var body: some View {
        NavigationStack {
            WorkoutDetailView(workout: selectedWorkout ?? defaultWorkout) {
                // ✅ [수정된 부분] 로그인 상태에 따라 다른 동작을 하도록 복원합니다.
                if stravaService.accessToken == nil {
                    // 로그아웃 상태: 바로 스트라바 로그인 실행
                    stravaService.startOAuthFlow()
                } else {
                    // 로그인 상태: 운동 선택 창 표시
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
            // 로그인 상태가 변경되었을 때 처리
            if stravaService.accessToken != nil && selectedWorkout == nil {
                // 로그인 후, 선택된 운동이 없으면 운동 선택 창을 자동으로 띄웁니다.
                try? await Task.sleep(for: .seconds(0.5))
                await MainActor.run {
                    showingWorkoutSelector = true
                }
            } else if stravaService.accessToken == nil {
                // 로그아웃 시, 선택된 운동 상태를 초기화합니다.
                selectedWorkout = nil
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
