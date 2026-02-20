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

    func requestAllPermissions(completion: @escaping (PermissionStatus) -> Void) {
        var status = PermissionStatus()
        let group = DispatchGroup()

        // Microphone
        group.enter()
        requestMicrophoneAccess { granted in
            status.microphone = granted
            group.leave()
        }

        // Speech Recognition
        group.enter()
        requestSpeechRecognition { granted in
            status.speechRecognition = granted
            group.leave()
        }

        // Accessibility (synchronous check)
        status.accessibility = checkAccessibility()

        group.notify(queue: .main) {
            completion(status)
        }
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

    private func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
