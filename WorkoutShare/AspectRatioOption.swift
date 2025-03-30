import Foundation
import CoreGraphics // CGFloat 사용

// 캔버스 가로세로 비율 옵션 Enum
enum AspectRatioOption: String, CaseIterable, Identifiable {
    case oneByOne = "1:1"
    case fourByFive = "4:5"
    case fourBySix = "4:6" // 인스타그램 세로 비율과 유사
    case nineBySixteen = "9:16" // 스토리 비율

    var id: String { self.rawValue } // Identifiable 준수

    // 각 옵션에 해당하는 비율 값 (CGFloat)
    var ratio: CGFloat {
        switch self {
        case .oneByOne:
            return 1.0 / 1.0
        case .fourByFive:
            return 4.0 / 5.0
        case .fourBySix:
            return 4.0 / 6.0
        case .nineBySixteen:
            return 9.0 / 16.0
        }
    }
}
