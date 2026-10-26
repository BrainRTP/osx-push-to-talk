//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//

import Cocoa

@main

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemToggle: NSMenuItem!
    @IBOutlet weak var deviceMenu: NSMenu!
    @IBOutlet weak var hotkeyMenuItem: NSMenuItem!
    
    var microphone = Microphone()
    var hotkey: HotKey?
    private let volumeItem = NSMenuItem(title: "Input volume: -", action: nil, keyEquivalent: "")
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // The XCTest runner kills the test host before applicationWillTerminate, so never mute under tests.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            microphone.status = .disabled // no device is selected yet, so this only stops later refreshes from muting
            return
        }
        self.hotkey = HotKey(microphone: microphone, menuItem: hotkeyMenuItem)

        statusMenu.delegate = self
        statusMenu.insertItem(volumeItem, at: 0)
        statusMenu.insertItem(.separator(), at: 1)
        statusItem.menu = statusMenu
        self.microphone.statusUpdated = { (status) in
            self.menuItemToggle.title = status.toggleTitle
            let uncontrolled = self.microphone.selectedInput == nil
            // Never claim "muted" when no input device can be muted.
            self.statusItem.button?.image = (uncontrolled && status == .muted ? MicrophoneStatus.disabled : status).image
            self.statusItem.button?.toolTip = uncontrolled ? "The input device has no mute control" : nil
        }
        self.microphone.setupDeviceMenu(deviceMenu)
        self.microphone.status = .muted
    }

    func menuWillOpen(_ menu: NSMenu) {
        volumeItem.title = microphone.inputVolume().map { "Input volume: \(Int(($0 * 100).rounded()))%" } ?? "Input volume: n/a"
    }

    func applicationWillTerminate(_ aNotification: Notification) {
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

