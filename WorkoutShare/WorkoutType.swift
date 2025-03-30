import Foundation

// 운동 종류 Enum 정의
enum WorkoutType: String, CaseIterable, Identifiable {
    case run = "Run" // Strava API 타입과 일치 고려
    case trailRun = "Trail Run"
    case treadmill = "Treadmill" // Strava에선 보통 "Run"
    case walk = "Walk"
    case hike = "Hike"
    // 필요시 다른 타입 추가 (예: Ride, Swim 등)

    var id: String { self.rawValue } // Identifiable 준수

    // UI 표시용 한글 이름
    var displayName: String {
        switch self {
        case .run: return "러닝"
        case .trailRun: return "트레일러닝"
        case .treadmill: return "트레드밀"
        case .walk: return "걷기"
        case .hike: return "하이킹"
        }
    }

    // 각 운동 타입별 데이터 표시 여부 플래그
    // 페이스 표시 여부
    var showsPace: Bool {
        switch self {
        case .run, .trailRun, .treadmill:
            return true // 달리기 관련은 페이스 표시
        case .walk, .hike:
            return false
        }
    }

    // 속도(km/h) 표시 여부
    var showsSpeed: Bool {
        switch self {
        case .run, .trailRun, .treadmill:
            return false
        case .walk, .hike:
            return true // 걷기/하이킹은 속도 표시
        }
    }

    // 상승고도 표시 여부
    var showsElevation: Bool {
        switch self {
        case .trailRun, .hike:
            return true // 트레일러닝/하이킹은 상승고도 표시
        case .run, .treadmill, .walk:
            return false
        }
    }
}
