# Implementation Plan: Step 1 — Replace the current white-background Boolean with an Appearance Mode Enum

## Objective

Replace the existing `whiteBackground` Boolean state with an enum representing all three appearance modes: Light, Dark, and System.

## 1. Define Enums in Swift

Add the following enums to `Helpers/Constants.swift`. These will be bridged to Objective-C via `FrontRowTunes-Swift.h`.

```swift
@objc public enum AppearanceMode: Int {
    case light = 0
    case dark = 1
    case system = 2
}

@objc public enum EffectiveAppearance: Int {
    case light = 0
    case dark = 1
}
```

## 2. Update Model Layers (SongLayer and CoverLayer)

Replace `BOOL whiteBackground` with `EffectiveAppearance effectiveAppearance` in the rendering layers, as they only need to know whether to draw in Light or Dark mode.

### CoverLayer

- **CoverLayer.h**:
    - Replace `BOOL whiteBackground` with `EffectiveAppearance effectiveAppearance`.
    - Update the property: `@property EffectiveAppearance effectiveAppearance;`.
- **CoverLayer.m**:
    - Update `drawInContext:`:
      ```objc
      double gradientBrightness = (effectiveAppearance == EffectiveAppearanceLight) ? 1.0 : 0.0;
      ```

### SongLayer

- **SongLayer.h**:
    - Replace `BOOL whiteBackground` with `EffectiveAppearance effectiveAppearance`.
    - Update the property: `@property (nonatomic) EffectiveAppearance effectiveAppearance;`.
    - Update the initializer: `- (id)initWithFrame:(CGRect)frame effectiveAppearance:(EffectiveAppearance)appearance;`.
- **SongLayer.m**:
    - Update `@synthesize effectiveAppearance;`.
    - Update the initializer to set the `effectiveAppearance` property and pass it to `coverLayer`.
    - Update `setEffectiveAppearance:` (renamed from `setWhiteBackground:`):
      - Update the mapping of colors (Background, Foreground, etc.) based on `EffectiveAppearanceLight` vs `EffectiveAppearanceDark`.
      - Pass the value down to `coverLayer.effectiveAppearance`.
    - Update `updateWithDuration:` to use `effectiveAppearance` when calculating the tint color for the clock.

## 3. Update SongView (Main Controller View)

- **SongView.h/m**:
    - Define a new constant for the appearance mode key: `static NSString * const kAppearanceModeKey = @"appearanceMode";`.
    - Replace the `BOOL whiteBackground` instance variable with `AppearanceMode selectedAppearanceMode` and `EffectiveAppearance effectiveAppearance`.
    - Rename/Update methods:
        - `- (void)setAppearanceMode:(AppearanceMode)mode writeDefaults:(BOOL)writeDefaults;`
        - `- (void)updateEffectiveAppearance;`
    - In `awakeFromNib`:
        - Register the default for `kAppearanceModeKey` as `AppearanceModeSystem` (2).
        - Implement migration logic: If `kAppearanceModeKey` is not set in `NSUserDefaults`, check the old `kWhiteBackgroundKey`. If it exists, map `YES` to `AppearanceModeLight` and `NO` to `AppearanceModeDark`.
        - Load the initial `selectedAppearanceMode`.
    - Implementation of `updateEffectiveAppearance`:
        - If `selectedAppearanceMode` is `light` -> `effectiveAppearance = light`.
        - If `selectedAppearanceMode` is `dark` -> `effectiveAppearance = dark`.
        - If `selectedAppearanceMode` is `system` -> fallback to `dark` (or perform a static check) for now. **Note:** Full dynamic detection and observation will be implemented in Step 2.
    - Implementation of `setAppearanceMode:writeDefaults:`:
        - Update `selectedAppearanceMode`.
        - Write to `NSUserDefaults` if requested.
        - Call `updateEffectiveAppearance`.
        - Update `rootLayer.backgroundColor` based on `effectiveAppearance`.
        - Pass `effectiveAppearance` to `activeSongLayer` and `lastSongLayer`.
        - Update `clock.darkMode` and `clock.tintColor` based on `effectiveAppearance`.
    - Update `keyDown:`:
        - Map `w` to `[self setAppearanceMode:AppearanceModeLight]`.
        - Map `b` to `[self setAppearanceMode:AppearanceModeDark]`.
    - Update `applyDebouncedUserDefaultsUpdate:` to handle the new `kAppearanceModeKey`.

## Verification Plan

- [ ] Build and run the app.
- [ ] Verify that the app defaults to Dark mode (if `AppearanceModeSystem` fallbacks to Dark).
- [ ] Verify that pressing `W` switches the app to Light mode immediately.
- [ ] Verify that pressing `B` switches the app to Dark mode immediately.
- [ ] Verify that restarting the app persists the manual `Light` or `Dark` selection.
- [ ] Verify that the migration from an old `whiteBackground` boolean works as expected.
