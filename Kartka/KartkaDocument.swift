import SwiftUI
import UniformTypeIdentifiers

struct KartkaDocument: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] {
        var types: [UTType] = [.plainText, .utf8PlainText, .json, .yaml, .sourceCode]
        if let markdown = UTType(filenameExtension: "md") {
            types.append(markdown)
        }
        // Files without an extension, such as git's COMMIT_EDITMSG, are only `.data`.
        types.append(.data)
        return types
    }

    // Every readable type is writable, so saving keeps a file's original type. `.plainText`
    // comes first, so it is the type of new documents.
    static var writableContentTypes: [UTType] { readableContentTypes }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = Self.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
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
