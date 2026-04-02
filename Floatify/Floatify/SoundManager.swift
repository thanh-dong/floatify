import AppKit
import Foundation

final class SoundManager {
    static let shared = SoundManager()

    private var sounds: [String: NSSound] = [:]
    private let soundDirectory = "Sounds"

    private init() {}

    func loadSounds() {
        loadSound(name: "pop")
        loadSound(name: "tink")
        loadSound(name: "whoosh")
    }

    private func loadSound(name: String) {
        guard sounds[name] == nil else { return }

        if let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: soundDirectory) {
            if let sound = NSSound(contentsOf: url, byReference: true) {
                sound.volume = 0.3
                sounds[name] = sound
            }
        }
    }

    func play(_ name: String?) {
        guard let name = name else { return }

        if let sound = sounds[name] {
            sound.currentTime = 0
            sound.play()
        } else {
            loadSound(name: name)
            sounds[name]?.play()
        }
    }
}
