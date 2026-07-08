//
//  MusicBridge.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 7/04/22.
//

import Foundation
import AppKit

@objc class MusicBridge: NSObject {
    @discardableResult
    private static func executeScript(source: String) -> NSAppleEventDescriptor? {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            print("Failed to create script")
            return nil
        }

        let output = script.executeAndReturnError(&errorInfo)
        if let errorInfo = errorInfo {
            print("Error: \(errorInfo.description)")
            return nil
        }
        return output
    }
    
    private static func isMusicRunning() -> Bool {
        return NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").count > 0
    }
    
    private static func isTrackPlaying() -> Bool {
        guard isMusicRunning() else { return false }
        let eventDescriptor = executeScript(source: "tell application \"Music\" to exists current track")
        return eventDescriptor?.booleanValue ?? false
    }
    
    @objc static func getTrackID() -> String? {
        guard isMusicRunning() else { return nil }
        let eventDescriptor = executeScript(source: "tell application \"Music\" to get persistent ID of current track")
        return eventDescriptor?.stringValue
    }
    
    private static func getAlbum() -> String? {
        guard isMusicRunning() else { return nil }
        return executeScript(source: "tell application \"Music\" to get album of current track")?.stringValue
    }

    private static func getArtist() -> String? {
        guard isMusicRunning() else { return nil }
        return executeScript(source: "tell application \"Music\" to get artist of current track")?.stringValue
    }

    private static func getTrackName() -> String? {
        guard isMusicRunning() else { return nil }
        return executeScript(source: "tell application \"Music\" to get name of current track")?.stringValue
    }
    
    private static func getArtwork() -> Data? {
        guard isMusicRunning() else { return nil }
        return executeScript(source: """
            tell application \"Music\" to tell current track
                if exists artworks then
                    get data of artwork 1
                end if
            end tell
        """)?.data
    }
    
    //TODO: rewrite and use
//    func downloadMusicArtwork(){
//            let editedSongArtist = currentSongArtist.replacingOccurrences(of: "&", with: "+", options: .literal, range: nil)
//            let safeArtistURL = editedSongArtist.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
//            let safeSongURL = currentSongName.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
//            let safeAlbumURL = currentAlbumName.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
//            let stringURL = "https://itunes.apple.com/search?term=\(safeArtistURL)+\(safeAlbumURL)+\(safeSongURL)&country=us&limit=1"
//            let editedStringURL = stringURL.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
//
//            let url = URL(string: editedStringURL)
//            URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
//                guard let data = data, error == nil else { return }
//
//                do {
//                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
//                    let posts = json!["results"] as? [[String: Any]] ?? []
//                    if posts.count != 0{
//                        let originalURL = posts[0]["artworkUrl100"] as! String
//                        let editedURL = originalURL.replacingOccurrences(of: "100x100bb.jpg", with: "600x600bb.jpg", options: .literal, range: nil)
//                        let imageURL = URL(string: editedURL)!
//                        DispatchQueue.main.async {
//                            if self.newSong{
//                                self.newArtworkURL(url: imageURL)
//                            }else{
//                                self.albumArt.image = NSImage(contentsOf: imageURL)
//                            }
//                            self.circularProgress.removeFromSuperview()
//                        }
//                    }else{
//                        DispatchQueue.main.async {
//                            self.noArtwork()
//                        }
//                    }
//
//
//                } catch {
//                    print(error)
//                }
//            }).resume()
//        }
    
    private static func getDuration() -> Double? {
        guard isMusicRunning() else { return nil }
        return executeScript(source: "tell application \"Music\" to get duration of current track")?.doubleValue
    }

    @objc static func getCurrentTrack() -> MusicTrack? {
        guard isTrackPlaying(), let trackID = getTrackID() else {
            return nil
        }
        
        return MusicTrack(
            id: trackID,
            name: getTrackName(),
            artist: getArtist(),
            album: getAlbum(),
            artwork: getArtwork(),
            duration: getDuration() ?? 0
        )
    }
    
    @objc static let PLAYER_STATE_PLAYING = "kPSP"
    @objc static let PLAYER_STATE_PAUSED = "kPSp"
    @objc static let PLAYER_STATE_STOPPED = "kPSS"
    @objc static let PLAYER_STATE_FAST_FORWARDING = "kPSF"
    @objc static let PLAYER_STATE_REWINDING = "kPSR"
    
    @objc static func getPlayerState() -> String? {
        guard isMusicRunning() else { return nil }
        return executeScript(source: "tell application \"Music\" to get player state")?.stringValue
    }
    
    @objc static func getPlayerPosition() -> Double {
        guard isMusicRunning() else { return 0 }
        return executeScript(source: "tell application \"Music\" to get player position")?.doubleValue ?? 0
    }
    
    // MARK: - Trigger events
    
    @objc static func playpause() {
        executeScript(source: "tell application \"Music\" to tell current track to playpause");
    }
    
    @objc static func backTrack() {
        executeScript(source: "tell application \"Music\" to tell current track to back track");
    }
    
    @objc static func nextTrack() {
        executeScript(source: "tell application \"Music\" to tell current track to next track");
    }
}
