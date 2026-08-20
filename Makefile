APP_NAME := CursorHighlighting
PROJECT := CursorHighlighting.xcodeproj
SCHEME := CursorHighlighting
DERIVED_DATA := build/DerivedData
DEBUG_PRODUCT := $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app
RELEASE_PRODUCT := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app
APP_BUNDLE := build/$(APP_NAME).app
ARCHIVE_PATH := build/$(APP_NAME).xcarchive
DEVELOPMENT_TEAM ?=
CODE_SIGN_IDENTITY ?=-
NOTARY_PROFILE ?=

.PHONY: project run app archive notarize build-debug build-release swift-build test verify clean

project:
	xcodegen generate

run: build-debug
	/usr/bin/open -n $(DEBUG_PRODUCT)

build-debug:
	xcodebuild -quiet -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-destination 'generic/platform=macOS' -derivedDataPath $(DERIVED_DATA) build

build-release:
	xcodebuild -quiet -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-destination 'generic/platform=macOS' -derivedDataPath $(DERIVED_DATA) build

swift-build:
	swift build

test:
	swift test

app: build-release
	rm -rf $(APP_BUNDLE)
	/usr/bin/ditto $(RELEASE_PRODUCT) $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

verify: app
	plutil -lint $(APP_BUNDLE)/Contents/Info.plist
	codesign --verify --deep --strict --verbose=4 $(APP_BUNDLE)
	@test "$$(find $(APP_BUNDLE) -mindepth 1 -maxdepth 1 -print)" = "$(APP_BUNDLE)/Contents"

archive:
	@test -n "$(DEVELOPMENT_TEAM)" || (echo "DEVELOPMENT_TEAM is required" && exit 1)
	@test "$(CODE_SIGN_IDENTITY)" != "-" || (echo "A Developer ID Application identity is required" && exit 1)
	xcodebuild -quiet archive -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-destination 'generic/platform=macOS' -archivePath $(ARCHIVE_PATH) \
		DEVELOPMENT_TEAM="$(DEVELOPMENT_TEAM)" \
		CODE_SIGN_IDENTITY="$(CODE_SIGN_IDENTITY)"

notarize: archive
	@test -n "$(NOTARY_PROFILE)" || (echo "NOTARY_PROFILE is required" && exit 1)
	/usr/bin/ditto -c -k --keepParent \
		$(ARCHIVE_PATH)/Products/Applications/$(APP_NAME).app build/$(APP_NAME).zip
	xcrun notarytool submit build/$(APP_NAME).zip --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple $(ARCHIVE_PATH)/Products/Applications/$(APP_NAME).app
	xcrun stapler validate $(ARCHIVE_PATH)/Products/Applications/$(APP_NAME).app

clean:
	swift package clean
	rm -rf build/
