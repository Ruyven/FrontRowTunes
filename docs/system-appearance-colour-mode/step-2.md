# Implementation Plan: Step 2 — Detect and Observe the macOS System Appearance

## Objective

Implement detection of the current macOS appearance and observe changes to it to support the `System` appearance mode.

## 1. System Appearance Detection Logic

Add a helper method to `SongView.m` (or a utility in Swift) to determine the current system appearance.

### Method in SongView.m

```objc
- (EffectiveAppearance)currentSystemAppearance {
    if (@available(macOS 10.14, *)) {
        NSAppearanceName appearance = [self.effectiveAppearance bestMatchFromAppearances:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
        if ([appearance isEqualToString:NSAppearanceNameDarkAqua]) {
            return EffectiveAppearanceDark;
        }
    }
    return EffectiveAppearanceLight;
}
```

## 2. Update Effective Appearance Calculation

Update `- (void)updateEffectiveAppearance` in `SongView.m` to use the system appearance when the selected mode is `system`.

```objc
- (void)updateEffectiveAppearance {
    EffectiveAppearance newEffectiveAppearance;
    
    switch (selectedAppearanceMode) {
        case AppearanceModeLight:
            newEffectiveAppearance = EffectiveAppearanceLight;
            break;
        case AppearanceModeDark:
            newEffectiveAppearance = EffectiveAppearanceDark;
            break;
        case AppearanceModeSystem:
            newEffectiveAppearance = [self currentSystemAppearance];
            break;
    }
    
    if (effectiveAppearance != newEffectiveAppearance) {
        effectiveAppearance = newEffectiveAppearance;
        [self applyAppearanceChanges]; // Helper to update layers/colors
    }
}
```

## 3. Observe System Appearance Changes

Override `viewDidChangeEffectiveAppearance` in `SongView.m` to respond to system-wide appearance changes.

```objc
- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    
    // Only update if we are in System mode
    if (selectedAppearanceMode == AppearanceModeSystem) {
        [self updateEffectiveAppearance];
    }
}
```

## 4. Initial Appearance Setup

Ensure that `updateEffectiveAppearance` is called during initialization (e.g., in `awakeFromNib` or `viewDidMoveToWindow`) to set the correct initial state when the app starts in `System` mode.

## Verification Plan

- [ ] Set macOS appearance to Light.
- [ ] Launch the app (it should default to System mode).
- [ ] Verify the app appears in Light mode.
- [ ] Change macOS appearance to Dark in System Settings.
- [ ] Verify the app immediately switches to Dark mode.
- [ ] Switch the app to manual Light mode (pressing `W`).
- [ ] Change macOS appearance to Light/Dark.
- [ ] Verify the app remains in Light mode.
- [ ] Switch the app back to System mode (not yet possible via hotkey, but can be tested by restarting after deleting the preference or manually setting it).
