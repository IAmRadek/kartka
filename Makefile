APP_DIR ?= $(HOME)/Applications
BIN_DIR ?= $(HOME)/.local/bin
APP := build/Build/Products/Release/Kartka.app

.PHONY: project build install clean

project:
	xcodegen generate

build: project
	xcodebuild -scheme Kartka -configuration Release -derivedDataPath build build

install: build
	mkdir -p "$(APP_DIR)" "$(BIN_DIR)"
	rm -rf "$(APP_DIR)/Kartka.app"
	cp -R "$(APP)" "$(APP_DIR)/"
	install -m 755 bin/kartka "$(BIN_DIR)/kartka"

clean:
	rm -rf build Kartka.xcodeproj
