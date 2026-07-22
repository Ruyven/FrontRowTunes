# Phase 3: Preferences Panel Integration - Implementation Plan

This document outlines the implementation plan for Phase 3 of the **Auto-Full-Screen Clock** feature. The goal is to provide a user-friendly UI for configuring the screensaver delays introduced in Phase 1 and 2.

---

## 1. Investigation Results

### SwiftUI Feasibility
- **Deployment Target:** The project targets macOS 10.15, which is the minimum version for SwiftUI.
- **Existing Swift Integration:** The project already uses Swift and has a bridging header, making SwiftUI integration straightforward.
- **Preferences Architecture:** 
    - Using SwiftUI with `@AppStorage` allows for direct, reactive binding to `NSUserDefaults`.
    - Hosting the SwiftUI view in an `NSHostingController` inside a standard `NSWindow` is a clean, modern approach for a project of this era.

### Compatibility
- **User Defaults:** SwiftUI bindings are fully compatible with the existing `NSUserDefaults` system.
- **Architectural Complexity:** Introducing SwiftUI for a new window (Preferences) is isolated and does not complicate the existing Objective-C layers (SongView, SongLayer).

---

## 2. Proposed Architecture

### Preferences Window
- A new Swift class `PreferencesWindowController` (subclass of `NSWindowController`) will manage the preferences window.
- It will host a SwiftUI `PreferencesView`.
- The window will be unhidden from the `MainMenu.xib` and connected to an action.

### Reactive Updates
- `SongView` currently reads preferences only during initialization.
- To handle real-time updates from the Preferences window, `SongView` will observe `NSUserDefaultsDidChangeNotification`.
- When a change is detected, `SongView` will update its `LastEventTracker` instances with the new timeouts.

---

## 3. UI Design

The `PreferencesView` will be a simple vertical layout:

- **Music Screensaver Delay:** 
    - A slider or stepper ranging from 0 to 300 seconds.
    - Label: "Automatically enter full-screen during music playback"
    - Subtext: "Set to 0 to disable."
- **Clock Screensaver Delay:**
    - A slider or stepper ranging from 0 to 300 seconds.
    - Label: "Automatically enter full-screen when clock is active"
    - Subtext: "Set to 0 to disable."

---

## 4. Implementation Steps

### Step 4.1: Centralize Preference Keys
The keys are currently defined as `static` strings in `SongView.m`. To avoid duplication and ensure SwiftUI and Objective-C stay in sync, move them to `Helpers/Constants.swift` and expose them to Objective-C.

**Action:** Update `Helpers/Constants.swift`:
```swift
@objc class PrefKeys: NSObject {
    @objc static let musicScreensaverDelay = "musicScreensaverDelay"
    @objc static let clockScreensaverDelay = "clockScreensaverDelay"
}
```

**Action:** Update `SongView.m` to use these keys:
```objc
// Replace static definitions with references to Swift constants
#define kMusicScreensaverDelayKey [PrefKeys musicScreensaverDelay]
#define kClockScreensaverDelayKey [PrefKeys clockScreensaverDelay]
```

### Step 4.2: Implement `PreferencesView.swift`
```swift
import SwiftUI

struct PreferencesView: View {
    @AppStorage(PrefKeys.musicScreensaverDelay) var musicDelay: Double = 60
    @AppStorage(PrefKeys.clockScreensaverDelay) var clockDelay: Double = 60

    var body: some View {
        Form {
            Section(header: Text("Screensaver Activation")) {
                VStack(alignment: .leading) {
                    Slider(value: $musicDelay, in: 0...300, step: 5) {
                        Text("Music Playback Delay: \(Int(musicDelay))s")
                    }
                    Text("Time to wait while music is playing before entering full-screen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $clockDelay, in: 0...300, step: 5) {
                        Text("Clock Mode Delay: \(Int(clockDelay))s")
                    }
                    Text("Time to wait in clock mode before entering full-screen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Text("Set delay to 0 to disable automatic full-screen.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 450)
    }
}
```

### Step 4.3: Implement `PreferencesWindowController.swift`
```swift
import AppKit
import SwiftUI

@objc class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentView = NSHostingView(rootView: PreferencesView())
        window.center()
        self.init(window: window)
    }
    
    @objc func show() {
        self.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

### Step 4.4: Update `FrontRowTunesAppDelegate.m`
Add the action to show the preferences window:

```objc
- (IBAction)showPreferences:(id)sender {
    [[PreferencesWindowController shared] show];
}
```

### Step 4.5: Update `SongView.m` to Observe Changes
Add observation in `awakeFromNib`:

```objc
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(userDefaultsDidChange:) 
                                             name:NSUserDefaultsDidChangeNotification 
                                           object:nil];
```

Implement the handler:

```objc
- (void)userDefaultsDidChange:(NSNotification *)notification {
    double musicDelay = [[NSUserDefaults standardUserDefaults] doubleForKey:kMusicScreensaverDelayKey];
    [musicInactivityTracker setDelegate:self eventType:kCGAnyInputEventType timeout:musicDelay];
    
    double clockDelay = [[NSUserDefaults standardUserDefaults] doubleForKey:kClockScreensaverDelayKey];
    [clockInactivityTracker setDelegate:self eventType:kCGAnyInputEventType timeout:clockDelay];
}
```
*(Note: setDelegate safely restarts the tracker with the new timeout)*

---

## 5. Verification Plan

### Manual Testing
1. **Menu Access:** Verify "Preferences..." is visible in the app menu and has the shortcut `Cmd+,`.
2. **Real-time Update:**
    - Open Preferences.
    - Set Music Delay to 5s.
    - Play music.
    - **Expectation:** App enters full-screen after 5s without restarting the app.
3. **Persistence:**
    - Change a value in Preferences.
    - Restart the app.
    - **Expectation:** The new value is retained in the Preferences UI and behavior.
