//
//  Constants.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 17/04/22.
//

import Foundation
import AppKit

@objc extension NSColor {
    @objc static let defaultTintColor = NSColor.orange
}

@objc class PrefKeys: NSObject {
    @objc static let musicScreensaverDelay = "musicScreensaverDelay"
    @objc static let clockScreensaverDelay = "clockScreensaverDelay"
}

@objc public enum AppearanceMode: Int {
    case light = 0
    case dark = 1
    case system = 2
}
