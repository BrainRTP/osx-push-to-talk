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
            self.menuItemToggle.title = status.title()
            self.statusItem.button?.image = status.image()
        }
        self.microphone.status = .Muted
        self.refreshDevices(nil);
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.microphone.status = .Speaking // leave the device unmuted
    }
    
    
    // MARK: Menu item Actions
    @IBAction func toggleAction(_ sender: NSMenuItem) {
        self.hotkey!.toggle()
    }
    
    @IBAction func menuItemQuitAction(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
    
    @IBAction func refreshDevices(_ sender: NSMenuItem?) {
        do {
            try self.microphone.setupDeviceMenu(menu: deviceMenu)
        } catch {
            print("Unexpected Error: \(error).")
            exit(1)
        }
    }
    
    @IBAction func recordNewHotKey(_ sender: NSMenuItem) {
        self.hotkey!.recordNewHotKey()
    }
}

