import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var animateHero = false
    @State private var animateGlow = false
    @State private var animateRush = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            GameBackground(isAnimated: animateGlow)

            switch vm.screen {
            case .home:
                homeView
            case .playing:
                gameView
            case .result:
                resultView
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                animateHero = true
            }

            withAnimation(.easeInOut(duration: 4.4).repeatForever(autoreverses: true)) {
                animateGlow = true
            }

            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                animateRush = true
            }
        }
    }

    private var homeView: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            MoleHeroBadge(isAnimated: animateHero)

            Text("app_name")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.cream)

            Text("home_tagline")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.cream.opacity(0.76))

            ScoreBadge(titleKey: "best", value: "\(vm.bestScore)")

            Button {
                vm.startGame()
            } label: {
                Text("play")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.brownDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(.sunYellow)
                    )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(10)
    }

    private var gameView: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.boardTop)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        StatPill(titleKey: "score", value: "\(vm.score)", accent: .sunYellow)
                            .scaleEffect(vm.scoreScale)

                        StatPill(
                            titleKey: "time",
                            value: "\(vm.timeLeft)s",
                            accent: vm.isFinalRush ? .rushRed : .sunYellow,
                            isUrgent: vm.isFinalRush
                        )
                    }

                    statusOverlay

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0 ..< 4, id: \.self) { index in
                            HoleButton(
                                isActive: vm.activeHole == index,
                                isGolden: vm.activeHole == index && vm.activeKind == .golden,
                                isFlashed: vm.flashHole == index,
                                isRewarded: vm.rewardHole == index,
                                rewardText: vm.rewardText,
                                moleScale: vm.activeHole == index ? vm.moleScale : 1.0
                            ) {
                                vm.hit(index)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var statusOverlay: some View {
        ZStack {
            Capsule()
                .fill(.white.opacity(0.08))

            if vm.isFinalRush {
                Text("rush")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.rushRed)
                    .scaleEffect(animateRush ? 1.06 : 0.94)
                    .opacity(animateRush ? 1 : 0.74)
                    .transition(.opacity.combined(with: .scale))
            } else if vm.showsStreak {
                Text("\(localized("streak_prefix")) \(vm.streak)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(vm.streak >= 4 ? .sunYellow : .cream)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Text(" ")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
            }
        }
        .frame(height: 20)
    }

    private var resultView: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            Text(LocalizedStringKey(vm.resultTitleKey))
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.cream)

            Text("\(localized("score")) \(vm.score)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.sunYellow)

            Text(LocalizedStringKey(vm.resultMessageKey))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.cream.opacity(0.74))
                .multilineTextAlignment(.center)

            if vm.didSetBest {
                Text("new_best")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.sunYellow)
                    .scaleEffect(animateHero ? 1.04 : 0.96)
            }

            ScoreBadge(titleKey: "best", value: "\(vm.bestScore)")

            if vm.longestStreak >= 2 {
                Text("\(localized("best_streak")) \(vm.longestStreak)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.cream.opacity(0.78))
            }

            Button {
                vm.playAgain()
            } label: {
                Text("play_again")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.brownDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(.sunYellow)
                    )
            }
            .buttonStyle(.plain)

            Button {
                vm.backToHome()
            } label: {
                Text("home")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(.white.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(10)
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

private struct HoleButton: View {
    let isActive: Bool
    let isGolden: Bool
    let isFlashed: Bool
    let isRewarded: Bool
    let rewardText: String
    let moleScale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.soil.opacity(0.72), .holeMid],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Circle()
                    .stroke(.black.opacity(0.18), lineWidth: 2)

                Circle()
                    .fill(.black.opacity(0.18))
                    .scaleEffect(1.14)
                    .blur(radius: 4)
                    .offset(y: 7)

                if isActive {
                    MoleView(isGolden: isGolden)
                        .scaleEffect(moleScale)
                        .offset(y: -1)
                        .transition(.scale.combined(with: .opacity))
                }

                if isFlashed {
                    Circle()
                        .fill(.sunYellow.opacity(0.22))
                        .scaleEffect(1.08)
                }

                if isRewarded {
                    Text(rewardText)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(isGolden ? .sunYellow : .cream)
                        .offset(y: -26)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .frame(height: 56)
            .contentShape(Circle())
            .scaleEffect(isFlashed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isFlashed)
        }
        .buttonStyle(.plain)
    }
}

private struct MoleView: View {
    let isGolden: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isGolden ? .goldenMole : .moleFace)
                .frame(width: 30, height: 30)

            Circle()
                .fill(isGolden ? .goldenEar : .moleEar)
                .frame(width: 9, height: 9)
                .offset(x: -8, y: -10)

            Circle()
                .fill(isGolden ? .goldenEar : .moleEar)
                .frame(width: 9, height: 9)
                .offset(x: 8, y: -10)

            Circle()
                .fill(.black)
                .frame(width: 3.2, height: 3.2)
                .offset(x: -5, y: -2)

            Circle()
                .fill(.black)
                .frame(width: 3.2, height: 3.2)
                .offset(x: 5, y: -2)

            Circle()
                .fill(isGolden ? .sunYellow : .pinkNose)
                .frame(width: 6, height: 5)
                .offset(y: 3)

            RoundedRectangle(cornerRadius: 2)
                .fill(isGolden ? .white.opacity(0.48) : .white.opacity(0.35))
                .frame(width: 12, height: 4)
                .offset(y: 10)
        }
        .shadow(color: isGolden ? .sunYellow.opacity(0.35) : .black.opacity(0.14), radius: 3, y: 1)
    }
}

private struct MoleHeroBadge: View {
    let isAnimated: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(.sunYellow.opacity(0.18))
                .frame(width: 58, height: 58)
                .blur(radius: 8)
                .scaleEffect(isAnimated ? 1.08 : 0.92)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 44, height: 44)

            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 1)
                .frame(width: 52, height: 52)
                .scaleEffect(isAnimated ? 1.06 : 0.94)

            MoleView(isGolden: false)
                .scaleEffect(1.05)
                .offset(y: isAnimated ? -1.5 : 1.5)
        }
    }
}

private struct StatPill: View {
    let titleKey: String
    let value: String
    var accent: Color = .orangeSoft
    var isUrgent = false

    var body: some View {
        VStack(spacing: 1) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.cream.opacity(0.72))

            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isUrgent ? .rushRed.opacity(0.18) : .white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isUrgent ? .rushRed.opacity(0.55) : .clear, lineWidth: 1)
        )
    }
}

private struct ScoreBadge: View {
    let titleKey: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.cream.opacity(0.70))

            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.sunYellow)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(.white.opacity(0.10))
        )
    }
}

private struct GameBackground: View {
    let isAnimated: Bool

    var body: some View {
        LinearGradient(
            colors: [.bgTop, .bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Circle()
                .fill(.orangeSoft.opacity(0.18))
                .frame(width: 110, height: 110)
                .offset(x: isAnimated ? 40 : 26, y: isAnimated ? -52 : -36)
                .blur(radius: 12)
        )
        .overlay(
            Circle()
                .fill(.sunYellow.opacity(0.08))
                .frame(width: 88, height: 88)
                .offset(x: isAnimated ? -26 : -14, y: isAnimated ? 48 : 36)
                .blur(radius: 10)
        )
        .ignoresSafeArea()
    }
}

private extension ShapeStyle where Self == Color {
    static var bgTop: Color { Color(red: 0.19, green: 0.10, blue: 0.07) }
    static var bgBottom: Color { Color(red: 0.34, green: 0.18, blue: 0.10) }
    static var boardTop: Color { Color(red: 0.42, green: 0.24, blue: 0.14) }
    static var holeMid: Color { Color(red: 0.30, green: 0.14, blue: 0.09) }
    static var soil: Color { Color(red: 0.10, green: 0.05, blue: 0.03) }
    static var moleFace: Color { Color(red: 0.62, green: 0.46, blue: 0.34) }
    static var moleEar: Color { Color(red: 0.72, green: 0.56, blue: 0.43) }
    static var goldenMole: Color { Color(red: 0.96, green: 0.77, blue: 0.34) }
    static var goldenEar: Color { Color(red: 1.00, green: 0.86, blue: 0.46) }
    static var pinkNose: Color { Color(red: 0.96, green: 0.61, blue: 0.63) }
    static var cream: Color { Color(red: 0.98, green: 0.92, blue: 0.84) }
    static var sunYellow: Color { Color(red: 0.98, green: 0.77, blue: 0.28) }
    static var orangeSoft: Color { Color(red: 0.96, green: 0.57, blue: 0.25) }
    static var rushRed: Color { Color(red: 0.95, green: 0.38, blue: 0.28) }
    static var brownDark: Color { Color(red: 0.28, green: 0.16, blue: 0.08) }
}

#Preview {
    ContentView()
}
