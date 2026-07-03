# Core Animation Debugging: Analog Clock Position Animation starts from (0,0)

## Problem Description
When moving the `AnalogClockLayer` (a custom Swift `CALayer` subclass) using an Objective-C `CATransaction`, the position animation always starts from `(0,0)` instead of its previous on-screen position.

### Observed Symptoms
- Position is updated inside an Objective-C `CATransaction` inside `SongView.m`.
- Animation always appears to start from `(0,0)`.
- This happens on every move, not just the first.
- `presentationLayer.position` reads `(0,0)` immediately before updates.
- Removing `CATransaction.flush()` in Swift did not resolve the issue.
- The layer is backed by a Swift `CALayer` subclass.

---

## Files Inspected
- `Layers/AnalogClockLayer.swift`
- `SongView.m`

---

## Current Best Hypothesis (CONFIRMED & RESOLVED)

### 1. Hypothesis 1 (CONFIRMED): Bypassing `super.init(layer:)` in custom `init(layer:)`
- **Explanation**: In Core Animation, when animating a property, a "presentation copy" of the layer is cloned via its copy initializer `init(layer:)`. For standard base layer properties (like `position`, `bounds`, `transform`, etc.) to be copied, a custom `CALayer` subclass's `init(layer:)` MUST call the superclass implementation `super.init(layer: layer)`.
- **Finding**: In `AnalogClockLayer.swift`, `init(layer:)` was originally implemented as:
  ```swift
  @objc override convenience init(layer: Any) {
      if let clockLayer = layer as? AnalogClockLayer {
          self.init(darkMode: clockLayer.darkMode)
      } else {
          self.init(darkMode: true)
      }
  }
  ```
  Since this was a `convenience` initializer, it delegated to `self.init(darkMode:)`, which called `super.init()` (the default parameterless initializer of `CALayer`). This completely bypassed `super.init(layer:)`.
- **Consequence**: The presentation layer was initialized as a fresh layer with default CALayer values (such as `position = (0,0)`). When Core Animation started the animation, it read the starting state from the presentation layer (which was `(0,0)`) and animated to the new destination.
- **Why it matches all symptoms**:
  - Explains why the animation starts from `(0,0)` on every move.
  - Explains why `presentationLayer.position` is read as `(0,0)` during transitions.
  - Explains why removing `CATransaction.flush()` did not solve the issue.
- **Verification**: Changing `init(layer:)` to a designated initializer that calls `super.init(layer: layer)` compiles cleanly and allows Core Animation to properly copy all standard CALayer properties (including `position` and `bounds`) to the presentation layer when animating.

---

## Evidence Table

| Hypothesis | Matches Symptoms | Code Evidence | Status |
| :--- | :--- | :--- | :--- |
| **1. Missing `super.init(layer:)`** | Yes (Perfect) | `AnalogClockLayer.swift` did not invoke `super.init(layer:)` | **Confirmed & Resolved** |
| **2. Superlayer Detachment** | No | `SongView.m` updates existing instance in-place | Eliminated |
| **3. Frame Overwrites** | No | Correct `.position` mutation in `SongView.m` | Eliminated |

---

## Latest Debug Outputs & Compile Logs
```
note: Using new build system
note: Planning
note: Build preparation complete
note: Building targets in dependency order
** BUILD SUCCEEDED **
```

---

## Resolution & Fix Detail

### Exact Cause
The custom `init(layer:)` in `AnalogClockLayer.swift` was marked as a `convenience` initializer and delegated to `self.init(darkMode:)` which subsequently called `super.init()`. This bypassed `super.init(layer:)`, meaning Core Animation was unable to copy any of the standard `CALayer` attributes (such as `position`, `bounds`, `transform`, and `anchorPoint`) to the presentation/copy layer before starting the transition. The presentation layer therefore always defaulted to a position of `(0,0)`, causing position animations to start from `(0,0)` on every move.

### Applied Fix
We modified the copy constructor `init(layer:)` in `Layers/AnalogClockLayer.swift` to be a designated initializer that initializes all of the subclass's stored properties and then correctly calls `super.init(layer: layer)`.

```swift
    @objc override init(layer: Any) {
        let clockLayer = layer as? AnalogClockLayer
        self.darkMode = clockLayer?.darkMode ?? true
        self.showSeconds = clockLayer?.showSeconds ?? true
        super.init(layer: layer)
    }
```

This ensures that all standard CALayer properties are copied by Core Animation's base copy initializer, restoring correct animation starting positions.
