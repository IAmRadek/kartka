APP_DIR ?= $(HOME)/Applications
BIN_DIR ?= $(HOME)/.local/bin
NOTARY_PROFILE ?= kartka-notary
VERSION := $(shell sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)

APP := build/Build/Products/Release/Kartka.app
ARCHIVE := build/Kartka.xcarchive
EXPORT := build/export
ZIP := build/Kartka-$(VERSION).zip

.PHONY: project build install export release clean

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
	xcodebuild -scheme Kartka -configuration Release -derivedDataPath build -archivePath "$(ARCHIVE)" archive
	xcodebuild -exportArchive -archivePath "$(ARCHIVE)" -exportPath "$(EXPORT)" -exportOptionsPlist ExportOptions.plist

# Uploads the app to Apple for notarization, then staples the ticket so the app
# opens offline. The zip is zipped again after stapling, so it holds the ticket.
release: export
	ditto -c -k --keepParent "$(EXPORT)/Kartka.app" "$(ZIP)"
	xcrun notarytool submit "$(ZIP)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(EXPORT)/Kartka.app"
	ditto -c -k --keepParent "$(EXPORT)/Kartka.app" "$(ZIP)"
	shasum -a 256 "$(ZIP)"

clean:
	rm -rf build Kartka.xcodeproj
