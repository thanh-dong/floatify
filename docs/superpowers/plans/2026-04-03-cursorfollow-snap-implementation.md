# cursorFollow Snap-to-Corner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement cursorFollow mode that snaps to nearest screen corner when cursor is near (<100px), otherwise follows cursor with 20px right, 10px below offset.

**Architecture:** Add snap detection logic to CursorTracker.swift. When cursor is within threshold of a corner, return that corner's position. Otherwise return cursor position + offset, clamped to screen bounds.

**Tech Stack:** Swift, AppKit (NSEvent, NSScreen)

---

## File: Floatify/Floatify/CursorTracker.swift

### Task 1: Add snap threshold and offset configuration

**Files:**
- Modify: `Floatify/Floatify/CursorTracker.swift`

- [ ] **Step 1: Add new configuration properties**

Add these properties after `edgePadding`:

```swift
var snapThreshold: CGFloat = 100  // pixels from corner to trigger snap
var cursorOffsetX: CGFloat = 20   // offset right of cursor
var cursorOffsetY: CGFloat = 10    // offset below cursor
```

- [ ] **Step 2: Add distance calculation helper**

Add this method before `clampedPosition`:

```swift
private func distanceToCorner(_ corner: Corner, from point: CGPoint, screenSize: CGSize) -> CGFloat {
    let cornerX: CGFloat
    let cornerY: CGFloat

    switch corner {
    case .bottomLeft:
        cornerX = 0
        cornerY = 0
    case .bottomRight:
        cornerX = screenSize.width
        cornerY = 0
    case .topLeft:
        cornerX = 0
        cornerY = screenSize.height
    case .topRight:
        cornerX = screenSize.width
        cornerY = screenSize.height
    default:
        return .greatestFiniteMagnitude
    }

    let dx = point.x - cornerX
    let dy = point.y - cornerY
    return sqrt(dx * dx + dy * dy)
}
```

- [ ] **Step 3: Modify screenCornerPosition for cursorFollow case**

Replace the cursorFollow case in `screenCornerPosition(for:panelSize:)` with:

```swift
case .cursorFollow:
    let cursorPos = NSEvent.mouseLocation
    let screenSize = screen.size

    // Calculate distance to each corner
    let corners: [Corner] = [.bottomLeft, .bottomRight, .topLeft, .topRight]
    var minDistance: CGFloat = .greatestFiniteMagnitude
    var nearestCorner: Corner = .bottomRight

    for corner in corners {
        let dist = distanceToCorner(corner, from: cursorPos, screenSize: screenSize)
        if dist < minDistance {
            minDistance = dist
            nearestCorner = corner
        }
    }

    // If cursor is near a corner, snap to it
    if minDistance < snapThreshold {
        return cornerOriginForFollow(corner: nearestCorner, size: panelSize)
    }

    // Otherwise follow cursor with offset
    var followPos = cursorPos
    followPos.x += cursorOffsetX
    followPos.y -= cursorOffsetY  // subtract because screen coords are flipped

    // Clamp to screen bounds
    followPos.x = max(edgePadding, min(followPos.x, screenSize.width - panelSize.width - edgePadding))
    followPos.y = max(edgePadding, min(followPos.y, screenSize.height - panelSize.height - edgePadding))

    return followPos
```

- [ ] **Step 4: Add cornerOriginForFollow helper**

Add this method in CursorTracker (after `distanceToCorner`):

```swift
private func cornerOriginForFollow(corner: Corner, size: CGSize) -> CGPoint {
    let screen = NSScreen.main?.frame ?? .zero

    switch corner {
    case .bottomLeft:
        return CGPoint(x: edgePadding, y: edgePadding)
    case .bottomRight:
        return CGPoint(x: screen.width - size.width - edgePadding, y: edgePadding)
    case .topLeft:
        return CGPoint(x: edgePadding, y: screen.height - size.height - edgePadding)
    case .topRight:
        return CGPoint(x: screen.width - size.width - edgePadding, y: screen.height - size.height - edgePadding)
    default:
        return CGPoint(x: edgePadding, y: edgePadding)
    }
}
```

- [ ] **Step 5: Build and verify**

Run:
```bash
cd Floatify && xcodegen generate && xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add Floatify/Floatify/CursorTracker.swift
git commit -m "feat: cursorFollow snaps to nearest corner when cursor is within threshold"
```

---

## Verification

Manual test:
```bash
# Move cursor to center of screen - notification should follow with offset
floatify --message 'Following cursor!' --position cursorFollow --duration 8 &

# Move cursor to bottom-right corner - notification should snap to corner
```

Expected behavior:
- Cursor in middle of screen: notification follows with 20px right, 10px below
- Cursor within 100px of corner: notification snaps to that corner
- Notification stays within screen bounds at all times
