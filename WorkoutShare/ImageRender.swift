import SwiftUI

@available(iOS 16.0, *)
extension View {
    func snapshot(aspectRatio: CGFloat = 1.0) -> UIImage? {
        let screenWidth = UIScreen.main.bounds.width
        let canvasWidth = min(screenWidth - 40, 300)
        let canvasHeight = canvasWidth / aspectRatio
        let targetSize = CGSize(width: canvasWidth, height: canvasHeight)
        
        print("Rendering with targetSize: \(targetSize)")
        
        // ImageRenderer를 사용하여 SwiftUI 뷰를 직접 렌더링
        let renderer = ImageRenderer(content: self.frame(width: canvasWidth, height: canvasHeight))
        renderer.proposedSize = ProposedViewSize(targetSize) // CGSize를 ProposedViewSize로 변환
        renderer.scale = UIScreen.main.scale // 디바이스 해상도에 맞게 스케일 설정
        
        return renderer.uiImage
    }
}
