//
//  ActivityModels.swift
//  134GenxubrenVartrarpex
//

import Foundation

/// How many stages exist for each difficulty within one activity (0-based indices: `0 ..< stagesPerDifficulty`).
enum LevelProgression {
    static let stagesPerDifficulty: Int = 6
}

enum ActivityKind: String, CaseIterable, Codable, Hashable {
    case colorSymphony
    case melodyMaker
    case adventureSketch

    var displayTitle: String {
        switch self {
        case .colorSymphony: return "The Color Symphony"
        case .melodyMaker: return "Melody Maker"
        case .adventureSketch: return "Adventure Sketch"
        }
    }

    var detailDescription: String {
        switch self {
        case .colorSymphony:
            return "Rearrange tiles to match the target pattern. Fewer moves and faster time earn more stars."
        case .melodyMaker:
            return "Place notes on the staff, then play your line. Match the target pitches to succeed."
        case .adventureSketch:
            return "Position, rotate, and scale scene pieces. Guided layouts on easier tiers; timed challenges on the hardest."
        }
    }
}

enum DifficultyTier: String, CaseIterable, Codable, Hashable {
    case easy
    case normal
    case hard

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

struct LevelAddress: Hashable, Codable {
    let activity: ActivityKind
    let difficulty: DifficultyTier
    let levelIndex: Int

    var storageKey: String {
        "\(activity.rawValue)_\(difficulty.rawValue)_\(levelIndex)"
    }
}

enum AppTab: Int, Hashable {
    case home
    case activities
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .activities: return "Activities"
        case .profile: return "Profile"
        }
    }
}

extension Notification.Name {
    static let progressDataDidReset = Notification.Name("progressDataDidReset")
}
