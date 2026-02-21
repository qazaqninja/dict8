# dict8

Local offline speech-to-text for macOS. Lives in the menu bar, transcribes with a global hotkey, and pastes text directly into any app. Fully on-device — no internet, no API keys, no data leaves your Mac.

## Install

### Homebrew (recommended)

```bash
brew install --cask qazaqninja/dict8/dict8
```

### curl

```bash
curl -fsSL https://raw.githubusercontent.com/qazaqninja/dict8/main/install.sh | bash
```

### Manual

1. Download `dict8-macos.zip` from the [latest release](https://github.com/qazaqninja/dict8/releases/latest)
2. Extract and move `dict8.app` to `/Applications`
3. Clear Gatekeeper quarantine:
   ```bash
   xattr -cr /Applications/dict8.app
   ```

## Permissions

On first launch, grant these in **System Settings > Privacy & Security**:

| Permission | Why |
|---|---|
| **Accessibility** | Global hotkey capture and text pasting |
| **Microphone** | Speech capture |
| **Speech Recognition** | On-device transcription |

## Usage

- Launch dict8 — a microphone icon appears in the menu bar
- Press **Ctrl+Space** to start dictation
- Speak — press **Ctrl+Space** again to stop
- Transcribed text is pasted into the active app

## Requirements

- macOS 13.0 (Ventura) or later
