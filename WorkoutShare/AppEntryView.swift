//
//  AppEntryView.swift
//  WorkoutShare
//
//  Created by 신용운 on 6/22/25.
//


import SwiftUI

struct AppEntryView: View {
    @State private var isSplashFinished = false

    var body: some View {
        if isSplashFinished {
            // 스플래시가 끝나면 메인 뷰를 보여줍니다.
            MainCanvasView()
        } else {
            // 스플래시 화면
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                Text("PaceOn")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .transition(.opacity.animation(.easeOut(duration: 0.5)))
            }
            .onAppear {
                // 1.5초 후에 isSplashFinished 상태를 true로 변경하여 화면을 전환합니다.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isSplashFinished = true
                    }
                }
            }
        }
    }
}

#Preview {
    AppEntryView()
}