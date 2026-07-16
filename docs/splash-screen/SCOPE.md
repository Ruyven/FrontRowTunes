# Scope: Splash Screen (Playback Stopped State)

## Objective
When music playback is stopped, instead of showing a simple "Playback stopped" text, display a rich "splash screen" using the existing `SongLayer` / `SongView` architecture. This provides a more polished and consistent UI when the app is idle.

## Requirements

### Visuals
- **Placeholder Art**: Use the `FrontRowGradient` asset instead of album artwork.
- **High-DPI Support**: Ensure `FrontRowGradient` has 2x and 3x versions for Retina displays.
- **Information**:
  - Track Title: "FrontRowTunes"
  - Artist Name: "Playback stopped"
- **UI Elements to Hide**:
  - Pause/Play icon.
  - Playback progress bar (status bar).
  - Playback time text (e.g., "02:45 / 04:30").
- **UI Elements to Keep**:
  - Clock (if enabled/applicable).

### Transitions

When playback starts, ensure the normal next-track-animation transition is applied.

When playback stops, e.g. Music app is quit, use the same animation to transition back to the splash screen.

### Loading state

Press space: change text "Playback stopped" to "Starting playback..."

Note: if the Music app is not running, this launches the Music app but doesn't actually start playback.
Suggested fix:
- on space input, detect if Music app is running
- if not:
	- Keep track in a local variable named "playbackRequested: bool"
	- set playbackRequested=true
	- after 1 second, trigger playback again (as long as playbackRequested is still true)
	- if Music app still not running (which means it's starting), wait for 1 second again
	- if Music app running, trigger playback again and set playbackRequested=false


Press right: change text to "Loading next track..."
Press left: change text to "No previous track" for 2 seconds, then back to "Playback stopped"

### Technical Implementation
- Modify `SongLayer` or `SongView` (whichever handles the "stopped" state) to render this "splash" configuration.
- Update asset catalog with high-resolution versions of `FrontRowGradient`.

## Success Criteria
- Opening the app while music is stopped shows the splash screen.
- Stopping music playback transitions to the splash screen.
- Resuming music playback correctly restores the actual track metadata and artwork.
