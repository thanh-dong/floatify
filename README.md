# Floatify

A lightweight macOS menu bar daemon that renders animated floating notifications in screen dead zones.

## Features

- Animated notifications appear in screen corners (bottom-left, bottom-right, top-left, top-right)
- Cursor-follow mode for dynamic positioning
- Sub-millisecond IPC via FIFO pipes
- No Dock icon (LSUIElement app)
- Stacking support with up to 3 visible notifications
- Configurable via Claude Code hooks

## Installation

### Build from Source

```bash
cd Floatify
xcodegen generate
xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Release build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

### Run the App

```bash
open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/Floatify.app
```

Approve the CLI symlink prompt when it appears.

## Quick Start

```bash
floatify --message 'Task complete!' --corner bottomRight --duration 6
```

## Claude Code Integration

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "floatify --message 'Floatify is waiting' --corner bottomRight --duration 10"
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
            "command": "floatify --message 'Bash done' --corner bottomLeft --duration 5"
          }
        ]
      }
    ]
  }
}
```

## CLI Reference

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `"Task complete!"` |
| `--corner` | Screen position | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
| `--effect` | Animation effect | Position-specific |

## Corner Positions

| Position | Description |
|----------|-------------|
| `bottomLeft` | Bottom-left corner |
| `bottomRight` | Bottom-right corner |
| `topLeft` | Top-left corner |
| `topRight` | Top-right corner |
| `center` | Screen center |
| `menubar` | Below menu bar |
| `horizontal` | Horizontal layout at bottom-center |
| `cursorFollow` | Follows cursor position |

## Architecture

```
Claude Code hooks -> floatify CLI -> FIFO pipe IPC -> Floatify.app -> NSPanel overlay
```

**Components:**
- **Floatify.app** - Background GUI app owning the floating NSPanel overlay
- **floatify CLI** - Sends messages to the app via FIFO pipe IPC

**Technical highlights:**
- FIFO pipe for sub-ms IPC (no network permissions needed)
- NSPanel with `.nonactivatingPanel` to avoid stealing keyboard focus
- `.popUpMenu` level floats above all apps including fullscreen windows
- Max 3 stacked panels with 4px vertical offset

**Pipe path:** `/var/tmp/floatify.pipe`

**Protocol:** JSON payload
```json
{
  "message": "Task complete!",
  "corner": "bottomRight",
  "duration": "6"
}
```

## License

MIT
