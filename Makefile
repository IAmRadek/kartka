APP_DIR ?= $(HOME)/Applications
BIN_DIR ?= $(HOME)/.local/bin
NOTARY_PROFILE ?= kartka-notary
# The release workflow sets VERSION from the git tag. Local builds use project.yml.
VERSION ?= $(shell sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)

APP := build/Build/Products/Release/Kartka.app
ARCHIVE := build/Kartka.xcarchive
EXPORT := build/export
ZIP := build/Kartka-$(VERSION).zip
ICONSET := Kartka/Assets.xcassets/AppIcon.appiconset

.PHONY: project build install export release icon clean

project:
	xcodegen generate

build: project
	xcodebuild -scheme Kartka -configuration Release -derivedDataPath build build

install: build
	mkdir -p "$(APP_DIR)" "$(BIN_DIR)"
	rm -rf "$(APP_DIR)/Kartka.app"
	cp -R "$(APP)" "$(APP_DIR)/"
	ln -sf "$(APP_DIR)/Kartka.app/Contents/Resources/kartka" "$(BIN_DIR)/kartka"

# Signed with Developer ID and a secure timestamp, which notarization requires.
export: project
	rm -rf "$(ARCHIVE)" "$(EXPORT)"
	xcodebuild -scheme Kartka -configuration Release -derivedDataPath build -archivePath "$(ARCHIVE)" \
		MARKETING_VERSION="$(VERSION)" archive
	xcodebuild -exportArchive -archivePath "$(ARCHIVE)" -exportPath "$(EXPORT)" -exportOptionsPlist ExportOptions.plist

# Uploads the app to Apple for notarization, then staples the ticket so the app
# opens offline. The zip is zipped again after stapling, so it holds the ticket.
release: export
	ditto -c -k --keepParent "$(EXPORT)/Kartka.app" "$(ZIP)"
	xcrun notarytool submit "$(ZIP)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(EXPORT)/Kartka.app"
	ditto -c -k --keepParent "$(EXPORT)/Kartka.app" "$(ZIP)"
	shasum -a 256 "$(ZIP)"

# Makes every macOS icon size from assets/icon.png. Run it after you change the icon.
icon:
	for size in 16 32 128 256 512; do \
		sips -z $$size $$size assets/icon.png --out "$(ICONSET)/icon_$$size.png" > /dev/null; \
		sips -z $$((size * 2)) $$((size * 2)) assets/icon.png --out "$(ICONSET)/icon_$$size@2x.png" > /dev/null; \
	done

clean:
	rm -rf build Kartka.xcodeproj
