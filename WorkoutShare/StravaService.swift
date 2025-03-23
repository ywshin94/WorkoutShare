import Foundation
import UIKit

class StravaService: ObservableObject {
    private let clientId = "102274"
    private let clientSecret = "ffe243278147663c88dddc2625b61fdf5a47953a"
    private let redirectUri = "https://ywshin94.mycafe24.com/oauth"
    
    @Published var accessToken: String?
    @Published var workouts: [StravaWorkout] = []
    @Published var errorMessage: String?
    
    func startOAuthFlow() {
        let baseAuthUrl = "https://www.strava.com/oauth/authorize"
        let parameters = [
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "response_type": "code",
            "scope": "activity:read_all"
        ]
        
        var components = URLComponents(string: baseAuthUrl)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        if let url = components.url {
            print("Opening URL: \(url)")
            UIApplication.shared.open(url)
        } else {
            errorMessage = "Failed to create authorization URL"
        }
    }
    
    func exchangeCodeForToken(code: String) async throws {
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)&grant_type=authorization_code"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Token exchange HTTP status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let errorResponse = String(data: data, encoding: .utf8) ?? "No data"
                    print("Token exchange failed: \(errorResponse)")
                    await MainActor.run {
                        self.errorMessage = "Token exchange failed: \(errorResponse)"
                    }
                    throw URLError(.badServerResponse)
                }
            }
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            print("Decoded token response: \(tokenResponse.accessToken)")
            await MainActor.run {
                self.accessToken = tokenResponse.accessToken
            }
            
            await fetchRecentWorkouts()
        } catch {
            print("Error in exchangeCodeForToken: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to exchange token: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    @MainActor
    func fetchRecentWorkouts() async {
        guard let token = accessToken else { return }
        let url = URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=10")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")") // 디버깅 로그 추가
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // ISO 8601 형식으로 디코딩 설정
            workouts = try decoder.decode([StravaWorkout].self, from: data)
        } catch {
            print("Error fetching workouts: \(error)")
            errorMessage = "Failed to fetch workouts: \(error.localizedDescription)"
        }
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
