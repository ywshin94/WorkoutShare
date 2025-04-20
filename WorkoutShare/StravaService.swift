import Foundation
import UIKit // UIApplication.shared.open 사용

class StravaService: ObservableObject {
    private let clientId = "102274"
    private let clientSecret = "ffe243278147663c88dddc2625b61fdf5a47953a" // 보안 주의
    private let redirectUri = "https://ywshin94.mycafe24.com/oauth"
    private let stravaAuthorizeUrl = "https://www.strava.com/oauth/authorize"
    private let stravaTokenUrl = "https://www.strava.com/oauth/token"
    private let stravaActivitiesUrl = "https://www.strava.com/api/v3/athlete/activities"

    @Published var accessToken: String?
    @Published var workouts: [StravaWorkout] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    func startOAuthFlow() {
        print("startOAuthFlow() called.")
        
        let scope = "activity:read_all"
        var components = URLComponents(string: stravaAuthorizeUrl)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: scope)
        ]
        if let url = components.url {
            print("Constructed URL: \(url)")
            UIApplication.shared.open(url)
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create authorization URL."
            }
        }
    }

    func exchangeCodeForToken(code: String) async throws {
        print("Attempting to exchange code for token...")
        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        guard let url = URL(string: stravaTokenUrl) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)&grant_type=authorization_code"
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let stravaError = decodeStravaError(from: data) ?? "HTTP \(httpResponse.statusCode)"
                await MainActor.run {
                    self.errorMessage = "Token exchange failed: \(stravaError)"
                    self.isLoading = false
                }
                throw NSError(domain: "StravaAuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: stravaError])
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)

            await MainActor.run {
                self.accessToken = tokenResponse.accessToken
                self.isLoading = false
                self.errorMessage = nil
            }

            await fetchRecentWorkouts()
        } catch {
            print("Error during token exchange: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to get token: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }

    @MainActor
    func fetchRecentWorkouts() async {
        guard let token = accessToken else { return }

        self.isLoading = true
        self.errorMessage = nil

        var components = URLComponents(string: stravaActivitiesUrl)!
        components.queryItems = [ URLQueryItem(name: "per_page", value: "30") ]

        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let stravaError = decodeStravaError(from: data) ?? "HTTP \(httpResponse.statusCode)"
                self.errorMessage = "Failed to fetch workouts: \(stravaError)"
                self.isLoading = false
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let fetchedWorkouts = try decoder.decode([StravaWorkout].self, from: data)

            self.workouts = fetchedWorkouts
            self.isLoading = false
        } catch {
            self.errorMessage = "Could not load workouts: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    private func decodeStravaError(from data: Data) -> String? {
        struct StravaErrorResponse: Decodable {
            let message: String?
            let errors: [StravaErrorDetail]?
        }
        struct StravaErrorDetail: Decodable {
            let resource: String?
            let field: String?
            let code: String?
        }

        guard let errorResponse = try? JSONDecoder().decode(StravaErrorResponse.self, from: data) else {
            return nil
        }

        var detailedError = errorResponse.message ?? "Unknown Strava error"
        if let firstError = errorResponse.errors?.first {
            detailedError += " (\(firstError.resource ?? "Resource") \(firstError.field ?? "field"): \(firstError.code ?? "code"))"
        }

        return detailedError
            .replacingOccurrences(of: "Unknown Strava error ()", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? nil : detailedError
    }
}

struct TokenResponse: Codable {
    let tokenType: String?
    let expiresAt: Int?
    let expiresIn: Int?
    let refreshToken: String?
    let accessToken: String
}
