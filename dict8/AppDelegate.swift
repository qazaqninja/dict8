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

        permissionManager.onStatusChanged = { [weak self] status in
            guard let self = self else { return }
            self.statusBarController.updatePermissionStatus(status)
            if status.allGranted {
                self.permissionManager.stopMonitoring()
                self.startHotkeyListener()
            }
        }

        // Trigger system permission dialogs sequentially
        permissionManager.requestAllPermissions()

        // Show current status and start polling for changes
        let initialStatus = permissionManager.checkCurrentStatus()
        statusBarController.updatePermissionStatus(initialStatus)

        if initialStatus.allGranted {
            startHotkeyListener()
        } else {
            permissionManager.startMonitoring()
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

}
