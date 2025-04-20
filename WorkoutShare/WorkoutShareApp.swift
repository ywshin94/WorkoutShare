import SwiftUI

@main
struct WorkoutShareApp: App {
    @StateObject private var stravaService = StravaService()

    var body: some Scene {
        WindowGroup {
            MainCanvasView()
                .environmentObject(stravaService) // ✅ 환경 객체 주입
                .onOpenURL { url in
                    // ✅ OAuth 인증 완료 후 redirect URI에서 code 추출
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
                       let code = codeItem.value {
                        print("Extracted code: \(code)")
                        Task {
                            do {
                                try await stravaService.exchangeCodeForToken(code: code)
                            } catch {
                                print("Error exchanging token: \(error)")
                            }
                        }
                    }
                }
        }
    }
}
