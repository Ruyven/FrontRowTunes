# Scope: System Appearance Mode

## Goal

Introduce a third appearance mode that follows the macOS system appearance.

The app currently supports two manually selected appearance modes:

- White background mode
- Black background mode

The new implementation should support three mutually exclusive modes:

- **Light** — equivalent to the current white background mode
- **Dark** — equivalent to the current black background mode
- **System** — follows the current macOS system appearance and automatically switches between Light and Dark when the system appearance changes

The existing White/Black behavior should remain unchanged when either manual mode is selected.

The existing `W` and `B` hotkeys should continue to select their respective manual modes. A new `S` hotkey will select System mode.

---

## Implementation Plan

Follow the plan laid out in the implementation files `step-1.md`-`step-5.md`.

Before starting a new step, review the implementation file against the new code. If inconsistencies are found, update the implementation file before starting implementation.

---

## Step 1 — Replace the current white-background Boolean with an Appearance Mode Enum

### Objective

Replace the existing Boolean state that distinguishes white background from black background with an enum representing all three appearance modes.

The enum should conceptually contain:

- `light`
- `dark`
- `system`

Use names appropriate to the existing codebase.

### Default

During development, the new appearance mode should default to:

`system`

This makes it possible to develop and test the new behavior without requiring the user to manually select System mode.

The final default can be reconsidered separately if necessary.

### State Refactor Only

Identify all in-memory and rendering uses of the current white-background Boolean and replace them with the new enum/effective-appearance model.

Step 1 should not read, write, migrate, or otherwise change user defaults. Persisted preference migration from the legacy `whiteBackground` key belongs to Step 3.

Avoid introducing separate Boolean state for System mode. There should be one authoritative selected appearance-mode value.

### Important distinction

The selected appearance mode and the currently displayed appearance are different concepts.

For example:

- Selected mode = `system`
- macOS = Dark
- Effective appearance = Dark

If macOS subsequently changes to Light:

- Selected mode remains `system`
- Effective appearance changes to Light

The app should not change the selected mode from `system` to `light` or `dark` as a result of the system appearance changing.

---

## Step 2 — Detect and Observe the macOS System Appearance

### Objective

Implement detection of the current macOS appearance and observe changes to it.

The app needs to be able to determine whether the system is currently using Light or Dark appearance.

The implementation should provide a single conceptually defined value for the **effective appearance**:

- If selected mode is `light`, effective appearance = Light
- If selected mode is `dark`, effective appearance = Dark
- If selected mode is `system`, effective appearance = current macOS appearance

### Initial detection

When the app starts, or when the relevant appearance state is initialized, determine the current system appearance.

This must work correctly when System mode is already selected.

### Notifications / observation

When the system appearance changes while the app is running:

1. Receive the appropriate macOS appearance-change notification/event.
2. Determine the new system appearance.
3. If the selected mode is `system`, update the app's effective appearance.
4. Trigger the same UI/rendering update that would occur when manually switching between Light and Dark.

If the selected mode is `light` or `dark`, a system appearance change should have no visible effect on the app.

### Avoid duplicated appearance logic

Where practical, existing code that currently reacts to the White/Black setting should consume the effective appearance rather than independently checking the selected mode.

For example, rendering code should conceptually ask:

`What is the effective appearance?`

rather than:

`Is white background enabled?`

This should make the distinction between selected mode and effective appearance explicit.

### Lifecycle / observer cleanup

Follow the existing project's conventions for registering and removing observers.

Ensure that observers do not accumulate if the relevant object is recreated or reinitialized.

---

## Step 3 — Default colour scheme and user defaults

Update user defaults: instead of storing a single boolean for `whiteBackground`, store the enum as an int.

If a legacy `whiteBackground` value exists, migrate it as follows:

- `true` -> light mode (white background)
- `false` -> dark mode (black background)

If no legacy value exists, default the new value to System mode as specified in Step 1.

---

## Step 4 — Add the `S` Hotkey for System Mode

### Objective

Add a new keyboard shortcut:

**S → System appearance mode**

The existing shortcuts remain:

- **W → Light**
- **B → Dark**

The new `S` shortcut should set the selected appearance mode to `system`.

### Behavior

If the current selected mode is:

- Light → pressing `S` changes it to System
- Dark → pressing `S` changes it to System
- System → pressing `S` has no meaningful state change

After selecting System mode, the app should immediately use the current macOS appearance.

For example:

1. App is currently in Dark mode.
2. User presses `S`.
3. Selected mode becomes System.
4. macOS is currently Light.
5. App immediately changes to Light appearance.

Likewise, if macOS is currently Dark, selecting System should immediately result in Dark appearance.

### Existing shortcuts

Do not change the existing semantics of:

- `W`
- `B`

They should continue to directly select the corresponding manual appearance modes.

---

## Step 5 — Add System Mode to the Existing Preferences Panel

### Objective

Expose all three appearance modes in the existing preferences UI.

The user should be able to select:

- Light
- Dark
- System

Use the existing preferences panel's UI conventions rather than introducing a new control style unless necessary.

### Selection behavior

Changing the preference should immediately update the app's effective appearance.

Examples:

- Select Light → immediately use Light appearance
- Select Dark → immediately use Dark appearance
- Select System → immediately use the current macOS appearance

When System is selected, the preference UI should continue to show System as selected even when the effective appearance changes because macOS changes.

For example:

`Selected preference: System`
`macOS appearance: Dark`
`Effective appearance: Dark`

After macOS changes:

`Selected preference: System`
`macOS appearance: Light`
`Effective appearance: Light`

The selected preference remains System in both cases.

### Persistence

The selected appearance mode should be persisted using the app's existing preferences mechanism.

On subsequent launches, the persisted value should determine the selected mode.

If no value exists yet during migration/development, default to System as specified in Step 1.

---

## Non-Goals

The following are explicitly outside the scope of this change:

- Redesigning the existing appearance styling.
- Changing the visual appearance of Light or Dark mode.
- Changing the existing `W` or `B` shortcuts.
- Adding a three-way cycling hotkey.
- Supporting custom colors or additional themes.
- Adding an independent "automatic schedule" unrelated to the macOS system appearance.

---

## Acceptance Criteria

### Appearance modes

- [ ] There is one authoritative selected appearance mode with three possible values: Light, Dark, System.
- [ ] Existing White mode behavior is preserved as Light.
- [ ] Existing Black mode behavior is preserved as Dark.
- [ ] System mode follows macOS appearance.

### System detection

- [ ] The current macOS appearance can be detected.
- [ ] The initial effective appearance is correct when System mode is selected.
- [ ] The app observes macOS appearance changes.
- [ ] Changing macOS appearance while System mode is selected updates the app automatically.
- [ ] Changing macOS appearance while Light or Dark is selected does not affect the app.

### Hotkeys

- [ ] `W` selects Light.
- [ ] `B` selects Dark.
- [ ] `S` selects System.
- [ ] Selecting System via `S` immediately applies the current system appearance.

### Preferences

- [ ] The preferences panel exposes Light, Dark, and System.
- [ ] The selected mode is visibly represented in the preferences UI.
- [ ] Selecting a mode takes effect immediately.
- [ ] System remains selected when the effective appearance changes due to a macOS appearance change.
- [ ] The selected mode is persisted.
- [ ] A missing/unmigrated preference defaults to System during development.

### Architecture

- [ ] Rendering/appearance code can distinguish selected mode from effective appearance.
- [ ] System appearance observation does not create duplicate observers.
- [ ] Existing appearance update mechanisms are reused where appropriate rather than creating a separate update path specifically for System mode.
