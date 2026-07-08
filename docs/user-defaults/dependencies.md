# Dependencies for User Defaults Restoration

This document maps the dependencies between user settings to ensure they are restored in the correct order during application launch.

## Dependency Map

- `clockSeconds` → `analogClockFullScreen` (Clock seconds preference must be restored before the full-screen clock is initialized).
- `whiteBackground` → `analogClock` (Background color affects the initial tint and dark mode of the analog clock).
- `whiteBackground` → `activeSongLayer` (Background color affects the `SongLayer` initialization).
- `displayClock` → `analogClock` (Whether to show the clock at all affects whether the analog clock layer should be set up).
- `analogClock` → `activeSongLayer.displayClock` (If analog clock is active, the digital clock in `SongLayer` must be hidden).
- `displayPlayerPositionBar` → `activeSongLayer`
- `displayPlayerPositionLabel` → `activeSongLayer`

## Restoration Order Recommendation

To avoid redundant UI updates and ensure correct initial state, settings should be restored in an order that resolves these dependencies:

1. `whiteBackground`
2. `clockSeconds`
3. `displayClock`
4. `analogClock`
5. `analogClockFullScreen`
6. `displayPlayerPositionBar`
7. `displayPlayerPositionLabel`
