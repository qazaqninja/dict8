import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var micPermissionItem: NSMenuItem?
    private var speechPermissionItem: NSMenuItem?
    private var accessibilityPermissionItem: NSMenuItem?
    private var settingsItem: NSMenuItem?

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

        micPermissionItem = NSMenuItem(title: "  Microphone: Checking…", action: nil, keyEquivalent: "")
        micPermissionItem?.isEnabled = false
        menu.addItem(micPermissionItem!)

        speechPermissionItem = NSMenuItem(title: "  Speech Recognition: Checking…", action: nil, keyEquivalent: "")
        speechPermissionItem?.isEnabled = false
        menu.addItem(speechPermissionItem!)

        accessibilityPermissionItem = NSMenuItem(title: "  Accessibility: Checking…", action: nil, keyEquivalent: "")
        accessibilityPermissionItem?.isEnabled = false
        menu.addItem(accessibilityPermissionItem!)

        settingsItem = NSMenuItem(title: "Open System Settings…", action: #selector(openSystemSettings), keyEquivalent: "")
        settingsItem?.target = self
        menu.addItem(settingsItem!)

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
        micPermissionItem?.title = "  \(status.microphone ? "✓" : "✗") Microphone"
        speechPermissionItem?.title = "  \(status.speechRecognition ? "✓" : "✗") Speech Recognition"
        accessibilityPermissionItem?.title = "  \(status.accessibility ? "✓" : "✗") Accessibility"

        if status.allGranted {
            settingsItem?.isHidden = true
        } else {
            settingsItem?.isHidden = false
        }
    }

    @objc private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
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
