APP_NAME = CursorHighlighting
BUILD_DIR = .build/release
APP_BUNDLE = build/$(APP_NAME).app
RESOURCE_BUNDLE = $(BUILD_DIR)/CursorHighlighting_CursorHighlighting.bundle

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
	cp Sources/$(APP_NAME)/Resources/Info.plist $(APP_BUNDLE)/Contents/
	@if [ -d "$(RESOURCE_BUNDLE)" ]; then \
		cp -r $(RESOURCE_BUNDLE) $(APP_BUNDLE)/Contents/Resources/; \
	fi
	@echo "✅ Built $(APP_BUNDLE)"

clean:
	swift package clean
	rm -rf build/
