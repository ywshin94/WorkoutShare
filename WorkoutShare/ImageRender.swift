import SwiftUI
import UIKit

extension View {
    // snapshot 함수: 현재 View를 UIImage로 렌더링
    func snapshot(aspectRatio: CGFloat = 1.0) -> UIImage? {
        // 캔버스 크기 계산 (CanvasView의 계산 로직과 일치해야 함)
        let screenWidth = UIScreen.main.bounds.width
        // 중요: CanvasView 내부의 canvasWidth 계산과 완전히 동일한 로직 사용
        let canvasWidth = min(screenWidth - 40, 350)
        let canvasHeight = canvasWidth / aspectRatio
        let targetSize = CGSize(width: canvasWidth, height: canvasHeight)

        // UIHostingController에 전달할 View 구성
        // 1. frame()을 적용하여 크기를 고정
        // 2. ignoresSafeArea()를 적용하여 안전 영역 무시 (상단 여백 방지)
        let rootView = self
            .frame(width: canvasWidth, height: canvasHeight) // 크기 고정 필수
            .ignoresSafeArea() // 안전 영역 무시

        // UIHostingController 생성
        let controller = UIHostingController(rootView: rootView)
        guard let view = controller.view else {
            print("Snapshot Error: Failed to get view from UIHostingController")
            return nil
        }

        // 호스팅된 뷰의 크기와 경계 설정
        view.frame = CGRect(origin: .zero, size: targetSize) // 프레임 설정
        view.bounds = CGRect(origin: .zero, size: targetSize) // 경계 설정
        view.backgroundColor = .clear // 호스팅 뷰 배경은 투명하게

        // UIGraphicsImageRenderer 설정 (불투명 이미지 생성)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true // 알파 채널 없이 불투명하게 (성능 및 용량 최적화)
        format.scale = UIScreen.main.scale // 화면 배율(레티나 등) 적용

        // 렌더러 생성
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // 이미지 렌더링 실행
        let image = renderer.image { context in
            // 뷰 계층 구조를 context에 그리기
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        print("Snapshot generated. Size: \(image.size), Scale: \(image.scale), Opaque: \(format.opaque)")
        return image
    }
}
