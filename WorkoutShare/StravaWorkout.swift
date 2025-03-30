import Foundation

struct StravaWorkout: Codable, Identifiable {
    let id: Int
    let name: String
    let distance: Double // meters
    let movingTime: Int? // seconds
    let type: String // Strava에서 원래 오는 타입 문자열
    let startDate: Date
    let totalElevationGain: Double? // 상승 고도 (meters)

    // 거리 포맷 (km)
    var formattedDistance: String {
        let distanceInKm = distance / 1000.0
        return String(format: "%.2f km", distanceInKm)
    }

    // 운동 시간 포맷 (HH:MM:SS 또는 MM:SS)
    var formattedDuration: String {
        guard let movingTime = movingTime, movingTime > 0 else { return "--:--:--" } // 시간 없으면 기본값
        let hours = movingTime / 3600
        let minutes = (movingTime % 3600) / 60
        let seconds = movingTime % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // 페이스 포맷 (min:ss /km)
    var formattedPace: String {
        guard let movingTime = movingTime, movingTime > 0, distance > 0 else { return "--:-- /km" } // 계산 불가 시 기본값
        let distanceInKm = distance / 1000.0
        let paceInSecondsPerKm = Double(movingTime) / distanceInKm
        let paceMinutes = Int(paceInSecondsPerKm) / 60
        let paceSeconds = Int(paceInSecondsPerKm) % 60
        return String(format: "%d:%02d /km", paceMinutes, paceSeconds)
    }

    // 속도 포맷 (km/h)
    var formattedSpeed: String {
        guard let movingTime = movingTime, movingTime > 0, distance > 0 else { return "--.- km/h" } // 계산 불가 시 기본값
        let distanceInKm = distance / 1000.0
        let durationInHours = Double(movingTime) / 3600.0
        let speedKmh = distanceInKm / durationInHours
        return String(format: "%.1f km/h", speedKmh) // 소수점 첫째 자리까지
    }

    // 상승 고도 포맷 (m)
    var formattedElevationGain: String {
        guard let elevation = totalElevationGain else { return "- m" } // 데이터 없으면 "-"
        // 상승 고도가 0일 경우도 처리
        if elevation == 0 { return "0 m"}
        return String(format: "%.0f m", elevation) // 정수로 표시
    }

    // JSON 디코딩을 위한 키 매핑
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case distance
        case movingTime = "moving_time"
        case type // Strava의 원래 type 필드
        case startDate = "start_date"
        case totalElevationGain = "total_elevation_gain" // API 필드 이름과 매핑
    }

    // (선택 사항) Strava 'type' 문자열을 WorkoutType enum으로 변환하는 로직
    // func mapToWorkoutType() -> WorkoutType {
    //     switch type {
    //     case "Run":
    //         // 추가적인 정보 (예: device_name) 로 트레드밀 구분 가능?
    //         return .run
    //     case "Walk": return .walk
    //     case "Hike": return .hike
    //     // "Trail Run" 타입이 별도로 있는지 Strava API 확인 필요
    //     // case "TrailRun": return .trailRun
    //     default:
    //         // 다른 타입들은 어떻게 처리할지 결정 (예: 기본 Run)
    //         print("Unhandled Strava workout type: \(type)")
    //         return .run // 기본값
    //     }
    // }
}
