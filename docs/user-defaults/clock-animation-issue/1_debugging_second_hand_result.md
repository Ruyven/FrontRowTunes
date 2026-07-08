# Debugging Results: Core Animation Second Hand Jump

## Problem Summary
A CoreAnimation-based analog clock exhibited a bug where the second hand would jump approximately 20 seconds forward during restoration (e.g., in `awakeFromNib`). Diagnostics revealed that this was caused by a desynchronization between the Model Layer and the Presentation Layer, combined with a "rapid-fire" animation loop when the layer was not yet windowed.

---

## Investigation of Suspected Issues

### Issue 1: `fillMode = .forwards`
**Analysis:** Using `fillMode = .forwards` and `isRemovedOnCompletion = false` pins the presentation layer to the animation's `toValue`, even if the model layer differs. This creates a "ghost" state that persists after the animation logically ends.
**Verdict:** **Confirmed as a contributing factor.** This causes the presentation layer to remain at the "future" position, which is then captured as the `fromValue` for the next animation.
**Fix:** Use `fillMode = .removed` and `isRemovedOnCompletion = true`. Sync the model layer to the target value to maintain visual persistence.

Result:

It's NOT a simple Model/Presentation desynchronization (Issues 1, 2, 3, & 5)  
If the jump were caused by fillMode = .forwards or a failure to sync the model layer before adding a new animation, the Golden Sequence would have solved it. By explicitly capturing the presentation() transform and syncing the model layer immediately before adding the new animation, we eliminated "snapping" and "ghost" states. Since the jump persists, the problem is deeper than just property synchronization.

### Issue 2: Existing animations not being removed
**Analysis:** While adding an animation with the same key replaces the previous one, doing so without syncing the model layer can cause a jump if the new `fromValue` doesn't perfectly match the current presentation state.
**Verdict:** **Contributing factor.** Rapidly adding animations during restoration without explicit removal and syncing leads to jumps.
**Fix:** Explicitly call `removeAnimation(forKey:)` and sync the model layer to the current presentation transform before adding a new animation.

Result: eliminated (see issue 1)

### Issue 3: Presentation layer usage
**Analysis:** `layer.presentation()` is the only source of truth for the current visible state. However, relying on it while a `fillMode = .forwards` animation is active can lead to capturing a "future" state rather than the actual current interpolation.
**Verdict:** **Confirmed.** The "Golden Sequence" is required to ensure a smooth transition from the current visible state to the new target.
**Fix:** Capture presentation transform $ightarrow$ remove animation $ightarrow$ sync model $ightarrow$ add new animation $ightarrow$ update model.

Result: eliminated (see issue 1)

### Issue 4: Animation key naming
**Analysis:** The distinction between `keyPath` (the property being animated) and the animation key (the identifier) is standard.
**Verdict:** **Not an issue.** `keyPath: "transform"` with `forKey: "rotation"` is functionally correct.

### Issue 5: Model layer updates
**Analysis:** Explicit animations (`CABasicAnimation`) do not update the model layer. If the model layer is not updated to the `toValue`, the layer will snap back to its original value once the animation is removed.
**Verdict:** **Required behavior.** Model updates must always accompany explicit animations.

Result: eliminated (see issue 1)

### Issue 6: CATransaction
**Analysis:** Mixing `CATransaction.setAnimationDuration()` (which triggers implicit animations) and `CABasicAnimation` (explicit) creates conflicting animations on the same property.
**Verdict:** **Confirmed.** Conflicts between implicit and explicit animations can cause erratic behavior.
**Fix:** Wrap all model updates in `CATransaction.setDisableActions(true)` when using explicit animations.

Result:

It's NOT a conflict between Implicit and Explicit animations (Issue 6)  
By using CATransaction.setDisableActions(true) and explicit CABasicAnimation, we removed all implicit animation interference. Since the bug remains, the issue is not coming from CATransaction duration conflicts.

---

## Final Recommended Implementation Pattern

To eliminate jumps and ensure perfectly smooth transitions, the following "Golden Sequence" must be used:

```swift
private func setHandRotation(_ hand: CALayer, _ rotation: CGFloat) {
    let angle = -rotation * 2 * CGFloat.pi / 60
    let targetTransform = CATransform3DMakeRotation(angle, 0, 0, 1)
    
    // 1. Capture the current VISUAL state (Presentation Layer)
    let currentTransform = hand.presentation()?.transform ?? hand.transform
    
    CATransaction.begin()
    // 2. Disable implicit animations to prevent conflicts
    CATransaction.setDisableActions(true)
    
    // 3. Remove old animation and sync model to current visual state
    // This prevents the "snap" when the old animation is removed
    hand.removeAnimation(forKey: "rotation")
    hand.transform = currentTransform
    
    // 4. Create explicit animation starting from current visual state
    let animation = CABasicAnimation(keyPath: "transform")
    animation.fromValue = NSValue(caTransform3D: currentTransform)
    animation.toValue = NSValue(caTransform3D: targetTransform)
    animation.duration = animationDuration
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    
    // Use standard removal to keep model/presentation in sync
    animation.fillMode = .removed 
    animation.isRemovedOnCompletion = true
    
    // 5. Apply animation
    hand.add(animation, forKey: "rotation")
    
    // 6. Set model to final destination
    hand.transform = targetTransform
    
    CATransaction.commit()
}
```
