import Foundation
import SwiftUI
import WatchKit

final class GameViewModel: ObservableObject {
    enum MoleKind {
        case normal
        case golden

        var points: Int {
            switch self {
            case .normal:
                return 1
            case .golden:
                return 2
            }
        }
    }

    enum Screen {
        case home
        case playing
        case result
    }

    @Published var screen: Screen = .home
    @Published var score = 0
    @Published var timeLeft = 30
    @Published var streak = 0
    @Published var longestStreak = 0
    @Published var activeHole: Int?
    @Published var activeKind: MoleKind = .normal
    @Published var flashHole: Int?
    @Published var rewardHole: Int?
    @Published var rewardText = "+1"
    @Published var moleScale: CGFloat = 1.0
    @Published var scoreScale: CGFloat = 1.0
    @Published var didSetBest = false

    @AppStorage("bestScore") var bestScore = 0

    private var gameTimer: Timer?
    private var moleTimer: Timer?

    func startGame() {
        stopTimers()
        score = 0
        timeLeft = 30
        streak = 0
        longestStreak = 0
        activeHole = nil
        activeKind = .normal
        flashHole = nil
        rewardHole = nil
        rewardText = "+1"
        moleScale = 1.0
        scoreScale = 1.0
        didSetBest = false
        screen = .playing

        spawnMole()
        scheduleGameTimer()
        scheduleMoleTimer()
    }

    func hit(_ index: Int) {
        guard screen == .playing else { return }

        guard activeHole == index else {
            flashHole = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                if self.flashHole == index {
                    self.flashHole = nil
                }
            }
            return
        }

        let points = activeKind.points
        let wasGolden = activeKind == .golden

        score += points
        streak += 1
        longestStreak = max(longestStreak, streak)
        flashHole = index
        rewardHole = index
        rewardText = points == 1 ? "+1" : "+2"
        activeHole = nil
        activeKind = .normal

        WKInterfaceDevice.current().play(.click)
        SoundPlayer.shared.playHit(isGolden: wasGolden)

        withAnimation(.spring(response: 0.18, dampingFraction: 0.58)) {
            moleScale = 0.78
            scoreScale = 1.14
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.64)) {
                self.moleScale = 1.0
                self.scoreScale = 1.0
            }
            self.spawnMole()
            self.scheduleMoleTimer()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.flashHole = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            self.rewardHole = nil
        }
    }

    func playAgain() {
        startGame()
    }

    func backToHome() {
        stopTimers()
        activeHole = nil
        flashHole = nil
        rewardHole = nil
        screen = .home
    }

    var isFinalRush: Bool {
        screen == .playing && timeLeft <= 10
    }

    var showsStreak: Bool {
        streak >= 2
    }

    var resultTitleKey: String {
        switch score {
        case 0 ... 7:
            return "result_cute_try"
        case 8 ... 14:
            return "result_nice"
        case 15 ... 21:
            return "result_great"
        default:
            return "result_master"
        }
    }

    var resultMessageKey: String {
        switch score {
        case 0 ... 7:
            return "msg_low"
        case 8 ... 14:
            return "msg_mid"
        case 15 ... 21:
            return "msg_high"
        default:
            return "msg_top"
        }
    }

    private func scheduleGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.tick()
        }
    }

    private func tick() {
        guard screen == .playing else { return }

        timeLeft -= 1
        if timeLeft <= 0 {
            endGame()
        } else {
            scheduleMoleTimer()
        }
    }

    private func spawnMole() {
        guard screen == .playing else { return }

        if activeHole != nil {
            streak = 0
        }

        var next = Int.random(in: 0 ..< 4)
        if let current = activeHole, next == current {
            next = (next + Int.random(in: 1 ..< 4)) % 4
        }

        moleScale = 0.72
        activeHole = next
        activeKind = nextKind()

        withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
            moleScale = 1.0
        }
    }

    private func nextKind() -> MoleKind {
        let goldenChance: Int
        if streak >= 4 || timeLeft <= 8 {
            goldenChance = 3
        } else if streak >= 2 || timeLeft <= 15 {
            goldenChance = 5
        } else {
            goldenChance = 8
        }

        return Int.random(in: 0 ..< goldenChance) == 0 ? .golden : .normal
    }

    private func scheduleMoleTimer() {
        moleTimer?.invalidate()

        let interval: TimeInterval
        switch timeLeft {
        case 21 ... 30:
            interval = 0.86
        case 11 ... 20:
            interval = 0.70
        case 6 ... 10:
            interval = 0.56
        default:
            interval = 0.46
        }

        moleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.spawnMole()
        }
    }

    private func endGame() {
        stopTimers()
        activeHole = nil
        flashHole = nil
        rewardHole = nil
        didSetBest = score > bestScore
        bestScore = max(bestScore, score)
        screen = .result
        WKInterfaceDevice.current().play(.success)
        SoundPlayer.shared.playFinish()
    }

    private func stopTimers() {
        gameTimer?.invalidate()
        moleTimer?.invalidate()
        gameTimer = nil
        moleTimer = nil
    }
}
