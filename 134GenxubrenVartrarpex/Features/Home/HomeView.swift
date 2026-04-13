//
//  HomeView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppDataStore
    var onOpenActivities: () -> Void = {}
    var onOpenProfile: () -> Void = {}

    @State private var appear = false
    @State private var heroPhase: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroBlock
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 14)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: appear)

                progressSection
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: appear)

                quickStatsStrip
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.1), value: appear)

                actionRow
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.14), value: appear)

                suggestedFocusCard(caption: store.suggestedFocusCaption())
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.18), value: appear)

                activitiesSection
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.22), value: appear)

                tipFooter
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
        .entertainmentSceneBackground()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            appear = true
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                heroPhase = 1
            }
        }
    }

    // MARK: - Sections

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                HomeHeroCanvas(phase: heroPhase)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.appPrimary.opacity(0.5), Color.appAccent.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.38), radius: 22, y: 12)
                    .shadow(color: Color.appPrimary.opacity(0.22), radius: 30, y: 4)

                Text(greetingLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(14)
            }

            Text("Creative studio")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.appTextPrimary)

            Text("Shape patterns, lines, and scenes in one calm hub. Stars track how far you have pushed each path.")
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var progressSection: some View {
        let total = AppDataStore.homeMaxStarsTotal
        let collected = store.totalStarsCollected()
        let ratio = total > 0 ? Double(collected) / Double(total) : 0

        return HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.appTextSecondary.opacity(0.18), lineWidth: 10)
                    .frame(width: 108, height: 108)

                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(
                        AngularGradient(
                            colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 108, height: 108)
                    .animation(.easeInOut(duration: 0.7), value: ratio)

                VStack(spacing: 2) {
                    Text("\(collected)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color.appTextPrimary)
                    Text("stars")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Collection")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text("Up to \(total) stars across every stage. Clear more tiers to brighten the ring.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                    Text(progressMoodLine(ratio: ratio))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .entertainmentCardChrome(cornerRadius: 22, elevated: true)
    }

    private func progressMoodLine(ratio: Double) -> String {
        switch ratio {
        case 0: return "Your first stars are one tap away."
        case ..<0.15: return "Nice start — keep chaining stages."
        case ..<0.4: return "Momentum building across activities."
        case ..<0.7: return "Serious coverage — polish the harder tiers."
        case ..<0.99: return "Almost there — chase the last glow-ups."
        default: return "Outstanding sweep of the whole catalog."
        }
    }

    private var quickStatsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                HomeStatChip(
                    icon: "star.fill",
                    title: "Stars",
                    value: "\(store.totalStarsCollected())",
                    tint: Color.appPrimary
                )
                HomeStatChip(
                    icon: "play.circle.fill",
                    title: "Sessions",
                    value: "\(store.totalActivitiesPlayed)",
                    tint: Color.appAccent
                )
                HomeStatChip(
                    icon: "chart.bar.fill",
                    title: "Rank",
                    value: "Lv \(store.playerLevel)",
                    tint: Color.appPrimary
                )
                HomeStatChip(
                    icon: "flame.fill",
                    title: "Streak",
                    value: store.consecutiveDayStreak > 0 ? "\(store.consecutiveDayStreak)d" : "—",
                    tint: Color.appAccent
                )
                HomeStatChip(
                    icon: "clock.fill",
                    title: "Active time",
                    value: store.homeFormattedPlayTime(),
                    tint: Color.appPrimary
                )
                HomeStatChip(
                    icon: "gift.fill",
                    title: "Rewards",
                    value: "\(store.unlockedRewardIds.count)/\(RewardCatalog.allBadges.count)",
                    tint: Color.appAccent
                )
                HomeStatChip(
                    icon: "seal.fill",
                    title: "Highlights",
                    value: "\(store.unlockedAchievementIds.count)/\(AppDataStore.allAchievements.count)",
                    tint: Color.appAccent
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: onOpenActivities) {
                Label("Open activities", systemImage: "square.grid.2x2.fill")
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(EntertainmentPrimaryButtonStyle())

            Button(action: onOpenProfile) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(width: 52, height: 52)
                    .entertainmentCardChrome(cornerRadius: 14, elevated: false)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Open profile and stats"))
        }
    }

    private func suggestedFocusCard(caption: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "scope")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimary)
                Text("Suggested focus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
            }
            Text(caption)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onOpenActivities) {
                Text("Go to activities")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(EntertainmentSecondaryButtonStyle())
        }
        .padding(18)
        .entertainmentCardChrome(cornerRadius: 20, elevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appPrimary.opacity(0.28), lineWidth: 1)
        )
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Explore")
                .font(.title3.bold())
                .foregroundStyle(Color.appTextPrimary)

            ForEach(ActivityKind.allCases, id: \.self) { kind in
                let cap = AppDataStore.homeMaxStarsPerActivity
                let got = store.starsSummed(for: kind)
                Button(action: onOpenActivities) {
                    HomeActivityRow(
                        kind: kind,
                        starsCollected: got,
                        starsCap: cap
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tipFooter: some View {
        Text("Hard tiers reward patience: tighter timing, larger grids, and richer soundscapes. Use the Activities tab to switch paths anytime.")
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }
}

// MARK: - Subviews

private struct HomeHeroCanvas: View {
    var phase: CGFloat

    var body: some View {
        Canvas { context, size in
            let warm = Color.appPrimary.opacity(0.35 + phase * 0.12)
            let cool = Color.appAccent.opacity(0.28 + phase * 0.1)

            let blob1 = Path(ellipseIn: CGRect(x: -20, y: 10, width: size.width * 0.55, height: size.height * 0.85))
            context.fill(blob1, with: .color(warm))

            let blob2 = Path(ellipseIn: CGRect(x: size.width * 0.35, y: -30, width: size.width * 0.6, height: size.height * 0.9))
            context.fill(blob2, with: .color(cool))

            let arcCenter = CGPoint(x: size.width * 0.72, y: size.height * 0.35)
            var arc = Path()
            arc.addArc(center: arcCenter, radius: min(size.width, size.height) * 0.22, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            context.stroke(arc, with: .color(Color.appTextPrimary.opacity(0.2)), lineWidth: 3)

            for index in 0..<5 {
                let angle = Double(index) / 5 * Double.pi * 2 + Double(phase) * 0.4
                let r: CGFloat = min(size.width, size.height) * 0.12
                let p = CGPoint(
                    x: arcCenter.x + CGFloat(cos(angle)) * r,
                    y: arcCenter.y + CGFloat(sin(angle)) * r
                )
                let dot = Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6))
                context.fill(dot, with: .color(Color.appTextPrimary.opacity(0.35)))
            }
        }
        .background(Color.appSurface.opacity(0.4))
        .accessibilityHidden(true)
    }
}

private struct HomeStatChip: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(Circle().fill(tint.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(minWidth: 100, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .entertainmentCardChrome(cornerRadius: 16, elevated: false)
    }
}

private struct HomeActivityRow: View {
    let kind: ActivityKind
    let starsCollected: Int
    let starsCap: Int

    private var ratio: CGFloat {
        guard starsCap > 0 else { return 0 }
        return CGFloat(starsCollected) / CGFloat(starsCap)
    }

    var body: some View {
        HStack(spacing: 16) {
            HomeActivityGlyph(kind: kind)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 8) {
                Text(kind.displayTitle)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(kind.detailDescription)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appTextSecondary.opacity(0.15))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPrimary, Color.appAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * ratio))
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(starsCollected) / \(starsCap) stars")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
        .padding(16)
        .entertainmentCardChrome(cornerRadius: 20, elevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appAccent.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct HomeActivityGlyph: View {
    let kind: ActivityKind

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            switch kind {
            case .colorSymphony:
                let cols = 2
                let rows = 2
                let w = rect.width / CGFloat(cols)
                let h = rect.height / CGFloat(rows)
                let colors: [Color] = [.red, .blue, .green, .yellow]
                for r in 0..<rows {
                    for c in 0..<cols {
                        let tile = CGRect(x: rect.minX + CGFloat(c) * w, y: rect.minY + CGFloat(r) * h, width: w - 3, height: h - 3)
                        context.fill(Path(roundedRect: tile, cornerRadius: 5), with: .color(colors[(r * cols + c) % colors.count].opacity(0.88)))
                    }
                }
            case .melodyMaker:
                for index in 0..<5 {
                    let y = rect.minY + rect.height * CGFloat(index + 1) / 6
                    var line = Path()
                    line.move(to: CGPoint(x: rect.minX, y: y))
                    line.addLine(to: CGPoint(x: rect.maxX, y: y))
                    context.stroke(line, with: .color(Color.appTextSecondary.opacity(0.5)), lineWidth: 1)
                }
                for index in 0..<4 {
                    let x = rect.minX + CGFloat(index + 1) / 5 * rect.width
                    let note = Path(ellipseIn: CGRect(x: x - 4, y: rect.midY - 6, width: 8, height: 6))
                    context.fill(note, with: .color(Color.appPrimary))
                }
            case .adventureSketch:
                context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(Color.appAccent.opacity(0.3)))
                context.fill(Path(ellipseIn: CGRect(x: rect.midX - 14, y: rect.midY - 8, width: 18, height: 18)), with: .color(Color.appPrimary.opacity(0.95)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appBackground.opacity(0.5))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}

// MARK: - Store helpers (home only)

extension AppDataStore {
    fileprivate static var homeMaxStarsPerActivity: Int {
        DifficultyTier.allCases.count * LevelProgression.stagesPerDifficulty * 3
    }

    fileprivate static var homeMaxStarsTotal: Int {
        ActivityKind.allCases.count * homeMaxStarsPerActivity
    }

    fileprivate func starsSummed(for activity: ActivityKind) -> Int {
        var sum = 0
        for difficulty in DifficultyTier.allCases {
            for index in 0..<LevelProgression.stagesPerDifficulty {
                let address = LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index)
                sum += stars(for: address)
            }
        }
        return sum
    }

    /// Next place to improve: first unlocked stage below three stars, in catalog order.
    fileprivate func suggestedFocusCaption() -> String {
        for activity in ActivityKind.allCases {
            for difficulty in DifficultyTier.allCases {
                for index in 0..<LevelProgression.stagesPerDifficulty {
                    let address = LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index)
                    if isLevelUnlocked(address), stars(for: address) < 3 {
                        return "\(activity.displayTitle) · \(difficulty.title) · Stage \(index + 1)"
                    }
                }
            }
        }
        return "Every unlocked stage shines with three stars — revisit any tier for faster runs or new personal bests."
    }

    fileprivate func homeFormattedPlayTime() -> String {
        let seconds = Int(max(0, totalPlaySeconds))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        if seconds > 0 {
            return "\(seconds)s"
        }
        return "0m"
    }
}
