import AVFoundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recorder: AVAudioRecorder?
    var isRecording = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let iconPath = Bundle.main.path(forResource: "Microphone", ofType: "png")!
            button.image = NSImage(contentsOfFile: iconPath)
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Record", action: #selector(toggleRecord), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func toggleRecord(_ sender: NSMenuItem) {
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
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}