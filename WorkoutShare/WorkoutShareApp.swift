import SwiftUI

@main
struct WorkoutShareApp: App {
    @StateObject private var stravaService = StravaService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stravaService)
                .onOpenURL { url in
                    print("Received URL: \(url)")
                    if url.scheme == "workoutshare",
                       let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
                        print("Extracted code: \(code)")
                        Task {
                            do {
                                try await stravaService.exchangeCodeForToken(code: code)
                                print("Access Token after exchange: \(stravaService.accessToken ?? "nil")")
                            } catch {
                                print("Error exchanging token: \(error)")
                                stravaService.errorMessage = "Failed to exchange token: \(error.localizedDescription)"
                            }
                        }
                    } else {
                        print("URL scheme mismatch or no code found")
                    }
                }
        }
    }
}
