# Investigation: Preferences Slider Interaction Blocks Main Thread Clock Animation

## 1. Executive Summary
When a user clicks and drags the delay sliders in the Preferences window, the main application's clock animation (both the analog clock hand sweeps and the digital clock string updates) halts completely. The clock resumes movement immediately once the mouse is released.

Similarly, if a different song starts playing while the user is dragging the preferences slider, the current song view animates out successfully, but the new song view **does not animate in** until the slider is released.

This behavior is caused by a fundamental aspect of macOS's cooperative multitasking and event handling architecture, specifically involving **Cocoa Run Loop Modes**. It is not a CPU bottleneck or a deadlock, but rather an expected pause due to timers being scheduled on the default run loop mode while the main thread transitions into an event tracking modal run loop.

---

## 2. Root Cause Analysis

### The Cocoa Run Loop & Tracking Modes
On macOS, the main thread runs a `NSRunLoop` (or `CFRunLoop`) that coordinates incoming events, timers, and drawing operations. To manage priorities, the run loop operates in different **modes**:
1. **`NSDefaultRunLoopMode` (`kCFRunLoopDefaultMode`)**: The default mode used when the application is idle or handling routine events.
2. **`NSEventTrackingRunLoopMode`**: A modal run loop mode entered automatically by AppKit whenever a user is actively interacting with a control (e.g., clicking and dragging a slider, resizing/moving a window, or scrolling a list).
3. **`NSModalPanelRunLoopMode`**: Entered when displaying modal panels or sheets.

---

### The Affected Timers
Within FrontRowTunes, multiple timers are scheduled on the main thread's run loop:

#### 1. Analog Clock Timer (`Layers/AnalogClockLayer.swift`)
An `animationTimer` of type `Timer` is scheduled using:
```swift
animationTimer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { ... }
```

#### 2. Player Position / Digital Clock Timer (`SongView.m`)
An `updatePlayerPositionTimer` of type `NSTimer` is scheduled using:
```objc
updatePlayerPositionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATEINTERVAL target:self selector:@selector(updatePlayerPosition) userInfo:nil repeats:YES];
```

#### 3. New Song Activation / Slide-In Timer (`SongView.m` in `setTrack:prev:`)
When a new song is detected, the old layer animates out, and the new layer is scheduled to animate in after a `0.6`s delay via a one-off timer:
```objc
[NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(activateNewLayer) userInfo:nil repeats:NO];
```

#### 4. Track Change Cooldown Timer (`SongView.m` in `setTrack:prev:`)
A `changeTrackTimer` is scheduled to reset track change state after `1`s:
```objc
changeTrackTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(resetJustChangedTrack) userInfo:nil repeats:NO];
```

---

### Why the Clock Pauses and Track Transitions Stall
All of these timers are scheduled using convenience methods like `Timer.scheduledTimer` and `[NSTimer scheduledTimerWithTimeInterval:...]`. These methods automatically register the created timers *exclusively* under **`NSDefaultRunLoopMode`**.

When a user clicks and drags a slider in the SwiftUI-based Preferences view:
1. AppKit detects the mouse interaction on the slider and puts the main run loop into **`NSEventTrackingRunLoopMode`**.
2. Because the run loop is operating *exclusively* in the tracking mode during the drag operation, any timer registered *only* for the default mode is **completely paused**.
3. **Clock Freezes:** `updatePlayerPositionTimer` (digital clock) and `animationTimer` (analog sweep) are paused, halting the clock displays.
4. **Transition Stalls:** When a track change is detected, the previous track layer's fade-out transaction is committed immediately. However, the `activateNewLayer` timer is paused in tracking mode. As a result, the run loop never fires the selector to trigger the scale-in animation of the new layer, causing the screen to remain blank (or stuck at the end of fade-out) until the user lets go of the slider.
5. Once the user releases the mouse, the run loop transitions back to `NSDefaultRunLoopMode`. The timers immediately fire, and the new track view finally animates in, while the clock jumps to the correct time and continues ticking.

---

## 3. Proposed Solutions

### Solution 1: Use Common Run Loop Modes (NSRunLoopCommonModes)
Instead of scheduling the timers on the run loop using default mode convenience methods, we can manually initialize the timers and add them to the main run loop under `.common` modes (`NSRunLoopCommonModes` in Objective-C, `RunLoop.Mode.common` in Swift).

The `.common` mode is a pseudo-mode containing a set of actual modes (including both the default and event tracking modes) to which timers and observers can be bound.

* **Swift (`Layers/AnalogClockLayer.swift`):**
  ```swift
  let timer = Timer(timeInterval: animationDuration, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.setTime(self.getTime(timeIntervalSinceNow: animationDuration), animationDuration: animationDuration)
  }
  RunLoop.main.add(timer, forMode: .common)
  animationTimer = timer
  ```

* **Objective-C (`SongView.m`):**
  Create helper methods or manually add timers like so:
  ```objc
  // Instead of scheduledTimerWithTimeInterval:
  NSTimer *timer = [NSTimer timerWithTimeInterval:0.6 target:self selector:@selector(activateNewLayer) userInfo:nil repeats:NO];
  [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
  ```

* **Pros:**
  - Extremely lightweight and native Cocoa pattern.
  - Zero performance overhead.
  - Maintains single-threaded UI safety without requiring background queue dispatching or lock/mutex synchronization.
  - Fixes all clock pause and transition stall issues during slider drags, window moves, resizes, and scrolling.
* **Cons:**
  - None.

---

### Solution 2: GCD Dispatch Source Timers
Grand Central Dispatch (GCD) has a timer source (`DispatchSourceTimer`) that is completely decoupled from the Cocoa `NSRunLoop` and runs independently of run loop modes.

* **Implementation:**
  Create a `DispatchSourceTimer` targeted at the main queue (`DispatchQueue.main` or `dispatch_get_main_queue()`).
* **Pros:**
  - Avoids run loop mode constraints completely.
  - High precision.
* **Cons:**
  - More verbose and complex API compared to standard timers.
  - Requires careful management to avoid memory leaks or reference cycles during cancellation.
  - Unnecessary for simple UI ticks that fit perfectly within the RunLoop model.

---

### Solution 3: Display Link (`CVDisplayLink` / `CADisplayLink`)
A Display Link is a timer synchronized to the refresh rate of the monitor (e.g., 60Hz or 120Hz).

* **Implementation:**
  Configure a `CVDisplayLink` to call a callback on every screen refresh to advance the clock hand.
* **Pros:**
  - Absolute smoothest animation possible; perfectly synchronized with display updates.
* **Cons:**
  - Significant overkill: a clock only updates once per second (or small fraction of a second for sub-second smooth sweep hands), so firing 60-120 times per second is wasteful.
  - Much higher CPU/energy usage.
  - Substantially higher implementation complexity.

---

## 4. Recommendation

We strongly recommend **Solution 1: Use Common Run Loop Modes (`NSRunLoopCommonModes` / `RunLoop.Mode.common`)**.

### Why Solution 1?
1. **Direct Match for Root Cause:** The problem is explicitly caused by run loop mode filtering. Scheduling on `.common` modes is the exact, standard platform solution designed by Apple for this scenario.
2. **Minimal and Safe Code Changes:** It requires modifying only a few lines where the timers are defined, preserving all existing animation and update logic without altering overall architecture or introducing multi-threading complexities.
3. **Comprehensive Coverage:** It resolves both the clock freezing and the song transition stall issues during slider dragging, window moving/resizing, or list scrolling.
