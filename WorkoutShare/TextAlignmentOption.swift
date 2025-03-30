import SwiftUI

// 캔버스 텍스트 정렬 옵션 Enum
enum TextAlignmentOption: String, CaseIterable, Identifiable {
    case left = "왼쪽"    // Picker 표시용
    case center = "가운데"
    case right = "오른쪽"

    var id: String { self.rawValue } // Identifiable 준수

    // SwiftUI의 HorizontalAlignment 타입으로 변환
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .left:
            return .leading // 왼쪽 정렬은 .leading
        case .center:
            return .center
        case .right:
            return .trailing // 오른쪽 정렬은 .trailing
        }
    }
}
