import AppKit
import SwiftUI

@MainActor
final class EditorModel: ObservableObject {
    static weak var activeModel: EditorModel?

    weak var textView: StrikeTextView?
    private var currentFileURL: URL?
    private var isEdited = false
    private var windowObserver: NSObjectProtocol?
    private var pendingURL: URL?

    init(documentURL: URL? = nil) {
        pendingURL = documentURL
    }

    func attach(_ textView: StrikeTextView) {
        self.textView = textView
        if let pendingURL {
            self.pendingURL = nil
            loadDocument(at: pendingURL)
        } else {
            refreshTitle()
        }

        DispatchQueue.main.async { [weak self, weak textView] in
            guard let self, let textView, let window = textView.window else { return }
            window.makeFirstResponder(textView)
            self.observeActivation(of: window)
            Self.activeModel = self
            self.refreshTitle()
        }
    }

    func newDocument() {
        Self.showWindow()
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsOtherFileTypes = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            Self.showWindow(for: url)
        }
    }

    private func loadDocument(at url: URL) {
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: editorFont,
                .foregroundColor: editorTextColor
            ]
            textView?.textStorage?.setAttributedString(NSAttributedString(string: contents, attributes: attributes))
            textView?.font = editorFont
            textView?.typingAttributes = attributes
            textView?.setSelectedRange(NSRange(location: 0, length: 0))
            currentFileURL = url
            isEdited = false
            refreshTitle()
        } catch {
            showError("Could not open the document", error: error)
        }
    }

    private static func showWindow(for url: URL? = nil) {
        let model = EditorModel(documentURL: url)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 480, height: 420)
        window.center()
        window.contentViewController = NSHostingController(rootView: EditorWindow(model: model))
        window.makeKeyAndOrderFront(nil)
    }

    private func observeActivation(of window: NSWindow) {
        if let windowObserver {
            NotificationCenter.default.removeObserver(windowObserver)
        }
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                Self.activeModel = self
            }
        }
    }

    func saveDocument(saveAs: Bool = false) {
        guard let textView else { return }
        if saveAs || currentFileURL == nil {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = currentFileURL?.lastPathComponent ?? "Untitled.txt"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            currentFileURL = url
        }

        guard let url = currentFileURL else { return }
        do {
            try plainTextWithoutStrikes(from: textView.attributedString()).write(to: url, atomically: true, encoding: .utf8)
            isEdited = false
            refreshTitle()
        } catch {
            showError("Could not save the document", error: error)
        }
    }

    func refreshTitle(markEdited: Bool = false) {
        if markEdited {
            isEdited = true
        }
        let baseName = currentFileURL?.lastPathComponent ?? "Untitled"
        let wordCount = wordCount(in: textView?.string ?? "")
        let editMarker = isEdited ? " — Edited" : ""
        textView?.window?.title = "\(baseName) — \(wordCount) words\(editMarker)"
        textView?.window?.isDocumentEdited = isEdited
    }

    private var editorFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    }

    private var editorTextColor: NSColor {
        NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.13, alpha: 1)
    }

    private func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private func plainTextWithoutStrikes(from contents: NSAttributedString) -> String {
        let fullRange = NSRange(location: 0, length: contents.length)
        var result = ""
        contents.enumerateAttribute(.strikethroughStyle, in: fullRange) { value, range, _ in
            let style = (value as? NSNumber)?.intValue ?? 0
            if style == 0 {
                result += contents.attributedSubstring(from: range).string
            }
        }
        return result
    }

    private func showError(_ message: String, error: Error) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

final class StrikeTextView: NSTextView {
    func strikeSelection() {
        let range = selectedRange()
        guard range.location != NSNotFound, range.length > 0 else { return }
        textStorage?.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        setSelectedRange(NSRange(location: NSMaxRange(range), length: 0))
        scrollRangeToVisible(selectedRange())
    }

    override func deleteBackward(_ sender: Any?) {
        strikeSelection()
    }

    override func deleteForward(_ sender: Any?) {
        strikeSelection()
    }

    override func cut(_ sender: Any?) {
        // Stroke never removes text. Use Delete/Backspace to mark a selection instead.
        strikeSelection()
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        let range = replacementRange.location == NSNotFound ? selectedRange() : replacementRange
        if range.location != NSNotFound, range.length > 0 {
            textStorage?.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            let insertionPoint = NSMaxRange(range)
            setSelectedRange(NSRange(location: insertionPoint, length: 0))
            var attributes = typingAttributes
            attributes.removeValue(forKey: .strikethroughStyle)
            typingAttributes = attributes
            super.insertText(insertString, replacementRange: NSRange(location: insertionPoint, length: 0))
        } else {
            super.insertText(insertString, replacementRange: replacementRange)
        }
    }
}

struct NativeEditor: NSViewRepresentable {
    @ObservedObject var model: EditorModel

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let textView = StrikeTextView()
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textColor = NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 42, height: 38)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        scrollView.documentView = textView
        model.attach(textView)

        NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { [weak model] _ in
            Task { @MainActor in
                model?.refreshTitle(markEdited: true)
            }
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let textView = scrollView.documentView as? StrikeTextView {
            model.textView = textView
        }
    }
}

struct EditorWindow: View {
    @ObservedObject var model: EditorModel

    var body: some View {
        NativeEditor(model: model)
            .frame(minWidth: 480, minHeight: 420)
            .background(Color.white)
    }
}

@main
struct StrokeApp: App {
    var body: some Scene {
        WindowGroup("Stroke") {
            EditorWindow(model: EditorModel())
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") { EditorModel.activeModel?.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Open…") { EditorModel.activeModel?.openDocument() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { EditorModel.activeModel?.saveDocument() }
                    .keyboardShortcut("s", modifiers: .command)
                Button("Save As…") { EditorModel.activeModel?.saveDocument(saveAs: true) }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
