//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//

import Cocoa

@main

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSMenuItemValidation {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemToggle: NSMenuItem!
    @IBOutlet weak var deviceMenu: NSMenu!
    @IBOutlet weak var hotkeyMenuItem: NSMenuItem!
    
    var microphone = Microphone()
    var hotkey: HotKey?
    private let volumeLabel = NSTextField(labelWithString: "Input volume: -")
    private let volumeSlider = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let volumeItem = NSMenuItem()
    private let lockVolumeItem = NSMenuItem(title: "Lock input volume", action: #selector(toggleVolumeLock(_:)), keyEquivalent: "")
    private let soundOnLabel = NSTextField(labelWithString: "Sound when live (Pop): -")
    private let soundOnSlider = NSSlider(value: 100, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let soundOnItem = NSMenuItem()
    private let soundOffLabel = NSTextField(labelWithString: "Sound when muted (Tink): -")
    private let soundOffSlider = NSSlider(value: 100, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let soundOffItem = NSMenuItem()
    private static let soundOnKey = "prefSoundOnVolume"
    private static let soundOffKey = "prefSoundOffVolume"
    private var announcedMuted = true
    private var lastLiveTime: TimeInterval = 0
    private var pendingSound: DispatchWorkItem?
    private var quitting = false
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // The XCTest runner kills the test host before applicationWillTerminate, so never mute under tests.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            microphone.status = .disabled // no device is selected yet, so this only stops later refreshes from muting
            return
        }
        self.hotkey = HotKey(microphone: microphone, menuItem: hotkeyMenuItem)

        statusMenu.delegate = self
        setUpSliderItems()
        for (index, item) in [volumeItem, lockVolumeItem, .separator(), soundOnItem, soundOffItem, .separator()].enumerated() {
            statusMenu.insertItem(item, at: index)
        }
        statusItem.menu = statusMenu
        self.microphone.statusUpdated = { (status) in
            self.menuItemToggle.title = status.toggleTitle
            let uncontrolled = self.microphone.selectedInput == nil
            // Never claim "muted" when no input device can be muted.
            self.statusItem.button?.image = (uncontrolled && status == .muted ? MicrophoneStatus.disabled : status).image
            self.statusItem.button?.toolTip = uncontrolled ? "The input device has no mute control" : nil
            if !self.quitting { self.announce(muted: status.isMuted) }
        }
        self.microphone.setupDeviceMenu(deviceMenu)
        self.microphone.status = .muted
    }

    // Pop at once when the mic goes live. Tink at once after a hold, but after a short tap it waits for the
    // double-tap window, so a second press (double tap, lock on) cancels it and the double tap sounds once.
    private func announce(muted: Bool) {
        let now = ProcessInfo.processInfo.systemUptime
        if !muted {
            pendingSound?.cancel()
            pendingSound = nil
            guard announcedMuted else { return }
            announcedMuted = false
            lastLiveTime = now
            play("Pop")
        } else if announcedMuted || pendingSound != nil {
            return
        } else if now - lastLiveTime < HotKey.doubleTapInterval {
            let work = DispatchWorkItem { [weak self] in
                MainActor.assumeIsolated {
                    self?.pendingSound = nil
                    self?.announce(muted: true)
                }
            }
            pendingSound = work
            DispatchQueue.main.asyncAfter(deadline: .now() + HotKey.doubleTapInterval - (now - lastLiveTime), execute: work)
        } else {
            announcedMuted = true
            play("Tink")
        }
    }

    private func play(_ name: String) {
        // A copy plays even while the previous sound is still playing.
        guard let sound = NSSound(named: name)?.copy() as? NSSound else { return }
        sound.volume = Self.soundVolume(forKey: name == "Pop" ? Self.soundOnKey : Self.soundOffKey)
        sound.play()
    }

    func menuWillOpen(_ menu: NSMenu) {
        if let volume = microphone.inputVolume() {
            volumeSlider.isEnabled = true
            volumeSlider.doubleValue = Double(volume * 100)
            volumeLabel.stringValue = "Input volume: \(Int((volume * 100).rounded()))%"
        } else {
            volumeSlider.isEnabled = false
            volumeLabel.stringValue = "Input volume: n/a"
        }
        lockVolumeItem.state = microphone.lockedInputVolume == nil ? .off : .on
        soundOnSlider.doubleValue = Double(Self.soundVolume(forKey: Self.soundOnKey) * 100)
        soundOffSlider.doubleValue = Double(Self.soundVolume(forKey: Self.soundOffKey) * 100)
        soundOnLabel.stringValue = "Sound when live (Pop): \(Int(soundOnSlider.doubleValue.rounded()))%"
        soundOffLabel.stringValue = "Sound when muted (Tink): \(Int(soundOffSlider.doubleValue.rounded()))%"
    }

    private func setUpSliderItems() {
        fill(volumeItem, label: volumeLabel, slider: volumeSlider, action: #selector(volumeSliderMoved(_:)))
        fill(soundOnItem, label: soundOnLabel, slider: soundOnSlider, action: #selector(soundSliderMoved(_:)))
        fill(soundOffItem, label: soundOffLabel, slider: soundOffSlider, action: #selector(soundSliderMoved(_:)))
        lockVolumeItem.target = self
    }

    private func fill(_ item: NSMenuItem, label: NSTextField, slider: NSSlider, action: Selector) {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 46))
        label.frame = NSRect(x: 14, y: 26, width: 192, height: 17)
        label.font = NSFont.menuFont(ofSize: 0)
        slider.frame = NSRect(x: 14, y: 4, width: 192, height: 20)
        slider.isContinuous = true
        slider.target = self
        slider.action = action
        view.addSubview(label)
        view.addSubview(slider)
        item.view = view
    }

    private static func soundVolume(forKey key: String) -> Float {
        UserDefaults.standard.object(forKey: key) as? Float ?? 1
    }

    @objc private func soundSliderMoved(_ slider: NSSlider) {
        let isOn = slider == soundOnSlider
        UserDefaults.standard.set(Float(slider.doubleValue / 100), forKey: isOn ? Self.soundOnKey : Self.soundOffKey)
        let percent = Int(slider.doubleValue.rounded())
        (isOn ? soundOnLabel : soundOffLabel).stringValue = isOn ? "Sound when live (Pop): \(percent)%" : "Sound when muted (Tink): \(percent)%"
        if NSApp.currentEvent?.type == .leftMouseUp { play(isOn ? "Pop" : "Tink") } // preview at the new level
    }

    @objc private func volumeSliderMoved(_ slider: NSSlider) {
        let volume = Float(slider.doubleValue / 100)
        microphone.setInputVolume(volume)
        if microphone.lockedInputVolume != nil { microphone.lockedInputVolume = volume }
        volumeLabel.stringValue = "Input volume: \(Int(slider.doubleValue.rounded()))%"
    }

    @objc private func toggleVolumeLock(_ sender: NSMenuItem) {
        microphone.lockedInputVolume = microphone.lockedInputVolume == nil ? microphone.inputVolume() : nil
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        menuItem != lockVolumeItem || microphone.inputVolume() != nil
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        quitting = true
        self.microphone.status = .disabled // leave the device unmuted
    }
    
    
    // MARK: Menu item Actions
    @IBAction func toggleAction(_ sender: NSMenuItem) {
        self.hotkey!.toggle()
    }
    
    @IBAction func menuItemQuitAction(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
    
    @IBAction func refreshDevices(_ sender: NSMenuItem?) {
        self.microphone.refreshDevices()
    }
    
    @IBAction func recordNewHotKey(_ sender: NSMenuItem) {
        self.hotkey!.recordNewHotKey()
    }
}

