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

When the app launches, check if the new `appearanceMode` key exists. If not, perform migration from the legacy `whiteBackground` boolean.

### Migration Code in SongView.m

```objc
- (void)migrateAppearanceDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // If the new key is already set, no migration needed
    if ([defaults objectForKey:kAppearanceModeKey] != nil) {
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
AppearanceMode savedMode = (AppearanceMode)[[NSUserDefaults standardUserDefaults] integerValueForKey:kAppearanceModeKey];
[self setAppearanceMode:savedMode writeDefaults:NO];
```

## Verification Plan

- [ ] **Fresh Install:** Delete app preferences (`defaults delete com.yourcompany.FrontRowTunes`). Launch the app and verify it defaults to System mode.
- [ ] **Migration (Light):** Set the old preference: `defaults write com.yourcompany.FrontRowTunes whiteBackground -bool YES`. Launch the app and verify it starts in Light mode and `appearanceMode` is now set to `0` (Light).
- [ ] **Migration (Dark):** Set the old preference: `defaults write com.yourcompany.FrontRowTunes whiteBackground -bool NO`. Launch the app and verify it starts in Dark mode and `appearanceMode` is now set to `1` (Dark).
- [ ] **Persistence:** Change mode via hotkey (e.g., press `B` for Dark). Relaunch the app and verify it stays in Dark mode.