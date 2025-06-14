import Cocoa

class GlobalHotkeyListener {
    private var eventTap: CFMachPort?
    private var hotkeyHandler: (() -> Void)?

    init(hotkeyHandler: @escaping () -> Void) {
        self.hotkeyHandler = hotkeyHandler
        installEventTap()
    }

    private func installEventTap() {
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

                let listener = Unmanaged<GlobalHotkeyListener>.fromOpaque(refcon).takeUnretainedValue()
                let isCmdShift = flags.contains(.maskCommand) && flags.contains(.maskShift)

                // F2 key = keycode 120
                if keycode == 120 && isCmdShift && type == .keyDown {
                    DispatchQueue.main.async {
                        listener.hotkeyHandler?()
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
}
