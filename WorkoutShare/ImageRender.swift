import SwiftUI
import UIKit

extension View {
    /// SwiftUI 뷰를 주어진 크기의 UIImage로 캡처합니다.
    /// UIGraphicsImageRenderer와 drawHierarchy를 사용하여 좌표, 스케일, 색상 문제를 모두 해결한 가장 안정적인 최종 버전입니다.
    /// - Parameter size: 캡처할 이미지의 최종 픽셀 크기
    /// - Returns: 렌더링된 UIImage. 실패 시 nil을 반환합니다.
    func snapshot(size: CGSize) -> UIImage? {
        // 1. 캡처할 뷰를 호스팅 컨트롤러에 담아 강제로 레이아웃을 실행시키기 위해 임시 윈도우에 추가합니다.
        let controller = UIHostingController(
            rootView: self
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
        )
        
        guard let view = controller.view else { return nil }
        
        let targetFrame = CGRect(origin: .zero, size: size)
        view.bounds = targetFrame
        view.backgroundColor = .clear

        let window = UIWindow(frame: targetFrame)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // 2. 애플의 고수준 이미지 렌더링 API를 사용합니다.
        // 이 렌더러는 레티나 스케일, 좌표계 등을 자동으로 처리합니다.
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { _ in
            // 3. 화면에 보이는 것과 가장 유사하게 캡처하는 drawHierarchy 메서드를 사용합니다.
            // 이 방법이 layer.render 보다 색상 표현이 더 정확합니다.
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // 4. 사용한 임시 윈도우를 정리하고 최종 UIImage를 반환합니다.
        window.isHidden = true
        window.rootViewController = nil
        
        return image
    }
}
