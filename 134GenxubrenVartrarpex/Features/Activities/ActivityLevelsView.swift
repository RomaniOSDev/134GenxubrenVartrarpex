//
//  ActivityLevelsView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct ActivityLevelsView: View {
    @Binding var path: NavigationPath
    let activity: ActivityKind

    @EnvironmentObject private var store: AppDataStore
    @State private var difficulty: DifficultyTier = .easy

    private var stageIndices: Range<Int> {
        0..<LevelProgression.stagesPerDifficulty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Follow the path—each node unlocks after the previous stage earns at least one star.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Picker("Difficulty", selection: $difficulty) {
                    ForEach(DifficultyTier.allCases, id: \.self) { tier in
                        Text(tier.title).tag(tier)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(Text("Difficulty"))

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(stageIndices), id: \.self) { index in
                        let address = LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index)
                        let stars = store.stars(for: address)
                        let unlocked = store.isLevelUnlocked(address)
                        let completed = stars >= 1
                        StageRowConnector(
                            index: index,
                            total: LevelProgression.stagesPerDifficulty,
                            completed: completed,
                            unlocked: unlocked
                        ) {
                            StageLevelCardView(
                                stageNumber: index + 1,
                                difficulty: difficulty,
                                stars: stars,
                                unlocked: unlocked,
                                activity: activity
                            )
                        } onTap: {
                            path.append(ActivityFlowRoute.session(address))
                        }
                    }
                }
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 16)
        }
        .entertainmentSceneBackground()
    }
}

// MARK: - Timeline + card

private struct StageRowConnector<Content: View>: View {
    let index: Int
    let total: Int
    let completed: Bool
    let unlocked: Bool
    @ViewBuilder let content: () -> Content
    let onTap: () -> Void

    private var isLast: Bool { index >= total - 1 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(Color.appAccent.opacity(unlocked ? 0.55 : 0.2), lineWidth: 3)
                        .frame(width: 20, height: 20)
                    if completed {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.appPrimary, Color.appAccent.opacity(0.85)],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 14
                                )
                            )
                            .frame(width: 12, height: 12)
                    } else if unlocked {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 26)

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(completed ? 0.65 : 0.18),
                                    Color.appAccent.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4)
                        .frame(minHeight: 88, maxHeight: 120)
                }
            }
            .frame(width: 28)

            Button(action: onTap) {
                content()
            }
            .buttonStyle(.plain)
            .disabled(!unlocked)
        }
        .padding(.bottom, isLast ? 0 : 6)
        .accessibilityElement(children: .combine)
    }
}

private struct StageLevelCardView: View {
    let stageNumber: Int
    let difficulty: DifficultyTier
    let stars: Int
    let unlocked: Bool
    let activity: ActivityKind

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                stageBadge

                VStack(alignment: .leading, spacing: 8) {
                    Text("Stage \(stageNumber)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitle)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    starStrip
                }

                Spacer(minLength: 8)

                Image(systemName: unlocked ? "chevron.right.circle.fill" : "lock.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(unlocked ? Color.appPrimary : Color.appTextSecondary.opacity(0.45))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            if !unlocked {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.appBackground.opacity(0.65))
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                    Text("Locked")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Color.appTextPrimary)
            }
        }
        .frame(minHeight: 112)
        .entertainmentCardChrome(cornerRadius: 22, elevated: unlocked)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color.appPrimary.opacity(unlocked ? 0.95 : 0.28),
                            Color.appAccent.opacity(unlocked ? 0.8 : 0.22),
                            Color.appPrimary.opacity(unlocked ? 0.55 : 0.18)
                        ],
                        center: .center
                    ),
                    lineWidth: unlocked ? 2.5 : 1
                )
        }
    }

    private var subtitle: String {
        switch difficulty {
        case .easy: return "Relaxed pacing · \(activityShortLabel)"
        case .normal: return "Balanced challenge · \(activityShortLabel)"
        case .hard: return "Sharper goals · \(activityShortLabel)"
        }
    }

    private var activityShortLabel: String {
        switch activity {
        case .colorSymphony: return "Color grid"
        case .melodyMaker: return "Staff line"
        case .adventureSketch: return "Scene build"
        }
    }

    private var stageBadge: some View {
        ZStack {
            Circle()
                .stroke(Color.appTextSecondary.opacity(0.22), lineWidth: 5)
                .frame(width: 62, height: 62)

            Circle()
                .trim(from: 0, to: CGFloat(stars) / 3)
                .stroke(
                    Color.appPrimary,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 62, height: 62)

            Text("\(stageNumber)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            MiniSparkleCanvas(active: stars >= 3)
                .frame(width: 72, height: 72)
                .allowsHitTesting(false)
                .opacity(stars >= 3 ? 1 : 0)
        }
        .frame(width: 72, height: 72)
    }

    private var starStrip: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(index < stars ? Color.appPrimary : Color.appTextSecondary.opacity(0.35))
                    .shadow(color: index < stars ? Color.appAccent.opacity(0.55) : .clear, radius: 4, y: 0)
            }
            if stars == 0 && unlocked {
                Text("Not cleared yet")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.8))
            }
        }
    }
}

/// Tiny SwiftUI Canvas sparkles when stage is perfected.
private struct MiniSparkleCanvas: View {
    let active: Bool

    var body: some View {
        Canvas { context, size in
            guard active else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for index in 0..<6 {
                let angle = Double(index) / 6 * Double.pi * 2
                let r: CGFloat = 26 + CGFloat(index % 2) * 4
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * r,
                    y: center.y + CGFloat(sin(angle)) * r
                )
                var path = Path()
                path.addEllipse(in: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
                context.fill(path, with: .color(Color.appAccent.opacity(0.45 + Double(index) * 0.08)))
            }
        }
    }
}
