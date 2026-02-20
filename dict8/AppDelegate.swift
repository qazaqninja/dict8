import Cocoa
import AVFoundation
import Speech

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var hotkeyManager: HotkeyManager!
    private var speechRecognizer: SpeechRecognizer!
    private var textPaster: TextPaster!
    private var permissionManager: PermissionManager!
    private var isRecording = false
    private var hotkeyDownTime: Date?
    private let debounceInterval: TimeInterval = 0.15

    func applicationDidFinishLaunching(_ notification: Notification) {
        permissionManager = PermissionManager()
        textPaster = TextPaster()
        speechRecognizer = SpeechRecognizer()
        statusBarController = StatusBarController()

        statusBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }

        checkPermissionsAndStart()
    }

    private func checkPermissionsAndStart() {
        permissionManager.requestAllPermissions { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.statusBarController.updatePermissionStatus(status)

                if status.allGranted {
                    self.startHotkeyListener()
                } else {
                    self.showPermissionAlert(status)
                }
            }
        }
    }

    private func startHotkeyListener() {
        hotkeyManager = HotkeyManager()
        hotkeyManager.onHotkeyDown = { [weak self] in
            self?.handleHotkeyDown()
        }
        hotkeyManager.onHotkeyUp = { [weak self] in
            self?.handleHotkeyUp()
        }
        hotkeyManager.start()
    }

    private func handleHotkeyDown() {
        guard !isRecording else { return }
        hotkeyDownTime = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval) { [weak self] in
            guard let self = self,
                  let downTime = self.hotkeyDownTime,
                  Date().timeIntervalSince(downTime) >= self.debounceInterval,
                  !self.isRecording else { return }

            self.isRecording = true
            self.statusBarController.setRecording(true)
            self.speechRecognizer.startRecording { partialResult in
                // Optional: update menu bar with partial result
            }
        }
    }

    private func handleHotkeyUp() {
        hotkeyDownTime = nil
        guard isRecording else { return }
        isRecording = false
        statusBarController.setRecording(false)

        speechRecognizer.stopRecording { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let text):
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        self.textPaster.paste(trimmed)
                    }
                case .failure(let error):
                    print("Speech recognition error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showPermissionAlert(_ status: PermissionStatus) {
        let alert = NSAlert()
        alert.messageText = "dict8 Needs Permissions"
        alert.alertStyle = .warning

        var missing: [String] = []
        if !status.microphone { missing.append("Microphone") }
        if !status.speechRecognition { missing.append("Speech Recognition") }
        if !status.accessibility { missing.append("Accessibility") }

        alert.informativeText = """
        The following permissions are required:
        \(missing.map { "  - \($0)" }.joined(separator: "\n"))

        Please grant these in System Settings > Privacy & Security.
        """

        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                NSWorkspace.shared.open(url)
            }
        case .alertSecondButtonReturn:
            checkPermissionsAndStart()
        default:
            NSApplication.shared.terminate(nil)
        }
    }
}
