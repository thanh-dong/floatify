# DuckNotify Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS floating notification app (DuckNotify.app) with a CLI tool (duck-notify) that triggers animated duck notifications from Claude Code hooks.

**Architecture:** LSUIElement menu bar app owns an NSPanel overlay positioned in screen dead zones via NSScreen.visibleFrame. CFMessagePort provides sub-ms IPC between the CLI and app. SwiftUI view with spring bounce animation renders the notification.

**Tech Stack:** Swift, AppKit, SwiftUI, CoreFoundation (CFMessagePort), XcodeGen

---

## File Map

```
DuckNotify/
├── DuckNotify.xcodeproj
│   └── project.yml                  ← XcodeGen config
├── DuckNotify/
│   ├── AppDelegate.swift           ← CFMessagePort server + menu bar + symlink install
│   ├── DuckNotificationManager.swift ← NSPanel factory + stacking logic
│   ├── DuckNotificationView.swift   ← SwiftUI notification view
│   ├── Corner.swift                 ← Corner enum
│   └── Info.plist                  ← LSUIElement = true
├── duck-notify/
│   ├── main.swift                  ← CLI: arg parse + CFMessagePort client
│   └── Info.plist
└── README.md
```

---

## Task 1: Scaffold Xcode Project with XcodeGen

**Files:**
- Create: `DuckNotify/project.yml`
- Create: `DuckNotify/DuckNotify/Info.plist`
- Create: `DuckNotify/duck-notify/Info.plist`
- Create: `DuckNotify/.gitignore`

- [ ] **Step 1: Verify XcodeGen is installed**

Run: `which xcodegen || brew install xcodegen`
Expected: `/usr/local/bin/xcodegen` or installation completes

- [ ] **Step 2: Create project.yml**

```yaml
name: DuckNotify
options:
  bundleIdPrefix: com.ducknotify
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"

settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "13.0"

targets:
  DuckNotify:
    type: application
    platform: macOS
    sources:
      - path: DuckNotify
        excludes:
          - "**/.DS_Store"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ducknotify.app
        INFOPLIST_FILE: DuckNotify/Info.plist
        CODE_SIGN_STYLE: Automatic
        COMBINE_HIDPI_IMAGES: YES
        LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
        ENABLE_HARDENED_RUNTIME: YES
    dependencies:
      - target: duck-notify
        embed: false
        copy:
          destination: resources
          subpath: ""

  duck-notify:
    type: command-line-tool
    platform: macOS
    sources:
      - path: duck-notify
        excludes:
          - "**/.DS_Store"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ducknotify.cli
        INFOPLIST_FILE: duck-notify/Info.plist
        CODE_SIGN_STYLE: Automatic
        SKIP_INSTALL: YES
        LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
```

- [ ] **Step 3: Create DuckNotify/DuckNotify/Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Create DuckNotify/duck-notify/Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
```

- [ ] **Step 5: Create DuckNotify/.gitignore**

```
.DS_Store
*.xcuserstate
*.xcworkspace
xcuserdata/
build/
```

- [ ] **Step 6: Generate Xcode project**

Run: `cd DuckNotify && xcodegen generate`
Expected: `DuckNotify.xcodeproj` created

- [ ] **Step 7: Verify project structure**

Run: `cd DuckNotify && ls -la`
Expected: DuckNotify.xcodeproj directory exists alongside project.yml

- [ ] **Step 8: Initialize git and commit**

```bash
git init
git add project.yml DuckNotify/Info.plist duck-notify/Info.plist .gitignore
git commit -m "chore: scaffold Xcode project with app and CLI targets"
```

---

## Task 2: Implement Corner Enum + DuckNotificationManager + DuckPanel

**Files:**
- Create: `DuckNotify/DuckNotify/Corner.swift`
- Create: `DuckNotify/DuckNotify/DuckNotificationManager.swift`

- [ ] **Step 1: Write Corner.swift**

```swift
import Foundation

enum Corner {
    case bottomLeft
    case bottomRight
}
```

- [ ] **Step 2: Write DuckNotificationManager.swift**

```swift
import AppKit

// MARK: - DuckPanel

class DuckPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

// MARK: - DuckNotificationManager

class DuckNotificationManager {
    static let shared = DuckNotificationManager()
    private var panels: [DuckPanel] = []
    private let maxPanels = 3
    private let stackOffset: CGFloat = 4

    private init() {}

    func show(message: String, corner: Corner, duration: TimeInterval = 6) {
        DispatchQueue.main.async {
            self.createPanel(message: message, corner: corner, duration: duration)
        }
    }

    private func createPanel(message: String, corner: Corner, duration: TimeInterval) {
        // Enforce max panel cap — dismiss oldest if needed
        if panels.count >= maxPanels {
            dismissOldest()
        }

        let size = CGSize(width: 280, height: 68)
        let stackOffsetY = CGFloat(panels.count) * stackOffset
        let origin = cornerOrigin(corner: corner, size: size, stackOffset: stackOffsetY)

        let panel = DuckPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false

        let view = DuckNotificationView(message: message) { [weak self, weak panel] in
            guard let panel = panel else { return }
            self?.dismiss(panel: panel)
        }
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFront(nil)
        panels.append(panel)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak panel] in
            guard let panel = panel else { return }
            self?.dismiss(panel: panel)
        }
    }

    private func dismiss(panel: DuckPanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
        repositionPanels()
    }

    private func dismissOldest() {
        guard let oldest = panels.first else { return }
        dismiss(panel: oldest)
    }

    private func repositionPanels() {
        for (index, panel) in panels.enumerated() {
            let offsetY = CGFloat(index) * stackOffset
            guard let frame = panel.contentView?.window?.frame else { continue }
            let size = frame.size
            let corner: Corner = frame.origin.x < (NSScreen.main?.visibleFrame.midX ?? 0) ? .bottomLeft : .bottomRight
            let newOrigin = cornerOrigin(corner: corner, size: size, stackOffset: offsetY)
            panel.setFrameOrigin(newOrigin)
        }
    }

    private func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 16, stackOffset: CGFloat = 0) -> CGPoint {
        guard let frame = NSScreen.main?.visibleFrame else { return .zero }
        switch corner {
        case .bottomLeft:
            return CGPoint(x: frame.minX + padding, y: frame.minY + padding + stackOffset)
        case .bottomRight:
            return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding + stackOffset)
        }
    }
}
```

- [ ] **Step 3: Verify compilation**

Run: `cd DuckNotify && xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)" | tail -5`
Expected: BUILD SUCCEEDED (SwiftUI DuckNotificationView will show "cannot find" errors — that's expected until Task 4)

- [ ] **Step 4: Commit**

```bash
git add DuckNotify/Corner.swift DuckNotify/DuckNotificationManager.swift
git commit -m "feat: add DuckNotificationManager with NSPanel and stacking logic"
```

---

## Task 3: Implement AppDelegate with CFMessagePort Server + Menu Bar

**Files:**
- Create: `DuckNotify/DuckNotify/AppDelegate.swift`

- [ ] **Step 1: Write AppDelegate.swift**

```swift
import AppKit
import CoreFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupMessagePort()
        installCLIToolIfNeeded()
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🦆"
        }

        let menu = NSMenu()
        let testItem = NSMenuItem(title: "Test Notification", action: #selector(testNotification), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DuckNotify", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func testNotification() {
        DuckNotificationManager.shared.show(message: "Test notification! 🦆", corner: .bottomRight, duration: 5)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - CFMessagePort Server

    private func setupMessagePort() {
        let portName = "com.yourname.duck-notify" as CFString

        let port = CFMessagePortCreateLocal(
            nil,
            portName,
            { (_, _, data, _) -> Unmanaged<CFData>? in
                guard
                    let data = data as Data?,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
                else { return nil }

                let message = json["message"] ?? "Task complete!"
                let cornerStr = json["corner"] ?? "bottomRight"
                let corner: Corner = cornerStr == "bottomLeft" ? .bottomLeft : .bottomRight
                let duration = Double(json["duration"] ?? "6") ?? 6.0

                DispatchQueue.main.async {
                    DuckNotificationManager.shared.show(
                        message: message,
                        corner: corner,
                        duration: duration
                    )
                }
                return nil
            },
            nil
        )

        guard let port = port else {
            print("Failed to create CFMessagePort")
            return
        }

        let source = CFMessagePortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    // MARK: - CLI Symlink Installation

    private func installCLIToolIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "CLISymlinkInstalled") else { return }

        let alert = NSAlert()
        alert.messageText = "Install duck-notify CLI?"
        alert.informativeText = "DuckNotify needs to create a symlink at /usr/local/bin/duck-notify so Claude Code can trigger notifications. This requires administrator privileges."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Skip")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let src = Bundle.main.url(forResource: "duck-notify", withExtension: nil)
        guard let srcURL = src else {
            print("duck-notify binary not found in app bundle")
            return
        }

        let dest = URL(fileURLWithPath: "/usr/local/bin/duck-notify")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: srcURL)
            defaults.set(true, forKey: "CLISymlinkInstalled")
            print("Installed duck-notify to /usr/local/bin/")
        } catch {
            let permAlert = NSAlert()
            permAlert.messageText = "Permission denied"
            permAlert.informativeText = "Could not create /usr/local/bin/duck-notify. Run: sudo ln -s \(srcURL.path) /usr/local/bin/duck-notify"
            permAlert.alertStyle = .warning
            permAlert.runModal()
        }
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `cd DuckNotify && xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)" | tail -5`
Expected: BUILD SUCCEEDED (or DuckNotificationView errors if not yet created — that is normal until Task 4)

- [ ] **Step 3: Commit**

```bash
git add DuckNotify/AppDelegate.swift
git commit -m "feat: add AppDelegate with CFMessagePort server and menu bar icon"
```

---

## Task 4: Implement SwiftUI DuckNotificationView

**Files:**
- Create: `DuckNotify/DuckNotify/DuckNotificationView.swift`

- [ ] **Step 1: Write DuckNotificationView.swift**

```swift
import SwiftUI

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

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 280, height: 68)
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

- [ ] **Step 2: Verify full app build**

Run: `cd DuckNotify && xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add DuckNotify/DuckNotificationView.swift
git commit -m "feat: add DuckNotificationView with bounce animation"
```

---

## Task 5: Implement duck-notify CLI Tool

**Files:**
- Create: `DuckNotify/duck-notify/main.swift`

- [ ] **Step 1: Write main.swift**

```swift
import Foundation
import CoreFoundation

// MARK: - Argument Parsing

var message = "Task complete!"
var corner = "bottomRight"
var duration = "6"

let args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let flag = args[index]
    index += 1
    guard index < args.count else { break }

    switch flag {
    case "--message":
        message = args[index]
    case "--corner":
        corner = args[index]
    case "--duration":
        duration = args[index]
    default:
        break
    }
    index += 1
}

// Validate corner
guard corner == "bottomLeft" || corner == "bottomRight" else {
    fputs("Invalid corner '\(corner)'. Use 'bottomLeft' or 'bottomRight'.\n", stderr)
    exit(1)
}

// Validate duration
guard Double(duration) != nil else {
    fputs("Invalid duration '\(duration)'. Must be a number.\n", stderr)
    exit(1)
}

// MARK: - CFMessagePort Client

let portName = "com.yourname.duck-notify" as CFString

guard let port = CFMessagePortCreateRemote(nil, portName) else {
    fputs("🦆 DuckNotify.app is not running\n", stderr)
    exit(1)
}

let payload: [String: String] = [
    "message":  message,
    "corner":   corner,
    "duration": duration
]

guard let data = try? JSONSerialization.data(withJSONObject: payload) as CFData else {
    fputs("Failed to encode payload\n", stderr)
    exit(1)
}

let result = CFMessagePortSendRequest(port, 0, data, 1.0, 0, nil, nil)

if result == kCFMessagePortSuccess {
    print("🦆 Sent: \(message)")
} else {
    fputs("❌ IPC failed (code: \(result))\n", stderr)
    exit(1)
}
```

- [ ] **Step 2: Verify CLI builds**

Run: `cd DuckNotify && xcodebuild -project DuckNotify.xcodeproj -scheme duck-notify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add duck-notify/main.swift
git commit -m "feat: add duck-notify CLI with CFMessagePort client"
```

---

## Task 6: Wire CLI Binary into App Bundle

**Files:**
- Modify: `DuckNotify/project.yml` (update dependency embed setting)

- [ ] **Step 1: Update project.yml to embed CLI binary**

Update the `DuckNotify` target's `dependencies` section to `embed: true`:

```yaml
    dependencies:
      - target: duck-notify
        embed: true
        codeSign: true
        copy:
          destination: resources
          subpath: ""
```

Run: `cd DuckNotify && xcodegen generate`

- [ ] **Step 2: Build and verify binary is in bundle**

Run: `cd DuckNotify && xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -3`
Then verify:
Run: `find ~/Library/Developer/Xcode/DerivedData -name "DuckNotify.app" -type d 2>/dev/null | head -1 | xargs -I{} ls "{}/Contents/Resources/" 2>/dev/null | grep duck`
Expected: `duck-notify` binary listed in Resources

- [ ] **Step 3: Commit**

```bash
git add project.yml
git commit -m "chore: embed duck-notify binary in app bundle resources"
```

---

## Task 7: Test Full Integration + Write README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Build release binary**

Run: `cd DuckNotify && xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Release build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)" | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Locate built app**

Run: `find ~/Library/Developer/Xcode/DerivedData -name "DuckNotify.app" -type d 2>/dev/null | head -1`
Expected: path to .app bundle

- [ ] **Step 3: Open app and verify it runs**

Run: `APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "DuckNotify.app" -type d | head -1) && open "$APP_PATH"`
Wait 3 seconds, then check:
Run: `ps aux | grep -i ducknotify | grep -v grep`
Expected: DuckNotify process running

- [ ] **Step 4: Test CLI manually**

```bash
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "DuckNotify.app" -type d | head -1)
CLI_BIN="$APP_PATH/Contents/Resources/duck-notify"
"$CLI_BIN" --message "Hello from CLI!" --corner bottomRight --duration 5
```
Expected output: `🦆 Sent: Hello from CLI!`
Expected visual: Duck notification appears in bottom-right corner, bounces, auto-dismisses after 5s

- [ ] **Step 5: Test corner and message**

```bash
CLI_BIN="$APP_PATH/Contents/Resources/duck-notify"
"$CLI_BIN" --message "Build succeeded ✓" --corner bottomLeft --duration 3
```
Expected: Duck notification appears in bottom-left corner

- [ ] **Step 6: Test app-not-running error**

Simulate: do NOT open DuckNotify.app, then run:
```bash
CLI_BIN="$APP_PATH/Contents/Resources/duck-notify"
"$CLI_BIN" --message "test" 2>&1
```
Expected: `🦆 DuckNotify.app is not running` on stderr, exit code 1

- [ ] **Step 7: Write README.md**

```markdown
# DuckNotify

A lightweight macOS menu bar daemon that renders animated duck notifications in screen dead zones.

## Installation

1. Build the app:
   ```bash
   cd DuckNotify
   xcodegen generate
   xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Release build
   ```

2. Open the built app:
   ```bash
   open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/DuckNotify.app
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

## CLI Usage

```bash
duck-notify --message "Task complete!" --corner bottomRight --duration 6
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `"Task complete!"` |
| `--corner` | `bottomLeft` or `bottomRight` | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
```

- [ ] **Step 8: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and usage instructions"
```

---

## Spec Coverage Check

| Spec Requirement | Task |
|-------------------|------|
| LSUIElement app, no Dock icon | Task 1, Step 3 (Info.plist) |
| CFMessagePort server | Task 3, Step 1 (setupMessagePort) |
| Menu bar icon with Quit + Test | Task 3, Step 1 (setupStatusItem) |
| CLI symlink on first launch | Task 3, Step 1 (installCLIToolIfNeeded) |
| NSPanel non-activating overlay | Task 2, Step 2 (DuckPanel class) |
| visibleFrame corner positioning | Task 2, Step 2 (cornerOrigin) |
| Stacking up to 3 panels, 4px offset | Task 2, Step 2 (maxPanels, stackOffset) |
| SwiftUI view with bounce | Task 4, Step 1 |
| Auto-dismiss after N seconds | Task 2, Step 2 (asyncAfter) |
| Tap to dismiss | Task 4, Step 1 (onTapGesture) |
| CLI arg parsing | Task 5, Step 1 |
| CLI CFMessagePort client | Task 5, Step 1 |
| CLI error when app not running | Task 5, Step 1 |
| CLI binary in app bundle | Task 6 |
| Claude Code hooks config | Task 7, Step 7 (README) |
