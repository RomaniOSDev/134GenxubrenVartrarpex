//
//  AdventureSketchViewModel.swift
//  134GenxubrenVartrarpex
//

import Combine
import Foundation
import SwiftUI

struct SketchPieceModel: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var rotation: Angle
    var scale: CGFloat
    let shapeKind: Int
    let templatePosition: CGPoint
}

@MainActor
final class AdventureSketchViewModel: ObservableObject {
    @Published var pieces: [SketchPieceModel]
    @Published private(set) var secondsRemaining: Double
    @Published private(set) var isComplete: Bool = false

    private var latchedHardSuccess: Bool = false
    private var latchedHardSeconds: Double?

    let address: LevelAddress
    let normalizedZone: CGRect
    let usesTimer: Bool
    let snapRadius: CGFloat

    private let startedAt: Date
    private var timerCancellable: AnyCancellable?

    init(address: LevelAddress) {
        self.address = address
        self.startedAt = Date()
        let setup = AdventureSketchViewModel.setup(for: address)
        pieces = setup.pieces
        normalizedZone = setup.zone
        usesTimer = setup.timer > 0
        secondsRemaining = setup.timer
        snapRadius = setup.snap

        if usesTimer {
            timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tickTimer()
                }
        }
    }

    private static func setup(for address: LevelAddress) -> (pieces: [SketchPieceModel], zone: CGRect, timer: Double, snap: CGFloat) {
        let zone = CGRect(x: 0.18, y: 0.35, width: 0.64, height: 0.45)
        let templates: [CGPoint] = [
            CGPoint(x: 0.28, y: 0.48),
            CGPoint(x: 0.52, y: 0.55),
            CGPoint(x: 0.72, y: 0.44)
        ]
        var items: [SketchPieceModel] = []
        for index in 0..<3 {
            let start = CGPoint(
                x: 0.2 + CGFloat(index) * 0.22,
                y: 0.18 + CGFloat(index % 2) * 0.06
            )
            let template = templates[min(index, templates.count - 1)]
            items.append(
                SketchPieceModel(
                    id: UUID(),
                    position: start,
                    rotation: .degrees(Double(index) * 14),
                    scale: 1,
                    shapeKind: index % 3,
                    templatePosition: template
                )
            )
        }
        let timer: Double
        let snap: CGFloat
        switch address.difficulty {
        case .easy:
            timer = 0
            snap = max(0.055, 0.095 - CGFloat(address.levelIndex) * 0.005)
        case .normal:
            timer = 0
            snap = max(0.085, 0.13 - CGFloat(address.levelIndex) * 0.006)
        case .hard:
            let span = LevelProgression.stagesPerDifficulty - 1
            timer = 55 + Double(span - address.levelIndex) * 5
            snap = max(0.07, 0.12 - CGFloat(address.levelIndex) * 0.004)
        }
        return (items, zone, timer, max(0.06, snap))
    }

    private func tickTimer() {
        guard usesTimer, !isComplete else { return }
        secondsRemaining = max(0, secondsRemaining - 0.2)
        if secondsRemaining <= 0 {
            timerCancellable?.cancel()
        }
    }

    func updatePiece(id: UUID, position: CGPoint, rotation: Angle?, scale: CGFloat?) {
        guard let idx = pieces.firstIndex(where: { $0.id == id }) else { return }
        pieces[idx].position = position
        if let rotation {
            pieces[idx].rotation = rotation
        }
        if let scale {
            pieces[idx].scale = max(0.55, min(1.45, scale))
        }
        recomputeCompletion()
    }

    func snapIfNeeded(for id: UUID) {
        guard address.difficulty == .easy else { return }
        guard let idx = pieces.firstIndex(where: { $0.id == id }) else { return }
        let template = pieces[idx].templatePosition
        var pos = pieces[idx].position
        let distance = hypot(pos.x - template.x, pos.y - template.y)
        if distance < snapRadius {
            pos = template
            pieces[idx].position = pos
            pieces[idx].rotation = .zero
        }
        recomputeCompletion()
    }

    private func recomputeCompletion() {
        switch address.difficulty {
        case .easy:
            let ok = pieces.allSatisfy { piece in
                hypot(piece.position.x - piece.templatePosition.x, piece.position.y - piece.templatePosition.y) < snapRadius * 0.95
            }
            isComplete = ok
        case .normal:
            let inset = normalizedZone.insetBy(dx: 0.04, dy: 0.05)
            let ok = pieces.allSatisfy { piece in
                inset.contains(piece.position)
            }
            isComplete = ok
        case .hard:
            let inset = normalizedZone.insetBy(dx: 0.04, dy: 0.05)
            let ok = pieces.allSatisfy { piece in
                inset.contains(piece.position)
            }
            if ok && secondsRemaining > 0 {
                latchedHardSuccess = true
                latchedHardSeconds = secondsRemaining
            }
            isComplete = latchedHardSuccess
        }
    }

    func evaluateOutcome() -> (stars: Int, duration: TimeInterval, accuracy: Double) {
        let duration = Date().timeIntervalSince(startedAt)
        guard isComplete else {
            return (0, duration, 0)
        }
        var accuracy: Double = 100
        switch address.difficulty {
        case .easy:
            let errors = pieces.map { piece in
                hypot(Double(piece.position.x - piece.templatePosition.x), Double(piece.position.y - piece.templatePosition.y))
            }
            let avg = errors.reduce(0, +) / Double(max(errors.count, 1))
            accuracy = max(0, 100 - avg * 120)
        case .normal:
            accuracy = 92
        case .hard:
            let snapshot = latchedHardSeconds ?? secondsRemaining
            let span = LevelProgression.stagesPerDifficulty - 1
            let totalBudget = max(1, 55 + Double(span - address.levelIndex) * 5)
            let timeRatio = snapshot / totalBudget
            accuracy = min(100, 70 + timeRatio * 30)
        }
        let stars: Int
        switch address.difficulty {
        case .easy:
            stars = duration < 35 ? 3 : (duration < 55 ? 2 : 1)
        case .normal:
            stars = duration < 50 ? 3 : (duration < 75 ? 2 : 1)
        case .hard:
            let snapshot = latchedHardSeconds ?? secondsRemaining
            stars = snapshot > 25 ? 3 : (snapshot > 10 ? 2 : 1)
        }
        return (stars, duration, min(100, accuracy))
    }
}
