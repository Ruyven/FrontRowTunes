# Implementation Plan: Step 3 — Default Colour Scheme and User Defaults

## Objective

Update the persistence layer to store the appearance mode as an integer enum instead of a boolean, and implement a migration path for existing users.

## 1. Update User Defaults Keys and Registration

In `SongView.m`, define the new key and update the default values registration.

### Changes in SongView.m

```objc
static NSString * const kAppearanceModeKey = @"appearanceMode";

// Inside awakeFromNib
NSDictionary *defaults = @{
    // ... other defaults ...
    kAppearanceModeKey: @(AppearanceModeSystem), // Default to System for new users
    // kWhiteBackgroundKey: @NO // Keep for migration or remove after migration is verified
};
[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
```

## 2. Implement Migration Logic

When the app launches, check whether `appearanceMode` is already persisted in the app's user defaults domain. If not, perform migration from the legacy `whiteBackground` boolean.

### Migration Code in SongView.m

```objc
- (void)migrateAppearanceDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // If the new key is already persisted, no migration needed
    if ([[defaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]] objectForKey:kAppearanceModeKey] != nil) {
        return;
    }
    
    // Check if the legacy key exists
    if ([defaults objectForKey:kWhiteBackgroundKey] != nil) {
        BOOL oldWhite = [defaults boolForKey:kWhiteBackgroundKey];
        AppearanceMode migratedMode = oldWhite ? AppearanceModeLight : AppearanceModeDark;
        [defaults setInteger:migratedMode forKey:kAppearanceModeKey];
        
        // Optionally remove the legacy key to clean up
        // [defaults removeObjectForKey:kWhiteBackgroundKey];
    } else {
        // No legacy setting found, ensure it defaults to System
        [defaults setInteger:AppearanceModeSystem forKey:kAppearanceModeKey];
    }
}
```

## 3. Load Persistent State

Update the initialization flow to call the migration and then load the authoritative `appearanceMode`.

```objc
[self migrateAppearanceDefaults];
AppearanceMode savedMode = (AppearanceMode)[[NSUserDefaults standardUserDefaults] integerForKey:kAppearanceModeKey];
[self setAppearanceMode:savedMode writeDefaults:NO];
```

## 4. Persist Explicit User Changes

Update the appearance setter so callers can choose whether the selected mode should be written to `NSUserDefaults`.

### Changes in SongView.h

```objc
- (void)setAppearanceMode:(AppearanceMode)mode writeDefaults:(BOOL)writeDefaults;
```

### Changes in SongView.m

Rename the Step 1 implementation of `setAppearanceMode:` to `setAppearanceMode:writeDefaults:` and write the selected mode only when requested.

```objc
- (void)setAppearanceMode:(AppearanceMode)mode writeDefaults:(BOOL)writeDefaults {
    selectedAppearanceMode = mode;
    
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setInteger:mode forKey:kAppearanceModeKey];
    }
    
    [self updateEffectiveAppearance];
}
```

Use `writeDefaults:NO` when loading persisted state during initialization or responding to defaults observation. User-initiated changes, such as hotkeys added in later steps, should use `writeDefaults:YES`.

Update any existing direct calls from Step 1 to use the new signature. The `W` and `B` hotkeys are user-initiated changes, so they should persist:

```objc
[self setAppearanceMode:AppearanceModeLight writeDefaults:YES];
[self setAppearanceMode:AppearanceModeDark writeDefaults:YES];
```

## Verification Plan

- [ ] **Fresh Install:** Delete app preferences (`defaults delete com.yourcompany.FrontRowTunes`). Launch the app and verify it defaults to System mode.
- [ ] **Migration (Light):** Set the old preference: `defaults write com.yourcompany.FrontRowTunes whiteBackground -bool YES`. Launch the app and verify it starts in Light mode and `appearanceMode` is now set to `0` (Light).
- [ ] **Migration (Dark):** Set the old preference: `defaults write com.yourcompany.FrontRowTunes whiteBackground -bool NO`. Launch the app and verify it starts in Dark mode and `appearanceMode` is now set to `1` (Dark).
- [ ] **Persistence:** Change mode via hotkey (e.g., press `B` for Dark). Relaunch the app and verify it stays in Dark mode.
