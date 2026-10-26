//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//

import Cocoa

@main

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemToggle: NSMenuItem!
    @IBOutlet weak var deviceMenu: NSMenu!
    @IBOutlet weak var hotkeyMenuItem: NSMenuItem!
    
    var microphone = Microphone()
    var hotkey: HotKey?
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.hotkey = HotKey(microphone: microphone, menuItem: hotkeyMenuItem)

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

