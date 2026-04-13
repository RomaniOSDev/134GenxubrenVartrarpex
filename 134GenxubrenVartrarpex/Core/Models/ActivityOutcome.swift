//
//  ActivityOutcome.swift
//  134GenxubrenVartrarpex
//

import Foundation

struct ActivityOutcome: Hashable {
    let stars: Int
    let duration: TimeInterval
    let accuracyPercent: Double
    let address: LevelAddress
    let newAchievementIds: [String]
    /// Experience earned this session (gamification).
    let experienceGained: Int
    let newRewardIds: [String]
}
