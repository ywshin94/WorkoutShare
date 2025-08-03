import SwiftUI

@main
struct WorkoutShareApp: App {
    @StateObject private var stravaService = StravaService()

    init() {
        // ✅ 앱 최초 실행 시 기본값 등록
        UserDefaults.standard.register(defaults: [
            "userDidDeauthorize": true
        ])
    }

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(stravaService)
                .onOpenURL { url in
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
                       let code = codeItem.value {
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

