import Foundation
import UIKit
import AuthenticationServices

class StravaService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    private let clientId = "102274"
    private let clientSecret = "ffe243278147663c88dddc2625b61fdf5a47953a"
    private let redirectUri = "https://ywshin94.mycafe24.com/oauth"
    private let stravaAuthorizeUrl = "https://www.strava.com/oauth/authorize"
    private let stravaTokenUrl = "https://www.strava.com/oauth/token"
    private let stravaActivitiesUrl = "https://www.strava.com/api/v3/athlete/activities"
    private let stravaDeauthorizeUrl = "https://www.strava.com/oauth/deauthorize"

    private let accessTokenKey = "accessToken"
    private var authSession: ASWebAuthenticationSession?

    @Published var accessToken: String?
    @Published var workouts: [StravaWorkout] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    override init() {
        super.init()
        if let token = UserDefaults.standard.string(forKey: accessTokenKey), !token.isEmpty {
            self.accessToken = token
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }

    @MainActor
    func startOAuthFlow() {
        var components = URLComponents(string: stravaAuthorizeUrl)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "force"),
            URLQueryItem(name: "scope", value: "activity:read_all")
        ]

        guard let authURL = components.url else {
            self.errorMessage = "Failed to create authorization URL."
            return
        }

        let callbackURLScheme = URL(string: redirectUri)?.scheme

        self.authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackURLScheme
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                // 사용자가 로그인을 취소한 경우(ASWebAuthenticationSessionError.canceledLogin)는 일반적인 상황이므로 에러 메시지를 표시하지 않을 수 있습니다.
                if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    print("Login canceled by user.")
                    return
                }
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
                return
            }

            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                  let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
                  let code = codeItem.value else {
                self.errorMessage = "Invalid callback URL."
                return
            }
            
            Task {
                do {
                    try await self.exchangeCodeForToken(code: code)
                } catch {
                    // 에러 메시지는 exchangeCodeForToken 내부에서 처리됨
                }
            }
        }
        
        authSession?.presentationContextProvider = self
        // ✅ [핵심 수정] 이 옵션을 true로 설정하면 기존 사파리 로그인 정보를 공유하지 않습니다.
        authSession?.prefersEphemeralWebBrowserSession = true
        
        authSession?.start()
    }
    
    // (이하 나머지 코드는 이전과 동일합니다)
    func exchangeCodeForToken(code: String) async throws {
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
                UserDefaults.standard.set(tokenResponse.accessToken, forKey: self.accessTokenKey)
                self.isLoading = false
                self.errorMessage = nil
            }
            
            await fetchRecentWorkouts()
        } catch {
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
            self.workouts = try decoder.decode([StravaWorkout].self, from: data)
            self.isLoading = false
        } catch {
            self.errorMessage = "Could not load workouts: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    func deauthorize() async {
        guard let tokenToDeauthorize = accessToken else { return }

        await MainActor.run {
            self.accessToken = nil
            self.workouts = []
            self.errorMessage = nil
            UserDefaults.standard.removeObject(forKey: self.accessTokenKey)
            UserDefaults.standard.synchronize()
        }
        
        guard let url = URL(string: stravaDeauthorizeUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "access_token=\(tokenToDeauthorize)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            _ = try await URLSession.shared.data(for: request)
            print("Successfully deauthorized token on Strava's server.")
        } catch {
            print("Failed to deauthorize on Strava server. Error: \(error.localizedDescription)")
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
        guard let errorResponse = try? JSONDecoder().decode(StravaErrorResponse.self, from: data) else { return nil }
        var detailedError = errorResponse.message ?? "Unknown Strava error"
        if let firstError = errorResponse.errors?.first {
            detailedError += " (\(firstError.resource ?? "Resource") \(firstError.field ?? "field"): \(firstError.code ?? "code"))"
        }
        return detailedError.replacingOccurrences(of: "Unknown Strava error ()", with: "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : detailedError
    }
}

struct TokenResponse: Codable {
    let tokenType: String?
    let expiresAt: Int?
    let expiresIn: Int?
    let refreshToken: String?
    let accessToken: String
}
