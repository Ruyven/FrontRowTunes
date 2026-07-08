# Debugging Results: Startup Performance & Music.app Integration

## Summary

The investigation confirmed that the primary startup issue is not the timer. The startup delay is caused by synchronous AppleScript execution on the main thread during `SongView` initialization.

The key findings are:

1. `Music.app` launch is triggered by synchronous AppleScript queries.
2. The first AppleScript call when Music is closed can block the main thread for several seconds while Music launches.
3. Even when Music is already running, AppleScript calls still block the UI thread.
4. The timer is responsible for relaunching Music after the user quits it, but is not the cause of initial startup delay.
5. AppleEvents can be executed asynchronously from background threads.
6. Distributed notifications are sufficient for metadata updates; polling is only required for playback position tracking.

---

# Runtime Validation Results

| Question | Feature / Method | Result |
|---|---|---|
| **Q1** | Slow Methods | `getPlayerPosition()` is the largest startup offender when Music.app is closed. First call takes ~3.5 seconds because Music.app must launch. Other calls are normally fast once Music is running. |
| **Q2** | Which calls launch Music? | `getPlayerPosition`, `getPlayerState`, and `getCurrentTrack` all trigger Music.app launch when executed while Music is closed. Any AppleScript query targeting Music can cause launch. |
| **Q3** | `NSRunningApplication` check | Confirmed safe. `NSRunningApplication.runningApplications(withBundleIdentifier:)` does not launch Music and completes immediately. |
| **Q4/Q5** | Timer impact | Timer is responsible for repeatedly polling Music and relaunching it after manual quit. It does not materially affect initial startup time once AppleScript startup calls are removed. |
| **Q6** | Main thread calls | Confirmed. Startup AppleScript calls execute on the main thread and block UI responsiveness. |
| **Q7** | Thread safety | Confirmed functional. Moving AppleScript execution to a background queue works without crashes or script-threading errors. |
| **Q8/Q9** | Notifications vs polling | Confirmed. `com.apple.Music.playerInfo` notifications update metadata, artwork, and playback state. Polling is only required for continuous playback position updates. |
| **Q10** | Script performance | Confirmed. `NSAppleScript` objects are created and compiled for every invocation. There is no script caching. |

---

# Detailed Observations

## Music.app Already Running

Typical timings:

| Operation | Time |
|---|---:|
| `getPlayerPosition` | ~0.02–0.49s |
| `getPlayerState` | ~0.006s |
| `exists current track` | ~0.02s |
| Track metadata queries | ~0.005–0.02s |
| Artwork retrieval | ~0.08s |
| Complete `getCurrentTrack` | ~0.15s |

Even with Music.app already running, these calls are still synchronous and execute on the main thread.

---

## Music.app Closed

Startup timings:

| Operation | Time |
|---|---:|
| First `getPlayerPosition` | ~3.51s |
| `getPlayerState` after launch | ~0.52s |
| `getCurrentTrack` | ~0.25s |
| Later position updates | ~0.02–0.04s |

The initial `getPlayerPosition` call is the primary source of the startup beachball.

---

# Confirmed Architecture

## Startup Sequence

```
App Launch
|
v
SongView awakeFromNib
|
+--> MusicBridge isMusicRunning
| |
| +--> NSRunningApplication check
|
+--> MusicBridge getPlayerPosition
| |
| +--> NSAppleScript
| |
| +--> launches Music.app if required
|
+--> MusicBridge getCurrentTrack
|
+--> Multiple NSAppleScript calls
```

---

# Root Causes

## Root Cause 1: Synchronous AppleScript During Startup

Current behaviour:

```
Main Thread
|
+--> AppleScript request
|
+--> Wait for Music.app
|
+--> UI frozen
```

Impact:

- Slow launch
- Beachball while Music.app starts
- Poor responsiveness even when Music.app is already running

---

## Root Cause 2: AppleScript Polling Can Relaunch Music

Current behaviour:

```
Timer
|
+--> getPlayerPosition()
|
+--> AppleEvent to Music
|
+--> Music.app launches if closed
```


Impact:

- User cannot keep Music.app closed while FrontRowTunes is running.
- Repeated launches can create unnecessary CPU usage and UI interruptions.

---

# Static Analysis Findings

## Confirmed by Source Inspection

### MusicBridge

- Uses `NSAppleScript` for Music.app communication.
- Every AppleScript invocation creates and compiles a new script.
- No AppleScript caching exists.
- All MusicBridge methods are synchronous.
- `isMusicRunning` is the only non-AppleScript query.

### SongView

Startup calls:

- `getPlayerPosition`
- `getCurrentTrack`

Both occur during initialization.

Additional observations:

- `getPlayerState` has already been moved off the main thread in several locations.
- Notification handling currently calls `getTrack:` on the main thread.
- `getTrack:` eventually calls expensive MusicBridge methods.

### Notifications

Existing notification:

`com.apple.Music.playerInfo`

is sufficient for:

- track changes
- artist
- album
- artwork
- playback state

The only missing continuous update is:

- playback position
