import SwiftUI

// 폰트 선택 옵션 Enum
enum FontOption: String, CaseIterable, Identifiable {
    case systemDefault = "기본" // 시스템 기본 폰트 (San Francisco)
    case serif = "명조 스타일"  // 시스템 명조 계열 (New York)
    case rounded = "둥근 고딕" // 시스템 둥근 고딕 계열 (SF Rounded)
    case monospaced = "고정폭" // 시스템 고정폭 폰트 (SF Mono)
    // 필요시 커스텀 폰트 추가 가능 (앱 번들 포함 및 Info.plist 등록 필요)
    // case customFont = "커스텀 폰트"

    var id: String { self.rawValue } // Identifiable 준수

    // Font 객체를 반환하는 함수 (크기는 외부에서 받아옴)
    func font(size: CGFloat) -> Font {
        switch self {
        case .systemDefault:
            // 기본 시스템 폰트 사용
            return .system(size: size)
        case .serif:
            // iOS 13+ New York 폰트 사용 시도 (없으면 시스템 기본 대체)
            // .system(size: size, weight: .regular, design: .serif) 방식도 가능
            return .custom("NewYork-Regular", size: size)
        case .rounded:
            // iOS 13+ SF Rounded 폰트 사용 시도 (없으면 시스템 기본 대체)
            // .system(size: size, weight: .regular, design: .rounded) 방식도 가능
             return .custom("SFRounded-Regular", size: size)
        case .monospaced:
            // iOS 13+ SF Mono 폰트 사용 시도 (없으면 시스템 기본 대체)
            // .system(size: size, weight: .regular, design: .monospaced) 방식도 가능
             return .custom("SFMono-Regular", size: size)
        // case .customFont:
            // 앱에 추가한 커스텀 폰트 이름 사용
            // return .custom("YourCustomFontName-Regular", size: size)
        }
    }
}
