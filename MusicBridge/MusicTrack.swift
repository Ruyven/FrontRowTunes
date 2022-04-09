//
//  MusicTrack.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 7/04/22.
//

import Foundation
import AppKit

@objc class MusicTrack: NSObject {
    @objc let id: String
    @objc let name: String
    @objc let artist: String
    @objc let album: String
    @objc let artwork: Data?
    @objc let duration: Double
    
    init(id: String, name: String?, artist: String?, album: String?, artwork: Data?, duration: Double) {
        self.id = id
        self.album = album ?? ""
        self.artist = artist ?? ""
        self.name = name ?? ""
        self.artwork = artwork
        self.duration = duration
    }
    
    @objc static var defaultArtwork: NSImage? {
        return NSImage(named: "FrontRowGradient")
    }
    
    @objc func tintColor(darkMode: Bool, strongAdjustment: Bool) -> NSColor {
        let tintColor: NSColor
        if let artwork = artwork,
           artwork.count > 0,
           let artworkImage = NSImage(data: artwork),
           let color = artworkImage.averageColor
        {
            tintColor = color
        } else {
            tintColor = .defaultTintColor
        }
        
        return tintColor.adjustingHSBA { hue, saturation, brightness, alpha in
            let maxLightModeBrightness: CGFloat = strongAdjustment ? 0.8 : 0.9
            let minDarkModeBrightness: CGFloat = strongAdjustment ? 0.8 : 0.6
            if darkMode && brightness < minDarkModeBrightness {
                brightness = minDarkModeBrightness
                return true
            } else if !darkMode && brightness > maxLightModeBrightness {
                brightness = maxLightModeBrightness
                return true
            } else {
                return false
            }
        }
    }
}
