# Implementation Plan: Fix Core Animation Second Hand Jump

## Goal

Prevent the analog clock second hand from jumping during restoration by ensuring that animations only begin after the layer is attached to a live render tree, and prevent animation state from becoming the source of truth.

The clock should:

- Start in a correct position immediately.
- Only animate when attached to a visible window hierarchy.
- Never enter a rapid completion loop during initialization.
- Recover correctly after hiding, showing, sleep/wake, or restoration.
- Use the current time as the source of truth rather than animation completion state.

---

# Phase 1: Remove premature animation startup

## Current issue

The clock currently starts animation from initialization:

    DispatchQueue.main.async {
        self.updateAnimations()
    }

At this point:

- The layer may not have a containing view.
- The view may not have a window.
- Core Animation may not create a presentation layer.
- Animation completion callbacks may execute immediately.
- The update loop may recursively advance the model transform.

## Changes

Remove all animation startup calls from:

- `init`
- `initWithCoder:`
- `awakeFromNib`
- any layer construction methods

Initialization should only:

- Create layers.
- Configure appearance.
- Set initial properties.
- Store configuration.

It should not begin animations.

---

# Phase 2: Add explicit lifecycle control

## Add start method

Add an explicit method responsible for beginning clock operation.

Example:

    - (void)start
    {
        if (self.isRunning) {
            return;
        }

        self.isRunning = YES;

        [self updateAnimations];
    }

Requirements:

- Starting twice should have no effect.
- The method should assume the owner has verified lifecycle readiness.
- It should not be called during construction.

---

## Add stop method

Add a matching shutdown method.

Example:

    - (void)stop
    {
        self.isRunning = NO;

        [self removeAllAnimations];
    }

Purpose:

- Prevent updates when the view is removed.
- Avoid stale animation state.
- Allow clean restart after reattachment.

---

# Phase 3: Move lifecycle ownership to the view

## Responsibility change

The owning NSView should decide when the clock starts.

The view knows:

- whether it has a window.
- whether it is visible.
- whether restoration has completed.

The CALayer does not.

---

## Start after window attachment

Implement in the owning view:

    - (void)viewDidMoveToWindow
    {
        [super viewDidMoveToWindow];

        if (self.window) {
            [self.analogClockLayer start];
        }
        else {
            [self.analogClockLayer stop];
        }
    }

This ensures:

- The layer is in a live hierarchy.
- Core Animation can create presentation state.
- Animation timing behaves normally.

---

# Phase 4: Separate initial placement from animation

## Problem

The first animation after restoration should not interpolate from an arbitrary state.

The clock should immediately display the correct current time.

---

## Add immediate positioning method

Create a method that updates the hand positions without animation.

Example:

    - (void)setHandsToCurrentTime
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];

        self.secondHand.transform = targetTransform;
        self.minuteHand.transform = targetTransform;
        self.hourHand.transform = targetTransform;

        [CATransaction commit];
    }

---

## Startup sequence

Change startup order:

    viewDidMoveToWindow
        |
        +-- clock start
                |
                +-- setHandsToCurrentTime
                |
                +-- begin animation loop

The first visible frame should already be correct.

---

# Phase 5: Keep model and presentation state synchronized

Continue using the safe animation pattern:

1. Capture presentation transform.
2. Remove existing animation.
3. Sync model layer to current visible state.
4. Add explicit animation.
5. Update model layer to final target.

Example:

    - (void)animateHand:(CALayer *)hand toTransform:(CATransform3D)target
    {
        CATransform3D current = hand.presentationLayer ?
            hand.presentationLayer.transform :
            hand.transform;

        [CATransaction begin];
        [CATransaction setDisableActions:YES];

        [hand removeAnimationForKey:@"rotation"];

        hand.transform = current;

        CABasicAnimation *animation =
            [CABasicAnimation animationWithKeyPath:@"transform"];

        animation.fromValue =
            [NSValue valueWithCATransform3D:current];

        animation.toValue =
            [NSValue valueWithCATransform3D:target];

        animation.duration = self.animationDuration;

        animation.timingFunction =
            [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

        animation.fillMode = kCAFillModeRemoved;
        animation.removedOnCompletion = YES;

        [hand addAnimation:animation forKey:@"rotation"];

        hand.transform = target;

        [CATransaction commit];
    }

---

# Phase 6: Remove completion-driven animation looping

## Current design risk

Avoid:

    animation completes
        |
        completion block
        |
        update animation
        |
        completion block
        |
        repeat

Reason:

Animation completion is not a reliable clock.

It can be affected by:

- application suspension.
- window removal.
- view visibility.
- display throttling.
- system sleep/wake.
- layer tree changes.

---

## Replace with time-driven updates

Use a timer or display update mechanism.

Example:

    start
      |
      +-- schedule timer
              |
              +-- calculate actual current time
              |
              +-- animate toward next position

The animation is only a visual transition.

The actual time remains authoritative.

---

# Phase 7: Add lifecycle safety checks

Before any animation update:

Verify:

- The clock is running.
- The view has a window.
- The layer hierarchy is attached.
- The application is active if required.

Example:

    - (void)updateAnimations
    {
        if (!self.isRunning) {
            return;
        }

        if (!self.view.window) {
            return;
        }

        // Continue animation update
    }

---

# Phase 8: Add diagnostic logging

Add temporary lifecycle logging.

## Instance tracking

Log pointer addresses:

    NSLog(@"AnalogClockLayer init %p", self);

Add to:

- init
- initWithCoder:
- awakeFromNib
- start
- stop
- updateAnimations

Purpose:

Confirm that only one clock instance exists.

---

## Animation state logging

Log:

- window state.
- animation keys.
- presentation layer availability.
- current transform.
- target transform.
- update timestamps.

Example:

    NSLog(@"Clock update %p window=%@ presentation=%@ animations=%@",
          self,
          self.view.window ? @"YES" : @"NO",
          hand.presentationLayer ? @"YES" : @"NO",
          hand.animationKeys);

---

# Phase 9: Test scenarios

## Fresh launch

Expected:

- Clock appears immediately at correct time.
- Second hand smoothly advances.

---

## Restoration from saved state

Expected:

- No jump.
- No accelerated movement.
- No repeated completion callbacks.

---

## Window hidden then shown

Expected:

- Clock stops while detached.
- Clock resumes correctly.

---

## Sleep/wake

Expected:

- Clock recalculates position from current system time.
- No accumulated animation drift.

---

## Multiple initialization check

Expected:

- Exactly one clock layer instance.
- One animation loop only.

---

# Final Architecture

The final flow should be:

    NSView created
        |
        +-- create/configure clock layer
        |
        +-- no animation starts
        |
        v
    viewDidMoveToWindow
        |
        +-- verify window exists
        |
        +-- clock.start()
                |
                +-- snap hands to current time
                |
                +-- start time-driven updates
                        |
                        +-- calculate target position
                        |
                        +-- animate smoothly
                        |
                        +-- keep model layer synchronized

The clock's time state should come from the system clock. Core Animation should only provide smooth visual interpolation.