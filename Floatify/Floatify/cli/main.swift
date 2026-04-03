import Foundation

// MARK: - Argument Parsing

var message = "Task complete!"
var corner = "bottomRight"
var duration = "6"
var project = "Claude Code"
var effect: String? = nil

let args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let flag = args[index]
    index += 1
    guard index < args.count else { break }

    switch flag {
    case "--message":
        message = args[index]
    case "--position", "--corner":
        corner = args[index]
    case "--duration":
        duration = args[index]
    case "--project":
        project = args[index]
    case "--effect":
        effect = args[index]
    default:
        break
    }
    index += 1
}

// Validate corner
let validCorners = ["bottomLeft", "bottomRight", "topLeft", "topRight", "center", "menubar", "horizontal", "cursorFollow"]
guard validCorners.contains(corner) else {
    fputs("Invalid corner '\(corner)'. Use: \(validCorners.joined(separator: ", ")).\n", stderr)
    exit(1)
}

// Validate duration
guard Double(duration) != nil else {
    fputs("Invalid duration '\(duration)'. Must be a number.\n", stderr)
    exit(1)
}

// MARK: - Write to Pipe

let pipePath = "/var/tmp/floatify.pipe"

var payload: [String: Any] = [
    "message":  message,
    "corner":   corner,
    "duration": Double(duration) ?? 6.0,
    "project":  project
]

if let effect = effect {
    payload["effect"] = effect
}

guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
    fputs("Failed to encode payload\n", stderr)
    exit(1)
}

// Open pipe for writing
let pipeFd = open(pipePath, O_WRONLY | O_NONBLOCK)
if pipeFd < 0 {
    if errno == EACCES || errno == EPERM {
        fputs("🦆 Permission denied - check app permissions\n", stderr)
    } else {
        fputs("🦆 Floatify.app is not running\n", stderr)
    }
    exit(1)
}

let bytesWritten = data.withUnsafeBytes { buffer -> Int in
    return write(pipeFd, buffer.baseAddress!, data.count)
}
close(pipeFd)

if bytesWritten == data.count {
    print("🦆 Sent: \(message)")
    exit(0)
} else {
    fputs("Failed to write to pipe\n", stderr)
    exit(1)
}
