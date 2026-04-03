# Position Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-position JSON configuration for margin, panel size, and stack offset.

**Architecture:** Two-tier config system - bundled default `positions.json` in app Resources merged with user override at `~/.floatify/positions.json`. `PositionConfigManager` singleton manages merged config cache.

**Tech Stack:** Swift Codable, FileManager, Bundle

---

## File Structure

```
Floatify/Floatify/
├── PositionConfigManager.swift   # NEW: Config loading/merging singleton
├── Resources/
│   └── positions.json            # NEW: Bundled default config
└── FloatNotificationManager.swift  # MODIFIED: Use PositionConfigManager
```

**Files:**
- Create: `Floatify/Floatify/PositionConfigManager.swift`
- Create: `Floatify/Floatify/Resources/positions.json`
- Modify: `Floatify/Floatify/FloatNotificationManager.swift`
- Modify: `Floatify/project.yml`

---

## Task 1: Create bundled default positions.json

**Files:**
- Create: `Floatify/Floatify/Resources/positions.json`

- [ ] **Step 1: Create Resources directory**

```bash
mkdir -p Floatify/Floatify/Resources
```

- [ ] **Step 2: Write default positions.json**

```json
{
  "bottomLeft": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "bottomRight": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "topLeft": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "topRight": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "center": { "margin": 0, "width": 280, "height": 68, "stackOffset": 4 },
  "menubar": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "horizontal": { "margin": 20, "width": 280, "height": 68, "stackOffset": 8 },
  "cursorFollow": { "margin": 20, "width": 280, "height": 68, "stackOffset": 4 }
}
```

- [ ] **Step 3: Commit**

```bash
git add Floatify/Floatify/Resources/positions.json && git commit -m "feat: add bundled default positions.json"
```

---

## Task 2: Create PositionConfigManager.swift

**Files:**
- Create: `Floatify/Floatify/PositionConfigManager.swift`

- [ ] **Step 1: Write PositionConfigManager.swift**

```swift
import Foundation

struct PositionConfig: Codable {
    let margin: CGFloat
    let width: CGFloat
    let height: CGFloat
    let stackOffset: CGFloat

    init(margin: CGFloat = 10, width: CGFloat = 280, height: CGFloat = 68, stackOffset: CGFloat = 4) {
        self.margin = margin
        self.width = width
        self.height = height
        self.stackOffset = stackOffset
    }
}

class PositionConfigManager {
    static let shared = PositionConfigManager()

    private var configs: [String: PositionConfig] = [:]

    private init() {
        loadConfigs()
    }

    private func loadConfigs() {
        // Load bundled defaults
        guard let bundledURL = Bundle.main.url(forResource: "positions", withExtension: "json", subdirectory: "Resources"),
              let bundledData = try? Data(contentsOf: bundledURL),
              let bundledConfigs = try? JSONDecoder().decode([String: PositionConfig].self, from: bundledData) else {
            loadHardcodedDefaults()
            return
        }

        configs = bundledConfigs

        // Merge user override
        let userConfigURL = URL(fileURLWithPath: "~/.floatify/positions.json")
            .standardizedFileURL
        if let userData = try? Data(contentsOf: userConfigURL),
           let userConfigs = try? JSONDecoder().decode([String: PositionConfig].self, from: userData) {
            for (key, value) in userConfigs {
                configs[key] = value
            }
        }
    }

    private func loadHardcodedDefaults() {
        configs = [
            "bottomLeft": PositionConfig(margin: 10, width: 280, height: 68, stackOffset: 4),
            "bottomRight": PositionConfig(margin: 10, width: 280, height: 68, stackOffset: 4),
            "topLeft": PositionConfig(margin: 10, width: 280, height: 68, stackOffset: 4),
            "topRight": PositionConfig(margin: 10, width: 280, height: 68, stackOffset: 4),
            "center": PositionConfig(margin: 0, width: 280, height: 68, stackOffset: 4),
            "menubar": PositionConfig(margin: 10, width: 280, height: 68, stackOffset: 4),
            "horizontal": PositionConfig(margin: 20, width: 280, height: 68, stackOffset: 8),
            "cursorFollow": PositionConfig(margin: 20, width: 280, height: 68, stackOffset: 4)
        ]
    }

    func config(for corner: Corner) -> PositionConfig {
        return configs[corner.rawValue] ?? PositionConfig()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Floatify/Floatify/PositionConfigManager.swift && git commit -m "feat: add PositionConfigManager with JSON config loading"
```

---

## Task 3: Update project.yml to include Resources

**Files:**
- Modify: `Floatify/project.yml`

- [ ] **Step 1: Add Resources to sources**

In `targets.Floatify.sources`, add:

```yaml
    sources:
      - path: Floatify/Floatify
        excludes:
          - "**/.DS_Store"
          - "cli/**"
      - path: Floatify/Floatify/Resources
        buildPhase: resources
      - path: Floatify/Assets.xcassets
        buildPhase: resources
```

- [ ] **Step 2: Regenerate Xcode project**

```bash
cd Floatify && xcodegen generate
```

- [ ] **Step 3: Verify positions.json is in build resources**

Check that the Xcode project includes positions.json under Build Phases > Copy Bundle Resources.

- [ ] **Step 4: Commit**

```bash
git add Floatify/project.yml && git commit -m "feat: add Resources to Xcode project sources"
```

---

## Task 4: Integrate PositionConfigManager into FloatNotificationManager

**Files:**
- Modify: `Floatify/Floatify/FloatNotificationManager.swift`

- [ ] **Step 1: Replace hardcoded values with config calls**

In `createPanel`, replace the hardcoded `size` calculation:

```swift
let config = PositionConfigManager.shared.config(for: corner)
let size = CGSize(width: config.width, height: config.height)
```

In `cornerOrigin`, replace hardcoded `padding` and `stackOffset`:

```swift
let config = PositionConfigManager.shared.config(for: corner)
let padding = config.margin
let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * config.stackOffset
```

In `handleVerticalPanel`, replace hardcoded `stackOffset`:

```swift
let config = PositionConfigManager.shared.config(for: corner)
let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * config.stackOffset
```

In `repositionPanels`, replace hardcoded `stackOffset`:

```swift
let config = PositionConfigManager.shared.config(for: panel.notificationCorner)
let offsetY = CGFloat(index) * config.stackOffset
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Floatify/Floatify/FloatNotificationManager.swift && git commit -m "feat: use PositionConfigManager for per-position settings"
```

---

## Verification

After all tasks:

1. Build succeeds
2. Run app and use menu bar "Test Notification" - all 8 positions should show with correct positions
3. Edit `~/.floatify/positions.json` to override a position, restart app - override should take effect
4. If `~/.floatify/positions.json` is deleted or malformed, bundled defaults are used
