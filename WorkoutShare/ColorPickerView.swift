import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Binding var useImageBackground: Bool
    var onClose: () -> Void

    private let presetColors: [Color] = [
        .black, .gray, .white, .blue, .green, .orange, .red, .purple, .yellow
    ]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 48, height: 6)
                .padding(.top, 8)
            HStack {
                Text("배경 색상 선택")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                        // ✅ 투명 배경 선택 버튼 UI를 격자무늬로 변경
                        Button(action: { selectColor(.clear) }) {
                            CheckerboardView()
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .frame(width: 60, height: 60)
                        }
                        
                        ForEach(presetColors, id: \.self) { color in
                            Button(action: { selectColor(color) }) {
                                Circle()
                                    .fill(color)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    ColorPicker("커스텀 색상 선택", selection: $selectedColor, supportsOpacity: true)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .onChange(of: selectedColor) { _ in
                            useImageBackground = false
                        }

                    Spacer()
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
    
    private func selectColor(_ color: Color) {
        useImageBackground = false
        selectedColor = color
        onClose()
    }
}


// ✅ 투명 배경을 나타내는 격자무늬를 그리는 뷰
struct CheckerboardView: View {
    let squareSize: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            let numCols = Int(ceil(geometry.size.width / squareSize))
            let numRows = Int(ceil(geometry.size.height / squareSize))
            
            VStack(spacing: 0) {
                ForEach(0..<numRows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<numCols, id: \.self) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color(UIColor.systemGray4) : Color(UIColor.systemGray6))
                                .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
            .clipped()
        }
    }
}
