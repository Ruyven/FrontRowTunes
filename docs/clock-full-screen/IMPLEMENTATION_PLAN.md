# Implementation Plan - Full-Screen Analog Clock

This document details the step-by-step implementation plan for adding the full-screen analog clock presentation mode. Each step is designed to be independently buildable and testable, minimizing risky dependencies.

---

## Phase 1: Extend `AnalogClockLayer` with Second Hand Toggle

### Step 1.1: Add `@objc var showSeconds` property to `AnalogClockLayer.swift`
- **Goal**: Expose a property to dynamically show or hide the second hand and its accompanying hinge elements.
- **Changes**:
  - Add `@objc var showSeconds: Bool = true` inside `AnalogClockLayer.swift`.
  - Implement a `didSet` block that toggles the `isHidden` property of `secondHand`, `secondHingeOuter`, `secondHingeInner`, and `secondHingeBackground` layers.
- **Verification**:
  - Build the Swift target to ensure no compile errors.

---

## Phase 2: Refactor Analog Clock Layout

### Step 2.1: Implement `-updateAnalogClockLayoutWithDuration:` in `SongView.m`
- **Goal**: Consolidate and centralize layout mathematics for both compact (corner) and full-screen modes.
- **Changes**:
  - Implement the following method in `SongView.m`:
    ```objc
    - (void)updateAnalogClockLayoutWithDuration:(NSTimeInterval)duration;
    ```
  - **Compact Mode Layout** (when `analogClockFullScreen == NO`):
    - Anchor point: `(1.0, 1.0)`
    - Position: top-right with 16pt inset (`self.bounds.size.width - 16`, `self.bounds.size.height - 16`)
    - Autoresizing mask: `kCALayerMinXMargin | kCALayerMinYMargin`
    - zPosition: `0` (normal)
    - Scale formula: `self.bounds.size.height * 0.05 / [AnalogClockLayer radius]`
  - **Full-Screen Mode Layout** (when `analogClockFullScreen == YES`):
    - Anchor point: `(0.5, 0.5)`
    - Position: center of `self.bounds` (`self.bounds.size.width / 2.0`, `self.bounds.size.height / 2.0`)
    - Autoresizing mask: `0` (none; relies on `setFrame:` layout updates)
    - zPosition: `100` (above song layers and transition layers)
    - Scale formula: `(MIN(self.bounds.size.width, self.bounds.size.height) * 0.82) / (2 * [AnalogClockLayer radius])`
  - Wrap the property modifications in a `CATransaction` block to set `animationDuration` or `disableActions` based on the `duration` parameter.
- **Verification**:
  - Build project. Confirm that compact clock displays and behaves exactly as before.

### Step 2.2: Update `setUpAnalogClockIfNeeded` and `setFrame:` to Use the New Layout Refactor
- **Goal**: Integrate the new layout method into standard lifecycle and resize events.
- **Changes**:
  - In `setUpAnalogClockIfNeeded`:
    - Remove duplicate positioning, anchor point, and autoresizing mask setups.
    - Set the new `showSeconds` property on `clock` using `clockSeconds`.
    - Call `[self updateAnalogClockLayoutWithDuration:0]`.
  - In `setFrame:`:
    - Replace `[self updateClockScale]` with `[self updateAnalogClockLayoutWithDuration:0]`.
- **Verification**:
  - Build and run the app. Confirm the compact corner clock still scales perfectly when resizing the window.

---

## Phase 3: Add Full-Screen State and Keyboard Handling

### Step 3.1: Add State Variables to `SongView`
- **Goal**: Introduce state tracking for full-screen mode and prior state preservation.
- **Changes**:
  - In `SongView.m` instance variable declarations (inside the `@implementation SongView` block), add:
    ```objc
    BOOL analogClockFullScreen;
    BOOL priorDisplayClock;
    BOOL priorAnalogClock;
    BOOL priorClockSeconds;
    ```
- **Verification**:
  - Build project to verify variables compile correctly.

### Step 3.2: Implement `-toggleAnalogClockFullScreen` in `SongView.m`
- **Goal**: Handle transitions between the full-screen mode and prior display modes.
- **Changes**:
  - Define `- (void)toggleAnalogClockFullScreen;` in `SongView.m`.
  - **Entering Full-Screen**:
    - Store the current state in prior state variables:
      ```objc
      priorDisplayClock = displayClock;
      priorAnalogClock = analogClock;
      priorClockSeconds = clockSeconds;
      ```
    - Force state to: `analogClockFullScreen = YES; displayClock = YES; analogClock = YES;`.
    - Ensure clock exists by calling `[self setUpAnalogClockIfNeeded]`.
    - Set `clock.showSeconds = clockSeconds;` on the active clock layer.
    - Hide song presentation: animate `activeSongLayer.opacity` to `0` with duration `0.5`.
    - Disable the digital clock drawing behind: set `activeSongLayer.displayClock = NO`.
    - Animate analog clock transition: call `[self updateAnalogClockLayoutWithDuration:0.5]`.
  - **Leaving Full-Screen**:
    - Set `analogClockFullScreen = NO;`.
    - Restore the state variables from prior state:
      ```objc
      displayClock = priorDisplayClock;
      analogClock = priorAnalogClock;
      clockSeconds = priorClockSeconds;
      ```
    - Sync restored properties to `activeSongLayer`:
      ```objc
      activeSongLayer.displayClock = displayClock && !analogClock;
      activeSongLayer.clockSeconds = clockSeconds;
      ```
    - Handle clock layer restoration:
      - If restored state is analog clock + visible, transition layout back to corner with `[self updateAnalogClockLayoutWithDuration:0.5]`, and set `clock.showSeconds = clockSeconds;`.
      - Otherwise, call `[self removeAnalogClock]`.
    - Restore song presentation: animate `activeSongLayer.opacity` to `1` with duration `0.5`.
    - Call standard update methods to synchronize display state:
      ```objc
      [activeSongLayer updateClock];
      [self updateClockColorWithDuration:0.5];
      [activeSongLayer updateWithDuration:0.5];
      ```
- **Verification**:
  - Build project successfully.

### Step 3.3: Bind Keyboard Trigger `Option+t` in `keyDown:`
- **Goal**: Intercept keypresses to trigger the full-screen clock mode.
- **Changes**:
  - Update `keyDown:` in `SongView.m` to detect `t` ignoring modifier keys, then inspect for the Option/Alt modifier flag:
    ```objc
    NSString *charactersIgnoringModifiers = [event charactersIgnoringModifiers];
    NSEventModifierFlags modifierFlags = [event modifierFlags];
    
    if ([charactersIgnoringModifiers isEqualToString:@"t"] || [charactersIgnoringModifiers isEqualToString:@"T"]) {
        if ((modifierFlags & NSEventModifierFlagOption) != 0) {
            [self toggleAnalogClockFullScreen];
        } else if ([character isEqualToString:@"T"]) {
            // Existing T handling...
        } else if ([character isEqualToString:@"t"]) {
            // Existing t handling...
        }
    }
    ```
- **Verification**:
  - Press `Option+t` with clock visible or hidden. Verify the screen transitions smoothly into the full-screen analog clock, and song elements fade out.
  - Press `Option+t` again to restore the prior state perfectly.

---

## Phase 4: Handle Key and State Edge Cases

### Step 4.1: Intercept `t` Cycle while in Full-Screen Mode
- **Goal**: Enable simple second hand toggling via `t` when full-screen is active instead of transitioning the layout back to digital/hidden.
- **Changes**:
  - In `keyDown:`, inside the `[character isEqualToString:@"t"]` block:
    ```objc
    if (analogClockFullScreen) {
        clockSeconds = !clockSeconds;
        if (clock) {
            clock.showSeconds = clockSeconds;
        }
        activeSongLayer.clockSeconds = clockSeconds;
    } else {
        // Existing t cycle code...
    }
    ```
- **Verification**:
  - Enter full-screen clock. Press `t` to toggle the second hand on and off. Exit full-screen clock and ensure normal clock style cycles work correctly.

### Step 4.2: Intercept `T` Clock Toggle when in Full-Screen Mode
- **Goal**: Restoring song presentation immediately if uppercase `T` is used to hide the clock while full-screen is active.
- **Changes**:
  - In `keyDown:`, inside the `[character isEqualToString:@"T"]` block:
    ```objc
    displayClock = !displayClock;
    if (!displayClock) {
        if (analogClockFullScreen) {
            analogClockFullScreen = NO;
            activeSongLayer.opacity = 1;
        }
        [self removeAnalogClock];
    } else if (analogClock) {
        [self setUpAnalogClockIfNeeded];
    }
    activeSongLayer.displayClock = displayClock && !analogClock;
    [activeSongLayer updateClock];
    [activeSongLayer updateWithDuration:.5];
    ```
- **Verification**:
  - Enter full-screen clock. Press `T`. Verify the clock is instantly removed and song details fade back into view. Press `T` again and verify song details stay active and normal clock restores to the corner.

### Step 4.3: Prevent Auto-Fade-In on Track Change in `activateNewLayer`
- **Goal**: Prevent the app from showing song layers if the track changes while full-screen clock is active.
- **Changes**:
  - In `activateNewLayer` in `SongView.m`:
    ```objc
    - (void)activateNewLayer {
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [CATransaction setValue:@0.5f forKey:kCATransactionAnimationDuration];
        if (analogClockFullScreen) {
            activeSongLayer.opacity = 0;
        } else {
            activeSongLayer.opacity = 1;
        }
        [activeSongLayer setAffineTransform:CGAffineTransformMake(1, 0, 0, 1, 0, 0)];
        
        allowScreenChange = YES;
    }
    ```
- **Verification**:
  - Enter full-screen clock. Let the track transition or change it in Apple Music. Verify the clock tint changes seamlessly, but the song details layer remains hidden.

### Step 4.4: Fix Analog Clock Animation Path (Enter Full-Screen)
- **Goal**: Ensure the clock animates from the top-right corner to the center, rather than appearing to move from the bottom-left.
- **Changes**:
  - In `updateAnalogClockLayoutWithDuration:`, when transitioning to full-screen, the anchor point change from `(1.0, 1.0)` to `(0.5, 0.5)` causes a jump in position.
  - To fix this, update the `position` property relative to the new anchor point immediately before the animation begins, or use a `CATransaction` to coordinate the anchor point and position change so they offset each other.
- **Verification**:
  - Trigger full-screen mode; verify the clock slides from the top-right corner to the center of the screen.

### Step 4.5: Fix Analog Clock Animation Path (Exit Full-Screen)
- **Goal**: Ensure the clock animates from the center back to the top-right corner.
- **Changes**:
  - Similarly to Step 4.4, ensure the transition of the anchor point from `(0.5, 0.5)` back to `(1.0, 1.0)` is offset by a corresponding change in `position` so the animation path is a direct line from center to corner.
- **Verification**:
  - Exit full-screen mode; verify the clock slides from the center back to the top-right corner.

### Step 4.6: Preserve Center Circle when Seconds are Hidden
- **Goal**: Keep the central white decorative circle visible even when the second hand is hidden.
- **Changes**:
  - In `AnalogClockLayer.swift`, update the `didSet` for `showSeconds`.
  - Ensure that the `secondHingeBackground` (or the specific layer responsible for the center white circle) is NOT hidden when `showSeconds` is false.
- **Verification**:
  - Cycle through clock styles to hide the second hand; verify that the white center circle remains visible while the second hand itself is hidden.

### (Superseded) Step 4.7: Fix Full-Screen Clock Fitting in Windowed Mode
**Works now!**

- **Goal**: Ensure the full-screen analog clock correctly fits and centers within the window when the app is not in macOS native full-screen mode.
- **Changes**:
  - Review `updateAnalogClockLayoutWithDuration:` in `SongView.m`.
  - Verify that `self.bounds` is providing the correct dimensions for the scale calculation in windowed mode.
  - Ensure that the clock is centered and scaled based on the actual current window size, handling arbitrary aspect ratios.
- **Verification**:
  - Run the app in windowed mode.
  - Toggle the full-screen analog clock and verify it fits perfectly within the window.
  - Resize the window while the full-screen clock is active and verify it remains centered and fits the shorter dimension of the window.

---

## Phase 5: Update Compact Mode Clock Cycle

### Step 5.1: Expand `t` Cycle to include Analog without Seconds
- **Goal**: Update the clock style rotation to follow: Analog (w/ Sec) -> Analog (w/o Sec) -> Digital (w/o Sec) -> Digital (w/ Sec) -> Analog (w/ Sec).
- **Changes**:
  - In `keyDown:`, update the `[character isEqualToString:@"t"]` block (when `analogClockFullScreen` is false) to implement the new rotation logic:
    - If `analogClock == YES` and `clockSeconds == YES`:
      Set `clockSeconds = NO`. (Analog, no seconds).
    - Else if `analogClock == YES` and `clockSeconds == NO`:
      Set `analogClock = NO`, `clockSeconds = NO`. (Digital, no seconds).
    - Else if `analogClock == NO` and `clockSeconds == NO`:
      Set `clockSeconds = YES`. (Digital, with seconds).
    - Else (`analogClock == NO` and `clockSeconds == YES`):
      Set `analogClock = YES`, `clockSeconds = YES`. (Analog, with seconds).
  - Ensure `[self setUpAnalogClockIfNeeded]` is called when transitioning back to analog.
  - Ensure `[self removeAnalogClock]` is called when transitioning to digital.
- **Verification**:
  - Run the app in compact mode. Press `t` repeatedly and verify the exact sequence: Analog-with-sec -> Analog-without-sec -> Digital-without-sec -> Digital-with-sec -> repeat.

---

## Phase 6: Optional Goal - Track Banner (Isolated Feature)

**Moved to PR #6** (`feat/clock-full-screen-track-with-album-art`)

### Step 6.1: Implement a Lightweight Bottom-Screen Track Overlay
- **Goal**: Show basic playing track information in an unobtrusive bottom-screen strip.
- **Changes**:
  - Define `CATextLayer *trackBannerLayer` in `SongView.m`.
  - Add logic in `-setTrack:prev:` to update `trackBannerLayer`'s text content.
  - Position `trackBannerLayer` centered near the bottom edge of `rootLayer`.
  - Hide and set opacity of `trackBannerLayer` to `1` only when `analogClockFullScreen` is active and a track is playing, otherwise set its opacity to `0`.
- **Verification**:
  - Enter full-screen clock and verify playing song is minimally displayed at the bottom of the screen.

---

## Phase 7: Finalise new version

### Step 7.1: Update Info panel to include correct hotkeys
- **Goal**: Update the `Shortcut Keys` section in the `MainMenu.xib` info panel to accurately reflect the revised hotkeys, using the established tabbed formatting.
- **Changes**:
  - Open `English.lproj/MainMenu.xib` in Xcode.
  - Locate the `About FrontRowTunes / Shortcut Keys` panel (ID `536`).
  - Update the text in the `textField` (ID `540`, cell `541`) to the following:
    ```
    FrontRowTunes {{appVersion}}
    Copyright © 2013-2026 by Alex Decker. All rights reserved.
    Shortcut Keys:
    	w			white background
    	b			black background
    	f			full screen
    	1,2,…		show maximized on different screens
    	←, →		switch track
    	space		play/pause
    	t			cycle clock styles
    	T			toggle clock visibility
    	Option+t	toggle full-screen clock
    	↵			toggle display track position as m:ss
    	fn+↵		toggle display track position bar
    	i, h		toggle display this info panel
    	q			quit
    ```
- **Verification**:
  - Run the app, press `i` (or `h`), and verify that the Shortcut Keys section correctly lists `Option+t` and has updated, correctly formatted descriptions for `t` and `T`.

### Step 7.2: Update version to 0.4.0 ahead of merging
