// Sources/main.swift
import Cocoa

let bundleID = Bundle.main.bundleIdentifier!
let runningInstances = 
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID);

if runningInstances.count > 1 {
    NSLog("Another instance is already running. Exiting.")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.prohibited)  // hide dock icon
app.run()