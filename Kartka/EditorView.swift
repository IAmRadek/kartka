import AppKit
import SwiftUI

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var lineSpacing: CGFloat
    var wrapsLines: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        // Whitespace markers come from an NSLayoutManager subclass. Reading `layoutManager`
        // switches the view from TextKit 2 to TextKit 1, so it has one to replace.
        _ = textView.layoutManager
        textView.textContainer?.replaceLayoutManager(WhitespaceLayoutManager())

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 24, height: 20)
        textView.drawsBackground = false
        scrollView.drawsBackground = false
        textView.string = text

        apply(to: textView, in: scrollView, coordinator: context.coordinator)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        context.coordinator.text = $text

        // Only external changes (revert, reload) reach this branch. Typing already
        // matches, so the selection and undo stack stay untouched.
        if textView.string != text {
            textView.string = text
            context.coordinator.appliedStyle = nil
        }
        apply(to: textView, in: scrollView, coordinator: context.coordinator)
    }

    private func apply(to textView: NSTextView, in scrollView: NSScrollView, coordinator: Coordinator) {
        let style = Coordinator.Style(font: font, lineSpacing: lineSpacing)
        if coordinator.appliedStyle != style {
            coordinator.appliedStyle = style
            applyStyle(style, to: textView)
        }
        if coordinator.appliedWrap != wrapsLines {
            coordinator.appliedWrap = wrapsLines
            applyWrap(to: textView, in: scrollView)
        }
    }

    private func applyStyle(_ style: Coordinator.Style, to textView: NSTextView) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = style.lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .paragraphStyle: paragraph,
            .foregroundColor: NSColor.textColor,
        ]

        textView.font = style.font
        textView.defaultParagraphStyle = paragraph
        textView.typingAttributes = attributes

        // Plain-text views keep per-range attributes, so restyle existing text too.
        guard let storage = textView.textStorage else { return }
        storage.beginEditing()
        storage.setAttributes(attributes, range: NSRange(location: 0, length: storage.length))
        storage.endEditing()
    }

    private func applyWrap(to textView: NSTextView, in scrollView: NSScrollView) {
        guard let container = textView.textContainer else { return }
        let unlimited = CGFloat.greatestFiniteMagnitude

        scrollView.hasHorizontalScroller = !wrapsLines
        textView.isHorizontallyResizable = !wrapsLines
        textView.maxSize = NSSize(width: unlimited, height: unlimited)
        container.widthTracksTextView = wrapsLines

        if wrapsLines {
            // Width tracking only kicks in on the next resize, so size the view now.
            textView.autoresizingMask = [.width]
            textView.setFrameSize(NSSize(width: scrollView.contentSize.width, height: textView.frame.height))
        } else {
            textView.autoresizingMask = []
            container.containerSize = NSSize(width: unlimited, height: unlimited)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        struct Style: Equatable {
            var font: NSFont
            var lineSpacing: CGFloat
        }

        var text: Binding<String>
        var appliedStyle: Style?
        var appliedWrap: Bool?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            // The end-of-file marker sits below the last line, outside the area AppKit redraws.
            textView.needsDisplay = true
        }
    }
}

/// Draws faint markers over spaces and tabs, and "⊘" under the last line. After a final newline
/// the last line is the empty one, so an empty line above "⊘" means the file ends with a newline.
/// The text itself is unchanged.
final class WhitespaceLayoutManager: NSLayoutManager {
    private static let markers: [unichar: String] = [0x20: "·", 0x09: "→"]

    private enum Placement {
        case over, belowLastLine
    }

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage, textStorage.length > 0 else { return }

        let text = textStorage.string as NSString
        let characters = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        for index in characters.location..<NSMaxRange(characters) {
            if let marker = Self.markers[text.character(at: index)] {
                drawMarker(marker, atCharacter: index, origin: origin, placement: .over)
            }
        }

        let last = text.length - 1
        guard NSLocationInRange(last, characters) else { return }
        drawMarker("⊘", atCharacter: last, origin: origin, placement: .belowLastLine)
    }

    private func drawMarker(_ marker: String, atCharacter index: Int, origin: NSPoint, placement: Placement) {
        guard let textStorage, let container = textContainers.first else { return }

        let glyph = glyphIndexForCharacter(at: index)
        // Relative to the line fragment; y is the baseline.
        let position = location(forGlyphAt: glyph)
        let font = textStorage.attribute(.font, at: index, effectiveRange: nil) as? NSFont
            ?? .systemFont(ofSize: NSFont.systemFontSize)

        let line: NSRect
        let x: CGFloat
        switch placement {
        case .over:
            line = lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            x = line.minX + position.x
        case .belowLastLine:
            // The extra line fragment exists only after a final newline. It has no glyphs, only
            // this rect. Lines share one height, so `position.y` from the last glyph still applies.
            let lastLine = extraLineFragmentTextContainer == nil
                ? lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
                : extraLineFragmentRect
            line = lastLine.offsetBy(dx: 0, dy: lastLine.height)
            x = lastLine.minX + container.lineFragmentPadding
        }
        // The text view is flipped, so draw(at:) places the marker's top edge at y.
        let point = NSPoint(x: origin.x + x, y: origin.y + line.minY + position.y - font.ascender)
        marker.draw(at: point, withAttributes: [.font: font, .foregroundColor: NSColor.tertiaryLabelColor])
    }
}

/// Blurs the desktop behind the window, including under the title bar.
struct BlurredWindowBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = WindowBlurView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        // .followsWindowActiveState would turn the window opaque when it loses focus.
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}

    // SwiftUI exposes no NSWindow, so the view configures the window it lands in.
    private final class WindowBlurView: NSVisualEffectView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
        }
    }
}

/// Word, character and line count. Delete this view and its use in `DocumentView` to remove it.
struct CountFooter: View {
    let text: String

    var body: some View {
        let words = text.split(whereSeparator: \.isWhitespace).count
        // Counts newlines, like `wc -l`. "\r\n" is one Character, so it counts once.
        let lines = text.filter(\.isNewline).count
        VStack(spacing: 0) {
            Divider()
            Text("\(words) Words  ·  \(text.count) Characters  ·  \(lines) Lines")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
    }
}
