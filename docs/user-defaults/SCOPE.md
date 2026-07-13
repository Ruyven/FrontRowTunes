# Scope: Persist User Settings with NSUserDefaults

## Objective

Persist user-configurable settings across application launches using `NSUserDefaults`.

The implementation should:
- Save settings immediately whenever they are changed.
- Restore all settings during startup.
- Display the information/tutorial panel automatically on first launch only.

---

## Requirements

### 1. Add setter methods

Replace direct assignment of configurable variables with setter methods.

Instead of:

    displayClock = true;

Use:

    setDisplayClock(true);

Each setter should:

1. Update the backing variable.
2. Perform any existing UI/update logic associated with the setting.
3. Immediately write the value to `NSUserDefaults`.

This ensures all setting changes are automatically persisted.

---

## Existing settings to persist

Persist the following existing boolean variables:

- displayClock
- analogClock
- analogClockFullScreen
- clockSeconds
- displayPlayerPositionBar
- displayPlayerPositionLabel
- whiteBackground

Each should have a corresponding setter.

Suggested naming:

- setDisplayClock(bool)
- setAnalogClock(bool)
- setAnalogClockFullScreen(bool)
- setClockSeconds(bool)
- setDisplayPlayerPositionBar(bool)
- setDisplayPlayerPositionLabel(bool)
- setWhiteBackground(bool)

The exact naming may be adjusted to match existing project conventions.

---

## NSUserDefaults keys

Create one user defaults key per setting.

Suggested keys:

- displayClock
- analogClock
- analogClockFullScreen
- clockSeconds
- displayPlayerPositionBar
- displayPlayerPositionLabel
- whiteBackground

Consistent naming is more important than the exact strings.

---

## Saving

Whenever a setter is called:

- Update the instance variable.
- Store the new value in `NSUserDefaults`.

No separate "Save Settings" action should exist.

---

## Restoring

In `awakeFromNib`:

1. Read each setting from `NSUserDefaults`.
2. Apply it by calling its setter rather than assigning directly.

Using the setters ensures:

- UI state is restored correctly.
- Existing update logic runs in one place.
- Future changes only need to modify the setter implementation.

For first launch, if a key has never been stored, use the current application's existing default values.

---

# Tutorial Tracking

## New variable

Add:

    int hasShownTutorial;

Persist it using `NSUserDefaults`.

---

## Startup behaviour

During `awakeFromNib`:

Read `hasShownTutorial`.

If its value is:

- 0
  - Open the information/tutorial panel.
  - Store `hasShownTutorial = 1`.

- 1
  - Do nothing.

The tutorial should therefore appear automatically only on the first launch after installation (or after preferences are cleared).

---

## User default key

Suggested key:

- hasShownTutorial

---

## Acceptance Criteria

- Every configurable setting listed above survives application restart.
- Changing a setting immediately updates `NSUserDefaults`.
- No direct assignments remain for persisted settings; callers use setter methods instead.
- `awakeFromNib` restores all persisted settings through the setters.
- First launch automatically opens the information/tutorial panel.
- Subsequent launches do not automatically open the tutorial.