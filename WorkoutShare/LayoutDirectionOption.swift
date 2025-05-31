//
//  LayoutDirectionOption.swift
//  WorkoutShare
//
//  Created by 신용운 on 5/31/25.
//


import SwiftUI

// 레이아웃 방향 옵션 Enum
enum LayoutDirectionOption: String, CaseIterable, Identifiable {
    case vertical = "세로"
    case horizontal = "가로"

    var id: String { self.rawValue } // Identifiable 준수

    // 실제 Stack 뷰 타입 (Internal usage, not directly returned as View)
    // 이 값을 직접 사용하기보다 CanvasView에서 case에 따라 VStack/HStack을 분기하는 것이 더 일반적입니다.
}