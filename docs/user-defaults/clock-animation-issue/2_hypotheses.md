# Hypotheses: Analog Clock Second Hand Jump Bug

This document tracks the hypotheses regarding the bug where the analog clock's second hand jumps approximately 20 seconds forward during restoration.

## Confirmed False

| Hypothesis | Description | Evidence / Test | Verdict |
| :--- | :--- | :--- | :--- |
| **Fill Mode Persistence** | `fillMode = .forwards` and `isRemovedOnCompletion = false` caused the presentation layer to stay pinned to a future value. | Implemented "Golden Sequence" with `.removed` and `isRemovedOnCompletion = true`. Bug persisted. | **Confirmed False** |
| **Animation Stacking** | New animations were being added without removing old ones, causing state accumulation. | Implemented explicit `removeAnimation(forKey:)` before adding new ones. Bug persisted. | **Confirmed False** |
| **Presentation Stale State** | Using `presentation().transform` as `fromValue` was capturing a stale or incorrect state. | Captured `presentation().transform` and synced the model layer immediately before the new animation. Bug persisted. | **Confirmed False** |
| **Key Naming Conflict** | Using `keyPath: "transform"` but identifying the animation as `"rotation"` caused issues. | Analyzed CA documentation; this is standard behavior. | **Confirmed False** |
| **Missing Model Update** | Failure to update the model layer `transform` after `addAnimation` caused a snap. | Verified that model updates were present and wrapped in `disableActions`. Bug persisted. | **Confirmed False** |
| **CATransaction Conflict** | `CATransaction` animation duration was fighting with `CABasicAnimation` duration. | Wrapped all updates in `CATransaction.setDisableActions(true)`. Bug persisted. | **Confirmed False** |
| **Time Space Shift** | Discrepancy between local layer time and `CACurrentMediaTime()` during restoration. | Explicitly set `animation.beginTime = CACurrentMediaTime()`. Bug persisted. | **Confirmed False** |
| **Rapid-Fire Loop** | `updateAnimations` triggered a completion loop before the layer was windowed. | Added `self.window` guard and retry logic. Bug persisted. | **Confirmed False** |
| **Target Time Calculation** | The `getTime(timeIntervalSinceNow:)` or `getHourMinuteSecond` logic produces an incorrect target value. | Logged `targetTime` and components during launch. Values were mathematically correct and matched system time + duration. | **Confirmed False** |
| **Transform Interpolation** | Animating `CATransform3D` matrices causes incorrect rotation interpolation. | Experimented with `transform.rotation.z` using radians. Did not fix the symptom. | **Confirmed False** |

## Confirmed / Highly Likely

| Hypothesis | Description | Evidence / Test | Verdict |
| :--- | :--- | :--- | :--- |
| **Windowless Animation Loop** | Animations added to windowless layers fail to persist or commit, causing `CATransaction` completions to fire immediately, triggering a rapid-fire loop that jumps the model transform to the target. | Logs show: `window: false`, `presentationValid: false`, `animationKeys` becoming empty in persistence check, and `setTime COMPLETION` firing in ~0.05s instead of 20s. This explains the "slow motion" as the hand finally animates from the jumped model state. | **Confirmed** |

## Yet to Confirm

| Hypothesis | Description | Proposed Investigation |
| :--- | :--- | :--- |
| **Double Initialization** | The clock is being initialized/restored twice (e.g., once in `awakeFromNib` and once via a setter), causing two overlapping animation loops. | Add pointer addresses to all lifecycle logs (`init`, `awakeFromNib`, `setTime`) to see if multiple `AnalogClockLayer` instances are active. |
| **Nib Restoration Side-Effect** | Something in the `.xib` restoration process (e.g., `decode`) is applying a transform or animation that persists despite our efforts. | Log `animationKeys()` and `transform` immediately inside `init(layer:)` and `awakeFromNib`. |
| **`CALayer` Copy Logic** | The custom `init(layer:)` (used by CA for copies) is not correctly transferring state or is triggering a side effect. | Compare the state of the original layer vs. the copied layer during the restoration process. |

---

## Current Status
The root cause is identified as a lifecycle race condition. The `AnalogClockLayer` starts its animation loop before the layer is attached to a windowed view hierarchy. Because Core Animation ignores animations on windowless layers, the `CATransaction` completion blocks fire immediately, creating a recursive loop that snaps the model transform to the target time. When the layer finally becomes windowed, the first "real" animation starts from the already-snapped model state, resulting in the "slow motion" (1 second of movement over 20 seconds) and an initial jump.

## Suggested Production Fix

To resolve the lifecycle race condition and eliminate the rapid-fire loop:

1.  **Remove Startup Trigger:** Remove the `DispatchQueue.main.async { self.updateAnimations() }` call from `init(darkMode:)`. The layer should not attempt to animate itself upon creation.
2.  **Explicit Start Method:** Implement a public `start()` method in `AnalogClockLayer` that triggers the initial `updateAnimations()` call.
3.  **Window-Aware Activation:** The owning `NSView` (e.g., `SongView`) should be responsible for calling `analogClockLayer.start()` only when the view is confirmed to be in a window hierarchy (e.g., inside `viewDidMoveToWindow` or after the view is added to a windowed superview).
4.  **Initial State Snap:** Modify the first call of the animation sequence to use a duration of `0`. This ensures the clock hands "snap" to the current time immediately upon appearing, providing a clean starting point for the subsequent 20-second smooth animations.

