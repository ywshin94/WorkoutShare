import Foundation

// 운동 종류 Enum 정의
enum WorkoutType: String, CaseIterable, Identifiable {
    case none = "None"
    case run = "Run" // Strava API 타입과 일치 고려
    case trailRun = "Trail Run"
    case treadmill = "Treadmill" // Strava에선 보통 "Run"
    case walk = "Walk"
    case hike = "Hike"
    case weight = "Weight" // 보강운동 추가

    var id: String { self.rawValue } // Identifiable 준수

    // UI 표시용 한글 이름
    var displayName: String {
        switch self {
        case .none: return ""
        case .run: return "러닝"
        case .trailRun: return "트레일러닝"
        case .treadmill: return "트레드밀"
        case .walk: return "걷기"
        case .hike: return "하이킹"
        case .weight: return "보강운동"
        }
    }

    // 각 운동 타입별 데이터 표시 여부 플래그 (CanvasView에서 show... && workoutType.shows... 로 사용)
    // 이 값들은 해당 운동 타입에서 '데이터가 존재할 수 있는가'를 나타내며,
    // 초기 토글 상태와는 별개로 캔버스에 표시될 수 있는 데이터 종류를 제한합니다.

    var showsDistance: Bool {
        switch self {
        case .none, .weight:
            return false
        default:
            return true
        }
    }

    var showsDuration: Bool {
        return true
    }

    var showsPace: Bool {
        switch self {
        case .run, .trailRun, .treadmill:
            return true
        case .walk, .hike: // 걷기/하이킹도 페이스 표시 가능
            return true
        default:
            return false
        }
    }

    var showsSpeed: Bool {
        switch self {
        case .run, .trailRun, .treadmill: // 러닝도 속도 표시 가능
            return true
        case .walk, .hike:
            return true
        default:
            return false
        }
    }

    var showsElevation: Bool {
        switch self {
        case .run, .trailRun, .hike:
            return true
        default:
            return false
        }
    }

    // var showsCalories: Bool { // ✨ 제거
    //     return true
    // }

    // 새로 추가: 해당 운동 타입의 주요(기본) 속도 지표가 페이스인지 여부
    var isPacePrimary: Bool {
        switch self {
        case .run, .trailRun, .treadmill:
            return true
        default:
            return false
        }
    }

    // 새로 추가: 해당 운동 타입의 주요(기본) 속도 지표가 속도(km/h)인지 여부
    var isSpeedPrimary: Bool {
        switch self {
        case .walk, .hike:
            return true
        default:
            return false
        }
    }


    static func fromStravaType(_ stravaType: String) -> WorkoutType {
        switch stravaType.lowercased() {
        case "run": return .run
        case "walk": return .walk
        case "hike": return .hike
        case "trailrun": return .trailRun
        case "treadmill": return .treadmill
        case "weighttraining", "weight": return .weight
        default:
            print("⚠️ 예상치 못한 Strava workout type: \(stravaType)")
            return .run // 기본값
        }
    }
}
