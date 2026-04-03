import AppKit
import Foundation

final class CursorTracker {
    static let shared = CursorTracker()

    var edgePadding: CGFloat = 20
    var snapThreshold: CGFloat = 100  // pixels from corner to trigger snap
    var cursorOffsetX: CGFloat = 20   // offset right of cursor
    var cursorOffsetY: CGFloat = 10    // offset below cursor

    var currentPosition: CGPoint {
        NSEvent.mouseLocation
    }

    private init() {}

    func startTracking() {
        // No-op: NSEvent.mouseLocation always returns current position
    }

    func stopTracking() {
        // No-op
    }

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

    func clampedPosition(in rect: CGRect, panelSize: CGSize) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero
        var pos = NSEvent.mouseLocation

        // Offset by panel half-size so setFrameOrigin (top-left corner) centers on cursor
        pos.x -= panelSize.width / 2
        pos.y -= panelSize.height / 2

        pos.x = max(rect.minX + edgePadding, min(pos.x, rect.maxX - edgePadding))
        pos.y = max(rect.minY + edgePadding, min(pos.y, rect.maxY - edgePadding))

        pos.x = max(edgePadding, min(pos.x, screen.width - edgePadding))
        pos.y = max(edgePadding, min(pos.y, screen.height - edgePadding))

        return CGPoint(x: pos.x, y: pos.y)
    }

    func screenCornerPosition(for corner: Corner, panelSize: CGSize) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero

        switch corner {
        case .bottomLeft:
            return CGPoint(x: edgePadding + panelSize.width / 2, y: edgePadding + panelSize.height / 2)
        case .bottomRight:
            return CGPoint(x: screen.width - edgePadding - panelSize.width / 2, y: edgePadding + panelSize.height / 2)
        case .topLeft:
            return CGPoint(x: edgePadding + panelSize.width / 2, y: screen.height - edgePadding - panelSize.height / 2)
        case .topRight:
            return CGPoint(x: screen.width - edgePadding - panelSize.width / 2, y: screen.height - edgePadding - panelSize.height / 2)
        case .center:
            return CGPoint(x: screen.midX, y: screen.midY)
        case .menubar:
            return CGPoint(x: screen.midX, y: screen.height - edgePadding - panelSize.height / 2)
        case .horizontal:
            return CGPoint(x: screen.midX, y: edgePadding + panelSize.height / 2)
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
        }
    }
}
