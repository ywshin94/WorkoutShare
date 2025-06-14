import SwiftUI

// 캔버스의 모든 디자인 및 데이터 표시 설정을 담는 구조체
struct CanvasConfiguration {
    // 배경 설정
    var useImageBackground: Bool = false
    var backgroundColor: Color = .blue
    var backgroundImage: UIImage?
    var aspectRatio: AspectRatioOption = .fourByFive

    // 텍스트 및 폰트 설정
    var textAlignment: TextAlignmentOption = .left
    var fontName: String = "Futura-Bold"
    var baseFontSize: CGFloat = 13.0
    var textColorValue: CGFloat = 1.0 // ✅ 텍스트 색상 값 (1.0: 흰색, 0.0: 검은색)
    
    // 레이아웃 및 위치/회전 설정
    var layoutDirection: LayoutDirectionOption = .vertical
    var accumulatedOffset: CGSize = .zero
    var rotationAngle: Angle = .zero

    // 데이터 항목별 표시 여부 설정
    var showTitle: Bool = true
    var showDateTime: Bool = true
    var showLabels: Bool = true
    var showDistance: Bool = true
    var showDuration: Bool = true
    var showPace: Bool = true
    var showSpeed: Bool = false
    var showElevation: Bool = true
    
    // 운동 종류에 따라 초기값을 설정하는 함수
    mutating func initialize(for workoutType: WorkoutType) {
        self.showDistance = workoutType.showsDistance
        self.showDuration = workoutType.showsDuration
        self.showElevation = workoutType.showsElevation
        
        if workoutType.isPacePrimary {
            self.showPace = true
            self.showSpeed = false
        } else if workoutType.isSpeedPrimary {
            self.showPace = false
            self.showSpeed = true
        } else {
            self.showPace = false
            self.showSpeed = false
        }
    }
}
