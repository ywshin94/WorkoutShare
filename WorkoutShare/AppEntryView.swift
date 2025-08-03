import SwiftUI

struct AppEntryView: View {
    // ✅ 1. 로그인 상태를 알기 위해 stravaService를 가져옵니다.
    @EnvironmentObject private var stravaService: StravaService
    @State private var isSplashFinished = false

    var body: some View {
        if isSplashFinished {
            // 스플래시가 끝나면 메인 뷰를 보여줍니다.
            MainCanvasView()
                // ✅ 2. accessToken 값에 따라 뷰의 ID를 부여합니다.
                // 이 값이 변경되면(로그인->로그아웃, 혹은 그 반대) MainCanvasView는 완전히 새로 그려집니다.
                .id(stravaService.accessToken)
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
        // ✅ Preview에서도 stravaService를 추가해야 합니다.
        .environmentObject(StravaService())
}
