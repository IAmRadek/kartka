import AppKit
import SwiftUI

@main
struct KartkaApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        // One document per window: hide "Merge All Windows" and the tab bar.
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    // Documents and their windows come from NSDocumentController and `KartkaDocument`,
    // through NSDocumentClass in Info.plist. SwiftUI only adds Settings and menu items.
    var body: some Scene {
        Settings {
            SettingsView()
        }
        .commands {
            FileCommands()
            FontSizeCommands()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var terminationSource: DispatchSourceSignal?

    // `open -W` returns when the app exits, so `bin/kartka` as $EDITOR needs this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // SwiftUI does not forward applicationOpenUntitledFile, so a launch without files opens
    // an untitled document here. Files given at launch open later, so `documents` is still empty.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // `bin/kartka` sends SIGTERM when its terminal command stops. By default SIGTERM ends
        // the process at once; quitting through NSApp autosaves open documents first.
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { NSApp.terminate(nil) }
        source.resume()
        terminationSource = source

        let isDefaultLaunch = notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool ?? true
        if isDefaultLaunch {
            NSDocumentController.shared.newDocument(nil)
        }
    }
}

struct DocumentView: View {
    @ObservedObject var document: KartkaDocument

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

/// File menu items. The document actions go through the responder chain to the key window's NSDocument.
struct FileCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New") { NSDocumentController.shared.newDocument(nil) }
                .keyboardShortcut("n")
            Button("Open…") { NSDocumentController.shared.openDocument(nil) }
                .keyboardShortcut("o")
        }
        CommandGroup(replacing: .saveItem) {
            Button("Save") { send(#selector(NSDocument.save(_:))) }
                .keyboardShortcut("s")
            Button("Duplicate") { send(#selector(NSDocument.duplicate(_:))) }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            Button("Rename…") { send(#selector(NSDocument.rename(_:))) }
            Button("Move To…") { send(#selector(NSDocument.move(_:))) }
            Button("Revert to Saved") { send(#selector(NSDocument.revertToSaved(_:))) }
        }
    }

    private func send(_ action: Selector) {
        NSApp.sendAction(action, to: nil, from: nil)
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
