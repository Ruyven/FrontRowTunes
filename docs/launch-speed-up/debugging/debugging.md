# Debugging Plan: Startup Performance & Music.app Launch Investigation

## Goal

Determine exactly which operations:

- block the UI thread,
- launch `Music.app`,
- cause the startup delay,
- and cause Music to relaunch after being quit.

The objective is to gather evidence before implementing changes.

---

# Question 1

## Which AppleScript calls are actually slow?

### Hypothesis

One or more `MusicBridge` methods are taking multiple seconds during startup.

### Tasks

1. Locate every call into `MusicBridge` during startup.
2. Wrap every call with timing logs.

Example:

    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    Track *track = [MusicBridge getCurrentTrack];
    NSLog(@"getCurrentTrack took %.3f seconds",
          CFAbsoluteTimeGetCurrent() - start);

Repeat for:

- `getCurrentTrack`
- `getPlayerState`
- `getPlayerPosition`
- artwork retrieval
- any other startup query

### Test

Run twice:

- Music.app already running
- Music.app not running

### Record

For each call:

- elapsed time
- whether Music launched
- whether UI became unresponsive

---

# Question 2

## Which call actually launches Music.app?

### Hypothesis

Not every AppleScript necessarily launches Music.

Determine exactly which method is responsible.

### Tasks

Temporarily disable all startup calls except one.

Example:

    Only call:

    getPlayerPosition()

Observe whether Music launches.

Repeat for:

- `getPlayerPosition`
- `getPlayerState`
- `getCurrentTrack`
- `getArtwork`
- etc.

### Goal

Produce a table:

| Method | Launches Music? |
|---------|-----------------|
| `getPlayerPosition` | Yes/No |
| `getCurrentTrack` | Yes/No |
| `getPlayerState` | Yes/No |
| ... | ... |

---

# Question 3

## Does `NSRunningApplication` avoid launching Music?

### Hypothesis

`NSRunningApplication.runningApplications(...)` never launches Music.

### Tasks

Create a tiny test program:

    print(isMusicRunning())

Run while Music is closed.

Observe:

- Does Music launch?
- Is the check instantaneous?

---

# Question 4

## Does `updatePlayerPosition()` relaunch Music?

### Hypothesis

The timer is solely responsible.

### Tasks

Disable:

    updatePlayerPositionTimer

Leave everything else unchanged.

Run:

1. Start FrontRowTunes.
2. Manually launch Music.
3. Quit Music.

Observe:

- Does Music relaunch?

If not:

The timer is confirmed as the culprit.

---

# Question 5

## Does the timer contribute to startup delay?

### Hypothesis

Probably not.

### Tasks

Measure startup twice.

Version A:

    Timer enabled

Version B:

    Timer disabled

Everything else identical.

Compare startup time.

---

# Question 6

## Are startup AppleEvents running on the main thread?

### Hypothesis

Yes.

### Tasks

Add:

    NSLog(@"Main thread: %d",
          [NSThread isMainThread]);

inside every `MusicBridge` method.

Record results.

---

# Question 7

## Can AppleEvents safely execute on a background thread?

### Hypothesis

Probably yes.

### Tasks

Move one harmless query, such as:

    getPlayerState()

onto a background queue.

Example:

    dispatch_async(...)

When complete:

    dispatch_async(main)

Update a label.

Observe:

- Does it work?
- Any crashes?
- Any AppleScript thread-safety issues?
- Does the UI remain responsive?

---

# Question 8

## Are distributed notifications sufficient to refresh the UI?

### Hypothesis

After Music launches, the existing

    com.apple.Music.playerInfo

notification already provides everything needed.

### Tasks

Start with:

- FrontRowTunes open
- Music closed

Launch Music manually.

Observe:

- Is notification received?
- Is `getTrack:` called?
- Does artwork appear?
- Does player state update?
- Does progress bar start?

Record anything still requiring polling.

---

# Question 9

## Is polling still necessary?

### Hypothesis

Only playback position requires polling.

Everything else may already be notification-driven.

### Tasks

Temporarily disable:

    updatePlayerPosition()

Observe:

What stops updating?

Result table:

| UI Element | Updated by `com.apple.Music.playerInfo` Notification | Requires Polling (`updatePlayerPosition`) |
|------------|-------------------------------------------------------|-------------------------------------------|
| Artwork | ✓ | ✖ |
| Song title | ✓ | ✖ |
| Artist | ✓ | ✖ |
| Album | ✓ | ✖ |
| Play/Pause state | ✓ | ✖ |
| Playback position / progress bar | ✖ | ✓ |

---

# Question 10

## How much startup time is caused by AppleScript compilation vs execution?

### Hypothesis

Repeatedly creating and compiling AppleScript may also contribute to latency.

### Tasks

Inspect `MusicBridge.swift`.

Determine:

- Is a new `NSAppleScript` created for every call?
- Is it compiled every time?
- Is anything cached?
- Is `NSUserAppleScriptTask` used?
- Is `NSAppleEventDescriptor` used directly?

Record the architecture.

---

# Deliverables

Produce a short report answering:

1. Which methods launch Music.app?
2. Which methods are slow?
3. Which methods execute on the main thread?
4. Does `NSRunningApplication` avoid launching Music?
5. Does the timer cause startup delay?
6. Does the timer cause Music relaunch?
7. Can AppleEvents safely run off the main thread?
8. Can startup AppleEvents be made asynchronous?
9. Is polling only needed for playback position?
10. What is the minimal code change that removes startup beachballs while preserving functionality?