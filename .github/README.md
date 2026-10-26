# OSX PushToTalk

OSX PushToTalk mutes and unmutes the microphone via a keypress. It works globally, in every app that uses the microphone (Google Meet, Zoom, Teams, Discord and so on), because it toggles the mute control of the input device itself.

![usage animation](https://user-images.githubusercontent.com/117752/96354725-0eabff00-10da-11eb-9539-6e159e7d588b.gif)

This fork is a modernized build of [yulrizka/osx-push-to-talk](https://github.com/yulrizka/osx-push-to-talk): native Apple Silicon support, Swift 6, and fixes and features collected from the upstream pull requests and forks.

## Features

- Hold a hotkey (default **Right ⌥**) to unmute, release to mute.
- Double-tap the hotkey to keep the microphone open; tap once more to mute again.
- The hotkey is ignored while other modifiers are held, so ⌘⌥ shortcuts do not unmute you.
- Sticky mute: while muted, the app re-applies mute every 0.2 s, so apps that reset the input device cannot unmute you.
- Control the system default input device (the default) or pin a specific device in the Devices menu. The choice is remembered across launches, and the list refreshes itself when devices are plugged in or out.
- The input volume (sensitivity) of the controlled device is shown in the menu.
- Menu bar icon: slashed mic = muted, green mic = live, gray mic = the app is disabled and the microphone is left open, keyboard = waiting for a new hotkey.

## Requirements

macOS 14 or newer. The app is a universal binary (Apple Silicon and Intel).

## Installation

### Download a build

1. Open the latest run on the [Actions page](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml) and download the `PushToTalk.app` artifact.
2. Unzip it and move `PushToTalk.app` to `/Applications`.
3. The app is signed ad hoc and not notarized, so macOS refuses to open a downloaded copy. Remove the quarantine flag:

```
xattr -dr com.apple.quarantine /Applications/PushToTalk.app
```

   or allow it under System Settings > Privacy & Security > "Open Anyway".

### Build from source

Requires Xcode 26 or newer.

```
git clone https://github.com/BrainRTP/osx-push-to-talk.git
cd osx-push-to-talk
xcodebuild -project PushToTalk.xcodeproj -target PushToTalk -configuration Release
```

The app ends up in `build/Release/PushToTalk.app`; move it to `/Applications`. A locally built app needs no quarantine handling.

### Homebrew (upstream version)

The upstream tap (`brew install yulrizka/tap/pushtotalk`) builds the original 0.1.5 release from source. It has none of the changes in this fork and no longer builds with Xcode 27, whose minimum deployment target is macOS 12.

## Usage notes

- Change HotKey: choose "Change HotKey" in the menu and press a modifier key (⌥, ⌘, ⌃, ⇧ or fn, left or right). Only modifier keys can be the hotkey, because the app listens for modifier changes only.
- Enable/Disable: "Disable" stops the app from managing the microphone and leaves it unmuted (gray icon); "Enable" mutes it again.
- Devices: "System Default" follows whatever macOS uses as the input device; picking a device pins it. Devices without a mute control (for example the iPhone Continuity microphone) are listed but cannot be selected.
- Quitting the app unmutes the microphone. If the app gets killed, the device stays muted: launch the app and quit it again.

## Troubleshooting

### The hotkey does nothing

Monitoring modifier keys normally needs no permission. If the app does not react, add PushToTalk under System Settings > Privacy & Security > Input Monitoring (or Accessibility) and relaunch it.

### "PushToTalk is damaged and can't be opened" or "unidentified developer"

The app is signed ad hoc, not notarized. Remove the quarantine flag as described under Download, or build it from source.

### Nobody hears me although the icon is green

Check the input volume shown in the menu; some apps lower it. Raise it under System Settings > Sound > Input.

### Uninstall

Quit the app (this unmutes the microphone) and delete `PushToTalk.app` from `/Applications`. Preferences live in `~/Library/Preferences/com.yulrizka.PushToTalk.plist`.

## Acknowledgement

- Original app by [Ahmy Yulrizka](https://github.com/yulrizka) and contributors (see AUTHORS).
- App icon by [jeff](https://thenounproject.com/jeff955/) (CC).
