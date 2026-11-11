# Stroke

Stroke is a simple first-draft text editor. The native macOS app is built with SwiftUI and AppKit: it presents a plain text editor, never deletes selected text, and marks a selection with strikethrough when you press Backspace/Delete. Saving writes plain text with struck-through text omitted.

## Build and run the native macOS app

Requires macOS 13 or later and Xcode or the Xcode Command Line Tools with Swift installed. From the repository root:

```sh
chmod +x native-macos/build-app.sh
./native-macos/build-app.sh
open release/Stroke.app
```

The script builds for the architecture of the Mac running it. On Apple silicon, the resulting app is arm64 and runs natively without Rosetta. To install, drag `release/Stroke.app` into Applications.

## Editor behavior

- Type and select text as in a basic text editor.
- Backspace or Delete with a selection strikes that text through; with no selection, they do nothing.
- Typing or pasting over selected text strikes the old text and inserts the new text after it rather than replacing it.
- Cut does not remove text.
- Open, Save, Save As, and New are available in the macOS File menu with standard Command shortcuts.
- Documents are saved as plain UTF-8 text with struck-through passages left out.

## Electron version

The repository also retains the earlier Electron implementation and browser demo. The native SwiftUI/AppKit build above is the recommended macOS app.
