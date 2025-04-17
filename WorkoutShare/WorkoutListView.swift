import SwiftUI

struct WorkoutListView: View {
    let workouts: [StravaWorkout] // 표시할 운동 데이터 배열

    var body: some View {
        // 운동 목록이 비어있는 경우 메시지 표시
        if workouts.isEmpty {
            Text("No workouts found or still loading...")
                .foregroundColor(.gray)
        } else {
            // List를 사용하여 운동 목록 표시
            List(workouts) { workout in
                // 각 항목을 누르면 WorkoutDetailView로 이동하는 네비게이션 링크
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    // 각 운동 항목의 내용 구성
                    VStack(alignment: .leading, spacing: 4) { // 간격 조절
                        Text(workout.name) // 운동 이름
                            .font(.headline)
                        HStack { // 거리와 시간 가로 배치
                            Text("거리: \(workout.formattedDistance)")
                            Spacer() // 공간 채우기
                            Text("시간: \(workout.formattedDuration)")
                        }
                        .font(.subheadline) // 거리/시간 폰트
                        .foregroundColor(.gray) // 거리/시간 색상
                        HStack { // 타입과 날짜 가로 배치
                            Text("종류: \(workout.type)") // Strava 기본 타입 표시
                            Spacer()
                            Text("날짜: \(workout.startDate, formatter: dateFormatter)")
                        }
                        .font(.caption) // 타입/날짜 폰트
                        .foregroundColor(.secondary) // 타입/날짜 색상
                    }
                    .padding(.vertical, 4) // 항목 상하 패딩
                }
            }
        }
    }

    // 날짜 포맷터 (List 내에서 사용)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // 날짜 형식 간결하게
        formatter.timeStyle = .short // 시간 형식 간결하게
        return formatter
    }()
}

#Preview {
    NavigationView { // 프리뷰에서 네비게이션 바 보이도록
        WorkoutListView(workouts: [
            StravaWorkout(id: 1, name: "Morning Run", distance: 5000, movingTime: 1800, type: "Run", startDate: Date().addingTimeInterval(-86400), totalElevationGain: 50, kilojoules: 1500.0),
            StravaWorkout(id: 2, name: "Evening Walk", distance: 3000, movingTime: 2400, type: "Walk", startDate: Date(), totalElevationGain: 10, kilojoules: 1500.0)
        ])
        .navigationTitle("Sample Workouts")
    }
}
