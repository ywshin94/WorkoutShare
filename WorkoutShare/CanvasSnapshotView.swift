// CanvasSnapshotView.swift — ✅ Metal 제거, 안정적 snapshot fallback

import SwiftUI

struct CanvasSnapshotView: UIViewRepresentable {
    let canvasContent: CanvasView

    func makeUIView(context: Context) -> UIView {
        let hostingController = UIHostingController(rootView: canvasContent)
        hostingController.view.backgroundColor = .clear
        return hostingController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 필요 시 업데이트 처리
    }

    // Snapshot UIImage로 변환 (fallback: render(in:))
    static func renderImage(from canvasView: CanvasView, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: canvasView)
        controller.view.backgroundColor = .clear
        controller.view.bounds = CGRect(origin: .zero, size: size)

        // 💡 Metal 의존 제거, 안정적 CoreAnimation 기반 snapshot
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }
    }
}
