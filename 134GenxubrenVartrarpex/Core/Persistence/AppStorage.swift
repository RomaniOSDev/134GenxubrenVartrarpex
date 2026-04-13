//
//  AppStorage.swift
//  134GenxubrenVartrarpex
//

import Combine
import Foundation
import SwiftUI

struct AchievementDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

@MainActor
final class AppDataStore: ObservableObject {
    private let defaults: UserDefaults

    private let keyOnboarding = "hasSeenOnboarding"
    private let keyStarsPrefix = "levelStars_"
    private let keyTotalPlaySeconds = "totalPlaySeconds"
    private let keyTotalActivitiesPlayed = "totalActivitiesPlayed"
    private let keyUnlockedAchievementIds = "unlockedAchievementIds"
    private let keyTotalExperience = "totalExperiencePoints"
    private let keyConsecutiveStreak = "consecutiveDayStreak"
    private let keyLastSessionDayStart = "lastSessionDayStart"
    private let keyUnlockedRewardIds = "unlockedRewardIds"

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var totalPlaySeconds: TimeInterval
    @Published private(set) var totalActivitiesPlayed: Int
    @Published private(set) var unlockedAchievementIds: Set<String>
    @Published private(set) var totalExperiencePoints: Int
    @Published private(set) var consecutiveDayStreak: Int
    @Published private(set) var unlockedRewardIds: Set<String>

    /// Start-of-day timestamp for the last successful session (calendar streak).
    private var lastSessionDayStart: Date?

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        hasSeenOnboarding = userDefaults.bool(forKey: keyOnboarding)
        totalPlaySeconds = userDefaults.double(forKey: keyTotalPlaySeconds)
        totalActivitiesPlayed = Int(userDefaults.integer(forKey: keyTotalActivitiesPlayed))
        totalExperiencePoints = max(0, userDefaults.integer(forKey: keyTotalExperience))
        consecutiveDayStreak = max(0, userDefaults.integer(forKey: keyConsecutiveStreak))
        if let stored = userDefaults.array(forKey: keyUnlockedAchievementIds) as? [String] {
            unlockedAchievementIds = Set(stored)
        } else {
            unlockedAchievementIds = []
        }
        if let stored = userDefaults.array(forKey: keyUnlockedRewardIds) as? [String] {
            unlockedRewardIds = Set(stored)
        } else {
            unlockedRewardIds = []
        }
        let lastTs = userDefaults.double(forKey: keyLastSessionDayStart)
        if lastTs > 0 {
            lastSessionDayStart = Date(timeIntervalSince1970: lastTs)
        } else {
            lastSessionDayStart = nil
        }
        reconcileStreakWithCalendar()
        refreshRewardBadgeUnlocks()
    }

    static let allAchievements: [AchievementDefinition] = [
        AchievementDefinition(id: "first_star", title: "Bright Start", detail: "Earn your first star in any activity."),
        AchievementDefinition(id: "five_sessions", title: "Curious Mind", detail: "Complete five activity sessions."),
        AchievementDefinition(id: "fifteen_stars", title: "Constellation", detail: "Collect fifteen stars in total."),
        AchievementDefinition(id: "hard_perfect", title: "Peak Performance", detail: "Earn three stars on any Hard level."),
        AchievementDefinition(id: "speed_star", title: "Swift Finish", detail: "Finish any level in under twenty seconds with three stars.")
    ]

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: keyOnboarding)
        objectWillChange.send()
    }

    func stars(for address: LevelAddress) -> Int {
        let key = keyStarsPrefix + address.storageKey
        return max(0, min(3, defaults.integer(forKey: key)))
    }

    func totalStarsCollected() -> Int {
        var sum = 0
        for activity in ActivityKind.allCases {
            for difficulty in DifficultyTier.allCases {
                for index in 0..<LevelProgression.stagesPerDifficulty {
                    sum += stars(for: LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index))
                }
            }
        }
        return sum
    }

    func isLevelUnlocked(_ address: LevelAddress) -> Bool {
        switch address.difficulty {
        case .easy:
            if address.levelIndex == 0 { return true }
            let prev = LevelAddress(activity: address.activity, difficulty: .easy, levelIndex: address.levelIndex - 1)
            return stars(for: prev) >= 1
        case .normal:
            if address.levelIndex == 0 {
                return (0..<LevelProgression.stagesPerDifficulty).allSatisfy { idx in
                    stars(for: LevelAddress(activity: address.activity, difficulty: .easy, levelIndex: idx)) >= 1
                }
            }
            let prev = LevelAddress(activity: address.activity, difficulty: .normal, levelIndex: address.levelIndex - 1)
            return stars(for: prev) >= 1
        case .hard:
            if address.levelIndex == 0 {
                return (0..<LevelProgression.stagesPerDifficulty).allSatisfy { idx in
                    stars(for: LevelAddress(activity: address.activity, difficulty: .normal, levelIndex: idx)) >= 1
                }
            }
            let prev = LevelAddress(activity: address.activity, difficulty: .hard, levelIndex: address.levelIndex - 1)
            return stars(for: prev) >= 1
        }
    }

    func nextLevel(after address: LevelAddress) -> LevelAddress? {
        let lastStage = LevelProgression.stagesPerDifficulty - 1
        if address.levelIndex < lastStage {
            return LevelAddress(activity: address.activity, difficulty: address.difficulty, levelIndex: address.levelIndex + 1)
        }
        switch address.difficulty {
        case .easy:
            return LevelAddress(activity: address.activity, difficulty: .normal, levelIndex: 0)
        case .normal:
            return LevelAddress(activity: address.activity, difficulty: .hard, levelIndex: 0)
        case .hard:
            if address.activity == .adventureSketch { return nil }
            let all = ActivityKind.allCases
            if let i = all.firstIndex(of: address.activity), i + 1 < all.count {
                return LevelAddress(activity: all[i + 1], difficulty: .easy, levelIndex: 0)
            }
            return nil
        }
    }

    func recordSessionCompletion(
        address: LevelAddress,
        starsEarned: Int,
        duration: TimeInterval,
        accuracyPercent: Double
    ) {
        totalPlaySeconds += max(0, duration)
        defaults.set(totalPlaySeconds, forKey: keyTotalPlaySeconds)

        guard starsEarned >= 1 else {
            objectWillChange.send()
            return
        }

        let clampedStars = min(3, starsEarned)
        let key = keyStarsPrefix + address.storageKey
        let existing = defaults.integer(forKey: key)
        if clampedStars > existing {
            defaults.set(clampedStars, forKey: key)
        }

        totalActivitiesPlayed += 1
        defaults.set(totalActivitiesPlayed, forKey: keyTotalActivitiesPlayed)

        updateStreakForSuccessfulSession()
        let xpGain = experienceAward(for: address, starsEarned: clampedStars)
        totalExperiencePoints += xpGain
        defaults.set(totalExperiencePoints, forKey: keyTotalExperience)

        refreshDerivedAchievements(duration: duration, starsEarned: clampedStars, accuracyPercent: accuracyPercent, address: address)
        refreshRewardBadgeUnlocks()
        objectWillChange.send()
    }

    private func refreshDerivedAchievements(
        duration: TimeInterval,
        starsEarned: Int,
        accuracyPercent: Double,
        address: LevelAddress
    ) {
        var updated = unlockedAchievementIds
        if starsEarned >= 1 {
            updated.insert("first_star")
        }
        if totalActivitiesPlayed >= 5 {
            updated.insert("five_sessions")
        }
        if totalStarsCollected() >= 15 {
            updated.insert("fifteen_stars")
        }
        if address.difficulty == .hard && starsEarned >= 3 {
            updated.insert("hard_perfect")
        }
        if starsEarned >= 3 && duration > 0 && duration < 20 {
            updated.insert("speed_star")
        }
        unlockedAchievementIds = updated
        defaults.set(Array(updated), forKey: keyUnlockedAchievementIds)
    }

    func newlyUnlockedAchievements(comparedTo previous: Set<String>) -> [AchievementDefinition] {
        AppDataStore.allAchievements.filter { unlockedAchievementIds.contains($0.id) && !previous.contains($0.id) }
    }

    func newlyUnlockedRewards(comparedTo previous: Set<String>) -> [RewardBadgeDefinition] {
        RewardCatalog.allBadges.filter { unlockedRewardIds.contains($0.id) && !previous.contains($0.id) }
    }

    var playerLevel: Int {
        PlayerProgression.level(forTotalXP: totalExperiencePoints)
    }

    var playerRankTitle: String {
        PlayerProgression.rankPresentation(forLevel: playerLevel).title
    }

    var playerRankSubtitle: String {
        PlayerProgression.rankPresentation(forLevel: playerLevel).subtitle
    }

    var xpTowardNextLevel: (current: Int, forNext: Int) {
        let slice = PlayerProgression.xpIntoCurrentLevel(totalXP: totalExperiencePoints)
        return (current: slice.into, forNext: slice.forNext)
    }

    func resetAllProgress() {
        hasSeenOnboarding = false
        defaults.removeObject(forKey: keyOnboarding)

        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys where key.hasPrefix(keyStarsPrefix) {
            defaults.removeObject(forKey: key)
        }

        totalPlaySeconds = 0
        totalActivitiesPlayed = 0
        unlockedAchievementIds = []
        totalExperiencePoints = 0
        consecutiveDayStreak = 0
        unlockedRewardIds = []
        lastSessionDayStart = nil

        defaults.set(0.0, forKey: keyTotalPlaySeconds)
        defaults.set(0, forKey: keyTotalActivitiesPlayed)
        defaults.removeObject(forKey: keyUnlockedAchievementIds)
        defaults.set(0, forKey: keyTotalExperience)
        defaults.set(0, forKey: keyConsecutiveStreak)
        defaults.removeObject(forKey: keyLastSessionDayStart)
        defaults.removeObject(forKey: keyUnlockedRewardIds)

        objectWillChange.send()
        NotificationCenter.default.post(name: .progressDataDidReset, object: nil)
    }

    // MARK: - Streak & rewards (private)

    private static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// If the player skipped more than one calendar day since last session, streak breaks.
    private func reconcileStreakWithCalendar() {
        guard let last = lastSessionDayStart else { return }
        let today = Self.startOfDay(Date())
        let gap = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
        if gap > 1 {
            consecutiveDayStreak = 0
            defaults.set(0, forKey: keyConsecutiveStreak)
        }
    }

    private func updateStreakForSuccessfulSession() {
        let today = Self.startOfDay(Date())
        if let last = lastSessionDayStart {
            let gap = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
            if gap == 0 {
                // Same calendar day — streak count unchanged
            } else if gap == 1 {
                consecutiveDayStreak += 1
            } else {
                consecutiveDayStreak = 1
            }
        } else {
            consecutiveDayStreak = 1
        }
        lastSessionDayStart = today
        defaults.set(today.timeIntervalSince1970, forKey: keyLastSessionDayStart)
        defaults.set(consecutiveDayStreak, forKey: keyConsecutiveStreak)
    }

    private func countHardStagesWithAtLeastOneStar() -> Int {
        var count = 0
        for activity in ActivityKind.allCases {
            for index in 0..<LevelProgression.stagesPerDifficulty {
                let address = LevelAddress(activity: activity, difficulty: .hard, levelIndex: index)
                if stars(for: address) >= 1 {
                    count += 1
                }
            }
        }
        return count
    }

    /// Recomputes reward badge set from current stats (idempotent).
    private func refreshRewardBadgeUnlocks() {
        var next = unlockedRewardIds
        if totalExperiencePoints > 0 {
            next.insert("reward_first_xp")
        }
        let level = PlayerProgression.level(forTotalXP: totalExperiencePoints)
        if level >= 3 { next.insert("reward_level_3") }
        if level >= 8 { next.insert("reward_level_8") }
        if consecutiveDayStreak >= 3 { next.insert("reward_streak_3") }
        if consecutiveDayStreak >= 7 { next.insert("reward_streak_7") }
        if totalStarsCollected() >= 30 { next.insert("reward_stars_30") }
        if totalStarsCollected() >= 90 { next.insert("reward_stars_90") }
        if totalActivitiesPlayed >= 10 { next.insert("reward_sessions_10") }
        if totalActivitiesPlayed >= 40 { next.insert("reward_sessions_40") }
        if countHardStagesWithAtLeastOneStar() >= 12 { next.insert("reward_hard_stages_12") }
        unlockedRewardIds = next
        defaults.set(Array(next), forKey: keyUnlockedRewardIds)
    }

    private func experienceAward(for address: LevelAddress, starsEarned: Int) -> Int {
        let tier: Int
        switch address.difficulty {
        case .easy: tier = 0
        case .normal: tier = 10
        case .hard: tier = 22
        }
        let streakBonus = min(consecutiveDayStreak, 12)
        return 14 + starsEarned * 9 + tier + streakBonus
    }
}
