# Planning: Startup Speed-up & Decoupling Music.app

## Problem Statement
Launching FrontRowTunes takes a long time and frequently causes the application to become unresponsive (beachball). On startup, it automatically forces the macOS Music app to launch. Furthermore, if the user manually quits the Music app while FrontRowTunes is open, the Music app is immediately relaunched.

---

## Technical Theories

### Theory 1: Synchronous AppleEvents (AppleScript) Blocking the UI Thread
During startup, `SongView` initializes and executes several synchronous AppleScript queries on the main thread inside `awakeFromNib`:
1. `playerPosition = [MusicBridge getPlayerPosition];`
2. `[self setTrack:[MusicBridge getCurrentTrack] prev:nil];`
And during view layer configuration:
3. `[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];`

These calls compile and run AppleScript targeting `Music.app`. 
- If `Music.app` is not running, macOS must launch the Music application in the background to handle these AppleEvents before replying.
- Launching `Music.app` takes several seconds, which blocks the main thread of FrontRowTunes synchronously. This leads to the application being marked as "Not Responding" during launch.
- Even if `Music.app` is already running, synchronous cross-process AppleEvents on the main thread cause general lag and stutter.

### Theory 2: The 0.5-Second Relaunch Loop (Timer Poll)
`SongView` schedules a repeating timer (`updatePlayerPositionTimer`) with an interval of `0.5` seconds (`UPDATEINTERVAL`):
```objc
updatePlayerPositionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATEINTERVAL target:self selector:@selector(updatePlayerPosition) userInfo:nil repeats:YES];
```
This timer periodically calls:
```objc
- (void)updatePlayerPosition {
    int newPlayerPosition = (int)[MusicBridge getPlayerPosition];
    ...
}
```
Because `getPlayerPosition` executes AppleScript targeting `"Music"`, any invocation of this script will automatically trigger macOS to launch the Music application if it is closed. This means if the user closes the Music app, FrontRowTunes will force it to launch again within at most 0.5 seconds, trapping the user in a loop and causing continuous main-thread stutters.

---

## Proposed Solution

To eliminate startup delays, prevent the auto-launch of Music.app on startup, and allow users to start playback manually by pressing the spacebar, we will implement the following:

### 1. Introduce Lightweight Running Application Verification
We will add a non-blocking check in `MusicBridge.swift` using Cocoa's `NSRunningApplication` API:
```swift
private static func isMusicRunning() -> Bool {
    return !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
}
```
This API queries `launchd`/`WindowServer` directly and does **not** send AppleEvents to `Music.app`. Therefore, it never triggers a launch or blocks.

### 2. Guard Status and Query Methods
We will guard all read-only query methods in `MusicBridge.swift` using `isMusicRunning()`:
- `getTrackID()`
- `getAlbum()`
- `getArtist()`
- `getTrackName()`
- `getArtwork()`
- `getDuration()`
- `getPlayerState()`
- `getPlayerPosition()`
- `getCurrentTrack()`

If `isMusicRunning()` is `false`, these methods will immediately return a safe default (e.g., `nil`, `0`, or `Stopped` state) without executing any AppleScript.

### 3. Allow User Commands to Trigger Launch
Commands that represent explicit user actions (such as pressing the spacebar to play, or using arrow keys for next/prev) will bypass the running application check:
- `playpause()`
- `backTrack()`
- `nextTrack()`

When the user presses Spacebar, `[MusicBridge playpause]` is called, sending the AppleEvent which will launch `Music.app` and resume playback.

### 4. Dynamic UI Rehydration
Once `Music.app` launches and begins playing, it publishes standard `com.apple.Music.playerInfo` notifications. `SongView` already listens to this notification via:
```objc
[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(getTrack:) name:@"com.apple.Music.playerInfo" object:nil];
```
When this notification fires, `SongView`'s `getTrack:` handler will query `MusicBridge` for the track details. Since `Music.app` is now running, `isMusicRunning()` will return `true`, and the UI will instantly rehydrate with the current song's details, artwork, and playback progress!

---

## Validation Strategy
1. **Launch Test:** Ensure FrontRowTunes launches instantly, without launching `Music.app` or showing a beachball.
2. **Quit Test:** Quit `Music.app` while FrontRowTunes is open. Verify that `Music.app` stays closed and FrontRowTunes does not force it to relaunch.
3. **Spacebar Test:** With `Music.app` closed, open FrontRowTunes and press spacebar. Verify that `Music.app` launches and begins playing.
4. **UI Rehydration Test:** Verify that once `Music.app` is playing, the album art, track details, and progress bar are fully operational in FrontRowTunes.
