# Implementation Plan: Step 3 — Add the `S` Hotkey for System Mode

## Objective

Add a new keyboard shortcut `S` to select the System appearance mode.

## 1. Update Hotkey Handling in SongView

Modify the `keyDown:` method in `SongView.m` to detect the `S` key.

### Changes in SongView.m

```objc
- (void)keyDown:(NSEvent *)event {
    NSString *character = [event charactersIgnoringModifiers];
    // ... existing logic ...
    
    } else if ([character isEqualToString:@"w"]) {
        [self setAppearanceMode:AppearanceModeLight];
    } else if ([character isEqualToString:@"b"]) {
        [self setAppearanceMode:AppearanceModeDark];
    } else if ([character isEqualToString:@"s"]) {
        [self setAppearanceMode:AppearanceModeSystem];
    }
    
    // ... existing logic ...
}
```

## 2. Verify Immediate Effect

When the `S` hotkey is pressed, the app should:
1. Update `selectedAppearanceMode` to `AppearanceModeSystem`.
2. Save the change to `NSUserDefaults`.
3. Re-calculate the `effectiveAppearance` based on the current system appearance.
4. Update the UI if the `effectiveAppearance` changed.

This behavior is already handled by the `setAppearanceMode:writeDefaults:` and `updateEffectiveAppearance` methods designed in Step 1 and Step 2.

## Verification Plan

- [ ] Launch the app.
- [ ] Press `W` -> verify Light mode.
- [ ] Press `B` -> verify Dark mode.
- [ ] Set macOS appearance to Dark.
- [ ] Press `S` -> verify the app immediately switches to Dark mode.
- [ ] Change macOS appearance to Light.
- [ ] Verify the app switches to Light mode automatically.
- [ ] Press `B` -> verify the app switches to Dark mode and stops following system changes.
- [ ] Press `S` -> verify the app resumes following system changes (switches to Light).
