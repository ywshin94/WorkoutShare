import Foundation
import UIKit // UIApplication.shared.open 사용

// Strava API 연동 및 데이터 관리를 위한 ObservableObject 클래스
class StravaService: ObservableObject {
    // ... (clientId, clientSecret, redirectUri 등 상수는 이전과 동일) ...
    private let clientId = "102274"
    private let clientSecret = "ffe243278147663c88dddc2625b61fdf5a47953a" // !!! 보안 주의 !!!
    private let redirectUri = "https://ywshin94.mycafe24.com/oauth" // 잘 작동했던 버전 사용
    private let stravaAuthorizeUrl = "https://www.strava.com/oauth/authorize"
    private let stravaTokenUrl = "https://www.strava.com/oauth/token"
    private let stravaActivitiesUrl = "https://www.strava.com/api/v3/athlete/activities"

    // ... (@Published 변수들 동일) ...
    @Published var accessToken: String?
    @Published var workouts: [StravaWorkout] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // ... (startOAuthFlow 함수 동일) ...
    func startOAuthFlow() {
        print("startOAuthFlow() called.") // <-- 함수 호출 확인
        
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
            print("Constructed URL: \(url)") // <-- 생성된 URL 확인
            print("Attempting to open URL...") // <-- URL 열기 시도 확인
            UIApplication.shared.open(url)
        } else {
            // --- URL 생성 실패 시 이 부분이 실행됨 ---
            print("Error: Failed to construct authorization URL.") // <-- 실패 로그 확인
            // errorMessage 업데이트가 메인 스레드에서 실행되는지 확인 (현재 코드는 맞음)
            DispatchQueue.main.async {
               self.errorMessage = "Failed to create authorization URL."
            }
        }
    }


    // ... (exchangeCodeForToken 함수 동일) ...
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
            if let httpResponse = response as? HTTPURLResponse {
                print("Token exchange HTTP status: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorResponse = String(data: data, encoding: .utf8) ?? "No error data"
                    print("Token exchange failed: \(errorResponse)")
                    // --- decodeStravaError 호출 부분 ---
                    let stravaError = decodeStravaError(from: data) ?? "HTTP \(httpResponse.statusCode)"
                    await MainActor.run {
                        self.errorMessage = "Token exchange failed: \(stravaError)"
                        self.isLoading = false
                    }
                    throw NSError(domain: "StravaAuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: stravaError])
                }
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
            print("Token exchange successful. Access Token received.")
            await MainActor.run {
                self.accessToken = tokenResponse.accessToken
                self.isLoading = false
                self.errorMessage = nil
            }
            await fetchRecentWorkouts()
        } catch {
            print("Error during token exchange: \(error)")
            await MainActor.run {
                if self.errorMessage == nil { self.errorMessage = "Failed to get token: \(error.localizedDescription)" }
                self.isLoading = false
            }
            throw error
        }
    }

    // ... (fetchRecentWorkouts 함수 동일) ...
    @MainActor
    func fetchRecentWorkouts() async {
        guard let token = accessToken else { return }
        print("Fetching recent workouts...")
        self.isLoading = true; self.errorMessage = nil
        var components = URLComponents(string: stravaActivitiesUrl)!
        components.queryItems = [ URLQueryItem(name: "per_page", value: "30") ]
        guard let url = components.url else { /* ... */ return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")")
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                 let errorResponse = String(data: data, encoding: .utf8) ?? "No error data"
                 print("Failed to fetch activities: Status \(httpResponse.statusCode), Response: \(errorResponse)")
                 // --- decodeStravaError 호출 부분 ---
                 let stravaError = decodeStravaError(from: data) ?? "HTTP \(httpResponse.statusCode)"
                 self.errorMessage = "Failed to fetch workouts: \(stravaError)"
                 self.isLoading = false
                 return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let fetchedWorkouts = try decoder.decode([StravaWorkout].self, from: data)
            
            // --- 디버깅 로그 추가 ---
            if let firstWorkoutWithElevation = fetchedWorkouts.first(where: { $0.totalElevationGain != nil && $0.totalElevationGain != 0 }) {
                 print("Decoded Elevation for a workout: \(firstWorkoutWithElevation.totalElevationGain!)")
            } else if let firstWorkout = fetchedWorkouts.first {
                print("Decoded Elevation for first workout: \(String(describing: firstWorkout.totalElevationGain))")
            }
            // --- 로그 추가 끝 ---
        
            print("Successfully fetched \(fetchedWorkouts.count) workouts.")
            self.workouts = fetchedWorkouts; self.isLoading = false; self.errorMessage = nil
        } catch {
            print("Error fetching workouts: \(error)")
            self.errorMessage = "Could not load workouts: \(error.localizedDescription)"; self.isLoading = false
        }
    }

    // --- Strava 오류 응답 디코딩 함수 (구조체 정의 포함) ---
    private func decodeStravaError(from data: Data) -> String? {
        // --- 구조체 정의를 함수 내부에 명시 ---
        struct StravaErrorResponse: Decodable {
            let message: String? // 이 프로퍼티를 참조합니다
            let errors: [StravaErrorDetail]?
        }
        struct StravaErrorDetail: Decodable {
            let resource: String?
            let field: String?
            let code: String?
        }
        // --- 구조체 정의 끝 ---

        // JSON 디코딩 시도
        guard let errorResponse = try? JSONDecoder().decode(StravaErrorResponse.self, from: data) else {
            // 디코딩 실패 시 nil 반환 (Strava 오류 형식이 아닐 수 있음)
            return nil
        }

        // 오류 메시지 조합
        var detailedError = errorResponse.message ?? "Unknown Strava error" // message 프로퍼티 사용
        if let firstError = errorResponse.errors?.first {
            // 상세 오류 정보 추가 (있을 경우)
            detailedError += " (\(firstError.resource ?? "Resource") \(firstError.field ?? "field"): \(firstError.code ?? "code"))"
        }

        // 비어있지 않으면 조합된 메시지 반환, 비어있으면 nil 반환
        return detailedError.replacingOccurrences(of: "Unknown Strava error ()", with: "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : detailedError
    }
    // --- decodeStravaError 함수 수정 완료 ---
}

// Strava 토큰 응답 구조체 - 변경 없음
struct TokenResponse: Codable {
    let tokenType: String?
    let expiresAt: Int?
    let expiresIn: Int?
    let refreshToken: String?
    let accessToken: String
}
