# Floatify

A lightweight macOS menu bar daemon that renders animated floating notifications in screen dead zones.

## Installation

1. Build the app:
   ```bash
   cd Floatify
   xcodegen generate
   xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Release build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
   ```

2. Open the built app:
   ```bash
   open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/Floatify.app
   ```

3. Approve the CLI symlink prompt when it appears.

## Claude Code Integration

Add to `~/.claude/settings.json`:

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

## CLI Usage

```bash
floatify --message 'Task complete!' --corner bottomRight --duration 6
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `"Task complete!"` |
| `--corner` | Screen position | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
| `--effect` | Animation effect (optional) | Position-specific |

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

## Test Commands

```bash
# Screen corners
floatify --message 'Bottom Left!' --corner bottomLeft --duration 4
floatify --message 'Bottom Right!' --corner bottomRight --duration 4
floatify --message 'Top Left!' --corner topLeft --duration 4
floatify --message 'Top Right!' --corner topRight --duration 4

# Center positions
floatify --message 'Center!' --corner center --duration 4
floatify --message 'Below Menubar!' --corner menubar --duration 4
floatify --message 'Horizontal!' --corner horizontal --duration 4

# Special
floatify --message 'Following Cursor!' --corner cursorFollow --duration 8
```
