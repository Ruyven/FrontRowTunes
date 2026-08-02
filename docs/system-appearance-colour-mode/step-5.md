# Implementation Plan: Step 5 — Add System Mode to the Existing Preferences Panel

## Objective

Expose the appearance mode setting in the SwiftUI Preferences panel and ensure that changes in the UI are immediately reflected in the app.

## 1. Update PrefKeys and AppearanceMode for Swift

Ensure `PrefKeys` in `Helpers/Constants.swift` includes the `appearanceMode` key and that `AppearanceMode` is easily usable in SwiftUI.

### Changes in Helpers/Constants.swift

```swift
@objc class PrefKeys: NSObject {
    // ...
    @objc static let appearanceMode = "appearanceMode"
}

// Ensure AppearanceMode is RawRepresentable by Int (default for @objc enum)
```

## 2. Update PreferencesView.swift

Add a `Picker` to the `PreferencesView` to allow the user to select the appearance mode.

### Changes in Views/PreferencesView.swift

```swift
struct PreferencesView: View {
    // ...
    @AppStorage(PrefKeys.appearanceMode) var appearanceMode: AppearanceMode = .system
    
    var body: some View {
        Form {
            Section(header: Text("Appearance").font(.title)) {
                Picker("Mode", selection: $appearanceMode) {
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                    Text("System").tag(AppearanceMode.system)
                }
                .pickerStyle(.segmented)
                
                Text("Select whether FrontRowTunes should use a light or dark background, or follow the system appearance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // ... existing Sections ...
        }
    }
}
```

## 3. Observe Preferences Changes in SongView

Ensure `SongView.m` responds to changes made in the Preferences panel via `NSUserDefaults` observation.

### Changes in SongView.m

1. **Update `awakeFromNib`**: Add `kAppearanceModeKey` to the `defaults` dictionary so it is automatically observed via `observeUserDefaultsChanges:`.
2. **Update `observeValueForKeyPath:`**: Add a case for `kAppearanceModeKey` to call `setAppearanceMode:writeDefaults:NO`.

```objc
// Inside observeValueForKeyPath: dictionary
kAppearanceModeKey: ^{
    AppearanceMode value = (AppearanceMode)[[NSUserDefaults standardUserDefaults] integerForKey:kAppearanceModeKey];
    [self setAppearanceMode:value writeDefaults:NO];
}
```

## Verification Plan

- [ ] Open the Preferences panel (`Command + ,`).
- [ ] Verify that the "Appearance" section shows the three modes (Light, Dark, System).
- [ ] Select **Light**: Verify the app immediately switches to Light mode.
- [ ] Select **Dark**: Verify the app immediately switches to Dark mode.
- [ ] Select **System**: Verify the app immediately switches to the system appearance.
- [ ] Close and reopen the app: Verify the preference is persisted.
- [ ] Press a hotkey (e.g., `W`): Verify the selection in the Preferences panel updates to reflect the new state.
