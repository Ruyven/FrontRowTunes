# Full-Screen Analog Clock Scope

## Summary

Add a full-screen analog clock presentation mode that reuses the existing `AnalogClockLayer` owned by `SongView`. The feature should make the clock the primary view, hide the song presentation while active, and restore the prior clock/song display state when dismissed.

The app already has two separate ideas of "full screen":

- macOS window full-screen mode, currently toggled with `f`.
- Clock visibility/style, currently controlled with `t` and `T`.

This feature should add a new clock style: full-screen analog clock. It should work whether or not the window is already in macOS full-screen.

## Invocation

Recommended option: use `Option+t` to toggle the full-screen analog clock.

Rationale:

- Lowercase `f` should remain dedicated to macOS window full-screen.
- A full-screen clock is a clock style, not a separate app/window command.
- Uppercase `T` can continue to hide/show the clock family without changing the selected style.
- The command should be discoverable from the app's info modal.

Invocation options:

1. `Option+t`, recommended.
   - Keep lowercase `t`'s current cycle unchanged and use Option-modified `t` for the full-screen clock.
   - Pros: avoids lengthening the existing cycle; keeps the feature clearly grouped with clock controls; easier to describe in the info modal.
   - Cons: modifier shortcuts are a bit less immediate than plain single-key toggles.

2. `t` cycle style.
   - Add full-screen analog clock to the existing lowercase `t` cycle.
   - Pros: matches the existing mental model; no modifier needed; treats full-screen clock as a clock style.
   - Cons: adds one more step to the clock cycle.

3. Long-press `t`.
   - Short press keeps the existing `t` cycle; holding `t` enters or exits full-screen analog clock.
   - Pros: keeps the existing cycle length; still groups the feature under clock controls.
   - Cons: more complex to implement reliably in `keyDown:`/repeat handling; less discoverable.

4. Uppercase `T`.
   - Repurpose `T` from hide/show clock to full-screen analog clock toggle.
   - Pros: easy to implement; related to the existing clock key.
   - Cons: removes the current separate clock visibility toggle, so existing behavior changes more sharply.

5. `c`.
   - Add a dedicated clock-presentation toggle key.
   - Pros: simple and explicit; does not lengthen the `t` cycle.
   - Cons: introduces a new command instead of extending the current clock controls.

Recommended keyboard behavior:

- `Option+t`: toggle full-screen analog clock.
- `t`: cycle through clock styles.
- `T`: keep the current clock visibility toggle behavior. If it hides the clock while full-screen analog clock is active, the song presentation should be restored.
- `f`: continue toggling macOS window full-screen only.
- `Esc`: keep the current behavior of exiting macOS window full-screen. It should not be required to exit full-screen analog clock style because `t` owns the clock-style cycle.
- `w` and `b`: keep working while the full-screen clock is active, updating the clock's dark mode and root background.
- Number keys for screen movement should continue working; clock layout should recalculate after the window/view size changes.

With the recommendation, the lowercase `t` cycle should be unchanged.

The rest of this scope assumes option 1, `Option+t`.

## Implementation Plan

Keep the implementation inside `SongView` and the existing `AnalogClockLayer`. Do not create a second clock layer, a new clock view, or a separate window.

Add state to `SongView`:

- `BOOL analogClockFullScreen`

Entering full-screen analog clock style should:

- Set `displayClock = YES`, `analogClock = YES`, and keep `clockSeconds` on current style.
- Call `setUpAnalogClockIfNeeded` so the existing `clock` layer is created only if needed.
- Hide the song presentation by fading `activeSongLayer.opacity` to `0`.
- Set `activeSongLayer.displayClock = NO` so the digital clock does not draw behind the analog clock.
- Reposition and scale the existing `clock` layer to the center of `SongView`.

Cycling through options via `t` while full-screen clock is active should:

- Show/hide the second hand

Leaving full-screen analog clock style should:

- Set `analogClockFullScreen = NO`.
- Move the analog clock back to the corner
- Restore `activeSongLayer.opacity` to `1`.
- Call `removeAnalogClock` because the next style is digital.
- Call `updateClock`, `updateClockColorWithDuration:`, and `updateWithDuration:` as needed so the display settles consistently.

When uppercase `T` hides the clock while `analogClockFullScreen` is active:

- Set `analogClockFullScreen = NO`.
- Restore `activeSongLayer.opacity` to `1`.
- Remove the analog clock layer.
- Leave the selected clock-style flags ready for the next `T` or `t` action.

Refactor analog clock layout into one method:

```objc
- (void)updateAnalogClockLayoutWithDuration:(NSTimeInterval)duration;
```

That method should handle both layouts:

- Compact mode:
  - Anchor point: `(1, 1)`
  - Position: top-right with the existing 16-point inset
  - Scale: preserve the current formula based on view height
  - Autoresizing mask: `kCALayerMinXMargin | kCALayerMinYMargin`
  - z-position: above `activeSongLayer`, but normal

- Full-screen clock mode:
  - Anchor point: `(0.5, 0.5)`
  - Position: center of `self.bounds`
  - Scale: fit the clock diameter within about 82% of the shorter view dimension
  - Autoresizing mask: none; rely on `setFrame:` calling the layout method
  - z-position: high enough to stay above song transition layers

Use this scale formula for full-screen mode:

```objc
CGFloat availableDiameter = MIN(self.bounds.size.width, self.bounds.size.height) * 0.82;
CGFloat clockScale = availableDiameter / (2 * [AnalogClockLayer radius]);
```

Update existing methods:

- `setUpAnalogClockIfNeeded` should only create/configure/add the layer, then call `updateAnalogClockLayoutWithDuration:0`.
- `removeAnalogClock` should remain the single cleanup point.
- `setFrame:` should call `updateAnalogClockLayoutWithDuration:0` instead of only updating scale.
- `updateClockScale` can either be replaced by `updateAnalogClockLayoutWithDuration:` or retained as a compact-layout helper.
- Track changes should continue calling `updateClockColor`; the full-screen clock should use the same tint-color behavior as the compact analog clock.

## Edge Cases

- `option`+`t` should always display the full-screen analog clock, whether the current clock is hidden, analog or digital.
- If current clock is visible (either analog or digital) without seconds, the full-screen analog clock should not have a second hand.
- If uppercase `T` hides the clock while full-screen analog clock is visible, the song presentation should return immediately.
- If uppercase `T` shows the clock again after hiding it from full-screen analog clock, it should restore the selected clock family without leaving the song presentation hidden.
- If Music changes track while the full-screen clock is active, the clock tint should update without revealing the song layer.
- If the window changes screen or size, the full-screen clock should remain centered and fitted.
- The inactivity behavior should remain unchanged: it may enter macOS window full-screen, but it should not automatically enable full-screen analog clock mode.

## Test Plan

Manual verification:

- Start the app with the default display; press `option`+`t`; verify the analog clock fills the view and song details fade out.
- Press `t` to cycle through clock styles; press `option`+`t` on each style; verify the analog clock fills the view and the second hand is shown/hidden as expected.
- Press `T` while full-screen analog clock is active; verify the clock hides and song details return.
- Press `T` again after hiding full-screen analog clock; verify expected behaviour.
- Press `Esc` while full-screen analog clock is active and the app is in macOS full-screen; verify the window fullscreen behavior is unchanged.
- Press lowercase `f`; verify macOS window full-screen behavior is unchanged.
- While full-screen analog clock is active, press `w` and `b`; verify foreground/background colors and hand colors update.
- While full-screen analog clock is active, change tracks in Music; verify the tint changes and song layers remain hidden.
- Move the window between screens or resize it; verify the clock remains centered and fitted.

Build verification:

- Build the Xcode target after implementation.
- Confirm there are no new tracked Xcode user-state files.

## Optional Goal - Out of Scope

Implement a separate, lower-priority feature that shows the currently playing track along the bottom of the screen, or nothing if nothing is playing.

Scope for the optional goal:

- Reuse the existing track metadata source already used by `SongLayer`.
- Keep it visually lightweight and secondary to the current song/clock presentation.
- Hide the strip completely when there is no current track.
- Treat this as a separate implementation from the full-screen clock work so the two features can be reviewed independently.
