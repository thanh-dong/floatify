# Floatify Lottie Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate Lottie animations for entry/exit choreography and spring physics for idle "living" micro-interactions in Floatify notification popups.

**Architecture:** Lottie JSON animations (via airbnb/lottie-macosx SPM package) handle cinematic entry/exit. SwiftUI spring animations handle idle bobbing, glow pulsing, and float drifting. The notification duck reacts to hover with spring overshoot.

**Tech Stack:** Swift Package Manager, lottie-macosx, SwiftUI, AppKit NSPanel

---

## File Map

```
Floatify/
├── project.yml                              # MODIFIED: add SPM lottie-macosx
├── Floatify/
│   ├── Floatify/
│   │   ├── LottieAnimator.swift            # NEW: wraps LottieAnimationView
│   │   ├── IdleAnimations.swift            # NEW: Bob, GlowPulse, FloatDrift modifiers
│   │   ├── FloatNotificationView.swift    # MODIFIED: integrate Lottie + idle
│   │   ├── FloatEffects.swift             # MODIFIED: add lottieFileName
│   │   └── Resources/
│   │       └── Animations/                 # NEW: Lottie JSON files
│   │           ├── slide_entry.json
│   │           ├── fade_entry.json
│   │           ├── dropdown_entry.json
│   │           ├── marquee_entry.json
│   │           ├── trail_entry.json
│   │           ├── exit_slide.json
│   │           └── exit_fade.json
```

---

## Task 1: Add lottie-macosx via SPM

**Files:**
- Modify: `Floatify/project.yml`
- Modify: `Floatify/Floatify/Resources/Animations/` (create directory)

- [ ] **Step 1: Add SPM package to project.yml**

Add `packages` section and reference in Floatify target:

```yaml
packages:
  Lottie:
    url: https://github.com/airbnb/lottie-ios
    from: "4.4.0"

targets:
  Floatify:
    type: application
    platform: macOS
    sources:
      - path: Floatify
        excludes:
          - "**/.DS_Store"
          - "cli/**"
      - path: Floatify/Resources
        buildPhase: resources
      - path: Floatify/Assets.xcassets
        buildPhase: resources
    dependencies:
      - package: Lottie
        product: Lottie
```

- [ ] **Step 2: Create Animations directory**

Run: `mkdir -p Floatify/Floatify/Resources/Animations`

- [ ] **Step 3: Generate Xcode project**

Run: `cd Floatify && xcodegen generate`

- [ ] **Step 4: Verify SPM resolved**

Open project in Xcode, check Package Dependencies for Lottie 4.4.0+

- [ ] **Step 5: Commit**

```bash
git add Floatify/project.yml
git commit -m "chore: add lottie-macosx SPM dependency"
```

---

## Task 2: Create minimal Lottie JSON animation files

**Files:**
- Create: `Floatify/Floatify/Resources/Animations/slide_entry.json`
- Create: `Floatify/Floatify/Resources/Animations/fade_entry.json`
- Create: `Floatify/Floatify/Resources/Animations/dropdown_entry.json`
- Create: `Floatify/Floatify/Resources/Animations/marquee_entry.json`
- Create: `Floatify/Floatify/Resources/Animations/trail_entry.json`
- Create: `Floatify/Floatify/Resources/Animations/exit_slide.json`
- Create: `Floatify/Floatify/Resources/Animations/exit_fade.json`

Each JSON must be valid Lottie 5.5.0+ format with:
- A `layers` array (can be empty for placeholder)
- `v` (version) field
- `fr` (frame rate), `ip` (in point), `op` (out point)

- [ ] **Step 1: Create slide_entry.json**

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 54,
  "w": 280,
  "h": 68,
  "nm": "slide_entry",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Scale",
      "sr": 1,
      "ks": {
        "o": { "a": 0, "k": 100 },
        "r": { "a": 0, "k": 0 },
        "p": { "a": 0, "k": [140, 34, 0] },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": {
          "a": 1,
          "k": [
            { "t": 0, "s": [80, 80, 100], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 20, "s": [108, 108, 100], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 40, "s": [100, 100, 100] }
          ]
        }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 },
          "nm": "Rectangle"
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 },
          "nm": "Fill"
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Create fade_entry.json** (same structure, scale stays at 100 but opacity animates 0-100)

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 36,
  "w": 280,
  "h": 68,
  "nm": "fade_entry",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Fade",
      "sr": 1,
      "ks": {
        "o": {
          "a": 1,
          "k": [
            { "t": 0, "s": [0], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 20, "s": [100] }
          ]
        },
        "r": { "a": 0, "k": 0 },
        "p": { "a": 0, "k": [140, 34, 0] },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": { "a": 0, "k": [100, 100, 100] }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 }
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 }
        }
      ]
    }
  ]
}
```

- [ ] **Step 3: Create dropdown_entry.json** (scale Y from 50 to 100 with bounce)

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 60,
  "w": 280,
  "h": 68,
  "nm": "dropdown_entry",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Dropdown",
      "sr": 1,
      "ks": {
        "o": { "a": 0, "k": 100 },
        "r": { "a": 0, "k": 0 },
        "p": { "a": 0, "k": [140, 34, 0] },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": {
          "a": 1,
          "k": [
            { "t": 0, "s": [100, 50, 100], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 30, "s": [100, 115, 100], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 50, "s": [100, 100, 100] }
          ]
        }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 }
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 }
        }
      ]
    }
  ]
}
```

- [ ] **Step 4: Create marquee_entry.json** (horizontal slide from -200 to 0 with overshoot)

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 48,
  "w": 280,
  "h": 68,
  "nm": "marquee_entry",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Marquee",
      "sr": 1,
      "ks": {
        "o": { "a": 0, "k": 100 },
        "r": { "a": 0, "k": 0 },
        "p": {
          "a": 1,
          "k": [
            { "t": 0, "s": [-160, 34, 0], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 25, "s": [150, 34, 0], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 40, "s": [140, 34, 0] }
          ]
        },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": { "a": 0, "k": [100, 100, 100] }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 }
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 }
        }
      ]
    }
  ]
}
```

- [ ] **Step 5: Create trail_entry.json** (quick pop in with scale overshoot)

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 42,
  "w": 280,
  "h": 68,
  "nm": "trail_entry",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Trail",
      "sr": 1,
      "ks": {
        "o": { "a": 0, "k": 100 },
        "r": { "a": 0, "k": 0 },
        "p": { "a": 0, "k": [140, 34, 0] },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": {
          "a": 1,
          "k": [
            { "t": 0, "s": [60, 60, 100], "i": { "x": [0.5], "y": [1] }, "o": { "x": [0.5], "y": [0] } },
            { "t": 15, "s": [120, 120, 100], "i": { "x": [0.5], "y": [1] }, "o": { "x": [0.5], "y": [0] } },
            { "t": 30, "s": [95, 95, 100], "i": { "x": [0.5], "y": [1] }, "o": { "x": [0.5], "y": [0] } },
            { "t": 40, "s": [100, 100, 100] }
          ]
        }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 }
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 }
        }
      ]
    }
  ]
}
```

- [ ] **Step 6: Create exit_slide.json** (slide out to right)

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 24,
  "w": 280,
  "h": 68,
  "nm": "exit_slide",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Exit",
      "sr": 1,
      "ks": {
        "o": {
          "a": 1,
          "k": [
            { "t": 0, "s": [100], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 18, "s": [0] }
          ]
        },
        "r": { "a": 0, "k": 0 },
        "p": {
          "a": 1,
          "k": [
            { "t": 0, "s": [140, 34, 0], "i": { "x": [0.4], "y": [1] }, "o": { "x": [0.6], "y": [0] } },
            { "t": 20, "s": [320, 34, 0] }
          ]
        },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": { "a": 0, "k": [100, 100, 100] }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 }
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 }
        }
      ]
    }
  ]
}
```

- [ ] **Step 7: Create exit_fade.json** (quick fade out)

```json
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 18,
  "w": 280,
  "h": 68,
  "nm": "exit_fade",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Exit",
      "sr": 1,
      "ks": {
        "o": {
          "a": 1,
          "k": [
            { "t": 0, "s": [100] },
            { "t": 12, "s": [0] }
          ]
        },
        "r": { "a": 0, "k": 0 },
        "p": { "a": 0, "k": [140, 34, 0] },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": { "a": 0, "k": [100, 100, 100] }
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": { "a": 0, "k": [260, 58] },
          "p": { "a": 0, "k": [0, 0] },
          "r": { "a": 0, "k": 14 }
        },
        {
          "ty": "fl",
          "c": { "a": 0, "k": [1, 0.95, 0.8, 1] },
          "o": { "a": 0, "k": 100 }
        }
      ]
    }
  ]
}
```

- [ ] **Step 8: Update project.yml to include Animations as resources**

The `Resources` path already includes all files in the directory. Verify `Resources/Animations/` is included by checking project.yml sources.

Run: `cd Floatify && xcodegen generate`

- [ ] **Step 9: Commit**

```bash
git add Floatify/Floatify/Resources/Animations/
git add Floatify/project.yml
git commit -m "feat: add Lottie animation JSON files for entry/exit"
```

---

## Task 3: Create LottieAnimator.swift

**Files:**
- Create: `Floatify/Floatify/LottieAnimator.swift`

- [ ] **Step 1: Write LottieAnimator.swift**

```swift
import SwiftUI
import Lottie

// MARK: - LottieAnimator

class LottieAnimator: ObservableObject {
    @Published var isPlaying = false
    @Published var currentProgress: CGFloat = 0

    private var animationView: LottieAnimationView?
    private var completion: (() -> Void)?

    func loadAnimation(named name: String) -> LottieAnimationView? {
        let animation: LottieAnimationView
        if let a = LottieAnimationView(name: name, bundle: .main) {
            animation = a
        } else {
            print("Floatify: Lottie animation '\(name)' not found, using fallback")
            return nil
        }
        animation.contentMode = .scaleAspectFit
        animation.loopMode = .playOnce
        animation.isHidden = true
        self.animationView = animation
        return animation
    }

    func play(named name: String, completion: (() -> Void)? = nil) {
        guard let animationView = loadAnimation(named: name) else {
            completion?()
            return
        }

        self.completion = completion
        isPlaying = true
        animationView.isHidden = false

        animationView.play { [weak self] finished in
            DispatchQueue.main.async {
                self?.isPlaying = false
                self?.completion?()
                self?.completion = nil
            }
        }
    }

    func playReverse(named name: String, completion: (() -> Void)? = nil) {
        guard let animationView = loadAnimation(named: name) else {
            completion?()
            return
        }

        self.completion = completion
        isPlaying = true
        animationView.isHidden = false
        animationView.currentProgress = 1.0

        animationView.play(fromProgress: 1.0, toProgress: 0.0) { [weak self] finished in
            DispatchQueue.main.async {
                self?.isPlaying = false
                self?.completion?()
                self?.completion = nil
            }
        }
    }

    func stop() {
        animationView?.stop()
        isPlaying = false
    }
}

// MARK: - LottieViewRepresentable

struct LottieViewRepresentable: NSViewRepresentable {
    let animationName: String
    @Binding var isPlaying: Bool

    func makeNSView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName, bundle: .main)
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: LottieAnimationView, context: Context) {
        if isPlaying {
            nsView.isHidden = false
            nsView.play { finished in
                if finished {
                    DispatchQueue.main.async {
                        self.isPlaying = false
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|warning:|BUILD)"`

Expected: No errors related to LottieAnimator

- [ ] **Step 3: Commit**

```bash
git add Floatify/Floatify/LottieAnimator.swift
git commit -m "feat: add LottieAnimator wrapper for LottieAnimationView"
```

---

## Task 4: Create IdleAnimations.swift

**Files:**
- Create: `Floatify/Floatify/IdleAnimations.swift`

- [ ] **Step 1: Write IdleAnimations.swift**

```swift
import SwiftUI

// MARK: - BobModifier

struct BobModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                guard isEnabled else { return }
                withAnimation(
                    .spring(response: 1.8, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.04
                }
            }
    }
}

// MARK: - GlowPulseModifier

struct GlowPulseModifier: ViewModifier {
    @State private var opacity: Double = 0.3
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .shadow(color: .yellow.opacity(opacity), radius: 8, x: 0, y: 0)
            .onAppear {
                guard isEnabled else { return }
                withAnimation(
                    .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.7
                }
            }
    }
}

// MARK: - FloatDriftModifier

struct FloatDriftModifier: ViewModifier {
    @State private var offsetY: CGFloat = 0
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .onAppear {
                guard isEnabled else { return }
                withAnimation(
                    .easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offsetY = -2
                }
            }
    }
}

// MARK: - HoverScaleModifier

struct HoverScaleModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Extensions

extension View {
    func bobbing(isEnabled: Bool = true) -> some View {
        modifier(BobModifier(isEnabled: isEnabled))
    }

    func glowPulse(isEnabled: Bool = true) -> some View {
        modifier(GlowPulseModifier(isEnabled: isEnabled))
    }

    func floatDrift(isEnabled: Bool = true) -> some View {
        modifier(FloatDriftModifier(isEnabled: isEnabled))
    }

    func hoverScale() -> some View {
        modifier(HoverScaleModifier())
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|warning:|BUILD)"`

Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add Floatify/Floatify/IdleAnimations.swift
git commit -m "feat: add idle spring animations (bob, glow pulse, float drift)"
```

---

## Task 5: Modify FloatEffects.swift to add lottieFileName

**Files:**
- Modify: `Floatify/Floatify/FloatEffects.swift`

- [ ] **Step 1: Read current FloatEffects.swift**

Read the file to see current structure

- [ ] **Step 2: Add lottieFileName computed property**

Add after the existing `defaultEffect` computed property:

```swift
var lottieFileName: String {
    switch self {
    case "slide":   return "slide_entry"
    case "fade":    return "fade_entry"
    case "dropdown": return "dropdown_entry"
    case "marquee": return "marquee_entry"
    case "trail":   return "trail_entry"
    default:        return "slide_entry"
    }
}

var exitLottieFileName: String {
    switch self {
    case "slide", "dropdown", "marquee", "trail":
        return "exit_slide"
    case "fade":
        return "exit_fade"
    default:
        return "exit_slide"
    }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)"`

- [ ] **Step 4: Commit**

```bash
git add Floatify/Floatify/FloatEffects.swift
git commit -m "feat: add lottieFileName and exitLottieFileName to FloatEffects"
```

---

## Task 6: Modify FloatNotificationView.swift to integrate Lottie + idle animations

**Files:**
- Modify: `Floatify/Floatify/FloatNotificationView.swift`

- [ ] **Step 1: Read current FloatNotificationView.swift`

- [ ] **Step 2: Replace FloatNotificationView content with integrated version**

Replace the entire file with:

```swift
import SwiftUI

struct FloatNotificationView: View {
    let message: String
    var project: String?
    var corner: Corner = .bottomRight
    var effect: String? = nil
    var sound: String? = nil
    var onTap: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var isVisible = false
    @State private var lottieProgress: CGFloat = 0
    @State private var showGlow = false
    @State private var showIdleAnimations = false
    @StateObject private var lottieAnimator = LottieAnimator()
    @StateObject private var particleSystem = ParticleSystem()

    private var effectiveEffect: String {
        effect ?? corner.defaultEffect
    }

    private var effectiveSound: String? {
        sound ?? corner.defaultSound
    }

    private var displayName: String {
        let name = project ?? "Claude Code"
        if name.count > 20 {
            return String(name.prefix(20)) + "..."
        }
        return name
    }

    var body: some View {
        ZStack {
            contentView
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.85)

            if corner == .cursorFollow {
                ParticleTrailView(system: particleSystem, color: .yellow)
                    .frame(width: 300, height: 100)
            }
        }
        .onAppear {
            triggerEntry()
        }
    }

    private var contentView: some View {
        HStack(spacing: 10) {
            duckIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
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
        .shimmer()
        .onTapGesture { onTap?() }
    }

    private var duckIcon: some View {
        Text("🦆")
            .font(.system(size: 32))
            .bobbing(isEnabled: showIdleAnimations)
            .glowPulse(isEnabled: showIdleAnimations && showGlow)
            .floatDrift(isEnabled: showIdleAnimations)
            .hoverScale()
    }

    private func triggerEntry() {
        SoundManager.shared.play(effectiveSound)

        let lottieName = effectiveEffect.lottieFileName

        lottieAnimator.play(named: lottieName) { [self] in
            showIdleAnimations = true
            showGlow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showGlow = false
            }
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
            isVisible = true
        }
    }

    func triggerExit(completion: (() -> Void)? = nil) {
        showIdleAnimations = false

        let exitName = effectiveEffect.exitLottieFileName
        lottieAnimator.playReverse(named: exitName) {
            withAnimation(.easeOut(duration: 0.15)) {
                isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                completion?()
                self.onDismiss?()
            }
        }
    }
}
```

- [ ] **Step 3: Update FloatNotificationManager to call triggerExit**

Read `FloatNotificationManager.swift` and update the `dismiss` method to call `triggerExit` instead of just `orderOut`.

In the `dismiss(panel:)` method, instead of:
```swift
panel.orderOut(nil)
```

Change to trigger the exit animation:
```swift
if let hostingView = panel.contentView as? NSHostingView<FloatNotificationView>,
   let notificationView = hostingView.rootView as? FloatNotificationView {
    notificationView.triggerExit { [weak self] in
        panel.orderOut(nil)
        self?.panels.removeAll { $0 === panel }
        self?.repositionPanels()
    }
} else {
    panel.orderOut(nil)
    panels.removeAll { $0 === panel }
    repositionPanels()
}
```

- [ ] **Step 4: Verify it compiles**

Run: `xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|BUILD)"`

- [ ] **Step 5: Commit**

```bash
git add Floatify/Floatify/FloatNotificationView.swift
git add Floatify/Floatify/FloatNotificationManager.swift
git commit -m "feat: integrate Lottie animations and idle spring physics into notification view"
```

---

## Task 7: Build and smoke test

**Files:**
- (build verification only)

- [ ] **Step 1: Full clean build**

Run: `xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -20`

Expected: `BUILD SUCCEEDED`

- [ ] **Step 2: Verify Lottie files are in bundle**

Run: `xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -i lottie`

Expected: No errors about missing Lottie

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: verify Lottie integration builds successfully"
```

---

## Implementation Order

1. Task 1: Add SPM dependency (creates build infrastructure)
2. Task 2: Create Lottie JSON files (resource files)
3. Task 3: Create LottieAnimator (animation playback logic)
4. Task 4: Create IdleAnimations (spring micro-interactions)
5. Task 5: Modify FloatEffects (add file name mapping)
6. Task 6: Modify FloatNotificationView + Manager (integration)
7. Task 7: Build verification

---

## Spec Coverage Check

- Lottie entry animation per effect type: Tasks 2, 3, 5, 6
- Lottie exit animation: Tasks 2, 3, 5, 6
- Spring idle bobbing: Task 4
- Glow pulse idle: Task 4
- Float drift idle: Task 4
- Hover reaction: Task 4
- Fallback if Lottie missing: Task 3 (loadAnimation returns nil, uses fallback)
- Performance (GPU, auto-cleanup): Tasks 3, 6
- No placeholder gaps found
