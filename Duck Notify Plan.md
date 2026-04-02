# DuckNotify — macOS Floating Notification App for Claude Code

**A lightweight macOS menu bar daemon that renders animated duck notifications in the screen's dead zones (bottom-left / bottom-right corners), triggered by Claude Code task completion hooks.**

---

## Overview

When working with Claude Code CLI, there is often unused screen real estate in the bottom corners — the gap between the active editor window and the macOS Dock. DuckNotify exploits this dead zone to surface non-intrusive, attention-grabbing notifications (a bouncing duck 🦆) that signal when Claude Code has finished a task and is waiting for the next prompt.

The system has two components:
1. **DuckNotify.app** — a background GUI app (no Dock icon) that owns the floating NSPanel overlay
2. **`duck-notify` CLI tool** — a thin binary that sends a message to the running app via CFMessagePort IPC

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
DuckNotify.app  (LSUIElement, runs at Login, no Dock icon)
    │
    │  NSPanel  (.nonactivatingPanel, .popUpMenu level)
    │  NSScreen.main?.visibleFrame  →  bottom-left / bottom-right
    ▼
🦆 Floating Duck Notification  (bounces, auto-dismisses after N seconds)
```

---

## Component 1 — DuckNotify.app

### App Configuration (`Info.plist`)

```xml
<!-- Run silently in background, no Dock icon, no Cmd+Tab entry -->
<key>LSUIElement</key>
<true/>

<!-- Auto-launch at Login (register via SMAppService or Login Items) -->
<key>LSBackgroundOnly</key>
<false/>
```

### IPC Server — CFMessagePort Listener

The app registers a named CFMessagePort on startup and listens for JSON payloads from the CLI tool.[cite:36][cite:37]

```swift
// AppDelegate.swift
import AppKit
import CoreFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMessagePort()
    }

    func setupMessagePort() {
        let portName = "com.yourname.duck-notify" as CFString

        let port = CFMessagePortCreateLocal(nil, portName, { _, _, data, _ in
            guard
                let data = data as Data?,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
            else { return nil }

            let message = json["message"] ?? "Task complete!"
            let corner: Corner = json["corner"] == "bottomLeft" ? .bottomLeft : .bottomRight
            let duration = Double(json["duration"] ?? "6") ?? 6.0

            DispatchQueue.main.async {
                DuckNotificationManager.shared.show(
                    message: message,
                    corner: corner,
                    duration: duration
                )
            }
            return nil
        }, nil)

        let source = CFMessagePortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }
}
```

### Corner Positioning — `NSScreen.visibleFrame`

`NSScreen.main?.visibleFrame` returns the usable screen area **after subtracting the Dock and Menubar**, so the panel always sits exactly in the dead zone above the Dock — no manual Dock height calculation needed.[cite:20][cite:19]

```swift
enum Corner { case bottomLeft, bottomRight }

func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 16) -> CGPoint {
    guard let frame = NSScreen.main?.visibleFrame else { return .zero }
    switch corner {
    case .bottomLeft:
        // x: left edge + padding
        // y: top of Dock + padding  ← visibleFrame.minY handles this automatically
        return CGPoint(x: frame.minX + padding, y: frame.minY + padding)
    case .bottomRight:
        return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding)
    }
}
```

### NSPanel — Non-Activating Floating Overlay

```swift
class DuckPanel: NSPanel {
    // Never steal focus from the active editor
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // Allow rendering outside normal screen constraints
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

class DuckNotificationManager {
    static let shared = DuckNotificationManager()
    private var panels: [DuckPanel] = []

    func show(message: String, corner: Corner, duration: TimeInterval = 6) {
        DispatchQueue.main.async {
            let size = CGSize(width: 280, height: 68)
            let origin = self.cornerOrigin(corner: corner, size: size)

            let panel = DuckPanel(
                contentRect: NSRect(origin: origin, size: size),
                styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.level = .popUpMenu              // Floats above all apps
            panel.collectionBehavior = [
                .canJoinAllSpaces,                // Visible on all Spaces
                .fullScreenAuxiliary              // Visible alongside fullscreen apps
            ]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false               // Shadow handled in SwiftUI view
            panel.ignoresMouseEvents = false      // Allow tap-to-dismiss

            let view = DuckNotificationView(message: message) {
                self.dismiss(panel: panel)
            }
            panel.contentView = NSHostingView(rootView: view)
            panel.orderFront(nil)
            self.panels.append(panel)

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismiss(panel: panel)
            }
        }
    }

    private func dismiss(panel: DuckPanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
    }
}
```

### SwiftUI Notification View

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
                .fill(.regularMaterial)           // Native macOS vibrancy
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

---

## Component 2 — `duck-notify` CLI Tool

A separate **Command Line Tool** Xcode target, compiled into the app bundle at `DuckNotify.app/Contents/Resources/duck-notify`, then symlinked to `/usr/local/bin/duck-notify` on first launch.[cite:37]

### CLI Source (`main.swift`)

```swift
import Foundation
import CoreFoundation

// --- Argument parsing ---
var message = "Task complete! Continue prompting ▶"
var corner  = "bottomRight"
var duration = "6"

var args = Array(CommandLine.arguments.dropFirst())
while !args.isEmpty {
    let flag = args.removeFirst()
    guard !args.isEmpty else { break }
    switch flag {
    case "--message":  message  = args.removeFirst()
    case "--corner":   corner   = args.removeFirst()
    case "--duration": duration = args.removeFirst()
    default: break
    }
}

// --- Send via CFMessagePort ---
let portName = "com.yourname.duck-notify" as CFString

guard let port = CFMessagePortCreateRemote(nil, portName) else {
    fputs("❌ DuckNotify.app is not running\n", stderr)
    exit(1)
}

let payload: [String: String] = [
    "message":  message,
    "corner":   corner,
    "duration": duration
]
let data = try! JSONSerialization.data(withJSONObject: payload) as CFData
let result = CFMessagePortSendRequest(port, 0, data, 1.0, 0, nil, nil)

if result == kCFMessagePortSuccess {
    print("🦆 Sent: \(message)")
} else {
    fputs("❌ IPC failed (code: \(result))\n", stderr)
    exit(1)
}
```

### CLI Usage

```bash
# Minimal
duck-notify --message "Task complete!"

# Full options
duck-notify \
  --message "Task complete! Continue prompting ▶" \
  --corner bottomRight \
  --duration 8

# Bottom-left example
duck-notify --message "Build succeeded ✓" --corner bottomLeft
```

### Symlink Installation (on first app launch)

```swift
// In AppDelegate.applicationDidFinishLaunching
func installCLITool() {
    let src  = Bundle.main.url(forResource: "duck-notify", withExtension: nil)!
    let dest = URL(fileURLWithPath: "/usr/local/bin/duck-notify")
    guard !FileManager.default.fileExists(atPath: dest.path) else { return }

    // Requires user approval — show an NSAlert first
    try? FileManager.default.createSymbolicLink(at: dest, withDestinationURL: src)
}
```

---

## Component 3 — Claude Code Integration

Claude Code supports lifecycle hooks in `~/.claude/settings.json`.[cite:37]

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

| Hook | When it fires | Suggested use |
|------|---------------|---------------|
| `Stop` | Claude finishes a full task and stops | Main "come back" notification — bottom-right |
| `PostToolUse` | After each individual tool call | Quick status per action — bottom-left |
| `PreToolUse` | Before a tool runs | Optional: "starting..." indicator |

---

## Project Structure

```
DuckNotify/
├── DuckNotify.xcodeproj
├── DuckNotify/                   ← GUI app target
│   ├── AppDelegate.swift         ← CFMessagePort server + symlink installer
│   ├── DuckNotificationManager.swift
│   ├── DuckNotificationView.swift
│   └── Info.plist                ← LSUIElement = true
├── duck-notify/                  ← CLI tool target
│   └── main.swift                ← Argument parser + CFMessagePort client
└── README.md
```

**Xcode targets:**
- `DuckNotify` — macOS App, deployment target macOS 13+
- `duck-notify` — Command Line Tool, linked into app bundle via Copy Files build phase

---

## Implementation Milestones

| Step | Task | Estimated effort |
|------|------|-----------------|
| 1 | Create Xcode project with two targets (App + CLI Tool) | 15 min |
| 2 | Implement CFMessagePort server in AppDelegate | 30 min |
| 3 | Build `DuckPanel` + `DuckNotificationManager` with `visibleFrame` positioning | 45 min |
| 4 | Build `DuckNotificationView` SwiftUI with bounce animation | 30 min |
| 5 | Implement CLI `main.swift` with arg parser + CFMessagePort client | 20 min |
| 6 | Wire CLI binary into app bundle via Copy Files phase + symlink on launch | 20 min |
| 7 | Add Claude Code hooks to `~/.claude/settings.json` | 5 min |
| 8 | Test: bottom-left, bottom-right, multi-monitor, fullscreen edge cases | 30 min |

**Total: ~3 hours for a working v1**

---

## Key Technical Decisions

**Why CFMessagePort over HTTP/Unix socket?**
CFMessagePort is macOS-native, requires no server setup, has sub-millisecond latency, and works with zero network permissions. HTTP localhost would require firewall/security approval dialogs.[cite:36][cite:37]

**Why `NSScreen.visibleFrame` over manual Dock height math?**
`visibleFrame` automatically excludes the Dock and Menubar regardless of Dock position (bottom, left, right) or auto-hide state. Manual calculations break when the user repositions the Dock.[cite:20][cite:19]

**Why `NSPanel` with `.nonactivatingPanel` over `NSWindow`?**
`NSPanel` with `.nonactivatingPanel` prevents the notification from stealing keyboard focus from the active editor — critical when Claude Code is waiting and the developer is mid-typing.[cite:12]

**Why `.popUpMenu` window level?**
This level floats above all standard app windows without requiring the app to claim `.screenSaver` level (which would block mouse events on underlying apps). Combined with `.fullScreenAuxiliary`, it appears alongside fullscreen apps as well.[cite:6][cite:25]

---

## Edge Cases & Mitigations

| Edge case | Mitigation |
|-----------|------------|
| Multiple monitors | Use `NSScreen.screens` to pick the screen where the active editor lives, or default to `NSScreen.main` |
| Dock on left/right side | `visibleFrame` adjusts automatically — no code change needed |
| Dock set to auto-hide | `visibleFrame` returns full height; panel appears at `y: frame.minY + padding` (near true bottom edge) |
| DuckNotify.app not running when CLI fires | CLI prints `❌ DuckNotify.app is not running` and exits with code 1 — add a fallback: `|| osascript -e 'display notification "Task done" with title "Claude Code"'` |
| Notification spam (rapid successive triggers) | Stagger panels with a 4px vertical offset per queued notification; cap queue at 3 visible at once |
