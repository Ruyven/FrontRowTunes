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

### Preserve Explicit User Actions

Do not guard:

- play/pause
- next track
- previous track

These are intentional user commands and should be allowed to launch Music.app.

---

# Future phases coming in a separate PR:

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

## Phase 3: Optimise UI/UX

**Problem:** Once initialisation on launch happens asynchronously, the app appears before it knows the Music state.

**Goal:** Improve the loading state before the playing track is displayed.

### Phase 3.1: Loading screen

Instead of simply displaying "Playback stopped", show a SongLayer with:

- Cover art: FrontRowTunes logo - already used as a fallback
- Title: FrontRowTunes (in place of track name)

Show this at app launch and if the app detects that playback is stopped.

When a track starts being detected, run the normal "next track" animation to its SongLayer.

### Phase 3.2: Specify status

As subtitle (in place of artist name), the new loading screen should specify one of these statuses:

- Initialising
- Music not running
- Launching Music - if Music is known to not be running, show this after performing an action known to launch it (play/pause, next track, previous track)
- Playback stopped

### Phase 3.3: Optimise transitions

When transitioning between loading screens, or from the Initialising loading screen straight to a track, do not run the "next track" animation. Instead, try a very short cross-fade.

Transitions to be reviewed - if the cross-fade is distracting for some of these transitions, we can transition immediately.

### Phase 3.4: Avoid blocking UI

Run all actions that may launch the Music app in a background thread, similar to phase 2.

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

The investigation confirms that the original theories were correct, but the largest contributor is specifically the first synchronous `getPlayerPosition()` call during startup, not the timer.
