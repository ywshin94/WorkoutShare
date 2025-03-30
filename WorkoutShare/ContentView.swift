import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var stravaService: StravaService // 환경 객체로 StravaService 접근

    var body: some View {
        NavigationView { // 네비게이션 인터페이스 사용
            // 액세스 토큰 유무에 따라 뷰 분기
            if stravaService.accessToken == nil {
                // 로그아웃 상태: 로그인 버튼 표시
                VStack {
                    Button("Login with Strava") {
                        print("Login button tapped!") // <-- 이 로그가 찍히는지 확인
                        stravaService.startOAuthFlow() // Strava 인증 시작
                    }
                    .padding()
                    .buttonStyle(.borderedProminent) // 버튼 스타일

                    // 디버깅 또는 상태 표시용 텍스트 (선택 사항)
                    Text("Access Token: \(stravaService.accessToken ?? "Not logged in")")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top)

                    // StravaService에서 발생한 오류 메시지 표시
                    if let error = stravaService.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .navigationTitle("Login") // 네비게이션 타이틀
            } else {
                // 로그인 상태: 운동 목록 표시
                VStack {
                    // 디버깅 또는 상태 표시용 텍스트 (선택 사항)
                    // Text("Access Token: \(stravaService.accessToken ?? "Logged in")")
                    //     .font(.caption)
                    //     .foregroundColor(.gray)
                    //     .padding(.bottom)

                    // 운동 목록 뷰 (데이터는 StravaService에서 가져옴)
                    WorkoutListView(workouts: stravaService.workouts)
                        // 데이터 로딩 중 또는 에러 발생 시 처리 (개선 가능)
                        // .overlay {
                        //     if stravaService.workouts.isEmpty && stravaService.errorMessage == nil {
                        //         ProgressView("Loading workouts...")
                        //     } else if let error = stravaService.errorMessage {
                        //         Text("Error loading workouts: \(error)")
                        //             .foregroundColor(.red)
                        //     }
                        // }
                }
                .navigationTitle("Workouts") // 네비게이션 타이틀
                .onAppear {
                    // 뷰가 나타날 때 운동 데이터 가져오기 (토큰이 이미 있을 경우)
                    Task {
                        await stravaService.fetchRecentWorkouts()
                    }
                }
            }
        }
        // 액세스 토큰 변경 감지 (디버깅용)
        .onChange(of: stravaService.accessToken) { newValue in
            print("ContentView detected Access Token change: \(newValue ?? "nil")")
            // 토큰이 생기면 자동으로 운동 목록 로드 시도
            if newValue != nil {
                Task {
                    await stravaService.fetchRecentWorkouts()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StravaService()) // 프리뷰용 환경 객체 주입
}
