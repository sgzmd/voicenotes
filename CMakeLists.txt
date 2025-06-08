cmake_minimum_required(VERSION 3.22)
project(VoiceNotesApp LANGUAGES Swift)

set(APP_NAME VoiceNotesApp)
set(SOURCES
    Sources/main.swift
    Sources/AppDelegate.swift
)

# Output bundle path
set(BUNDLE_DIR ${CMAKE_BINARY_DIR}/${APP_NAME}.app)
set(MACOS_DIR ${BUNDLE_DIR}/Contents/MacOS)
set(RESOURCES_DIR ${BUNDLE_DIR}/Contents/Resources)

# Define executable target
add_executable(${APP_NAME} ${SOURCES})

# Set macOS app properties
set_target_properties(${APP_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME}
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Plist/Info.plist
    RESOURCE "${CMAKE_SOURCE_DIR}/Assets/Microphone.png"
)

# Copy resource manually if RESOURCE doesn't work
add_custom_command(TARGET ${APP_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${RESOURCES_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/Assets/Microphone.png" "${RESOURCES_DIR}/Microphone.png"
)

# Run target
add_custom_target(run
    COMMAND open "${BUNDLE_DIR}"
    DEPENDS ${APP_NAME}
)