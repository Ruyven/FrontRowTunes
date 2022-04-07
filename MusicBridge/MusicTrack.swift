//
//  MusicTrack.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 7/04/22.
//

import Foundation

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
}
