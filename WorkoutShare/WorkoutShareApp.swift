import SwiftUI

@main
struct WorkoutShareApp: App {
    @StateObject private var stravaService = StravaService()

    var body: some Scene {
        WindowGroup {
            // ✅ [수정] 앱의 첫 시작점을 AppEntryView로 변경합니다.
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
