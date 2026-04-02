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