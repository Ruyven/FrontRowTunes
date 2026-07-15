# FrontRowTunes

<img src="docs/images/FrontRowTunes-splash.png" alt="splash screen" />

After FrontRow was removed in Mac OS X 10.7 Lion, in 2013 I decided to build a little app that brings back a FrontRow-like music experience, but for music playing in iTunes. Later updated to support the Music app instead.

## Features

- Show currently playing track with album art
- Animated with Core Animation, e.g. on track change
- Press [ W ] to turn background white, [ B ] to turn it black
- Press [ F ] to toggle between full-screen and windowed mode
- Press space to play/pause, arrow keys to select next/previous track
- Display current playback progress as position bar and/or position as mm:ss - press [ ↵ ] or [ fn ] [ ↵ ] to toggle through options.
- Clock (analog or digital) - press [ T ] to toggle through options or [ shift ] [ T ] to hide the clock completely
- Press [ option ] [ T ] to show a full-screen clock instead of currently playing track
- In-app tutorial shown on first launch - press [ I ] or [ H ] to invoke it again

## Screensaver mode

By default, FrontRowTunes enters "screensaver mode" - entering full-screen and/or activating itself - when either music is playing, or the full-screen clock is enabled.

This can be adjusted via user defaults. Examples:

- When music is playing, and clock is not full-screen, enter screensaver mode after 2 minutes  

        defaults write com.ruyven.FrontRowTunes musicScreensaverDelay -float 120

- Only enter screensaver mode when clock is full-screen - not depending on whether music is playing

        defaults write com.ruyven.FrontRowTunes musicScreensaverDelay -float 0

- When clock is full-screen, enter screensaver mode after 30 seconds

        defaults write com.ruyven.FrontRowTunes clockScreensaverDelay -float 30

- Only enter screensaver mode when music is playing - not when clock is full-screen and music is paused

        defaults write com.ruyven.FrontRowTunes clockScreensaverDelay -float 0

