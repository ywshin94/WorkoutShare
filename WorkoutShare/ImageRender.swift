import SwiftUI
import UIKit

extension View {
    func snapshot(size: CGSize) -> UIImage? {
        // 캡처하려는 SwiftUI 뷰를 UIHostingController로 감쌉니다.
        let controller = UIHostingController(
            rootView: self
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
        )
        
        guard let view = controller.view else {
            return nil
        }
        
        // 뷰의 프레임을 설정하고 모든 배경을 명시적으로 투명하게 만듭니다.
        let targetFrame = CGRect(origin: .zero, size: size)
        view.bounds = targetFrame
        view.backgroundColor = .clear

        // 뷰를 화면에 표시되는 것과 동일한 상태로 만들기 위해 임시 UIWindow에 추가합니다.
        // 이것이 뷰의 레이아웃과 렌더링을 보장하는 가장 확실한 방법입니다.
        let window = UIWindow(frame: targetFrame)
        window.rootViewController = controller
        window.backgroundColor = .clear
        window.makeKeyAndVisible() // 윈도우를 활성화하여 렌더링을 강제합니다.
        
        // 뷰가 레이아웃을 다시 계산하고 적용하도록 강제합니다.
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // 이미지 렌더러의 포맷을 설정합니다.
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false // 투명도를 지원하도록 설정 (가장 중요)
        format.scale = 1.0   // 1배율로 렌더링하여 요청된 픽셀 크기를 정확히 맞춥니다.
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        // 최종적으로 이미지를 렌더링합니다.
        let image = renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
        
        // 사용한 임시 윈도우를 정리합니다.
        window.isHidden = true
        window.rootViewController = nil
        
        // 생성된 이미지의 크기가 0인지 확인하여 실패 여부를 판단합니다.
        if image.size.width == 0 || image.size.height == 0 {
             print("Warning: Snapshot resulted in a zero-size image.")
             return nil
        }

        return image
    }
}
