//
//  ActivityResultView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct ActivityResultView: View {
    @Binding var path: NavigationPath
    let outcome: ActivityOutcome

    @EnvironmentObject private var store: AppDataStore
    @State private var revealedStars = 0
    @State private var bannerOffset: CGFloat = -240
    @State private var rewardBannerOffset: CGFloat = -280

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 22) {
                    Text("Session Complete")
                        .font(.title.bold())
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Here is how this run shaped up. Keep refining your approach to climb the tiers.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 18) {
                        HStack(spacing: 18) {
                            ForEach(0..<3, id: \.self) { index in
                                let active = index < min(revealedStars, outcome.stars)
                                ZStack {
                                    if active {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 44))
                                            .foregroundStyle(Color.appPrimary)
                                            .shadow(color: Color.appAccent.opacity(0.85), radius: 16, y: 0)
                                            .shadow(color: Color.appPrimary.opacity(0.55), radius: 8, y: 4)
                                            .transition(.scale.combined(with: .opacity))
                                    } else {
                                        Image(systemName: "star")
                                            .font(.system(size: 44))
                                            .foregroundStyle(Color.appTextSecondary.opacity(0.35))
                                    }
                                }
                                .frame(width: 56, height: 56)
                                .animation(.spring(response: 0.45, dampingFraction: 0.62), value: revealedStars)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            statRow(title: "Elapsed time", value: formatDuration(outcome.duration))
                            statRow(title: "Focus score", value: String(format: "%.0f%%", outcome.accuracyPercent))
                            statRow(title: "Stars secured", value: "\(outcome.stars) / 3")
                            statRow(
                                title: "Experience gained",
                                value: outcome.experienceGained > 0 ? "+\(outcome.experienceGained) XP" : "—"
                            )
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .entertainmentCardChrome(cornerRadius: 20, elevated: true)
                    }

                    VStack(spacing: 12) {
                        if let next = store.nextLevel(after: outcome.address), outcome.stars >= 1 {
                            Button {
                                popSessionLayers()
                                path.append(ActivityFlowRoute.session(next))
                            } label: {
                                Text("Next Stage")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .buttonStyle(EntertainmentPrimaryButtonStyle())
                        }

                        Button {
                            popSessionLayers()
                            path.append(ActivityFlowRoute.session(outcome.address))
                        } label: {
                            Text("Retry")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())

                        Button {
                            popSessionLayers()
                        } label: {
                            Text("Back to Stages")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())
                    }
                }
                .entertainmentScreenPadding()
                .padding(.vertical, 28)
            }

            VStack(alignment: .leading, spacing: 10) {
                if !outcome.newAchievementIds.isEmpty {
                    achievementBanner
                        .offset(y: bannerOffset)
                        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: bannerOffset)
                }
                if !outcome.newRewardIds.isEmpty {
                    rewardBanner
                        .offset(y: rewardBannerOffset)
                        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: rewardBannerOffset)
                }
            }
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .entertainmentSceneBackground()
        .onAppear {
            animateStars()
            if !outcome.newAchievementIds.isEmpty {
                withAnimation(.easeInOut(duration: 0.35)) {
                    bannerOffset = 0
                }
            }
            if !outcome.newRewardIds.isEmpty {
                withAnimation(.easeInOut(duration: 0.4).delay(0.12)) {
                    rewardBannerOffset = 0
                }
            }
        }
    }

    private var achievementBanner: some View {
        let titles = AppDataStore.allAchievements.filter { outcome.newAchievementIds.contains($0.id) }
        return VStack(alignment: .leading, spacing: 6) {
            Text("New highlight unlocked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appBackground)
            ForEach(titles) { item in
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Color.appBackground)
                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(Color.appBackground.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary,
                            Color.appAccent.opacity(0.88),
                            Color.appPrimary.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appBackground.opacity(0.35),
                                    Color.clear,
                                    Color.appBackground.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.38), radius: 22, y: 10)
                .shadow(color: Color.appAccent.opacity(0.45), radius: 28, y: 6)
        )
        .entertainmentScreenPadding()
    }

    private var rewardBanner: some View {
        let items = RewardCatalog.allBadges.filter { outcome.newRewardIds.contains($0.id) }
        return VStack(alignment: .leading, spacing: 8) {
            Text("New reward badge")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.symbolName)
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 28, alignment: .center)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .entertainmentCardChrome(cornerRadius: 18, elevated: true)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.appAccent.opacity(0.5), lineWidth: 1.5)
        }
        .entertainmentScreenPadding()
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatDuration(_ value: TimeInterval) -> String {
        let clamped = max(0, value)
        if clamped < 60 {
            return String(format: "%.1f s", clamped)
        }
        let minutes = Int(clamped) / 60
        let seconds = Int(clamped) % 60
        return "\(minutes)m \(seconds)s"
    }

    private func animateStars() {
        revealedStars = 0
        for index in 0..<outcome.stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
                    revealedStars = index + 1
                }
            }
        }
    }

    private func popSessionLayers() {
        if path.count >= 2 {
            path.removeLast(2)
        } else if path.count == 1 {
            path.removeLast()
        }
    }
}
