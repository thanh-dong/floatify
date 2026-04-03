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
