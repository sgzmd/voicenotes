APP_NAME = VoiceNotesApp
SRC = Sources/main.swift Sources/AppDelegate.swift
ICON = Assets/Microphone.png
PLIST = Plist/Info.plist

APP_BUNDLE = Build/$(APP_NAME).app
MACOS_DIR = $(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources

.PHONY: all clean run

all: $(MACOS_DIR)/$(APP_NAME)

$(MACOS_DIR)/$(APP_NAME): $(SRC) $(PLIST) $(ICON)
	@echo "Building app bundle..."
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	cp $(PLIST) $(APP_BUNDLE)/Contents/Info.plist
	cp $(ICON) $(RESOURCES_DIR)/Microphone.png
	swiftc -o $(MACOS_DIR)/$(APP_NAME) \
		-framework Cocoa -framework AVFoundation $(SRC)

run: all
	open $(APP_BUNDLE)

clean:
	rm -rf Build