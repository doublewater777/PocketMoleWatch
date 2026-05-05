import AVFoundation
import Foundation

final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        ["hit", "golden", "finish"].forEach { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else {
                return
            }

            player.prepareToPlay()
            player.volume = 0.42
            players[name] = player
        }
    }

    func playHit(isGolden: Bool) {
        play(named: isGolden ? "golden" : "hit")
    }

    func playFinish() {
        play(named: "finish")
    }

    private func play(named name: String) {
        guard let player = players[name] else { return }
        player.currentTime = 0
        player.play()
    }
}
