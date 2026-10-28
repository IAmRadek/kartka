import AppKit
import SwiftUI

@main
struct KartkaApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        // One document per window: hide "Merge All Windows" and the tab bar.
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        DocumentGroup(newDocument: KartkaDocument()) { file in
            DocumentView(document: file.$document)
        }
        .defaultSize(width: 720, height: 560)
        .commands { FontSizeCommands() }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // `open -W` returns when the app exits, so `bin/kartka` as $EDITOR needs this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

struct DocumentView: View {
    @Binding var document: KartkaDocument

    @AppStorage(SettingsKey.fontSize) private var fontSize = SettingsDefault.fontSize
    @AppStorage(SettingsKey.fontStyle) private var fontStyle = SettingsDefault.fontStyle
    @AppStorage(SettingsKey.lineSpacing) private var lineSpacing = SettingsDefault.lineSpacing
    @AppStorage(SettingsKey.wrapsLines) private var wrapsLines = SettingsDefault.wrapsLines

    var body: some View {
        VStack(spacing: 0) {
            EditorView(
                text: $document.text,
                font: fontStyle.font(size: fontSize),
                lineSpacing: lineSpacing,
                wrapsLines: wrapsLines
            )
            CountFooter(text: document.text)
        }
        .background(BlurredWindowBackground().ignoresSafeArea())
        .frame(minWidth: 360, minHeight: 240)
    }
}

struct FontSizeCommands: Commands {
    @AppStorage(SettingsKey.fontSize) private var fontSize = SettingsDefault.fontSize

    var body: some Commands {
        CommandGroup(after: .textFormatting) {
            Button("Bigger") {
                fontSize = min(fontSize + 1, SettingsDefault.fontSizeRange.upperBound)
            }
            .keyboardShortcut("+")

            Button("Smaller") {
                fontSize = max(fontSize - 1, SettingsDefault.fontSizeRange.lowerBound)
            }
            .keyboardShortcut("-")

            Button("Actual Size") {
                fontSize = SettingsDefault.fontSize
            }
            .keyboardShortcut("0")
        }
    }
}
