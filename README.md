# Stroke

Stroke is a simple native macOS fork of [David Merfield's](https://github.com/davidmerfield/Stroke) first-draft text editor, built with SwiftUI and AppKit. It never deletes text: selecting text and pressing Backspace or Delete marks it with strikethrough. Saving writes plain UTF-8 text with struck-through passages omitted.

## Build and run

Requires macOS 13 or later and Xcode or the Xcode Command Line Tools with Swift installed. From the repository root:

```sh
./native-macos/build-app.sh
open release/Stroke.app
```

The build targets the architecture of the Mac running it. On Apple silicon, the app runs natively. Drag `release/Stroke.app` into Applications to install it.

## Editor behavior

- Type and select text in a simple native editor.
- Backspace or Delete with a selection strikes that text through; with no selection, they do nothing.
- Typing or pasting over selected text strikes the old text and inserts the new text after it.
- Cut does not remove text.
- New, Open, Save, and Save As are available from the macOS File menu.
- The title bar shows a live word count.
- Documents are saved as plain UTF-8 text with struck-through passages omitted.

The Swift package and app bundling script are in `native-macos/`.
