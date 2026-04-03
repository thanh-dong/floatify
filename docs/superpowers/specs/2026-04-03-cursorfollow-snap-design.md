# cursorFollow Snap-to-Corner Design

## Overview

cursorFollow mode snaps to the nearest screen corner when the cursor is near that corner (within threshold), otherwise follows the cursor with a fixed offset.

## Behavior

### Snap Mode
- When cursor is within 100px of a screen corner, notification snaps to that corner
- Uses the same corner positioning as the fixed corner positions

### Follow Mode
- When cursor is far from all corners (>100px), notification follows cursor
- Offset: 20px to the right, 10px below the cursor
- Position is clamped to stay within screen bounds

## Implementation

### CursorTracker.swift changes

Add new configuration:
```swift
var snapThreshold: CGFloat = 100  // pixels from corner to trigger snap
var cursorOffsetX: CGFloat = 20   // offset right of cursor
var cursorOffsetY: CGFloat = 10    // offset below cursor
```

Modify `screenCornerPosition(for: .cursorFollow, panelSize:)`:
1. Get cursor position via NSEvent.mouseLocation
2. Calculate Euclidean distance to each corner
3. Find minimum distance and corresponding corner
4. If minDistance < snapThreshold, return that corner's position
5. Otherwise, return cursor position + (offsetX, offsetY), clamped to screen

### Distance Calculation
```swift
func distanceToCorner(_ corner: Corner, from point: CGPoint, screenSize: CGSize) -> CGFloat {
    let cornerPoint = CGPoint(
        x: corner == .bottomLeft || corner == .topLeft ? 0 : screenSize.width,
        y: corner == .bottomLeft || corner == .bottomRight ? 0 : screenSize.height
    )
    return hypot(point.x - cornerPoint.x, point.y - cornerPoint.y)
}
```

## Visual Behavior

```
Near corner (<100px):           Far from corner (>100px):
┌────────────────────┐          ┌────────────────────┐
│[cursor]            │          │                    │
│   ↓                │          │      [cursor]      │
│┌────────┐          │          │         ↓          │
││ snap!  │          │          │   ┌────────┐       │
│└────────┘          │          │   │follow! │       │
│         └─100px──┬│          │   └────────┘       │
└────────────────────┘          └────────────────────┘
```

## Files Modified

- `Floatify/Floatify/CursorTracker.swift`
