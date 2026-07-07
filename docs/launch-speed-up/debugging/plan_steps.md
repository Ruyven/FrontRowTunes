# Step-by-Step Debugging & Validation Plan: Startup Performance & Music.app Integration

This document outlines a highly structured, repeatable execution plan to answer each of the 10 diagnostic questions posed in `DEBUGGING.md`. Each phase includes concrete file/line modifications, target commands, and expected manual/automated validation checks.

Debugging in Gemini session 00d600d4-fe5b-44f6-98aa-0b20771df138

---

## Phase 1: Timing and Thread Instrumentation
**Goal:** Address **Question 1**, **Question 6**, and **Question 10** (measure startup latency of each call, identify active threads, and inspect scripting performance).

### Step 1.1: Instrument `executeScript` inside `MusicBridge.swift`
* **Role:** **Automatable for LLM**
* **File to edit:** `MusicBridge/MusicBridge.swift`
* **Action:** Replace the existing `executeScript(source:)` method with one that logs thread safety, compilation/execution timing, and the source of the AppleScript being run.
* **Code Change:**
  ```swift
  private static func executeScript(source: String) -> NSAppleEventDescriptor? {
      let isMain = Thread.isMainThread
      let threadName = isMain ? "Main Thread" : "Background Thread (\(Thread.current))"
      let start = CFAbsoluteTimeGetCurrent()
      
      var errorInfo: NSDictionary?
      guard let script = NSAppleScript(source: source) else {
          print("[\(threadName)] Failed to create script: \(source)")
          return nil
      }

      let output = script.executeAndReturnError(&errorInfo)
      let elapsed = CFAbsoluteTimeGetCurrent() - start
      
      print(String(format: "[\(threadName)] Execute took %.4f seconds | Script: %@", elapsed, source))
      
      if let errorInfo = errorInfo {
          print("[\(threadName)] Error: \(errorInfo.description)")
          return nil
      }
      return output
  }
  ```

### Step 1.2: Instrument `getCurrentTrack` in `MusicBridge.swift`
* **Role:** **Automatable for LLM**
* **File to edit:** `MusicBridge/MusicBridge.swift`
* **Action:** Measure the cumulative time of `getCurrentTrack` (which performs multiple AppleScript queries under the hood).
* **Code Change:** Wrap `getCurrentTrack()` body with top-level timing metrics.
  ```swift
  @objc static func getCurrentTrack() -> MusicTrack? {
      let start = CFAbsoluteTimeGetCurrent()
      defer {
          let elapsed = CFAbsoluteTimeGetCurrent() - start
          print(String(format: "[MusicBridge getCurrentTrack] Total execution took %.4f seconds", elapsed))
      }
      
      guard isTrackPlaying(), let trackID = getTrackID() else {
          return nil
      }
      
      return MusicTrack(
          id: trackID,
          name: getTrackName(),
          artist: getArtist(),
          album: getAlbum(),
          artwork: getArtwork(),
          duration: getDuration() ?? 0
      )
  }
  ```

### Step 1.3: Build, Run, and Record Observations (Diagnostic Runs)
* **Role:** **Manual Step for User**
* **Command:**
  ```bash
  xcodebuild -project FrontRowTunes.xcodeproj -scheme FrontRowTunes -configuration Debug build
  ```
* **Actions:**
  1. Ensure **Music.app is already running** and playing a song. Launch FrontRowTunes. Keep the terminal output open to capture logs.
  2. Quit both applications. Now ensure **Music.app is closed**. Launch FrontRowTunes again.
* **Expected Observations & Recording:**
  - Record timing values of each query (e.g. `exists current track`, `persistent ID`, `artist`, `artwork`, etc.).
  - Identify which thread they ran on.
  - Note if the UI beachballed when Music.app was closed.

### Results

#### Music.app already running
```
[Main Thread] Execute took 0.4921 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0063 seconds | Script: tell application "Music" to get player state
[Main Thread] Execute took 0.0211 seconds | Script: tell application "Music" to exists current track
[Main Thread] Execute took 0.0074 seconds | Script: tell application "Music" to get persistent ID of current track
[Main Thread] Execute took 0.0050 seconds | Script: tell application "Music" to get name of current track
[Main Thread] Execute took 0.0215 seconds | Script: tell application "Music" to get artist of current track
[Main Thread] Execute took 0.0052 seconds | Script: tell application "Music" to get album of current track
[Main Thread] Execute took 0.0824 seconds | Script:     tell application "Music" to tell current track
        if exists artworks then
            get data of artwork 1
        end if
    end tell
[Main Thread] Execute took 0.0050 seconds | Script: tell application "Music" to get duration of current track
[MusicBridge getCurrentTrack] Total execution took 0.1482 seconds
[Main Thread] Execute took 0.0222 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0266 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0228 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0214 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0222 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0219 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0238 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0225 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0215 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0220 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0227 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0217 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0146 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0100 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0229 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0223 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0216 seconds | Script: tell application "Music" to get player position
```

#### Music.app closed, starting up with FrontRowTunes
```
[Main Thread] Execute took 3.5108 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.5175 seconds | Script: tell application "Music" to get player state
[Main Thread] Execute took 0.2451 seconds | Script: tell application "Music" to exists current track
[MusicBridge getCurrentTrack] Total execution took 0.2452 seconds
[Main Thread] Execute took 0.0268 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0343 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0413 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0269 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0234 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0217 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0230 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.2054 seconds | Script: tell application "Music" to get player position
[Main Thread] Execute took 0.0226 seconds | Script: tell application "Music" to get player position
```

---

## Phase 2: Isolating Startup Method Launch Causes
**Goal:** Address **Question 2** (determine exactly which API call causes macOS to auto-launch `Music.app`).

### Step 2.1: Isolate `getPlayerPosition`
* **Role:** **Automatable for LLM**
* **File to edit:** `SongView.m`
* **Action:** Comment out the `getCurrentTrack` query in `awakeFromNib` and any layer configuration in `setupLayers` to isolate `getPlayerPosition` as the sole startup call.
* **Line modifications:**
  - Inside `- (void)awakeFromNib`:
    - Keep: `playerPosition = [MusicBridge getPlayerPosition];`
    - Comment out: `[self setTrack:[MusicBridge getCurrentTrack] prev:nil];`
    - Comment out: `updatePlayerPositionTimer = ...` (to avoid subsequent poll interferences)
  - Inside `- (void)setupLayers`:
    - Comment out: `[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];`

### Step 2.2: Test and Record `getPlayerPosition` Behavior
* **Role:** **Manual Step for User**
* **Action:** Close Music.app. Run FrontRowTunes.
* **Recording:** Does Music.app auto-launch? → Yes

### Step 2.3: Isolate `getCurrentTrack`
* **Role:** **Automatable for LLM**
* **File to edit:** `SongView.m`
* **Action:** Restore the previous changes, then isolate `getCurrentTrack` as the sole startup call.
* **Line modifications:**
  - Inside `- (void)awakeFromNib`:
    - Comment out: `playerPosition = [MusicBridge getPlayerPosition];`
    - Keep: `[self setTrack:[MusicBridge getCurrentTrack] prev:nil];`
    - Comment out: `updatePlayerPositionTimer = ...`
  - Inside `- (void)setupLayers`:
    - Comment out: `[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];`

### Step 2.4: Test and Record `getCurrentTrack` Behavior
* **Role:** **Manual Step for User**
* **Action:** Close Music.app. Run FrontRowTunes.
* **Recording:** Does Music.app auto-launch? → Yes

### Step 2.5: Isolate `getPlayerState`
* **Role:** **Automatable for LLM**
* **File to edit:** `SongView.m`
* **Action:** Restore previous changes, then isolate `getPlayerState` as the sole startup call.
* **Line modifications:**
  - Inside `- (void)awakeFromNib`:
    - Comment out: `playerPosition = [MusicBridge getPlayerPosition];`
    - Comment out: `[self setTrack:[MusicBridge getCurrentTrack] prev:nil];`
    - Comment out: `updatePlayerPositionTimer = ...`
  - Inside `- (void)setupLayers`:
    - Keep: `[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];`

### Step 2.6: Test and Record `getPlayerState` Behavior
* **Role:** **Manual Step for User**
* **Action:** Close Music.app. Run FrontRowTunes.
* **Recording:** Does Music.app auto-launch? → Yes

---

## Phase 3: Testing NSRunningApplication Isolation
**Goal:** Address **Question 3** (verify if Cocoa's API can safely check if Music is running without launching it).

### Step 3.1: Add `isMusicRunning()` check to `MusicBridge.swift`
* **Role:** **Automatable for LLM**
* **File to edit:** `MusicBridge/MusicBridge.swift`
* **Action:** Implement a swift function querying `NSRunningApplication`. Print its result during class initialization or inside `awakeFromNib`.
* **Code Change:**
  ```swift
  @objc static func isMusicRunning() -> Bool {
      let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")
      let running = !apps.isEmpty
      print("[MusicBridge] NSRunningApplication check - isMusicRunning: \(running)")
      return running
  }
  ```
  And inside `SongView.m` `- (void)awakeFromNib`, add a log:
  ```objc
  NSLog(@"[SongView] awakeFromNib: isMusicRunning check says: %d", [MusicBridge isMusicRunning]);
  ```

### Step 3.2: Test NSRunningApplication Behavior
* **Role:** **Manual Step for User**
* **Action:** Close Music.app. Run FrontRowTunes.
* **Recording:**
  - Does Music.app launch? → No
  - Is the check instantaneous and free of main-thread block logs? → Yes

---

## Phase 4: Testing the 0.5-Second Relaunch Timer
**Goal:** Address **Question 4** and **Question 5** (verify timer relaunch culpability and startup contribution).

### Step 4.1: Disable the `updatePlayerPositionTimer`
* **Role:** **Automatable for LLM**
* **File to edit:** `SongView.m`
* **Action:** Comment out the timer initialization inside `awakeFromNib`.
* **Line modifications:**
  - Comment out line:
    ```objc
    // updatePlayerPositionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATEINTERVAL target:self selector:@selector(updatePlayerPosition) userInfo:nil repeats:YES];
    ```

### Step 4.2: Perform Timer Relaunch Verification
* **Role:** **Manual Step for User**
* **Action:**
  1. Open FrontRowTunes with Music.app closed.
  2. Manually launch Music.app (Music.app should open and remain open).
  3. Manually quit Music.app.
* **Recording:**
  - With the timer disabled, does Music.app remain closed, or does it relaunch? → Remains closed
  - How does startup time compare with the timer disabled vs. enabled?
    - With all other AppleScript methods running on launch disabled, the timer doesn't really make a difference to launch. But with the timer enabled, the Music app auto-launches once FrontRowTunes is running, and auto-restarts when quit.

---

## Phase 5: Executing AppleEvents on Background Threads
**Goal:** Address **Question 7** (can we run AppleEvents off the main thread, or does AppleScript require main-thread serialization?).

### Step 5.1: Offload `getPlayerState` to Background Queue
* **Role:** **Automatable for LLM**
* **File to edit:** `SongView.m`
* **Action:** Modify `setupLayers` to query `getPlayerState` on a background thread and update the active layer state on the main thread.
* **Line modifications:**
  - In `setupLayers`, replace:
    ```objc
    [activeSongLayer setPlayerState:[MusicBridge getPlayerState]];
    ```
    With:
    ```objc
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *state = [MusicBridge getPlayerState];
        dispatch_async(dispatch_get_main_queue(), ^{
            [activeSongLayer setPlayerState:state];
            NSLog(@"[SongView] Asynchronously updated player state to: %@", state);
        });
    });
    ```

### Step 5.2: Run and Validate Background Safety
* **Role:** **Manual Step for User**
* **Action:** Run FrontRowTunes and observe console logs and app stability.
* **Recording:**
  - Does it update correctly? → Yes
  - Does the app crash or throw script-threading warnings/errors? → No
  - Does the UI load visibly faster and stay interactive? → Staying interactive, but not loading visibly faster, because other AppleScript functions still block the UI until Music app is running.

### Risks

Moving all AppleScript to background threads may block the app from showing a coherent state on first launch and require a loading state; to be tested.

---

## Phase 6: Distributed Notifications vs Polling Sufficiency
**Goal:** Address **Question 8** and **Question 9** (verify if distributed notifications are sufficient to keep artwork/metadata updated, and whether position polling is the only necessary timer function).

### Step 6.1: Disable Polling but keep Notifications
* **Role:** **Automatable for LLM**
* **File to edit:** `SongView.m`
* **Action:** Keep the timer enabled but change `updatePlayerPosition` to skip querying `MusicBridge`.
* **Line modifications:**
  - Replace the contents of `- (void)updatePlayerPosition` so it simply prints a log and updates the clock, skipping any call to `[MusicBridge getPlayerPosition]`.
  - For example:
    ```objc
    - (void)updatePlayerPosition {
        // Skip player position query to test notifications only
        [activeSongLayer updateClock];
    }
    ```

### Step 6.2: Run Notification Verification Tests
* **Role:** **Manual Step for User**
* **Action:**
  1. Close Music.app, open FrontRowTunes.
  2. Manually launch Music.app and start playing a track.
* **Recording:**
  - Is the `com.apple.Music.playerInfo` notification received? → Yes
  - Is `getTrack:` called, and does metadata (song title, artist, album, artwork) render correctly? → Yes
  - Does the play/pause state transition correctly on notification? → Yes
  - Does the progress bar stop advancing? → Yes, confirming polling is indeed ONLY required for playback position progression tracking

---

## Summary of Findings Report (To be compiled after plan execution)
Use the table below to document the final deliverables:

| Question | Feature/Method | Behavior / Result |
|---|---|---|
| **Q1** | Slow Methods | |
| **Q2** | Launches Music? | |
| **Q3** | `NSRunningApplication` | |
| **Q4/5** | Timer Impact | |
| **Q6** | Main Thread Calls | |
| **Q7** | Thread Safety | |
| **Q8/9** | Notification Scope | |
| **Q10** | Script Performance | |
