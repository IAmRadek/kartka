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
        }
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
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
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
