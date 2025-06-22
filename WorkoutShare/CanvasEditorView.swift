import SwiftUI

struct CanvasEditorView: View {
    @Binding var configuration: CanvasConfiguration
    var onClose: () -> Void

    private let curatedFonts: [(name: String, displayName: String)] = [
        ("Futura-Bold", "Futura"), ("AvenirNext-Bold", "Avenir Next"),
        ("GillSans-SemiBold", "Gill Sans"), ("Georgia-Bold", "Georgia"),
        ("NewYork-Medium", "New York"), ("SFProRounded-Semibold", "Rounded"),
        ("Impact", "Impact")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.4)).frame(width: 48, height: 6).padding(.top, 8)
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.secondary)
                }.padding(.trailing, 12)
            }
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 28) {
                    fontSection
                    textStyleSection
                    layoutSection
                    displayItemsSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
}

private extension CanvasEditorView {
    @ViewBuilder
    var fontSection: some View {
        VStack(alignment: .leading) {
            Text("폰트 스타일").font(.headline).padding(.leading, 4).padding(.bottom, 4)
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
                Text("텍스트 크기: \(Int(configuration.baseFontSize))")
                Slider(value: $configuration.baseFontSize, in: 10...30, step: 1)
            }
            VStack(alignment: .leading) {
                Text("텍스트 색상")
                HStack {
                    Text("검은색").font(.caption)
                    Slider(value: $configuration.textColorValue, in: 0.0...1.0)
                    Text("흰색").font(.caption)
                }
            }
            Picker("정렬", selection: $configuration.textAlignment) {
                ForEach(TextAlignmentOption.allCases) { option in Text(option.rawValue).tag(option) }
            }.pickerStyle(.segmented)
        }
    }
    
    @ViewBuilder
    var layoutSection: some View {
        Picker("레이아웃", selection: $configuration.layoutDirection) {
            ForEach(LayoutDirectionOption.allCases) { option in Text(option.rawValue).tag(option) }
        }.pickerStyle(.segmented)
    }

    @ViewBuilder
    var displayItemsSection: some View {
        VStack(alignment: .leading) {
            Text("표시 항목 선택").font(.caption).foregroundColor(.secondary).padding(.leading, 4)
            VStack {
                Toggle(isOn: $configuration.showTitle) { Text("운동 제목 표시") }
                Divider()
                Toggle(isOn: $configuration.showDateTime) { Text("날짜/시간 표시") }
                Divider()
                Toggle(isOn: $configuration.showLabels) { Text("항목 이름 표시 (거리, 시간 등)") }
                Divider()
                Toggle(isOn: $configuration.showDistance) { Text("거리 표시") }
                Divider()
                Toggle(isOn: $configuration.showDuration) { Text("시간 표시") }
                Divider()
                Toggle(isOn: $configuration.showPace) { Text("페이스 표시") }
                Divider()
                Toggle(isOn: $configuration.showSpeed) { Text("속도 표시") }
                Divider()
                Toggle(isOn: $configuration.showElevation) { Text("상승고도 표시") }
            }
            .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(12)
        }
    }
}
