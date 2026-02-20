import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var permissionMenuItem: NSMenuItem?

    var onQuit: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setupIcon()
        setupMenu()
    }

    private func setupIcon() {
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "dict8")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "dict8 — Hold Right Option to dictate"
        }
    }

    private func setupMenu() {
        menu = NSMenu()

        let aboutItem = NSMenuItem(title: "About dict8", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        permissionMenuItem = NSMenuItem(title: "Permissions: Checking...", action: nil, keyEquivalent: "")
        permissionMenuItem?.isEnabled = false
        menu.addItem(permissionMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit dict8", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func setRecording(_ recording: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let button = self?.statusItem.button else { return }
            if recording {
                let image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Recording")
                image?.isTemplate = false
                button.image = image
                button.contentTintColor = .systemRed
                button.toolTip = "Listening..."
            } else {
                let image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "dict8")
                image?.isTemplate = true
                button.image = image
                button.contentTintColor = nil
                button.toolTip = "dict8 — Hold Right Option to dictate"
            }
        }
    }

    func updatePermissionStatus(_ status: PermissionStatus) {
        if status.allGranted {
            permissionMenuItem?.title = "Permissions: All Granted"
        } else {
            var missing: [String] = []
            if !status.microphone { missing.append("Mic") }
            if !status.speechRecognition { missing.append("Speech") }
            if !status.accessibility { missing.append("Accessibility") }
            permissionMenuItem?.title = "Missing: \(missing.joined(separator: ", "))"
        }
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "dict8"
        alert.informativeText = "Local speech-to-text for macOS.\nHold Right Option to dictate.\n\nAll recognition happens on-device."
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func quitApp() {
        onQuit?()
    }
}
