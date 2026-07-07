# Recommended Implementation Strategy

## Phase 1: Prevent Unwanted Music Launch

Add `isMusicRunning()` guards to all read-only MusicBridge methods:

- `getTrackID`
- `getAlbum`
- `getArtist`
- `getTrackName`
- `getArtwork`
- `getDuration`
- `getPlayerState`
- `getPlayerPosition`
- `getCurrentTrack`

Behaviour:

```
Music closed
|
+--> Query requested
|
+--> Return safe default
```

---

## Phase 2: Move Startup Queries Off Main Thread

Convert:

```
awakeFromNib
|
+--> synchronous MusicBridge calls
```

into:

```
awakeFromNib
|
+--> start UI immediately
|
+--> background MusicBridge query
|
+--> update UI on main thread
```

Do so with a helper function, for minimal repeated boilerplate code.

---

## Phase 3: Preserve Explicit User Actions

Do not guard:

- play/pause
- next track
- previous track

These are intentional user commands and should be allowed to launch Music.app.

---

## Phase 4: Refine Metadata Polling

Keep polling only for:

- playback position (only when `isMusicRunning()` is true)
- keep: timer is also used to update clock in SongLayer

Use notifications for:

- song changes
- artwork
- metadata
- play/pause state

---

# Remaining Open Questions

| Question | Status |
|---|---|
| Should AppleScript compilation be cached? | Not yet measured. Likely a secondary optimisation. |
| Are there notification edge cases where metadata becomes stale? | Inconsistency: Sometimes app doesn't react to events when it's windowed and not the active window, only reacting once it becomes active again. Keep as secondary optimisation, if required. |
| Should playback position polling pause when Music.app is closed? | Yes. |
| Should UI show a "Music unavailable" state before the user presses Play? | No, keep current UI for stopped playback. |
| If UI starts before knowing the Music status, what should it show? | Product decision. |
| Should all MusicBridge calls become async APIs? | Recommended architectural improvement. |

---

# Final Conclusion

The minimal fix is:

1. Add `isMusicRunning()` guards to read-only queries - this is likely enough to stop the multi-second UI block on launch.
2. Stop querying Music synchronously during startup.
3. Move MusicBridge queries off the main thread.
4. Keep explicit user actions capable of launching Music.
5. Keep position polling only while Music is actively running.

The investigation confirms that the original theories were correct, but the largest contributor is specifically the first synchronous `getPlayerPosition()` call during startup, not the timer.
