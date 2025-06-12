import AVFoundation
import Cocoa
import WhisperKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recorder: AVAudioRecorder?
    var isRecording = false
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
            let symbolName = isRecording ? "stop.circle.fill" : "mic.fill"
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            image?.isTemplate = true
            statusItem.button?.image = image
        }
    }

    @MainActor @objc func toggleRecord(_ sender: Any?) {
        if isRecording {
            recorder?.stop()
            isRecording = false
            hideSpectrumWindow()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {                
                if let url = self.recorder?.url {
                    Task {
                        do {
                            let whisper = try await WhisperKit(WhisperKitConfig(model: "tiny"))
                            let result = try await whisper.transcribe(
                                audioPath: url.path() ?? "")
                            let fullText = result.flatMap { $0.segments }.map { $0.text }.joined()
                            NSLog("Transcript: \(fullText)")
                        } catch {
                            NSLog("Transcription error: \(error)")
                        }
                    }
                }
            }

        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let folder = docs.appendingPathComponent("VoiceNotes")
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

            let timestamp = Int(Date().timeIntervalSince1970)
            let fileURL = folder.appendingPathComponent("voice-note-\(timestamp).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]

            recorder = try? AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.prepareToRecord()
            recorder?.isMeteringEnabled = true
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    self.recorder?.updateMeters()
                }
            }
            recorder?.record()
            isRecording = true
            showSpectrumWindow()
        }

        updateIcon()
        updateMenuTitle()
    }

    @MainActor func updateMenuTitle() {
        guard let menu = statusItem.menu else { return }
        menu.items.first?.title = isRecording ? "Stop Recording" : "Record"
    }

    @MainActor func toggleRecordingFromHotkey() {
        print("Hotkey: toggle recording")
        toggleRecord(
            NSMenuItem(
                title: isRecording ? "Stop Recording" : "Record",
                action: #selector(toggleRecord),
                keyEquivalent: "r")
        )
    }
    @MainActor @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
