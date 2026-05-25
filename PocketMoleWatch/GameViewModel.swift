import Foundation
import SwiftUI
import WatchKit

final class GameViewModel: ObservableObject {
    enum MoleKind {
        case normal
        case golden
        case bomb

        var basePoints: Int {
            switch self {
            case .normal:
                return 1
            case .golden:
                return 2
            case .bomb:
                return 0
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
    @Published var canPlayAgain = false

    @AppStorage("bestScore") var bestScore = 0

    private var gameTimer: Timer?
    private var moleTimer: Timer?
    private var currentMoleInterval: TimeInterval = 0.86

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
        canPlayAgain = false
        screen = .playing

        spawnMole()
        scheduleGameTimer()
        scheduleMoleTimer()
    }

    func hit(_ index: Int) {
        guard screen == .playing else { return }

        guard activeHole == index else {
            streak = 0
            flashHole = index
            WKInterfaceDevice.current().play(.retry)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                if self.flashHole == index {
                    self.flashHole = nil
                }
            }
            return
        }

        if activeKind == .bomb {
            hitBomb(at: index)
            return
        }

        streak += 1
        let points = activeKind.basePoints * multiplier
        let wasGolden = activeKind == .golden

        score += points
        longestStreak = max(longestStreak, streak)
        flashHole = index
        rewardHole = index
        let isCombo = streak >= 5
        let prefix = isCombo ? "🔥+" : "+"
        rewardText = "\(prefix)\(points)"
        activeHole = nil
        activeKind = .normal

        if wasGolden {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.click)
        }

        if streak > 0 && streak % 5 == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                WKInterfaceDevice.current().play(.directionUp)
            }
        }

        SoundPlayer.shared.playHit(isGolden: wasGolden)

        let targetMoleScale: CGFloat = isCombo ? 0.65 : 0.78
        let targetScoreScale: CGFloat = isCombo ? 1.25 : 1.14

        withAnimation(.spring(response: 0.18, dampingFraction: 0.58)) {
            moleScale = targetMoleScale
            scoreScale = targetScoreScale
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

    private func hitBomb(at index: Int) {
        score = max(0, score - 2)
        streak = 0
        flashHole = index
        rewardHole = index
        rewardText = "-2"
        activeHole = nil
        activeKind = .normal

        WKInterfaceDevice.current().play(.failure)

        withAnimation(.spring(response: 0.16, dampingFraction: 0.52)) {
            moleScale = 0.70
            scoreScale = 0.92
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.64)) {
                self.moleScale = 1.0
                self.scoreScale = 1.0
            }
            self.spawnMole()
            self.scheduleMoleTimer()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.flashHole = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            self.rewardHole = nil
        }
    }

    func playAgain() {
        guard canPlayAgain else { return }
        startGame()
    }

    func backToHome() {
        stopTimers()
        activeHole = nil
        flashHole = nil
        rewardHole = nil
        canPlayAgain = false
        screen = .home
    }

    var isFinalRush: Bool {
        screen == .playing && timeLeft <= 10
    }

    var showsStreak: Bool {
        streak >= 2
    }

    var multiplier: Int {
        switch streak {
        case 10...:
            return 3
        case 5...:
            return 2
        default:
            return 1
        }
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
            return
        }

        let newInterval = moleInterval()
        if newInterval != currentMoleInterval {
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

        let bombChance: Int
        if timeLeft <= 8 {
            bombChance = 5
        } else if streak >= 5 || timeLeft <= 15 {
            bombChance = 7
        } else {
            bombChance = 10
        }

        if Int.random(in: 0 ..< bombChance) == 0 {
            return .bomb
        }

        return Int.random(in: 0 ..< goldenChance) == 0 ? .golden : .normal
    }

    private func moleInterval() -> TimeInterval {
        switch timeLeft {
        case 21 ... 30:
            return 0.86
        case 11 ... 20:
            return 0.70
        case 6 ... 10:
            return 0.56
        default:
            return 0.46
        }
    }

    private func scheduleMoleTimer() {
        moleTimer?.invalidate()

        currentMoleInterval = moleInterval()

        moleTimer = Timer.scheduledTimer(withTimeInterval: currentMoleInterval, repeats: true) { _ in
            self.spawnMole()
        }
    }

    private func endGame() {
        stopTimers()
        activeHole = nil
        flashHole = nil
        rewardHole = nil
        canPlayAgain = false
        didSetBest = score > bestScore
        bestScore = max(bestScore, score)
        screen = .result
        WKInterfaceDevice.current().play(.success)
        SoundPlayer.shared.playFinish()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if self.screen == .result {
                self.canPlayAgain = true
            }
        }
    }

    private func stopTimers() {
        gameTimer?.invalidate()
        moleTimer?.invalidate()
        gameTimer = nil
        moleTimer = nil
    }
}
