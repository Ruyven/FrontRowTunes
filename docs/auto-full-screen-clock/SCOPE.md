# Scope: Expand Screensaver Activation Feature

## Overview

The app currently includes a "screensaver" mode that automatically activates while a track is playing. When triggered, it enters full-screen mode and displays the screensaver experience.

This project expands that behaviour by:
- making the activation delay configurable,
- extending activation to non-music scenarios,
- exposing configuration to users through preferences.

The implementation should be staged to keep changes isolated and allow earlier phases to ship independently.

---

# Phase 1: Configurable Screensaver Delay

## Goal

Make the automatic screensaver activation delay configurable through user defaults.

The preference should not be exposed in the UI yet. It should only be editable through the preferences plist / user defaults system.

## Requirements

- Add a user defaults value controlling the screensaver activation delay.
- A value of `0` disables automatic screensaver activation.
- Existing behaviour should remain unchanged unless the value is modified.
- The default value should match the current hard-coded delay.

## Preference Naming

The preference name should be chosen with future expansion in mind.

Choose a music-specific name, since Phase 2 will implement activation beyond music playback.

Suggested naming direction:

- `musicScreensaverDelay`
- `trackScreensaverDelay`
- `playingScreensaverDelay`

Avoid names such as:

- `screensaverActivationDelay`
- `screensaverDelay`
- `fullScreenScreensaverDelay`

The preference should describe the general screensaver activation behaviour, not its current trigger condition.

## Acceptance Criteria

- Screensaver activates after the configured delay while music is playing.
- Setting the value to `0` prevents automatic activation.
- No UI changes are introduced.
- Existing users receive the current behaviour through the default value.

---

# Phase 2: Enable Screensaver Without Music Playback

## Goal

Allow the screensaver feature to activate even when no music is playing, provided the full-screen clock feature is enabled.

## Requirements

- The existing activation mechanism should be extended to support multiple activation conditions.
- Music playback remains one activation condition.
- Full-screen clock enabled state becomes another activation condition.
- The same configurable delay from Phase 1 should apply.

## Behaviour

Screensaver activation should occur when:

    (music is playing OR full-screen clock is enabled)
    AND
    screensaver activation delay has elapsed
    AND
    screensaver activation is not disabled

## Preference Considerations

Choose a preference name matching the Phase 1 preference name.

Examples:

- `fullScreenClockScreensaverDelay`
- `clockScreensaverDelay`
- `analogClockScreensaverDelay`

## Acceptance Criteria

- Screensaver can activate with music stopped.
- Screensaver can activate when full-screen clock mode is enabled.
- Delay configuration continues to work unchanged.
- Disabling the delay (`0`) disables automatic activation for all modes.

---

# Phase 3: Preferences Panel Integration

## Goal

Expose screensaver activation settings in the application preferences.

## Investigation Required

Before implementation, investigate whether the existing app architecture can support a SwiftUI-based preferences panel.

Questions to answer:

- Can a new SwiftUI preferences panel be integrated cleanly into existing windows and panels?
- Are preference bindings compatible with user defaults?
- Would introducing SwiftUI create unnecessary architectural complexity?

## Implementation Options

If practical:

- Add a preferences section for screensaver settings.
- Bind controls directly to user defaults.
- Provide a user-friendly explanation of the delay behaviour.
- Include an option to disable automatic activation.

This is likely to be split out into a separate PR.

## Acceptance Criteria

- Users can configure screensaver activation without editing plist files.
- Existing user defaults continue to work.
- Preference UI matches the application's existing design patterns.

---

# Out of Scope

- Redesigning the screensaver experience.
- Changing full-screen clock functionality itself.
- Changing manual screensaver activation behaviour.

---

# Implementation Notes

- Keep activation logic independent from the current music-only trigger where possible.
- Prefer a general activation state model that can accommodate future triggers.
- Avoid coupling preference names or APIs to music playback.

---

# Phase planning

Have a look at docs/auto-full-screen-clock/SCOPE.md

Plan out phase n against the codebase, writing a neighboring `phase-n.md`
Spend at most 5 minutes acquainting yourself with the code