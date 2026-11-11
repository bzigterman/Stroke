# Stroke

Stroke is a text editor for first drafts. The desktop app now uses Electron instead of the discontinued NW.js runtime, so it can be built and run on current macOS releases (including Apple silicon and Intel Macs).

## Run from source

Install a current Node.js LTS release, then from the repository root run:

```sh
npm install
npm start
```

## Build the macOS app

Run this on macOS with Xcode Command Line Tools installed:

```sh
npm install
npm run dist:mac
```

The build produces a universal macOS app in both `.dmg` and `.zip` formats under `release/`, supporting Apple silicon and Intel Macs. Electron and electron-builder are resolved to their latest npm releases when installing. Unsigned builds may require opening the app via Finder's Open command; distribution outside personal use should be signed and notarized with an Apple Developer ID.

The old browser-based public demo is separate from the desktop app. The desktop build loads its local files and does not depend on the legacy hosted app or application cache.
