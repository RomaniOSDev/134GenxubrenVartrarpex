//
//  GamificationModels.swift
//  134GenxubrenVartrarpex
//

import Foundation

// MARK: - XP & rank (no currency metaphors — experience only)

enum PlayerProgression {
    /// XP cost to move from `level` → `level + 1`.
    static func xpToAdvance(fromLevel level: Int) -> Int {
        let safe = max(1, level)
        return 85 + (safe - 1) * 38
    }

    static func level(forTotalXP total: Int) -> Int {
        var remaining = max(0, total)
        var level = 1
        while remaining >= xpToAdvance(fromLevel: level) {
            remaining -= xpToAdvance(fromLevel: level)
            level += 1
            if level > 500 { break }
        }
        return level
    }

    /// XP accumulated inside the current level (toward next).
    static func xpIntoCurrentLevel(totalXP: Int) -> (into: Int, forNext: Int) {
        let lvl = level(forTotalXP: totalXP)
        var used = 0
        for L in 1..<lvl {
            used += xpToAdvance(fromLevel: L)
        }
        let into = max(0, totalXP - used)
        let need = xpToAdvance(fromLevel: lvl)
        return (into, need)
    }

    static func rankPresentation(forLevel level: Int) -> (title: String, subtitle: String) {
        switch level {
        case ..<2:
            return ("Curious Visitor", "You are just opening the studio doors.")
        case 2..<4:
            return ("Playful Apprentice", "Rhythm and color are starting to stick.")
        case 4..<7:
            return ("Studio Regular", "You return with intent and sharper focus.")
        case 7..<11:
            return ("Creative Specialist", "Hard tiers notice your persistence.")
        case 11..<16:
            return ("Virtuoso in Residence", "Few stages can hide a challenge from you.")
        default:
            return ("Legend of the Hall", "The full catalog bends to your practice.")
        }
    }
}

// MARK: - Reward badges (separate from “highlights” achievements)

struct RewardBadgeDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
}

enum RewardCatalog {
    static let allBadges: [RewardBadgeDefinition] = [
        RewardBadgeDefinition(
            id: "reward_first_xp",
            title: "First Spark",
            detail: "Earn your first experience from a cleared stage.",
            symbolName: "bolt.fill"
        ),
        RewardBadgeDefinition(
            id: "reward_level_3",
            title: "Rising Talent",
            detail: "Reach studio rank level 3.",
            symbolName: "arrow.up.circle.fill"
        ),
        RewardBadgeDefinition(
            id: "reward_level_8",
            title: "Deep Focus",
            detail: "Reach studio rank level 8.",
            symbolName: "scope"
        ),
        RewardBadgeDefinition(
            id: "reward_streak_3",
            title: "Three-Day Flow",
            detail: "Play on three different calendar days in a row.",
            symbolName: "flame.fill"
        ),
        RewardBadgeDefinition(
            id: "reward_streak_7",
            title: "Week of Wonder",
            detail: "Keep a seven-day activity streak alive.",
            symbolName: "flame.circle.fill"
        ),
        RewardBadgeDefinition(
            id: "reward_stars_30",
            title: "Star Gatherer",
            detail: "Collect thirty stars across all stages.",
            symbolName: "star.circle.fill"
        ),
        RewardBadgeDefinition(
            id: "reward_stars_90",
            title: "Bright Constellation",
            detail: "Collect ninety stars across all stages.",
            symbolName: "sparkles"
        ),
        RewardBadgeDefinition(
            id: "reward_sessions_10",
            title: "Ten-Session Spark",
            detail: "Finish ten successful sessions.",
            symbolName: "figure.run"
        ),
        RewardBadgeDefinition(
            id: "reward_sessions_40",
            title: "Marathon Mind",
            detail: "Finish forty successful sessions.",
            symbolName: "figure.strengthtraining.traditional"
        ),
        RewardBadgeDefinition(
            id: "reward_hard_stages_12",
            title: "Edge Walker",
            detail: "Earn at least one star on twelve different Hard stages.",
            symbolName: "mountain.2.fill"
        )
    ]
}
