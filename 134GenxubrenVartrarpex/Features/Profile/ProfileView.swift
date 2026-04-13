//
//  ProfileView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Journey insights")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.appTextPrimary)

                Text("Track your rank, streak, reward badges, and classic highlights in one place.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    SettingsView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "gearshape.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.appAccent.opacity(0.15)))
                        Text("Settings")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                    }
                    .padding(16)
                    .entertainmentCardChrome(cornerRadius: 18, elevated: false)
                }
                .buttonStyle(.plain)

                gamificationCard

                VStack(spacing: 14) {
                    statCard(title: "Total active time", value: formattedTime(store.totalPlaySeconds))
                    statCard(title: "Finished sessions", value: "\(store.totalActivitiesPlayed)")
                    statCard(title: "Stars collected", value: "\(store.totalStarsCollected())")
                    statCard(title: "Total experience", value: "\(store.totalExperiencePoints) XP")
                }

                rewardBadgesSection

                VStack(alignment: .leading, spacing: 12) {
                    Text("Highlights cabinet")
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    if store.unlockedAchievementIds.isEmpty {
                        Text("Complete activities to reveal your first highlight.")
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(AppDataStore.allAchievements) { achievement in
                        achievementRow(achievement, unlocked: store.unlockedAchievementIds.contains(achievement.id))
                    }
                }

                Button {
                    showResetConfirm = true
                } label: {
                    Text("Reset All Progress")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(EntertainmentSecondaryButtonStyle())
                .confirmationDialog(
                    "Reset all progress?",
                    isPresented: $showResetConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Reset everything", role: .destructive) {
                        store.resetAllProgress()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Clears stars, stages, experience, streaks, reward badges, and highlights on this device.")
                }
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 20)
        }
        .entertainmentSceneBackground()
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    private var gamificationCard: some View {
        let xp = store.xpTowardNextLevel
        let ratio = xp.forNext > 0 ? Double(xp.current) / Double(xp.forNext) : 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Studio rank")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(store.playerRankTitle)
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(store.playerRankSubtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                ZStack {
                    Text("\(store.playerLevel)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.appBackground)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                                        center: .center
                                    )
                                )
                        )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Next rank progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Text("\(xp.current) / \(xp.forNext) XP")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
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
                            .frame(width: max(6, geo.size.width * ratio))
                    }
                }
                .frame(height: 8)
            }

            HStack(spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day streak")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.appTextSecondary)
                        Text(store.consecutiveDayStreak > 0 ? "\(store.consecutiveDayStreak) days in a row" : "Play on consecutive days")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.appAccent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .entertainmentInsetWell(cornerRadius: 14)
            }
        }
        .padding(20)
        .entertainmentCardChrome(cornerRadius: 22, elevated: true)
    }

    private var rewardBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reward badges")
                    .font(.title3.bold())
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text("\(store.unlockedRewardIds.count)/\(RewardCatalog.allBadges.count)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.appAccent)
            }

            Text("Earn these through experience, streaks, stars, sessions, and Hard-tier milestones.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(RewardCatalog.allBadges) { badge in
                    rewardBadgeTile(
                        badge,
                        unlocked: store.unlockedRewardIds.contains(badge.id)
                    )
                }
            }
        }
    }

    private func rewardBadgeTile(_ badge: RewardBadgeDefinition, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: badge.symbolName)
                .font(.title2)
                .foregroundStyle(unlocked ? Color.appPrimary : Color.appTextSecondary.opacity(0.35))
                .frame(height: 28)
            Text(badge.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(badge.detail)
                .font(.caption2)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(unlocked ? 1 : 0.88)
        .entertainmentCardChrome(cornerRadius: 16, elevated: unlocked)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    Color.appAccent.opacity(unlocked ? 0.45 : 0.14),
                    lineWidth: unlocked ? 1.5 : 1
                )
        )
    }

    private func statCard(title: String, value: String) -> some View {
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
        .padding(16)
        .entertainmentCardChrome(cornerRadius: 16, elevated: false)
    }

    private func achievementRow(_ achievement: AchievementDefinition, unlocked: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: unlocked ? "seal.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(unlocked ? Color.appPrimary : Color.appTextSecondary.opacity(0.45))
                .frame(width: 32, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text(achievement.detail)
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .entertainmentCardChrome(cornerRadius: 16, elevated: unlocked)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appAccent.opacity(unlocked ? 0.5 : 0.18), lineWidth: 1)
        )
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let seconds = Int(max(0, interval))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}
