// ImageRender.swift — UIImage snapshot 받는 구조로 수정

import SwiftUI
import UIKit

extension View {
    // snapshot 함수: 현재 View를 UIImage로 렌더링 (뷰가 실제 표시된 상태여야 함)
    func snapshot(aspectRatio: CGFloat = 1.0) -> UIImage? {
        let screenWidth = UIScreen.main.bounds.width
        let canvasWidth = min(screenWidth - 40, 350)
        let canvasHeight = canvasWidth / aspectRatio
        let targetSize = CGSize(width: canvasWidth, height: canvasHeight)

        let rootView = self
            .frame(width: canvasWidth, height: canvasHeight)
            .ignoresSafeArea()

        let controller = UIHostingController(rootView: rootView)
        let view = controller.view!

        view.frame = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear

        // ✅ 강제 layout 진행
        let window = UIWindow(frame: view.bounds)
        window.rootViewController = controller
        window.windowLevel = .normal
        window.isHidden = false

        // 🔁 강제로 layout cycle 돌림
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}
