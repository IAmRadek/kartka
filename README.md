# Kartka

Kartka is a minimal plain text editor for macOS. Each document opens in its own window. The app has no tabs, no rich text, and no formatting.

Kartka uses SwiftUI `DocumentGroup` for open, save, autosave, and recent files. The editor is an AppKit `NSTextView`.

## Requirements

- macOS 14 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Generate the project

The file `project.yml` is the source of truth. Git ignores `Kartka.xcodeproj`, `Info.plist`, and the entitlements file, because XcodeGen generates them.

If you change `project.yml` or add a source file, run this command again:

```sh
xcodegen generate
```

## Build and run

1. Generate the project.
2. Build the app:

   ```sh
   xcodebuild -scheme Kartka -configuration Debug -derivedDataPath build build
   ```

3. Open the app:

   ```sh
   open build/Build/Products/Debug/Kartka.app
   ```

You can also open `Kartka.xcodeproj` in Xcode and press ⌘R. The app uses an ad-hoc signature ("Sign to Run Locally"), so you do not need a developer account.

## Install

Run this command:

```sh
make install
```

The command builds a Release copy and puts `Kartka.app` in `~/Applications`. It also puts the `kartka` script in `~/.local/bin`. To use other folders, set `APP_DIR` or `BIN_DIR`, for example `make install BIN_DIR=/usr/local/bin`.

## Use as $EDITOR

The `kartka` script opens files in a new Kartka process, then waits for that process to stop. When you close the last window of a Kartka process, that process quits.

If `~/.local/bin` is in your `PATH`, add this line to your shell profile:

```sh
export EDITOR=kartka
```

If a file does not exist, the script creates it as an empty file, because `open` cannot open a missing path.

The script opens `~/Applications/Kartka.app`. If you installed the app in a different folder, set `KARTKA_APP` to the full path of `Kartka.app`.
