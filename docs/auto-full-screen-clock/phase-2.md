# Phase 2: Enable Screensaver Without Music Playback - Implementation Plan

This document outlines the implementation plan for Phase 2 of the **Auto-Full-Screen Clock** feature. The goal is to allow the screensaver (macOS full-screen mode) to activate automatically even when music is not playing, provided the full-screen clock display mode is active.

---

## 1. Codebase Analysis Summary

### Current Activation Logic
In `SongView.m`, the inactivity timeout handler is currently restricted to music playback:

```objc
- (void)handleEventTimeout {
    if ([MusicBridge getPlayerState] == MusicBridge.PLAYER_STATE_PLAYING) {
        if ([self isWindowFullScreen]) {
            // ... (focus app)
        } else {
            [self.window toggleFullScreen:self];
        }
    }
}
```

### State Variables
The full-screen clock display mode is tracked by the `analogClockFullScreen` boolean in `SongView.m`. This mode is toggled by the user (typically via `Option+t`).

### Shared vs Independent Delays
Phase 1 introduced `musicScreensaverDelay`. Per requirements, Phase 2 introduces a **distinct** key `clockScreensaverDelay` for the full-screen clock activation condition. 

This allows users to have different idle times for music playback (where they might want a longer delay to see metadata) vs the clock (where they might want a faster transition to full-screen).

---

## 2. Implementation Step-by-Step

### Step 2.1: Define New Key & Default
In `SongView.m`, add the new key and its default value:

```objc
static NSString * const kClockScreensaverDelayKey = @"clockScreensaverDelay";
static const NSTimeInterval kDefaultClockScreensaverDelay = 60.0;
```

### Step 2.2: Register the Default Setting
In `SongView.m` inside `awakeFromNib`, add `kClockScreensaverDelayKey` to the registered defaults dictionary.

### Step 2.3: Update Tracker Management (Choose an Option)

There are three architectural approaches to managing independent timeouts. **Option A is recommended** for its simplicity and alignment with the existing codebase.

#### Option A: Two Trackers (Recommended)
Use two separate trackers, one for each condition. This allows for clean, independent timeout logic.

**Implementation Details:**
1. **Rename** `systemInactivityTracker` to `musicInactivityTracker` throughout `SongView.m`.
2. Add `LastEventTracker *clockInactivityTracker;` to the class extension.
3. Initialize `musicInactivityTracker` using `kMusicScreensaverDelayKey`.
4. Initialize `clockInactivityTracker` using `kClockScreensaverDelayKey`.
5. Update `lastEventTracker:timeoutPassed:` to handle both:

```objc
- (void)lastEventTracker:(LastEventTracker *)lastEventTracker timeoutPassed:(NSTimeInterval)timeoutPassed {
    if (lastEventTracker == musicInactivityTracker) {
        [self handleMusicInactivityTimeout];
    } else if (lastEventTracker == clockInactivityTracker) {
        [self handleClockInactivityTimeout];
    } else if (lastEventTracker == mouseHideTracker) {
        [self handleMouseInactivity];
    }
}
```

#### Option B: Single Tracker with Dynamic Reconfiguration
Continue using a single tracker but update its `timeout` whenever state changes (music start/stop or clock toggle).

**Implementation Details:**
1. Maintain `systemInactivityTracker`.
2. Create a method `updateScreensaverTimeout` that calculates the effective timeout (likely `min(musicDelay, clockDelay)` if both are active).
3. Call this method whenever `analogClockFullScreen` or player state changes.
4. **Drawback:** Reseting the timeout on state change can "reset the clock" on user idle time, leading to inconsistent behavior.

#### Option C: Manual Polling in Update Timer
Skip the `LastEventTracker` objects for screensaver logic and check system idle time manually within the existing `updatePlayerPositionTimer` (0.5s interval).

**Implementation Details:**
1. In `updatePlayerPosition`, query `CGEventSourceSecondsSinceLastEventType`.
2. Compare against both preference keys and their respective state conditions.
3. **Drawback:** Couples screensaver logic into the UI/Position update loop.

---

### Step 2.4: Update Activation Logic (for Option A)
Modify the delegate method to handle the specific tracker that timed out:

```objc
- (void)handleMusicInactivityTimeout {
    if ([MusicBridge getPlayerState] == MusicBridge.PLAYER_STATE_PLAYING) {
        [self enterScreensaverIfRequired];
    }
}

- (void)handleClockInactivityTimeout {
    if (analogClockFullScreen) {
        [self enterScreensaverIfRequired];
    }
}

- (void)enterScreensaverIfRequired {
    if ([self isWindowFullScreen]) {
        if (![NSApp isActive]) {
            [NSApp activateIgnoringOtherApps:true];
            [self.window makeKeyAndOrderFront:self];
        }
    } else {
        [self.window toggleFullScreen:self];
    }
}
```

---

## 3. Manual Verification & Testing Strategy

### Test Scenario 1: Independent Delays
1. Set music delay to 10s and clock delay to 5s:
   ```bash
   defaults write com.ruyven.FrontRowTunes musicScreensaverDelay -float 10.0
   defaults write com.ruyven.FrontRowTunes clockScreensaverDelay -float 5.0
   ```
2. Enable Full-screen Analog Clock (music stopped).
3. **Expected Result:** Enters full-screen after 5s.
4. Disable Full-screen Analog Clock and Play music.
5. **Expected Result:** Enters full-screen after 10s.

### Test Scenario 2: Clock Only Activation
1. Ensure music is **stopped** in Apple Music.
2. Launch FrontRowTunes.
3. Press `Option+t` to enter "Full-screen Analog Clock" mode.
4. Set the clock delay to a short value:
   ```bash
   defaults write com.ruyven.FrontRowTunes clockScreensaverDelay -float 5.0
   ```
5. Let the app sit idle for 5 seconds.
6. **Expected Result:** The window automatically enters macOS full-screen mode.

### Test Scenario 3: Neither Condition Met
1. Ensure music is **stopped**.
2. Ensure Full-screen Analog Clock is **disabled**.
3. Let the app sit idle.
4. **Expected Result:** The window does **NOT** enter full-screen mode.

### Test Scenario 4: Disabled Delay
1. Set `musicScreensaverDelay` to `0`.
2. Set `clockScreensaverDelay` to `0`.
3. Enable Full-screen Analog Clock and play music.
4. **Expected Result:** The window does **NOT** enter full-screen mode under any condition.


