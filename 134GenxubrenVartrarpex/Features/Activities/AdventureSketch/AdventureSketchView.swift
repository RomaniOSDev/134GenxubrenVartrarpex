//
//  AdventureSketchView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct AdventureSketchActivityScreen: View {
    @Binding var path: NavigationPath
    let address: LevelAddress

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel: AdventureSketchViewModel
    @State private var dragOffsets: [UUID: CGSize] = [:]

    init(path: Binding<NavigationPath>, address: LevelAddress) {
        _path = path
        self.address = address
        _viewModel = StateObject(wrappedValue: AdventureSketchViewModel(address: address))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(headerCopy)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.usesTimer {
                    HStack {
                        Label("Time left", systemImage: "timer")
                            .foregroundStyle(Color.appTextSecondary)
                        Spacer()
                        Text(String(format: "%.0f s", viewModel.secondsRemaining))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color.appAccent)
                    }
                    .padding(14)
                    .entertainmentCardChrome(cornerRadius: 16, elevated: false)
                }

                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        Group {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.appSurface.opacity(0.55))

                            let zone = viewModel.normalizedZone
                            Path { path in
                                path.addRect(
                                    CGRect(
                                        x: zone.minX * size.width,
                                        y: zone.minY * size.height,
                                        width: zone.width * size.width,
                                        height: zone.height * size.height
                                    )
                                )
                            }
                            .stroke(Color.appAccent.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                        }
                        .drawingGroup()

                        if address.difficulty == .easy {
                            ForEach(viewModel.pieces) { piece in
                                templateOutline(for: piece, in: size)
                            }
                        }

                        ForEach(viewModel.pieces) { piece in
                            pieceShape(for: piece)
                                .fill(fillColor(for: piece))
                                .frame(width: 54, height: 54)
                                .scaleEffect(piece.scale)
                                .rotationEffect(piece.rotation)
                                .position(position(for: piece, in: size))
                                .shadow(color: Color.black.opacity(0.45), radius: 8, y: 5)
                                .shadow(color: Color.appPrimary.opacity(0.35), radius: 10, y: 3)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffsets[piece.id, default: .zero] = value.translation
                                        }
                                        .onEnded { value in
                                            commitDrag(for: piece, translation: value.translation, in: size)
                                            dragOffsets[piece.id] = nil
                                            if address.difficulty == .easy {
                                                viewModel.snapIfNeeded(for: piece.id)
                                            }
                                        }
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 360)
                .padding(12)
                .entertainmentInsetWell(cornerRadius: 22)

                controls(for: viewModel.pieces)

                Button {
                    finalize()
                } label: {
                    Text("Finish Scene")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(EntertainmentPrimaryButtonStyle())
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 16)
        }
        .entertainmentSceneBackground()
    }

    private var headerCopy: String {
        switch address.difficulty {
        case .easy:
            return "Drag each shape onto the faint guides. They snap in place when you are close enough."
        case .normal:
            return "Arrange every element inside the dashed zone to frame your story."
        case .hard:
            return "Work quickly—keep everything inside the zone before the countdown ends."
        }
    }

    private func position(for piece: SketchPieceModel, in size: CGSize) -> CGPoint {
        let drag = dragOffsets[piece.id] ?? .zero
        return CGPoint(
            x: piece.position.x * size.width + drag.width,
            y: piece.position.y * size.height + drag.height
        )
    }

    private func commitDrag(for piece: SketchPieceModel, translation: CGSize, in size: CGSize) {
        let dx = translation.width / max(size.width, 1)
        let dy = translation.height / max(size.height, 1)
        let next = CGPoint(x: piece.position.x + dx, y: piece.position.y + dy)
        let clamped = CGPoint(x: min(0.95, max(0.05, next.x)), y: min(0.95, max(0.05, next.y)))
        viewModel.updatePiece(id: piece.id, position: clamped, rotation: nil, scale: nil)
    }

    @ViewBuilder
    private func templateOutline(for piece: SketchPieceModel, in size: CGSize) -> some View {
        pieceShape(for: piece)
            .stroke(Color.appTextSecondary.opacity(0.35), lineWidth: 2)
            .frame(width: 54, height: 54)
            .rotationEffect(.zero)
            .position(
                CGPoint(
                    x: piece.templatePosition.x * size.width,
                    y: piece.templatePosition.y * size.height
                )
            )
    }

    private func pieceShape(for piece: SketchPieceModel) -> AnyShape {
        switch piece.shapeKind % 3 {
        case 0:
            return AnyShape(Circle())
        case 1:
            return AnyShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        default:
            return AnyShape(DiamondShape())
        }
    }

    private func fillColor(for piece: SketchPieceModel) -> Color {
        switch piece.shapeKind % 3 {
        case 0:
            return Color.appPrimary.opacity(0.92)
        case 1:
            return Color.appAccent.opacity(0.85)
        default:
            return Color.appTextPrimary.opacity(0.85)
        }
    }

    private func controls(for pieces: [SketchPieceModel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fine tune")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            ForEach(pieces) { piece in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Piece \(pieceIndex(piece))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    HStack {
                        Button {
                            adjustRotation(for: piece.id, delta: -10)
                        } label: {
                            Image(systemName: "rotate.left")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())

                        Button {
                            adjustRotation(for: piece.id, delta: 10)
                        } label: {
                            Image(systemName: "rotate.right")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())
                    }
                    HStack {
                        Button {
                            adjustScale(for: piece.id, delta: -0.05)
                        } label: {
                            Text("Smaller")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())

                        Button {
                            adjustScale(for: piece.id, delta: 0.05)
                        } label: {
                            Text("Larger")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())
                    }
                }
                .padding(12)
                .entertainmentCardChrome(cornerRadius: 16, elevated: false)
            }
        }
    }

    private func pieceIndex(_ piece: SketchPieceModel) -> Int {
        (viewModel.pieces.firstIndex(where: { $0.id == piece.id }) ?? 0) + 1
    }

    private func adjustRotation(for id: UUID, delta: Double) {
        guard let piece = viewModel.pieces.first(where: { $0.id == id }) else { return }
        let next = piece.rotation + .degrees(delta)
        viewModel.updatePiece(id: id, position: piece.position, rotation: next, scale: nil)
    }

    private func adjustScale(for id: UUID, delta: CGFloat) {
        guard let piece = viewModel.pieces.first(where: { $0.id == id }) else { return }
        viewModel.updatePiece(id: id, position: piece.position, rotation: nil, scale: piece.scale + delta)
    }

    private func finalize() {
        let snapAch = store.unlockedAchievementIds
        let snapRew = store.unlockedRewardIds
        let xpBefore = store.totalExperiencePoints
        let evaluation = viewModel.evaluateOutcome()
        store.recordSessionCompletion(
            address: address,
            starsEarned: evaluation.stars,
            duration: evaluation.duration,
            accuracyPercent: evaluation.accuracy
        )
        let unlocked = store.newlyUnlockedAchievements(comparedTo: snapAch)
        let newRewards = store.newlyUnlockedRewards(comparedTo: snapRew).map(\.id)
        let xpGained = store.totalExperiencePoints - xpBefore
        let outcome = ActivityOutcome(
            stars: evaluation.stars,
            duration: evaluation.duration,
            accuracyPercent: evaluation.accuracy,
            address: address,
            newAchievementIds: unlocked.map(\.id),
            experienceGained: xpGained,
            newRewardIds: newRewards
        )
        path.append(ActivityFlowRoute.feedback(outcome))
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct AnyShape: Shape {
    private let builder: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        builder = { @Sendable rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        builder(rect)
    }
}
