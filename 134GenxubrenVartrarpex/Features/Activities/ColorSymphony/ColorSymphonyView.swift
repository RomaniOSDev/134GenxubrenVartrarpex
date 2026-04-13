//
//  ColorSymphonyView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct ColorSymphonyActivityScreen: View {
    @Binding var path: NavigationPath
    let address: LevelAddress

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel: ColorSymphonyViewModel
    @State private var didEmitResult = false

    init(path: Binding<NavigationPath>, address: LevelAddress) {
        _path = path
        self.address = address
        _viewModel = StateObject(wrappedValue: ColorSymphonyViewModel(address: address))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Match the reference pattern by swapping neighboring tiles.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Reference")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                patternGrid(colors: viewModel.targetFlat.indices.map { viewModel.targetColor(at: $0) }, side: viewModel.gridSide, interactive: false)

                Text("Your arrangement")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                patternGrid(colors: viewModel.currentFlat.indices.map { viewModel.color(at: $0) }, side: viewModel.gridSide, interactive: true)

                HStack {
                    Label("Moves \(viewModel.moveCount)", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                    Spacer()
                }
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 16)
        }
        .entertainmentSceneBackground()
        .onChange(of: viewModel.isComplete) { completed in
            guard completed, !didEmitResult else { return }
            didEmitResult = true
            finalizeSession()
        }
    }

    private func patternGrid(colors: [Color], side: Int, interactive: Bool) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: side)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(colors.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colors[index].opacity(1),
                                colors[index].opacity(0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.appTextPrimary.opacity(0.35), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 5, y: 3)
                    .shadow(color: colors[index].opacity(0.35), radius: 6, y: 2)
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                guard interactive else { return }
                                handleSwipe(from: index, translation: value.translation, side: side)
                            }
                    )
                    .accessibilityLabel(Text("Tile \(index + 1)"))
            }
        }
        .padding(14)
        .entertainmentInsetWell(cornerRadius: 18)
    }

    private func handleSwipe(from index: Int, translation: CGSize, side: Int) {
        let row = index / side
        let col = index % side
        var target: Int?
        if abs(translation.width) > abs(translation.height) {
            if translation.width > 24, col + 1 < side {
                target = index + 1
            } else if translation.width < -24, col - 1 >= 0 {
                target = index - 1
            }
        } else {
            if translation.height > 24, row + 1 < side {
                target = index + side
            } else if translation.height < -24, row - 1 >= 0 {
                target = index - side
            }
        }
        if let target {
            viewModel.swap(from: index, to: target)
        }
    }

    private func finalizeSession() {
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
