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
    private let volumeItem = NSMenuItem(title: "Input volume", action: nil, keyEquivalent: "")
    private let lockVolumeItem = NSMenuItem(title: "Lock input volume", action: #selector(toggleVolumeLock(_:)), keyEquivalent: "")
    private let soundOnItem = NSMenuItem(title: "Sound when live (Pop)", action: nil, keyEquivalent: "")
    private let soundOffItem = NSMenuItem(title: "Sound when muted (Tink)", action: nil, keyEquivalent: "")
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
        setUpLevelMenus()
        for (index, item) in [volumeItem, .separator(), soundOnItem, soundOffItem, .separator()].enumerated() {
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
        let volume = microphone.inputVolume()
        let onLevel = Self.soundVolume(forKey: Self.soundOnKey)
        let offLevel = Self.soundVolume(forKey: Self.soundOffKey)
        if menu == statusMenu {
            volumeItem.title = volume.map { "Input volume: \(Self.percent($0))%" } ?? "Input volume: n/a"
            soundOnItem.title = "Sound when live (Pop): \(Self.percent(onLevel))%"
            soundOffItem.title = "Sound when muted (Tink): \(Self.percent(offLevel))%"
        } else if menu == volumeItem.submenu {
            check(menu, percent: volume.map { Self.nearest($0, step: 10) })
            lockVolumeItem.state = microphone.lockedInputVolume == nil ? .off : .on
        } else if menu == soundOnItem.submenu {
            check(menu, percent: Self.nearest(onLevel, step: 25))
        } else if menu == soundOffItem.submenu {
            check(menu, percent: Self.nearest(offLevel, step: 25))
        }
    }

    // Submenus with preset levels: plain menu items instead of sliders, which are hard to drag inside a menu.
    private func setUpLevelMenus() {
        volumeItem.submenu = levelMenu(step: 10, action: #selector(volumeLevelChosen(_:)))
        volumeItem.submenu?.addItem(.separator())
        lockVolumeItem.target = self
        lockVolumeItem.tag = -1
        volumeItem.submenu?.addItem(lockVolumeItem)
        soundOnItem.submenu = levelMenu(step: 25, action: #selector(soundLevelChosen(_:)))
        soundOffItem.submenu = levelMenu(step: 25, action: #selector(soundLevelChosen(_:)))
    }

    private func levelMenu(step: Int, action: Selector) -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        for percent in stride(from: 0, through: 100, by: step) {
            let item = NSMenuItem(title: "\(percent)%", action: action, keyEquivalent: "")
            item.target = self
            item.tag = percent
            menu.addItem(item)
        }
        return menu
    }

    private func check(_ menu: NSMenu, percent: Int?) {
        for item in menu.items where item.tag >= 0 && item.action != nil {
            item.state = item.tag == percent ? .on : .off
        }
    }

    private static func percent(_ level: Float) -> Int { Int((level * 100).rounded()) }

    private static func nearest(_ level: Float, step: Int) -> Int { Int((level * 100 / Float(step)).rounded()) * step }

    private static func soundVolume(forKey key: String) -> Float {
        UserDefaults.standard.object(forKey: key) as? Float ?? 1
    }

    @objc private func volumeLevelChosen(_ item: NSMenuItem) {
        let volume = Float(item.tag) / 100
        microphone.setInputVolume(volume)
        if microphone.lockedInputVolume != nil { microphone.lockedInputVolume = volume }
    }

    @objc private func soundLevelChosen(_ item: NSMenuItem) {
        let isOn = item.menu == soundOnItem.submenu
        UserDefaults.standard.set(Float(item.tag) / 100, forKey: isOn ? Self.soundOnKey : Self.soundOffKey)
        play(isOn ? "Pop" : "Tink") // preview at the new level
    }

    @objc private func toggleVolumeLock(_ sender: NSMenuItem) {
        microphone.lockedInputVolume = microphone.lockedInputVolume == nil ? microphone.inputVolume() : nil
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        menuItem.menu != volumeItem.submenu || microphone.inputVolume() != nil
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

