//
//  PreferencesWindowController.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 17/07/26.
//

import AppKit
import SwiftUI

@objc class PreferencesWindowController: NSWindowController {
    @objc static let shared = PreferencesWindowController()
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentView = NSHostingView(rootView: PreferencesView())
        window.center()
        self.init(window: window)
    }
    
    @objc func show() {
        self.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
