import SwiftUI

enum SettingsKey {
    static let fontSize = "fontSize"
    static let fontStyle = "fontStyle"
    static let lineSpacing = "lineSpacing"
    static let wrapsLines = "wrapsLines"
}

enum SettingsDefault {
    static let fontSize: Double = 14
    static let fontSizeRange: ClosedRange<Double> = 10...28
    static let fontStyle: FontStyle = .monospaced
    static let lineSpacing: Double = 1.25
    static let lineSpacingRange: ClosedRange<Double> = 1.0...2.0
    static let wrapsLines = true
}

enum FontStyle: String, CaseIterable, Identifiable {
    case monospaced, system, serif

    var id: Self { self }

    var title: String {
        switch self {
        case .monospaced: "Monospaced"
        case .system: "System"
        case .serif: "Serif (New York)"
        }
    }

    func font(size: CGFloat) -> NSFont {
        switch self {
        case .monospaced:
            return .monospacedSystemFont(ofSize: size, weight: .regular)
        case .system:
            return .systemFont(ofSize: size)
        case .serif:
            let system = NSFont.systemFont(ofSize: size)
            guard let descriptor = system.fontDescriptor.withDesign(.serif),
                  let serif = NSFont(descriptor: descriptor, size: size) else { return system }
            return serif
        }
    }
}

struct SettingsView: View {
    @AppStorage(SettingsKey.fontSize) private var fontSize = SettingsDefault.fontSize
    @AppStorage(SettingsKey.fontStyle) private var fontStyle = SettingsDefault.fontStyle
    @AppStorage(SettingsKey.lineSpacing) private var lineSpacing = SettingsDefault.lineSpacing
    @AppStorage(SettingsKey.wrapsLines) private var wrapsLines = SettingsDefault.wrapsLines

    var body: some View {
        Form {
            Picker("Font:", selection: $fontStyle) {
                ForEach(FontStyle.allCases) { Text($0.title).tag($0) }
            }
            Stepper(value: $fontSize, in: SettingsDefault.fontSizeRange) {
                Text("Size: \(Int(fontSize)) pt")
            }
            Slider(value: $lineSpacing, in: SettingsDefault.lineSpacingRange) {
                Text("Line spacing:")
            }
            Toggle("Wrap lines", isOn: $wrapsLines)
        }
        .padding(20)
        .frame(width: 360)
    }
}
