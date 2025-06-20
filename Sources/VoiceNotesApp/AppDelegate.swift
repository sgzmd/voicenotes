import AVFoundation
import Cocoa
import WhisperKit

class AppDelegate: NSObject, NSApplicationDelegate, AudioRecorderDelegate {
    var statusItem: NSStatusItem!
    var audioRecorder = AudioRecorder()
    var globalHotkeyListener: GlobalHotkeyListener? // Added

    var promptWindowController: PromptWindowController?

    @MainActor func showSpectrumWindow() {
        promptWindowController = PromptWindowController()
    }

    @MainActor func hideSpectrumWindow() {
        promptWindowController?.close()
        promptWindowController = nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        audioRecorder.delegate = self
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        statusItem.button?.action = #selector(toggleRecord)
        statusItem.button?.target = self

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Record", action: #selector(toggleRecord), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu

        // Use GlobalHotkeyListener instead of startEventTap
        globalHotkeyListener = GlobalHotkeyListener { [weak self] in
            Task { @MainActor in
                self?.toggleRecordingFromHotkey()
            }
        }
    }

    @MainActor func updateIcon() {
        if #available(macOS 11.0, *) {
            let symbolName = audioRecorder.isRecording ? "stop.circle.fill" : "mic.fill"
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            image?.isTemplate = true
            statusItem.button?.image = image
        }
    }

    @MainActor @objc func toggleRecord(_ sender: Any?) {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
        } else {
            do {
                try audioRecorder.startRecording()
            } catch {
                NSLog("Failed to start recording: \(error)")
            }
        }
    }

    @MainActor func updateMenuTitle() {
        guard let menu = statusItem.menu else { return }
        menu.items.first?.title = audioRecorder.isRecording ? "Stop Recording" : "Record"
    }

    @MainActor func toggleRecordingFromHotkey() {
        print("Hotkey: toggle recording")
        toggleRecord(
            NSMenuItem(
                title: audioRecorder.isRecording ? "Stop Recording" : "Record",
                action: #selector(toggleRecord),
                keyEquivalent: "r")
        )
    }
    
    // MARK: - AudioRecorderDelegate
    
    func audioRecorderDidStartRecording() {
        Task { @MainActor in
            updateIcon()
            updateMenuTitle()
            showSpectrumWindow()
        }
    }
    
    func audioRecorderDidStopRecording() {
        Task { @MainActor in
            updateIcon()
            updateMenuTitle()
            hideSpectrumWindow()
        }
    }
    
    func audioRecorderDidFinishTranscription(_ text: String, audioURL: URL) {
        print("Transcription finished: \(text)")
        // TODO: Handle the transcribed text and audio URL, e.g., save to a file, display in UI
    }
    
    func audioRecorderDidFailWithError(_ error: Error) {
        NSLog("Recording error: \(error)")
    }

    @MainActor @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
