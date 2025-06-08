import AVFoundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recorder: AVAudioRecorder?
    var isRecording = false
    var eventTap: CFMachPort?

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

        startEventTap()
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

    @MainActor func startEventTap() {
        print("Installing global event tap")
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { (_, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                print("Key event received. Keycode: \(keycode), flags: \(flags.rawValue)")

                let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()

                let isCmdShift = flags.contains(.maskCommand) && flags.contains(.maskShift)

                // F2 key = keycode 120
                if keycode == 120 && isCmdShift && type == .keyDown {
                    Task { @MainActor in
                        delegate.toggleRecordingFromHotkey()
                    }
                    // Prevent key event from propagating if you want (optional)
                    return nil
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        guard let eventTap = eventTap else {
            print("Failed to create event tap.")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("Global event tap installed successfully.")
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
