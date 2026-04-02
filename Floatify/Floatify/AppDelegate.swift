import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var pipeSource: DispatchSourceRead?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPipeListener()
        installCLIToolIfNeeded()
        SoundManager.shared.loadSounds()
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
        menu.addItem(NSMenuItem(title: "Quit Floatify", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func testNotification() {
        FloatNotificationManager.shared.show(message: "Test notification! 🦆", corner: .bottomRight, duration: 5)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Pipe Listener

    private let pipePath = "/var/tmp/floatify.pipe"

    private func setupPipeListener() {
        NSLog("Floatify: Setting up pipe at %@", pipePath)

        // Create pipe if it doesn't exist
        if !FileManager.default.fileExists(atPath: pipePath) {
            let result = mkfifo(pipePath, 0o666)
            NSLog("Floatify: mkfifo result: %d, errno: %d", result, errno)
        }

        // Remove existing pipe to avoid stale state
        try? FileManager.default.removeItem(atPath: pipePath)
        let mkresult = mkfifo(pipePath, 0o666)
        NSLog("Floatify: mkfifo second call result: %d, errno: %d", mkresult, errno)

        // Open pipe for reading
        let pipeFd = open(pipePath, O_RDONLY | O_NONBLOCK)
        NSLog("Floatify: pipeFd: %d, errno: %d", pipeFd, errno)
        guard pipeFd >= 0 else {
            print("Failed to open pipe at \(pipePath)")
            return
        }

        // Set up dispatch source to read from pipe
        pipeSource = DispatchSource.makeReadSource(fileDescriptor: pipeFd, queue: .main)
        pipeSource?.setEventHandler { [weak self] in
            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(pipeFd, &buffer, buffer.count)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self?.handleJSON(json)
                }
            }
        }
        pipeSource?.setCancelHandler {
            close(pipeFd)
        }
        pipeSource?.resume()
    }

    private func handleJSON(_ json: [String: Any]) {
        let message = json["message"] as? String ?? "Task complete!"
        let cornerStr = json["corner"] as? String ?? "bottomRight"
        let corner: Corner
        switch cornerStr {
        case "bottomLeft": corner = .bottomLeft
        case "bottomRight": corner = .bottomRight
        case "topLeft": corner = .topLeft
        case "topRight": corner = .topRight
        case "center": corner = .center
        case "menubar": corner = .menubar
        case "horizontal": corner = .horizontal
        case "cursorFollow": corner = .cursorFollow
        default: corner = .bottomRight
        }
        let duration = json["duration"] as? TimeInterval ?? 6.0

        DispatchQueue.main.async {
            FloatNotificationManager.shared.show(message: message, corner: corner, duration: duration)
        }
    }

    // MARK: - CLI Symlink Installation

    private func installCLIToolIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "CLISymlinkInstalled") else { return }

        let src = Bundle.main.url(forResource: "floatify", withExtension: nil)
        guard let srcURL = src else {
            NSLog("Floatify: floatify binary not found in app bundle")
            return
        }

        let dest = URL(fileURLWithPath: "/usr/local/bin/floatify")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: srcURL)
            defaults.set(true, forKey: "CLISymlinkInstalled")
            NSLog("Floatify: Installed floatify to /usr/local/bin/")
        } catch {
            NSLog("Floatify: Failed to install floatify CLI: %@", error.localizedDescription)
        }
    }
}
