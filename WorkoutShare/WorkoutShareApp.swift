import SwiftUI

@main
struct WorkoutShareApp: App {
    @StateObject private var stravaService = StravaService()

    var body: some Scene {
        WindowGroup {
            // ContentView가 앱의 시작점
            ContentView()
                .environmentObject(stravaService) // StravaService를 환경 객체로 주입
                .onOpenURL { url in
                    // 앱이 커스텀 URL 스킴을 통해 열렸을 때 처리 (Strava OAuth 콜백)
                    print("Received URL: \(url)")
                    // 스킴과 파라미터 확인
                    if url.scheme == "workoutshare", // 등록된 URL 스킴인지 확인
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
                       let code = codeItem.value {
                        print("Extracted code: \(code)")
                        // 인증 코드를 사용하여 토큰 교환 작업 시작
                        Task {
                            do {
                                try await stravaService.exchangeCodeForToken(code: code)
                                print("Access Token after exchange (in App): \(stravaService.accessToken ?? "nil")")
                            } catch {
                                print("Error exchanging token (in App): \(error)")
                                // 오류 메시지는 StravaService 내부에서 @Published 변수를 통해 처리됨
                            }
                        }
                    } else {
                        print("URL scheme mismatch or no code found in URL.")
                    }
                }
        }
    }
}
