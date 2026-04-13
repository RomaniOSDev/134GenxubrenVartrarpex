//
//  ColorSymphonyViewModel.swift
//  134GenxubrenVartrarpex
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ColorSymphonyViewModel: ObservableObject {
    @Published private(set) var gridSide: Int
    @Published private(set) var palette: [Color]
    @Published private(set) var targetFlat: [Int]
    @Published private(set) var currentFlat: [Int]
    @Published private(set) var moveCount: Int = 0
    @Published private(set) var isComplete: Bool = false

    let address: LevelAddress
    private let startedAt: Date
    private let idealMoves: Int
    private let parTime: TimeInterval

    private let colorTokens: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink
    ]

    init(address: LevelAddress) {
        self.address = address
        self.startedAt = Date()

        let spec = ColorSymphonyViewModel.spec(for: address)
        let side = spec.side
        gridSide = side
        idealMoves = spec.idealMoves
        parTime = spec.parTime

        let count = spec.colorCount
        let base = Array(colorTokens.prefix(count))
        palette = base

        let cells = side * side
        var target = ColorSymphonyViewModel.makePattern(side: side, colorCount: count)
        if target.count != cells {
            target = Array(repeating: 0, count: cells)
        }
        targetFlat = target

        var shuffled = target
        repeat {
            shuffled.shuffle()
        } while shuffled == target && cells > 1
        currentFlat = shuffled
    }

    private static func spec(for address: LevelAddress) -> (side: Int, colorCount: Int, idealMoves: Int, parTime: TimeInterval) {
        let tier = address.difficulty
        let level = address.levelIndex
        switch tier {
        case .easy:
            let side = 2 + min(level / 2, 1)
            let colors = max(2, min(6, 2 + min(level, 3)))
            let moves = 4 + level * 3
            let par = max(22, 50 - Double(level) * 4)
            return (side, colors, moves, par)
        case .normal:
            let side = 3 + min(level / 3, 1)
            let colors = max(3, min(6, 3 + min(level, 2)))
            let moves = 10 + level * 5
            let par = max(32, 78 - Double(level) * 5)
            return (side, colors, moves, par)
        case .hard:
            let side = 4
            let colors = max(4, min(7, 4 + min(level / 2, 2)))
            let moves = 22 + level * 4
            let par = max(38, 98 - Double(level) * 6)
            return (side, colors, moves, par)
        }
    }

    private static func makePattern(side: Int, colorCount: Int) -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(side * side)
        for row in 0..<side {
            for col in 0..<side {
                let value = (row + col * 2) % colorCount
                result.append(value)
            }
        }
        return result
    }

    func color(at index: Int) -> Color {
        let token = currentFlat[index]
        guard token >= 0 && token < palette.count else { return .gray }
        return palette[token]
    }

    func targetColor(at index: Int) -> Color {
        let token = targetFlat[index]
        guard token >= 0 && token < palette.count else { return .gray }
        return palette[token]
    }

    func swap(from: Int, to: Int) {
        guard !isComplete, from != to,
              from >= 0, to >= 0,
              from < currentFlat.count, to < currentFlat.count else { return }
        currentFlat.swapAt(from, to)
        moveCount += 1
        if currentFlat == targetFlat {
            isComplete = true
        }
    }

    func evaluateOutcome() -> (stars: Int, duration: TimeInterval, accuracy: Double) {
        let duration = Date().timeIntervalSince(startedAt)
        guard isComplete else {
            return (0, duration, 0)
        }
        let moveScore = max(0, 1 - Double(max(0, moveCount - idealMoves)) / Double(idealMoves + 4))
        let timeScore = max(0, 1 - max(0, duration - parTime) / (parTime + 10))
        let accuracy = (moveScore * 0.55 + timeScore * 0.45) * 100
        let stars: Int
        if moveCount <= idealMoves && duration <= parTime {
            stars = 3
        } else if moveCount <= idealMoves + 4 || duration <= parTime + 12 {
            stars = 2
        } else {
            stars = 1
        }
        return (stars, duration, min(100, accuracy))
    }
}
