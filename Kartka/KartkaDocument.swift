import AppKit
import SwiftUI

final class KartkaDocument: NSDocument, ObservableObject {
    @Published var text = ""

    override class var autosavesInPlace: Bool { true }

    // NSDocument saves only to the exact types in Info.plist, and offers to duplicate any
    // other file, such as a Makefile (public.make-source). Every file here is text, so it
    // can always save as the type it was opened as.
    override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
        let types = super.writableTypes(for: saveOperation)
        guard let fileType, !types.contains(fileType) else { return types }
        return [fileType] + types
    }

    // NSDocument otherwise adds the type's usual extension, so a Makefile saves as
    // Makefile.make, which the sandbox refuses because only the opened file is writable.
    override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        if let fileURL, typeName == fileType {
            return fileURL.pathExtension
        }
        return super.fileNameExtension(forType: typeName, saveOperation: saveOperation)
    }

    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        let hostingView = NSHostingView(rootView: DocumentView(document: self))
        hostingView.sizingOptions = [.minSize]
        window.contentView = hostingView
        window.center()
        addWindowController(NSWindowController(window: window))
    }

    override func read(from data: Data, ofType typeName: String) throws {
        text = Self.decode(data)
    }

    override func data(ofType typeName: String) throws -> Data {
        Data(text.utf8)
    }

    /// UTF-8 first, then Foundation's encoding detection, then lossy UTF-8.
    private static func decode(_ data: Data) -> String {
        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        var converted: NSString?
        let encoding = NSString.stringEncoding(
            for: data, encodingOptions: nil, convertedString: &converted, usedLossyConversion: nil
        )
        if encoding != 0, let converted {
            return converted as String
        }
        return String(decoding: data, as: UTF8.self)
    }
}
