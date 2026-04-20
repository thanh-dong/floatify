# Floatify - macOS Floating Notification App for Claude Code

> Historical note: This design doc describes the removed temporary-notification and corner-position architecture. Current Floatify only supports persistent session floaters and CLI status updates.

A macOS menu bar daemon that renders animated floating notifications at configurable screen positions, triggered by Claude Code hooks. Features Lottie animations, sound effects, cursor-following mode, and per-position layout config.

---

## Overview

Floatify exploits unused screen real estate (gaps between editor windows and the Dock) to surface non-intrusive, attention-grabbing notifications. When Claude Code finishes a task, a floating panel appears with an animated duck icon, project label, and message - then auto-dismisses.

Two components:
1. Floatify.app - Background GUI app (LSUIElement, no Dock icon) that owns floating NSPanel overlays
2. floatify CLI - Thin binary that sends messages to the app via FIFO pipe IPC

---

## Architecture

```
Claude Code (CLI)
    |
    |  ~/.claude/settings.json hooks (PostToolUse / Stop)
    v
floatify CLI  (/usr/local/bin/floatify)
    |
    |  FIFO pipe IPC  "/var/tmp/floatify.pipe"
    |  latency < 1ms, no network, no permissions needed
    v
Floatify.app  (LSUIElement, runs at Login, no Dock icon)
    |
    |  FloatNotificationManager
    |    -> FloatPanel (NSPanel, .nonactivatingPanel, .popUpMenu level)
    |    -> FloatNotificationView (SwiftUI + Lottie animations)
    |    -> PositionConfigManager (per-corner layout)
    |    -> SoundManager (pop/tink/whoosh)
    |    -> CursorTracker (cursorFollow mode)
    v
Floating Notification  (animated entry, idle animations, timed dismiss)
```

---

## Component 1 - Floatify.app

### App Configuration (Info.plist)

```xml
<key>LSUIElement</key>
<true/>
```

LSUIElement = true means no Dock icon, no Cmd+Tab entry. The app runs silently with only a menu bar item.

### Build System

Uses XcodeGen (`project.yml`) instead of a manual Xcode project. Run `cd Floatify && xcodegen generate` to create the `.xcodeproj`.

Dependencies:
- Lottie (airbnb/lottie-ios, from 4.4.0) - SPM package for animated backgrounds

### IPC Server - FIFO Pipe Listener

The app creates a named FIFO pipe at `/var/tmp/floatify.pipe` and listens for JSON payloads. On launch, it removes any stale pipe and recreates it to avoid stale state from previous runs.

The JSON handler parses these fields:
- `message` (String) - notification text, default "Task complete!"
- `project` (String) - source project name, default "Claude Code"
- `corner` (String) - one of 8 positions, default "bottomRight"
- `duration` (Double) - auto-dismiss timeout in seconds, default 6.0
- `effect` (String, optional) - override animation effect name

### Corner Positions

8 supported positions, each with a default animation effect and optional sound:

| Corner | Effect | Sound |
|--------|--------|-------|
| bottomLeft | slide | - |
| bottomRight | slide | - |
| topLeft | slide | - |
| topRight | slide | - |
| center | fade | pop |
| menubar | dropdown | tink |
| horizontal | marquee | - |
| cursorFollow | trail | - |

Uses `NSScreen.main?.frame` for absolute screen-edge positioning (not `visibleFrame`, which respects Dock).

### Position Configuration

`PositionConfigManager` loads layout per corner from:
1. Bundled defaults at `Floatify/Resources/positions.json`
2. User overrides at `~/.floatify/positions.json` (merged on top)

Each position config has:
- `margin` - padding from screen edge in points
- `width` - panel width (default 280)
- `height` - panel height (default 68)
- `stackOffset` - vertical spacing between stacked panels

Defaults are hardcoded as fallback if no JSON files exist.

### NSPanel - Non-Activating Floating Overlay

```swift
class FloatPanel: NSPanel {
    var horizontalIndex: Int = 0
    var notificationCorner: Corner = .bottomRight
    var dismissController: DismissController?

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}
```

Panel properties:
- level: .popUpMenu (floats above all apps including fullscreen)
- collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]
- isOpaque: false, backgroundColor: .clear, hasShadow: false
- ignoresMouseEvents: false (tappable to dismiss early)

### Notification Stacking

- Max 8 panels visible at once (`maxPanels = 8`)
- Max 5 horizontal panels (`maxHorizontalPanels = 5`)
- Vertical stack offset per panel from PositionConfig (default 4px)
- Horizontal stack offset of 8px
- When cap is reached, oldest panel is dismissed first
- When any panel is dismissed, remaining panels reposition

### Cursor Following

`CursorTracker` provides cursor-following notifications via `NSEvent.mouseLocation` polled at 30fps via a Timer:
- When cursor is within 100px of a screen corner, panel snaps to that corner
- Otherwise panel follows cursor with a 20px right / 10px below offset
- Panel position is clamped to screen bounds with 20px edge padding

### DismissController

Manages animated entry and exit transitions:
- Entry: scale from 0.85 to 1.0 with spring animation, opacity 0 to 1
- Exit: scale from 1.0 to 0.85 with easeOut over 0.25s, opacity 0
- Calls `onDismissComplete` callback after exit animation finishes
- Panel is not removed from screen until exit animation completes

---

## Animation System

### Lottie Entry Animations

`LottiePanelBackground` is an NSViewRepresentable wrapping `LottieAnimationView`. Each corner has a default Lottie animation:

| Effect name | Lottie file |
|-------------|-------------|
| slide | slide_entry.json |
| fade | fade_entry.json |
| dropdown | dropdown_entry.json |
| marquee | marquee_entry.json |
| trail | trail_entry.json |

Exit animations:
- slide/dropdown/marquee/trail use exit_slide.json
- fade uses exit_fade.json

Lottie files live in `Floatify/Resources/Animations/`.

### Idle Animations (IdleAnimations.swift)

After the Lottie entry completes, these SwiftUI modifiers activate on the duck icon:
- `bobbing` - scale 1.0x to 1.04x with spring, repeating forever
- `glowPulse` - yellow shadow radius oscillating, repeating forever
- `floatDrift` - 2px vertical offset with easeInOut, repeating forever
- `hoverScale` - scale to 1.15x on mouse hover

### Particle System (FloatEffects.swift)

Used by cursorFollow mode. Emits particles at a position with random velocity, angle, and opacity. Particles fade out over 0.8s lifetime. Rendered via Canvas at 30fps.

Also includes reusable effects:
- `GlowModifier` - multi-layered shadow glow
- `ShimmerModifier` - animated gradient overlay with linear sweep
- `RippleView` - expanding circle with fading stroke

---

## Sound Effects

`SoundManager` loads and plays system sounds from `Sounds/` directory in the bundle:
- pop - used by center corner
- tink - used by menubar corner
- whoosh - loaded but not assigned to any default corner

Playback volume is 0.3. Sounds play on entry via `SoundManager.shared.play(effectiveSound)`.

---

## Component 2 - floatify CLI Tool

A separate Command Line Tool Xcode target, compiled into the app bundle, then symlinked to `/usr/local/bin/floatify` on first launch.

### Arguments

| Flag | Alias | Type | Default | Description |
|------|-------|------|---------|-------------|
| --message | - | String | "Task complete!" | Notification text |
| --position | --corner | String | "bottomRight" | Screen position |
| --duration | - | Double | 6 | Auto-dismiss timeout (seconds) |
| --project | - | String | "Claude Code" | Source project label |
| --effect | - | String | nil | Override animation effect |

Valid corner values: bottomLeft, bottomRight, topLeft, topRight, center, menubar, horizontal, cursorFollow.

The CLI validates the corner and duration before writing to the pipe. On failure, it prints a descriptive error to stderr with the duck emoji prefix.

### CLI Usage

```bash
# Minimal
floatify --message "Task complete!"

# Full options
floatify \
  --message "Task complete! Continue prompting" \
  --position bottomRight \
  --duration 8 \
  --project "MyApp"

# Cursor-follow mode
floatify --message "Build succeeded" --position cursorFollow

# With custom effect
floatify --message "Deploy done" --position center --effect fade
```

### Symlink Installation

On first launch, AppDelegate symlinks the bundled `floatify` binary to `/usr/local/bin/floatify`. A UserDefaults flag (`CLISymlinkInstalled`) prevents re-installation. If the symlink already exists, it is removed and recreated.

---

## Component 3 - Claude Code Integration

Claude Code hooks in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "floatify --message 'Floatify is waiting' --position bottomRight --duration 10"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "floatify --message 'Bash task done' --position bottomLeft --duration 5"
          }
        ]
      }
    ]
  }
}
```

| Hook | When it fires | Suggested use |
|------|---------------|---------------|
| Stop | Claude finishes a full task | Main notification, bottom-right |
| PostToolUse | After each tool call | Per-action status, bottom-left or center |
| PreToolUse | Before a tool runs | Optional "starting..." indicator |

---

## Project Structure

```
Floatify/
├── project.yml                          XcodeGen config
├── Floatify.xcodeproj/                  Generated Xcode project
├── Floatify/                            macOS App target
│   ├── main.swift                       App entry point
│   ├── AppDelegate.swift                FIFO pipe server + menu bar + symlink install
│   ├── FloatNotificationManager.swift    NSPanel factory + stacking + repositioning
│   ├── FloatNotificationView.swift       SwiftUI notification view + Lottie integration
│   ├── FloatEffects.swift               Particle system, glow, shimmer, ripple effects
│   ├── IdleAnimations.swift             Bob, glowPulse, floatDrift, hoverScale modifiers
│   ├── LottieAnimator.swift             DismissController + LottiePanelBackground
│   ├── SoundManager.swift               NSSound loading and playback
│   ├── CursorTracker.swift              Cursor position tracking + corner snapping
│   ├── PositionConfigManager.swift      JSON-based per-corner layout config
│   ├── Corner.swift                     Corner enum with default effects/sounds
│   ├── Info.plist                       LSUIElement = true
│   ├── Assets.xcassets/                 App icon
│   ├── Resources/
│   │   ├── positions.json               Default position configs
│   │   └── Animations/                  Lottie JSON files
│   │       ├── slide_entry.json
│   │       ├── fade_entry.json
│   │       ├── dropdown_entry.json
│   │       ├── marquee_entry.json
│   │       ├── trail_entry.json
│   │       ├── exit_slide.json
│   │       └── exit_fade.json
│   └── cli/                             CLI tool target
│       ├── main.swift                   Argument parser + FIFO pipe client
│       └── Info.plist
└── Floatify Plan.md                     This file
```

Xcode targets:
- Floatify - macOS App, deployment target macOS 13+, links Lottie SPM package
- floatify - Command Line Tool, no external dependencies

---

## Key Technical Decisions

Why FIFO pipe over CFMessagePort or HTTP?
FIFO pipe is macOS-native, requires no server setup, has sub-millisecond latency, and works with zero network permissions. No firewall or security approval dialogs needed.

Why `NSScreen.frame` over `NSScreen.visibleFrame`?
`frame` gives absolute screen edges regardless of Dock state. `visibleFrame` respects Dock size/position, which causes notifications to jump when the Dock auto-hides.

Why `NSPanel` with `.nonactivatingPanel` over `NSWindow`?
Prevents the notification from stealing keyboard focus from the active editor. Critical when Claude Code is waiting and the developer is mid-typing.

Why `.popUpMenu` window level?
Floats above all standard app windows without blocking mouse events on underlying apps. Combined with `.fullScreenAuxiliary`, it appears alongside fullscreen apps.

Why XcodeGen over manual .xcodeproj?
Declarative `project.yml` is easier to maintain and diff than the binary-ish Xcode project format. Generates the `.xcodeproj` on demand.

Why Lottie over Core Animation?
Lottie animations are authored in After Effects and exported as JSON - no code changes needed to tweak animations. The `lottie-ios` library renders them efficiently on the GPU. Only 7 small JSON files in the bundle.

---

## Edge Cases and Mitigations

| Edge case | Mitigation |
|-----------|------------|
| Multiple monitors | Defaults to `NSScreen.main`; multi-monitor-aware positioning is a future enhancement |
| Dock on left/right side | Frame-based positioning always uses absolute edges |
| Dock set to auto-hide | Frame-based positioning keeps notifications at true screen edges |
| Floatify.app not running | CLI prints descriptive error with duck emoji and exits code 1 |
| Rapid successive triggers | Panels cap at 8 total (5 horizontal); oldest dismissed first; 4px vertical stacking |
| Pipe stale state | AppDelegate removes and recreates pipe on every launch |
| Symlink conflicts | AppDelegate removes existing symlink before creating new one |
| Invalid CLI arguments | Corner and duration validated before pipe write; helpful error messages |
| Fullscreen apps | `.fullScreenAuxiliary` + `.canJoinAllSpaces` ensures notifications appear |
