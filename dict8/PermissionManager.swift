import Cocoa
import AVFoundation
import Speech

struct PermissionStatus {
    var microphone: Bool = false
    var speechRecognition: Bool = false
    var accessibility: Bool = false

    var allGranted: Bool {
        microphone && speechRecognition && accessibility
    }
}

class PermissionManager {
    var onStatusChanged: ((PermissionStatus) -> Void)?

    private var pollingTimer: Timer?
    private var lastStatus = PermissionStatus()

    /// Returns the current permission status without triggering any prompts.
    func checkCurrentStatus() -> PermissionStatus {
        var status = PermissionStatus()
        status.microphone = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        status.speechRecognition = SFSpeechRecognizer.authorizationStatus() == .authorized
        status.accessibility = AXIsProcessTrusted()
        return status
    }

    /// Triggers system permission dialogs sequentially: Mic → Speech → Accessibility.
    func requestAllPermissions() {
        requestMicrophoneAccess { [weak self] _ in
            self?.requestSpeechRecognition { [weak self] _ in
                DispatchQueue.main.async {
                    self?.promptAccessibility()
                }
            }
        }
    }

    /// Starts a 2-second polling timer that fires `onStatusChanged` when any permission changes.
    func startMonitoring() {
        lastStatus = checkCurrentStatus()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let current = self.checkCurrentStatus()
            if current.microphone != self.lastStatus.microphone ||
               current.speechRecognition != self.lastStatus.speechRecognition ||
               current.accessibility != self.lastStatus.accessibility {
                self.lastStatus = current
                self.onStatusChanged?(current)
            }
        }
    }

    /// Stops the polling timer.
    func stopMonitoring() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }

    private func requestSpeechRecognition(completion: @escaping (Bool) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            completion(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                completion(authStatus == .authorized)
            }
        default:
            completion(false)
        }
    }

    private func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
