# Floatify Lottie Animation Design

## Status

Approved: 2026-04-03

## Overview

Refactor Floatify's notification popup animations to use Lottie (airbnb/lottie-macosx) for cinematic entry/exit choreography, with spring physics for idle "living" micro-interactions. The goal is a more theatrical, polished feel that makes the notification feel like a character, not just a popup.

## Library

- **Package:** `lottie-macosx` via Swift Package Manager
- **Source:** https://github.com/airbnb/lottie-ios (macOS target available)
- **Minimum macOS:** 10.15

## Animation Pipeline

### Entry Animation (Lottie, plays once)

Each effect type maps to a Lottie JSON animation file:

| Effect    | Lottie File               | Duration |
|-----------|---------------------------|----------|
| slide     | `slide_entry.json`        | ~0.9s    |
| fade      | `fade_entry.json`         | ~0.6s    |
| dropdown  | `dropdown_entry.json`     | ~1.0s    |
| marquee   | `marquee_entry.json`      | ~0.8s    |
| trail     | `trail_entry.json`        | ~0.7s    |
| default   | `slide_entry.json`        | ~0.9s    |

The Lottie animation handles:
- Panel scaling from 0.85 to 1.0 with spring overshoot
- Content fade-in with stagger
- Background shape morphing
- Color/glow transitions

### Idle Animation (Spring physics, continuous)

While the notification is visible:

1. **Duck bobbing:** Scale oscillates 0.96-1.04 using `.spring(response: 1.8, dampingFraction: 0.6)` on a `withAnimation` loop
2. **Glow pulse:** Yellow glow opacity cycles 0.3-0.7 over 3s using `OpacityPulse` modifier
3. **Float drift:** Y offset drifts +/- 2px over 2.5s using sine wave via `TimelineView`
4. **Hover reaction:** On mouse hover, duck scales to 1.15 with spring overshoot

### Exit Animation (Lottie reverse or dedicated JSON)

- Lottie animation plays in reverse (playRange reversed) over 0.4s
- Alternatively, use `exit_slide.json` / `exit_fade.json` dedicated files
- Final fade-out: 0.15s ease-out

## File Structure

```
Floatify/
├── Floatify/
│   ├── LottieAnimator.swift        # NEW: Lottie animation wrapper
│   ├── LottieEntryModifier.swift   # NEW: SwiftUI modifier for Lottie entry
│   ├── IdleAnimations.swift        # NEW: Spring idle animations (bob, glow, drift)
│   ├── FloatNotificationView.swift # MODIFIED: integrate Lottie + idle spring
│   ├── FloatEffects.swift         # MODIFIED: add lottieFileName per effect
│   └── Resources/
│       └── Animations/            # NEW: Lottie JSON files
│           ├── slide_entry.json
│           ├── fade_entry.json
│           ├── dropdown_entry.json
│           ├── marquee_entry.json
│           ├── trail_entry.json
│           ├── exit_slide.json
│           └── exit_fade.json
```

## Component Specifications

### LottieAnimator (new)

```swift
class LottieAnimator: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentProgress: CGFloat = 0

    func play(entryNamed name: String, completion: (() -> Void)? = nil)
    func playReverse(entryNamed name: String, completion: (() -> Void)? = nil)
    func stop()
}
```

Wraps `LottieAnimationView` from lottie-macosx in an `NSViewRepresentable` / `NSViewControllerRepresentable`.

### IdleAnimations (new)

- `BobModifier`: applies continuous scale oscillation via spring animation
- `GlowPulseModifier`: applies continuous shadow opacity pulse
- `FloatDriftModifier`: applies Y offset sine wave drift via `TimelineView`

### FloatNotificationView (modified)

- Replace hardcoded `onAppear` animation block with `LottieEntryModifier`
- Add idle animation modifiers to the duck icon
- Add hover state for duck scale reaction

### FloatEffects (modified)

Add computed property:

```swift
var lottieFileName: String {
    switch self {
    case "slide":  return "slide_entry"
    case "fade":   return "fade_entry"
    case "dropdown": return "dropdown_entry"
    case "marquee": return "marquee_entry"
    case "trail":  return "trail_entry"
    default:      return "slide_entry"
    }
}
```

## Lottie JSON Files

Since LottieFiles.com has free notification/toast animations, the following free files can be used or referenced:

- Search on LottieFiles: "toast notification enter", "pop up animation", "slide in notification"
- Download JSON, place in `Resources/Animations/`
- Verify `V` field (Lottie spec version) is 5.5.0+ compatible with lottie-macosx

If no suitable free files found, create minimal custom JSON:
- A group that scales from 0.85 to 1.0 with spring bezier
- A star/sparkle element that fades in at 50% progress
- A rounded rect that morphs from slightly smaller to final size

## Error Handling

- If Lottie JSON fails to load, fall back to existing hardcoded SwiftUI animation
- If animation file missing, log warning and use default "slide_entry"
- Animations auto-cleanup when view disappears

## Performance

- Lottie renders on CALayer (GPU)
- Idle animations use `TimelineView` (60Hz, minimal CPU)
- Max 8 concurrent panels, each with independent animation state
- Animations terminate immediately on dismiss (no orphaned timers)

## Test Plan

1. Trigger notification with each effect type, verify Lottie plays full entry
2. Let notification sit for 10s, verify idle animations continue smoothly
3. Dismiss notification, verify exit animation plays
4. Hover mouse over notification, verify duck reacts
5. Stress test: trigger 8 notifications rapidly, verify no performance degradation
6. Kill and relaunch app, verify no animation state leakage
