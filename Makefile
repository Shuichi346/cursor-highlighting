APP_NAME = CursorHighlighting
BUILD_DIR = .build/release
APP_BUNDLE = build/$(APP_NAME).app

.PHONY: run app build-release clean

run:
	swift run $(APP_NAME)

build-release:
	swift build -c release

app: build-release
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/
	cp Resources/icon/icon.icns $(APP_BUNDLE)/Contents/Resources/
	@find -L $(BUILD_DIR) -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} $(APP_BUNDLE)/ \;
	@echo "✅ Built $(APP_BUNDLE)"

clean:
	swift package clean
	rm -rf build/
