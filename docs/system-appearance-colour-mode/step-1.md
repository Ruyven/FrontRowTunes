# Implementation Plan: Step 1 — Replace the current white-background Boolean with an Appearance Mode Enum

## Objective

Replace the existing `whiteBackground` Boolean state with an enum representing all three appearance modes: Light, Dark, and System. This step focuses on the architectural refactor and rendering logic.

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

### State Refactor
- **SongView.h/m**:
    - Replace the `BOOL whiteBackground` instance variable with:
        - `AppearanceMode selectedAppearanceMode`
        - `EffectiveAppearance effectiveAppearance`
    - Rename/Update methods:
        - `- (void)setAppearanceMode:(AppearanceMode)mode;`
        - `- (void)updateEffectiveAppearance;`

### Initialization and Logic
- In `awakeFromNib` (or `setupLayers`):
    - Initialize `selectedAppearanceMode` to `AppearanceModeSystem` in memory only (hardcoded for this step; persistence will be added in Step 3).
    - Call `updateEffectiveAppearance`.
- Implementation of `updateEffectiveAppearance`:
    - If `selectedAppearanceMode` is `light` -> `effectiveAppearance = light`.
    - If `selectedAppearanceMode` is `dark` -> `effectiveAppearance = dark`.
    - If `selectedAppearanceMode` is `system` -> fallback to `dark` for now (full system detection is Step 2).
- Implementation of `setAppearanceMode:`:
    - Update `selectedAppearanceMode`.
    - Call `updateEffectiveAppearance`.
    - Update `rootLayer.backgroundColor` based on `effectiveAppearance`.
    - Pass `effectiveAppearance` to `activeSongLayer` and `lastSongLayer`.
    - Update `clock.darkMode` and `clock.tintColor` based on `effectiveAppearance`.
- Update `keyDown:`:
    - Map `w` to `[self setAppearanceMode:AppearanceModeLight]`.
    - Map `b` to `[self setAppearanceMode:AppearanceModeDark]`.

## Verification Plan

- [ ] Build and run the app.
- [ ] Verify that the app defaults to Dark mode (as `AppearanceModeSystem` currently fallbacks to Dark).
- [ ] Verify that pressing `W` switches the app to Light mode immediately.
- [ ] Verify that pressing `B` switches the app to Dark mode immediately.
- [ ] **Note:** Step 1 should not read, write, or migrate user defaults. Persistence and migration will be verified in Step 3.
