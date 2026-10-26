# 🎙️ PushToTalk

🇬🇧 English | 🇷🇺 [Русский](README_RU.md)

> A macOS menu bar app: the microphone is on only while the hotkey is held down

## 📖 Description

PushToTalk turns the microphone off and turns it back on for as long as you hold the hotkey. It works globally, in every app that records audio from the input device it controls (Google Meet, Zoom, Teams, Discord and others): the app toggles mute on the device itself, not in an individual program.

![Animation of the app at work](https://user-images.githubusercontent.com/117752/96354725-0eabff00-10da-11eb-9539-6e159e7d588b.gif)

This is a fork of [yulrizka/osx-push-to-talk](https://github.com/yulrizka/osx-push-to-talk) with a native Apple Silicon build. The build is universal (arm64 + x86_64) and does not need Rosetta. This matters because from macOS 28 Rosetta will remain only for some older games, and Intel-only programs will not run there ([Apple](https://support.apple.com/en-us/102527)). The original does not build in Xcode 27: Xcode does not accept its deployment target 10.14. Some features were taken from forks and open pull requests of the original. The list is in the "Related projects" section.

What the app does:

- The hotkey (right ⌥ by default) turns the microphone on while it is held down and off again when it is released.
- A double press leaves the microphone on, and the next press turns it off.
- While other modifiers are held, the key is ignored, so combinations like ⌘⌥ do not turn the microphone on.
- While the microphone is off, mute is reapplied every 0.2 seconds (sticky mute): if another program resets the input device, the mute comes back.
- The app controls the default input device or the one you pinned in the menu. The choice is remembered, and the device list updates when devices are connected or disconnected.
- The menu shows the input volume (sensitivity) of the controlled device, with a slider to change it and a lock that restores it when another app changes it.
- The menu bar icon shows the state: microphone off, microphone on, app disabled, or waiting for a new key.
- A sound marks every change: Pop when the microphone goes live, Tink when it is muted.

## 🏗️ Project architecture

```
osx-push-to-talk/
│
├── 💻 PushToTalk/               # app sources, the PushToTalk target
│   ├── AppDelegate.swift        # 🚀 launch, status bar menu, volume slider and lock, sounds
│   ├── HotKey.swift             # ⌨️ modifier monitor, double press, recording a new key
│   ├── Microphone.swift         # 🎙️ CoreAudio: devices, mute, input volume, 0.2 s timer, connection listeners
│   ├── MicrophoneStatus.swift   # 🚦 microphone states and SF Symbols icons
│   ├── KeyCode.swift            # 🔤 key codes and their labels for the menu item
│   ├── Base.lproj/MainMenu.xib  # 📋 status bar menu
│   ├── Images.xcassets/         # 🎨 app icon
│   └── Info.plist               # LSUIElement: the app has no Dock icon
│
├── 🧪 PushToTalkTests/          # XCTest unit tests
│   └── PushToTalkTests.swift    # 3 tests: modifiers, mute states, key label
│
├── 🛠️ PushToTalk.xcodeproj/     # Xcode project
│   ├── project.pbxproj          # macOS 14.0, Swift 6, MainActor by default in the app target
│   └── xcshareddata/xcschemes/  # shared PushToTalk scheme together with the tests
│
├── ⚙️ .github/
│   └── workflows/Build.yaml     # CI: universal build and the PushToTalk.app artifact
│
├── 🇬🇧 README.md                 # English version (this file)
├── 🇷🇺 README_RU.md              # Russian version
├── 📝 CHANGELOG.md              # version history
├── 👥 AUTHORS                   # authors and contributors
├── 📄 LICENSE                   # MIT
└── 🙈 .gitignore                # ignores build output, Xcode user data and .idea/
```

## 🔧 Tech stack

| Layer        | Technology                                                                                                |
|--------------|-----------------------------------------------------------------------------------------------------------|
| Language     | Swift 6 (language mode), MainActor as the default isolation in the app target                             |
| UI           | AppKit: `NSStatusItem`, `NSMenu`, the menu in `MainMenu.xib`, `NSSlider` in a menu item, SF Symbols icons |
| Audio        | CoreAudio HAL, C API (`AudioObject*`): device list, mute, input volume, change listeners                  |
| Keyboard     | `NSEvent`: a global and a local `flagsChanged` monitor, that is, modifiers only                           |
| Settings     | `UserDefaults`: the hotkey, the UID of the pinned device and the locked input volume                      |
| Logs         | `os.Logger`                                                                                               |
| Platform     | macOS 14.0 or newer, universal binary (arm64 + x86_64)                                                    |
| Build        | Xcode 26 or newer, `xcodebuild`, ad hoc signing                                                           |
| Tests        | XCTest                                                                                                    |
| CI           | GitHub Actions, `macos-latest`                                                                            |
| Dependencies | Third-party: none                                                                                         |

## 🚀 Quick start

### Requirements

1. macOS 14 or newer to run the app.
2. Xcode 26 or newer to build it from source.
3. There are no third-party dependencies.

### Prebuilt build

1. Open the latest run of the [Build](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml) workflow and download the `PushToTalk.app` artifact.
2. Extract the archive and move `PushToTalk.app` to `/Applications`.
3. The app is ad hoc signed and not notarized, so macOS will not open the downloaded copy. Remove the quarantine flag with the command below or allow it in System Settings > Privacy & Security > Open Anyway.

```bash
# Remove the quarantine flag from the downloaded copy
xattr -dr com.apple.quarantine /Applications/PushToTalk.app
```

### Building from source

```bash
git clone https://github.com/BrainRTP/osx-push-to-talk.git
cd osx-push-to-talk

# Release build, output: build/Release/PushToTalk.app
xcodebuild -project PushToTalk.xcodeproj -target PushToTalk -configuration Release

# Install (ditto, not cp -R: cp would put the new bundle inside the one already installed)
rm -rf /Applications/PushToTalk.app && ditto build/Release/PushToTalk.app /Applications/PushToTalk.app
```

A copy built locally has no quarantine flag, so there is nothing to remove.

### Homebrew

The fork has no tap of its own. The original's tap (`brew install yulrizka/tap/pushtotalk`) builds the original version 0.1.5: it has none of the fork's changes, and it does not build in Xcode 27 because Xcode 27's minimum deployment target is macOS 12.

### Running and uninstalling

Launch `PushToTalk.app`: an icon appears in the menu bar. To uninstall the app, quit it (this lifts the mute) and delete `PushToTalk.app` from `/Applications`. Settings are stored in `~/Library/Preferences/com.yulrizka.PushToTalk.plist`.

## 🎛️ Usage

After launch, an icon appears in the menu bar and the app has no Dock icon. The microphone is muted right away. The app does not request microphone access: mute is changed through a device property in CoreAudio. Every mute and unmute is confirmed by a sound: Pop when the microphone goes live, Tink when it is muted.

### Hotkey

- A new key is set with the `Change HotKey` menu item: choose it and press the modifier you want. While the app waits for a key, the microphone stays off.
- Any of ⌥, ⌘, ⌃, ⇧ and fn works, left or right. The app watches only for modifier changes, so regular keys and Caps Lock do not work.
- A second press within the system double-click interval (0.5 seconds by default, System Settings > Accessibility > Pointer Control > Double-click speed) counts as a double press. The microphone stays on until the next press.

### Menu bar icon

| Icon                      | State                                                                                                                                                 |
|---------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| 🔇 Crossed-out microphone | The microphone is off                                                                                                                                 |
| 🟢 Green microphone       | The microphone is on: the key is held down or it was turned on with a double press                                                                    |
| ⚪ Gray microphone        | The app is disabled, the microphone is open. The icon looks the same if the input device has no mute (tooltip "The input device has no mute control") |
| ⌨️ Keyboard               | The app is waiting for a new hotkey, the microphone is off                                                                                            |

### Menu

| Item                        | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|-----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Input volume: N%` + slider | Shows and sets the input volume (sensitivity) of the controlled device, refreshed when the menu opens. The slider is disabled and the label says `n/a` when the device has no volume control                                                                                                                                                                                                                                                                                                                        |
| `Lock input volume`         | Remembers the current input volume and restores it within 0.2 seconds whenever another app changes it (conferencing apps with automatic level adjustment do this). The check mark shows the lock is on; moving the slider moves the locked value. The lock belongs to the controlled device: it turns off when that device changes (you pick another one in `Devices`, or another device becomes the system default while `System Default` is selected). The item is disabled when the device has no volume control |
| `Disable` / `Enable`        | `Disable` stops controlling the microphone and leaves it on (gray icon), `Enable` turns it off again                                                                                                                                                                                                                                                                                                                                                                                                                |
| `Devices`                   | `System Default` follows the macOS input device. Choosing a device pins it. Devices without mute cannot be selected, for example the iPhone microphone via Continuity                                                                                                                                                                                                                                                                                                                                               |
| `Refresh Devices`           | Refreshes the list manually. Usually not needed: the list updates when devices are connected or disconnected and when the default device changes                                                                                                                                                                                                                                                                                                                                                                    |
| `Change HotKey (Right-⌥)`   | Records a new key, the current one is in parentheses                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `Quit PushToTalk`           | Quits the app and lifts the mute                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

### Quitting and settings

Quitting the app lifts the mute, and the microphone stays on. The same happens when you log out or shut down the Mac. If the process is killed (for example, with Force Quit), the device stays muted: launch the app and quit it again. The hotkey, the pinned device and the locked input volume are stored in `~/Library/Preferences/com.yulrizka.PushToTalk.plist`.

## 🧪 Testing

| Type                      | Command                                                                                          | What it checks                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| 🔬 Unit (XCTest, 3 tests) | `xcodebuild test -project PushToTalk.xcodeproj -scheme PushToTalk -destination 'platform=macOS'` | Hotkey modifier matching, mute states, the default key label                                         |
| 🏗️ CI (GitHub Actions)    | [Build](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml) workflow      | Release build, arm64 and x86_64 present in the binary (`lipo -archs`), the `PushToTalk.app` artifact |

Tests run inside the app (app-hosted). The XCTest runner kills the test host before `applicationWillTerminate`, so under tests `AppDelegate` does not mute the microphone: it checks the `XCTestConfigurationFilePath` environment variable.

CI does not run the tests: [.github/workflows/Build.yaml](.github/workflows/Build.yaml) builds the app, checks the architectures and saves the artifact. The workflow runs on a push to `master`, on a pull request and manually, on `macos-latest` with the newest non-beta Xcode.

## 🩺 Troubleshooting

### The hotkey does nothing

Watching modifiers usually needs no permissions. If the app does not respond, add PushToTalk to System Settings > Privacy & Security > Input Monitoring (or Accessibility) and restart it. If the icon is gray and the menu shows the `Enable` item, the app is disabled: enable it.

### "PushToTalk is damaged and can't be opened" or "unidentified developer"

The app is ad hoc signed and not notarized. Remove the quarantine flag as described in the "Prebuilt build" section, or build the app from source.

### People can't hear me even though the icon is green

Check the input volume in the menu and raise it with the slider. If it keeps dropping, turn on `Lock input volume`: some apps lower the system input level automatically.

### The icon is gray, the tooltip says "The input device has no mute control"

The input device macOS uses has no mute control, for example the iPhone microphone via Continuity. The app will not pick another device on its own: muting a microphone that macOS is not using would leave the working one on. Switch the input in System Settings > Sound > Input to a device that has mute. The same icon and tooltip appear when there are no input devices at all.

### The microphone stayed muted after the app was killed

Quitting the app lifts the mute, and a killed process (for example, with Force Quit) cannot do that. Launch the app and quit it again.

### Mute is not applied

CoreAudio write errors (with an OSStatus code) go to the log under the subsystem `com.yulrizka.PushToTalk`:

```bash
log stream --predicate 'subsystem == "com.yulrizka.PushToTalk"'
```

## 🔗 Related projects

> Current as of 2026-10-26. Feature ideas were taken from the forks listed here.

| Project                                                                              | Relationship                                                                                                                                                                          |
|--------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [yulrizka/osx-push-to-talk](https://github.com/yulrizka/osx-push-to-talk)            | The original, the fork started from its version 0.1.5. Author: Ahmy Yulrizka                                                                                                          |
| [yulrizka/osx-push-to-talk#44](https://github.com/yulrizka/osx-push-to-talk/pull/44) | A pull request with microphone state monitoring, not merged into the original. The idea of refreshing devices on connect was reimplemented, without the vendored library from this PR |
| [12joan/push-to-talk](https://github.com/12joan/push-to-talk)                        | The idea of reapplying mute every 0.2 seconds                                                                                                                                         |
| [gerotakke/osx-push-to-talk](https://github.com/gerotakke/osx-push-to-talk)          | The idea of remembering the selected input device                                                                                                                                     |
| [arx8x/osx-push-to-talk](https://github.com/arx8x/osx-push-to-talk)                  | The idea of remembering the selected input device                                                                                                                                     |
| [RoryQ/osx-push-to-talk](https://github.com/RoryQ/osx-push-to-talk)                  | The idea of ignoring the hotkey when other modifiers are held                                                                                                                         |
| [darruda/osx-push-to-talk](https://github.com/darruda/osx-push-to-talk)              | The idea of colored state icons                                                                                                                                                       |
| [nielubowicz/osx-push-to-talk](https://github.com/nielubowicz/osx-push-to-talk)      | The idea of colored state icons                                                                                                                                                       |

## 🔗 Links

- [Original repository](https://github.com/yulrizka/osx-push-to-talk)
- [This fork](https://github.com/BrainRTP/osx-push-to-talk)
- [Build workflow in GitHub Actions](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml)
- [Apple: Using Intel-based apps on a Mac with Apple silicon](https://support.apple.com/en-us/102527): Rosetta works in macOS 27 and earlier, from macOS 28 only for some older games
- [Version history](CHANGELOG.md)
- [Authors and contributors](AUTHORS)
- [MIT license](LICENSE)
- App icon: [jeff](https://thenounproject.com/jeff955/) (CC)

## 👤 Maintainers

[@BrainRTP](https://github.com/BrainRTP) (Stanislav Panchenko), original author: Ahmy Yulrizka ([@yulrizka](https://github.com/yulrizka))
