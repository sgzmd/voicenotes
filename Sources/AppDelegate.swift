import AVFoundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recorder: AVAudioRecorder?
    var isRecording = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        statusItem.button?.action = #selector(toggleRecord(_:))
        statusItem.button?.target = self

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Record", action: #selector(toggleRecord), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @MainActor func updateIcon() {
        if #available(macOS 11.0, *) {
            let symbolName = isRecording ? "stop.circle.fill" : "mic.fill"
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            image?.isTemplate = true
            statusItem.button?.image = image
        }
    }

    @MainActor @objc func toggleRecord(_ sender: NSMenuItem) {
        if isRecording {
            recorder?.stop()
            sender.title = "Record"            
            isRecording = false
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
                    NSLog("Average power: \(self.recorder?.averagePower(forChannel: 0) ?? -999)")
                }
            }
            recorder?.record()

            sender.title = "Stop Recording"
            isRecording = true
        }

        updateIcon()
    }

    @MainActor @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
