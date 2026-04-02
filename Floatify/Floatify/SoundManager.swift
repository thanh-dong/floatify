import AVFoundation
import Foundation

final class SoundManager {
    static let shared = SoundManager()

    private var sounds: [String: AVAudioPlayer] = [:]
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
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                sounds[name] = player
            } catch {
                print("Floatify: Failed to load sound \(name): \(error)")
            }
        }
    }

    func play(_ name: String?) {
        guard let name = name else { return }
        guard isSilentMode() == false else { return }

        if let player = sounds[name] {
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
        } else {
            loadSound(name: name)
            sounds[name]?.play()
        }
    }

    private func isSilentMode() -> Bool {
        return false
    }
}
