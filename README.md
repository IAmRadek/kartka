# Kartka

Kartka is a minimal plain text editor for macOS. Each document opens in its own window. The app has no tabs, no rich text, and no formatting.

Kartka uses an AppKit `NSDocument` subclass for open, save, autosave, and recent files. Kartka saves every file as the type that it opened. The editor is an AppKit `NSTextView` in a SwiftUI view.

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

The command builds a Release copy and puts `Kartka.app` in `~/Applications`. It also links `~/.local/bin/kartka` to the `kartka` script inside the app. To use other folders, set `APP_DIR` or `BIN_DIR`, for example `make install BIN_DIR=/usr/local/bin`.

Release builds use the "Developer ID Application" certificate of team `JYDM4GTWRT`. Without that certificate in your keychain, use the Debug build.

## Release

A release is a notarized zip of `Kartka.app`. Notarization is a check by Apple that lets macOS open the app without a warning.

Before the first release, save the notarization credentials in your keychain:

```sh
xcrun notarytool store-credentials kartka-notary --apple-id <Apple ID> --team-id JYDM4GTWRT
```

To make a release, do these steps:

1. Set `MARKETING_VERSION` in `project.yml`.
2. Run `make release`.
3. Upload `build/Kartka-<version>.zip` to a GitHub release.

The command prints the SHA-256 hash of the zip. The hash goes into the Nix package.

### Release from GitHub Actions

The workflow `.github/workflows/release.yml` does the same steps on a GitHub macOS runner. If you push a tag such as `v0.1.0`, the workflow starts. The tag must match `MARKETING_VERSION`.

The workflow needs these repository secrets:

- `DEVELOPER_ID_P12`: the Developer ID certificate and its private key, as a base64 `.p12` file
- `DEVELOPER_ID_P12_PASSWORD`: the password of the `.p12` file
- `NOTARY_APPLE_ID`: your Apple ID
- `NOTARY_PASSWORD`: the app-specific password for notarization

## Use as $EDITOR

The `kartka` script opens files in a new Kartka process, then waits for that process to stop. When you close the last window of a Kartka process, that process quits. If you stop the script with Ctrl-C or close its terminal, the script quits its Kartka process. Kartka saves open documents before it quits.

If `~/.local/bin` is in your `PATH`, add this line to your shell profile:

```sh
export EDITOR=kartka
```

If a file does not exist, the script creates it as an empty file, because `open` cannot open a missing path.

The script opens the app that contains it. If you start the script through a symlink, it opens the same app. A copy of the script outside an app opens `~/Applications/Kartka.app`. To open a different copy, set `KARTKA_APP` to the full path of `Kartka.app`.
