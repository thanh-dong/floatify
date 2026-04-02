# Remove Floatify Startup Alerts Design

## Overview

Remove two modal alerts that interrupt the user when Floatify app launches:
1. "Floatify Started" startup alert
2. "Install floatify CLI?" installation alert

Both will be replaced with silent background behavior.

## Changes

### AppDelegate.swift

**Remove startup alert** - Delete the NSAlert block in `applicationDidFinishLaunching`:

```swift
// REMOVE this block:
let alert = NSAlert()
alert.messageText = "Floatify Started"
alert.informativeText = "The app has started successfully"
alert.runModal()
```

**Make CLI install silent** - Remove the NSAlert prompt in `installCLIToolIfNeeded()`, attempt install directly, log failures:

- Remove `NSAlert` construction and `runModal()` call
- Keep the symlink creation logic
- Replace permission-denied alert with `NSLog`
- Keep `UserDefaults` check to avoid repeated install attempts

## Success Criteria

- App launches without any visible modal dialogs
- CLI symlink is installed automatically on first launch
- Permission failures are logged, not shown to user
