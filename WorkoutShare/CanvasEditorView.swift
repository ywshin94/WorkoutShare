import SwiftUI

struct CanvasEditorView: View {
    @Binding var configuration: CanvasConfiguration
    let mode: WorkoutDetailView.ActivePanel

    private let curatedFonts: [(name: String, displayName: String)] = [
        ("Futura-Bold", "Futura"), ("AvenirNext-Bold", "Avenir Next"),
        ("GillSans-SemiBold", "Gill Sans"), ("Georgia-Bold", "Georgia"),
        ("NewYork-Medium", "New York"), ("SFProRounded-Semibold", "Rounded"),
        ("Impact", "Impact")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 48, height: 6).padding(.top, 8)
            
            Divider().padding(.vertical, 12)

            // ✅ [수정] mode에 따라 Spacer() 유무를 다르게 하여 높이를 제어
            switch mode {
            case .style:
                styleSection
                    .padding(.horizontal)
                // '스타일'은 고정된 프레임 안에서 내용을 위로 밀기 위해 Spacer 사용
                Spacer()
                
            case .layout:
                layoutSection
                    .padding(.horizontal)
                // '레이아웃'은 높이가 내용에 맞게 줄어들어야 하므로 Spacer를 사용하지 않음
                
            case .items:
                ScrollView {
                    displayItemsSection
                        .padding(.horizontal)
                }
                // '항목'은 ScrollView가 공간을 모두 채우므로 Spacer 불필요
                
            default:
                EmptyView()
            }
        }
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
        .cornerRadius(18, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
}

// MARK: - Subviews
private extension CanvasEditorView {
    
    @ViewBuilder
    var styleSection: some View {
        VStack(spacing: 28) {
            fontSection
            textStyleSection
        }
    }
    
    @ViewBuilder
    var fontSection: some View {
        VStack(alignment: .leading) {
            Text("폰트 스타일").font(.subheadline).foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(curatedFonts, id: \.name) { font in
                        Button(action: { configuration.fontName = font.name }) {
                            VStack {
                                Text("Aa").font(.custom(font.name, size: 22)).frame(height: 30)
                                Text(font.displayName).font(.system(size: 10))
                            }
                            .foregroundColor(configuration.fontName == font.name ? .accentColor : .primary)
                            .frame(width: 70, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray5))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(configuration.fontName == font.name ? Color.accentColor : Color.clear, lineWidth: 2))
                            )
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var textStyleSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading) {
                Text("텍스트 크기: \(Int(configuration.baseFontSize))").font(.subheadline).foregroundColor(.secondary)
                Slider(value: $configuration.baseFontSize, in: 10...30, step: 1)
            }
            
            VStack(alignment: .leading) {
                Text("텍스트 색상").font(.subheadline).foregroundColor(.secondary)
                ColorSelectorView(selectedColor: $configuration.textColor)
            }
        }
    }
    
    @ViewBuilder
    var layoutSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 16) {
                 Text("레이아웃 방향").font(.subheadline).foregroundColor(.secondary)
                Picker("레이아웃", selection: $configuration.layoutDirection) {
                    ForEach(LayoutDirectionOption.allCases) { option in Text(option.rawValue).tag(option) }
                }.pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("텍스트 정렬").font(.subheadline).foregroundColor(.secondary)
                Picker("정렬", selection: $configuration.textAlignment) {
                    ForEach(TextAlignmentOption.allCases) { option in Text(option.rawValue).tag(option) }
                }.pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    var displayItemsSection: some View {
        VStack {
            Toggle(isOn: $configuration.showTitle) { Text("운동 제목") }
            Divider()
            Toggle(isOn: $configuration.showDateTime) { Text("날짜/시간") }
            Divider()
            Toggle(isOn: $configuration.showLabels) { Text("항목 이름 (거리, 시간 등)") }
            Divider()
            Toggle(isOn: $configuration.showDistance) { Text("거리") }
            Divider()
            Toggle(isOn: $configuration.showDuration) { Text("시간") }
            Divider()
            Toggle(isOn: $configuration.showPace) { Text("페이스") }
            Divider()
            Toggle(isOn: $configuration.showSpeed) { Text("속도") }
            Divider()
            Toggle(isOn: $configuration.showElevation) { Text("상승고도") }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ColorSelectorView: View {
    @Binding var selectedColor: Color
    
    private let presetTextColors: [Color] = [
        .white, .black, .gray, Color(UIColor.lightGray), .yellow, .orange
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(presetTextColors, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .overlay(
                                ZStack {
                                    if selectedColor == color {
                                        Circle().stroke(Color.accentColor, lineWidth: 2)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(color == .white ? .black : .white)
                                    }
                                }
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
