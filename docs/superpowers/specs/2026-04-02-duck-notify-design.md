# DuckNotify — Design Specification

## Overview

DuckNotify is a macOS menu bar daemon that renders animated duck notifications in the screen's dead zones (bottom-left / bottom-right corners), triggered by Claude Code task completion hooks.

The system has two components:

1. **DuckNotify.app** — background GUI app (no Dock icon) that owns the floating NSPanel overlay
2. **duck-notify CLI** — thin binary that sends a message to the running app via CFMessagePort IPC

---

## Architecture

```
Claude Code (CLI)
    │
    │  ~/.claude/settings.json hooks (PostToolUse / Stop)
    ▼
duck-notify CLI  (/usr/local/bin/duck-notify)
    │
    │  CFMessagePort IPC  "com.yourname.duck-notify"
    │  latency < 1ms, no network, macOS native
    ▼
DuckNotify.app  (LSUIElement, menu bar icon 🦆)
    │
    │  NSPanel  (.nonactivatingPanel, .popUpMenu level)
    │  NSScreen.main?.visibleFrame  →  bottom-left / bottom-right
    │
    │  Stacking: up to 3 panels, 4px vertical offset each
    ▼
🦆 Floating Duck Notification  (bounces 3x, auto-dismisses after N seconds)
```

---

## Component 1 — DuckNotify.app

### App Configuration

- **LSUIElement = true** — no Dock icon, no Cmd+Tab entry
- **Menu bar icon** — 🦆 emoji in status bar; click reveals Quit and "Test Notification"
- **No launch at login** — v1, user manually launches once
- **Deployment target** — macOS 13+

### IPC Server — CFMessagePort Listener

App registers a named CFMessagePort on startup and listens for JSON payloads from the CLI tool.

**Port name:** `com.yourname.duck-notify`

JSON payload schema:
```json
{
  "message":  "Task complete!",
  "corner":   "bottomRight",
  "duration": "6"
}
```

- `corner` accepts: `bottomLeft`, `bottomRight` (defaults to `bottomRight`)
- `duration` accepts: integer seconds (defaults to `6`)
- Invalid/corrupt JSON is silently ignored

### NSPanel — Non-Activating Floating Overlay

```swift
class DuckPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}
```

- **Level:** `.popUpMenu` — floats above all apps, visible on all Spaces
- **Collection behavior:** `.canJoinAllSpaces`, `.fullScreenAuxiliary`
- **Background:** clear, non-opaque, no shadow (shadow handled in SwiftUI view)
- **Mouse events:** ignored for panel itself, tap handled by SwiftUI view

### Corner Positioning

Uses `NSScreen.main?.visibleFrame` which automatically excludes Dock and Menubar regardless of Dock position (bottom, left, right) or auto-hide state.

```swift
enum Corner { case bottomLeft, bottomRight }

func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 16, stackOffset: CGFloat = 0) -> CGPoint {
    guard let frame = NSScreen.main?.visibleFrame else { return .zero }
    switch corner {
    case .bottomLeft:
        return CGPoint(x: frame.minX + padding, y: frame.minY + padding + stackOffset)
    case .bottomRight:
        return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding + stackOffset)
    }
}
```

### Notification Manager — Stacking Behavior

- Max 3 visible panels at once
- New panels stack with 4px vertical offset above the previous
- When a panel dismisses, panels above fall down to fill gap
- Replacement/dispatch logic: new notification appends to stack

### CLI Symlink Installation (First Launch)

On first app launch, show NSAlert:

> "DuckNotify needs to install the `duck-notify` command-line tool to `/usr/local/bin/`. This allows Claude Code hooks to trigger notifications. Create the symlink?"

- User approves → create symlink `duck-notify` → `/usr/local/bin/`
- User declines → app continues running, CLI won't work until manually installed
- If symlink already exists → skip silently

---

## Component 2 — duck-notify CLI Tool

### Binary Location

After install: `/usr/local/bin/duck-notify` (symlink to app bundle resource)

### Argument Parsing

```bash
duck-notify --message "Task complete!" --corner bottomRight --duration 6
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification message text | `"Task complete!"` |
| `--corner` | `bottomLeft` or `bottomRight` | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |

### CFMessagePort Client Behavior

1. Attempt to connect to `com.yourname.duck-notify` port
2. If port unavailable → write `🦆 DuckNotify.app is not running` to stderr, exit code 1
3. If connected → send JSON payload, exit code 0 on success

---

## Component 3 — Claude Code Integration

`~/.claude/settings.json` hooks:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "duck-notify --message '🦆 Claude is waiting for your next prompt' --corner bottomRight --duration 10"
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
            "command": "duck-notify --message 'Bash task done ✓' --corner bottomLeft --duration 5"
          }
        ]
      }
    ]
  }
}
```

| Hook | When it fires | Suggested corner | Suggested duration |
|------|---------------|-----------------|-------------------|
| `Stop` | Claude finishes a full task | bottomRight | 10s |
| `PostToolUse` | After each individual tool call | bottomLeft | 5s |

---

## SwiftUI Notification View

```swift
struct DuckNotificationView: View {
    let message: String
    var onTap: (() -> Void)?

    @State private var isVisible = false
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 10) {
            Text("🦆")
                .font(.system(size: 32))
                .scaleEffect(bounce ? 1.2 : 1.0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.5)
                    .repeatCount(3, autoreverses: true),
                    value: bounce
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Code")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .onTapGesture { onTap?() }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bounce = true
            }
        }
    }
}
```

**Animation sequence:**
1. Panel slides in from bottom (offset y: 24 → 0, opacity 0 → 1) over ~450ms
2. Duck bounces 3x starting 500ms after appear (spring, 300ms each)
3. Auto-dismiss after `duration` seconds (panel slides/fades out)

---

## Project Structure

```
DuckNotify/
├── DuckNotify.xcodeproj
├── DuckNotify/                    ← macOS App target
│   ├── AppDelegate.swift         ← CFMessagePort server + menu bar + symlink installer
│   ├── DuckNotificationManager.swift
│   ├── DuckNotificationView.swift
│   └── Info.plist                ← LSUIElement = true
├── duck-notify/                   ← Command Line Tool target
│   └── main.swift                ← Argument parser + CFMessagePort client
└── README.md
```

**Xcode targets:**
- `DuckNotify` — macOS App, deployment target macOS 13+
- `duck-notify` — Command Line Tool, linked into app bundle via Copy Files build phase

---

## Edge Cases

| Edge case | Mitigation |
|-----------|------------|
| App not running when CLI fires | CLI prints error to stderr, exits 1 |
| Multiple monitors | Defaults to `NSScreen.main` (primary screen) |
| Dock on left/right side | `visibleFrame` adjusts automatically |
| Dock set to auto-hide | `visibleFrame` returns full height |
| Rapid successive triggers | Stack up to 3 panels, 4px vertical offset per queued notification |
| Invalid JSON payload | Silently ignored by CFMessagePort handler |
| Symlink already exists | Skip installation silently on next launch |

---

## Technical Decisions

**Why CFMessagePort over HTTP/Unix socket?**
CFMessagePort is macOS-native, requires no server setup, has sub-millisecond latency, and works with zero network permissions. HTTP localhost would require firewall/security approval dialogs.

**Why NSPanel with .nonactivatingPanel?**
NSPanel with .nonactivatingPanel prevents the notification from stealing keyboard focus from the active editor — critical when Claude Code is waiting and the developer is mid-typing.

**Why .popUpMenu window level?**
This level floats above all standard app windows without blocking mouse events on underlying apps. Combined with .fullScreenAuxiliary, it appears alongside fullscreen apps as well.

**Why NSScreen.visibleFrame over manual Dock height math?**
visibleFrame automatically excludes the Dock and Menubar regardless of Dock position or auto-hide state. Manual calculations break when the user repositions the Dock.
