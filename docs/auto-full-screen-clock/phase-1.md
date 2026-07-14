# Phase 1: Configurable Screensaver Delay - Implementation Plan

This document outlines the implementation plan for Phase 1 of the **Auto-Full-Screen Clock** feature, which makes the screensaver activation delay configurable via user defaults.

---

## 1. Codebase Analysis Summary

Our analysis of the codebase reveals that the auto-screensaver mechanism is implemented in `SongView.m` and `Helpers/LastEventTracker.swift`:

1. **Inactivity Tracking Initialization (`SongView.m`):**
   ```objc
   systemInactivityTracker = [[LastEventTracker alloc] init];
   [systemInactivityTracker setDelegate:self eventType:kCGAnyInputEventType timeout:60];
   ```
   The delay is currently hard-coded to `60` seconds.

2. **Trigger Logic (`SongView.m`):**
   When inactivity reaches the timeout, `LastEventTracker` notifies `SongView` through its delegate method `lastEventTracker:timeoutPassed:`, which calls `handleEventTimeout`.
   ```objc
   - (void)handleEventTimeout {
       if ([MusicBridge getPlayerState] == MusicBridge.PLAYER_STATE_PLAYING) {
           if ([self isWindowFullScreen]) {
               // ...
           } else {
               [self.window toggleFullScreen:self];
           }
       }
   }
   ```

3. **Disabling Behaviour (`Helpers/LastEventTracker.swift`):**
   In `LastEventTracker.swift`, passing a `timeout` of `0` (or less) inherently disables the timer and tracking:
   ```swift
   private func updateLastEventTime() {
       guard timeout > 0 && delegate != nil else {
           waitUntilNextTrigger()
           return
       }
       // ...
   }

   private func waitUntilNextTrigger() {
       if timeout > 0 {
           checkAgainIn(timeout)
       }
   }
   ```
   If `timeout <= 0`, `updateLastEventTime()` simply returns without scheduling any timer or triggering the delegate. Thus, registering/writing `0` as the delay will perfectly disable the screensaver.

---

## 2. Preference Naming Analysis

There is a slight logical contradiction in the naming instructions in `SCOPE.md`:
* Under **Phase 1**, it says: *"Choose a music-specific name, since Phase 2 will implement activation beyond music playback."* with suggested names: `musicScreensaverDelay`, `trackScreensaverDelay`, `playingScreensaverDelay`.
* However, it also says: *"The preference should describe the general screensaver activation behaviour, not its current trigger condition."* and under **Phase 2**, the same delay configuration is shared across both music and full-screen clock conditions, with suggested clock/analog names.

### Recommended Names

To reconcile these requirements:
1. **Option A: `musicScreensaverDelay` (Selected)**
   * **Why:** This is the primary suggestion listed in Phase 1. It clearly describes the behavior of entering screensaver during music playback.
   * **Independence:** Phase 2 will introduce a separate key for non-music scenarios, allowing independent control over the two triggers.

2. **Option B: Generic names like `screensaverDelay`**
   * **Why it was rejected:** To allow independent delays for music playback vs. the full-screen clock (as clarified for Phase 2), distinct names are required. Generic names would imply a single shared delay.

**Decision for Implementation:**
We will implement Option A (`musicScreensaverDelay`) as it is the most prominent recommendation for Phase 1 and avoids system-wide preference collisions. If needed, renaming or expanding this to a generic key can be performed during Phase 2.

---

## 3. Implementation Step-by-Step

### Step 3.1: Define Key & Default Value Constants
In `SongView.m`, declare the user default key and default value constants near the other key definitions (around line 15):

```objc
static NSString * const kMusicScreensaverDelayKey = @"musicScreensaverDelay";
static const NSTimeInterval kDefaultMusicScreensaverDelay = 60.0;
```

### Step 3.2: Register the Default Setting
In `SongView.m` inside `awakeFromNib`, add `kMusicScreensaverDelayKey` to the registered defaults dictionary:

```objc
    // Register default settings
    NSDictionary *defaults = @{
        kDisplayPlayerPositionBarKey: @YES,
        kDisplayPlayerPositionLabelKey: @NO,
        kDisplayClockKey: @NO,
        kClockSecondsKey: @YES,
        kAnalogClockKey: @YES,
        kAnalogClockFullScreenKey: @NO,
        kWhiteBackgroundKey: @NO,
        kMusicScreensaverDelayKey: @(kDefaultMusicScreensaverDelay)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
```

### Step 3.3: Initialize `systemInactivityTracker` using the Registered Preference
In `SongView.m` inside `awakeFromNib`, read the user default value and pass it to the tracker instead of the hard-coded `60`:

```objc
    double delay = [[NSUserDefaults standardUserDefaults] doubleForKey:kMusicScreensaverDelayKey];
    systemInactivityTracker = [[LastEventTracker alloc] init];
    [systemInactivityTracker setDelegate:self eventType:kCGAnyInputEventType timeout:delay];
```

---

## 4. Manual Verification & Testing Strategy

Since there are no automated tests in this Cocoa-based project, verification is performed manually. 

### Test Scenario 1: Default Behavior (Regression Testing)
1. Launch the application with no custom settings written.
2. Start playing music in Apple Music.
3. Ensure no user input is made for 60 seconds.
4. **Expected Result:** The application automatically enters full-screen mode after exactly 60 seconds.

### Test Scenario 2: Configured Active Delay (e.g., 5 seconds)
1. Quit the application.
2. In the Terminal, run:
   ```bash
   defaults write com.ruyven.FrontRowTunes musicScreensaverDelay -float 5.0
   ```
   *(Note: Verify the bundle identifier in the Info.plist if needed)*
3. Launch the application and play a track.
4. Let the app sit idle for 5 seconds.
5. **Expected Result:** The application automatically enters full-screen mode after exactly 5 seconds.

### Test Scenario 3: Disabled Automatic Activation (Value of 0)
1. Quit the application.
2. In the Terminal, run:
   ```bash
   defaults write com.ruyven.FrontRowTunes musicScreensaverDelay -float 0.0
   ```
3. Launch the application and play a track.
4. Let the app sit idle for more than 60 seconds.
5. **Expected Result:** The application does NOT enter full-screen mode automatically.

### Test Scenario 4: Clean-Up
1. Reset the user default after testing to avoid persistent custom behavior:
   ```bash
   defaults delete com.ruyven.FrontRowTunes musicScreensaverDelay
   ```
