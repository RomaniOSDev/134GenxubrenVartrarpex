//
//  MelodyMakerView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct MelodyMakerActivityScreen: View {
    @Binding var path: NavigationPath
    let address: LevelAddress

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel: MelodyMakerViewModel
    @State private var playbackStartedAt: Date?

    init(path: Binding<NavigationPath>, address: LevelAddress) {
        _path = path
        self.address = address
        _viewModel = StateObject(wrappedValue: MelodyMakerViewModel(address: address))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Recreate the hidden line by adjusting each step, listen carefully, then submit.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                staffCanvas

                controls

                HStack(spacing: 12) {
                    Button {
                        playbackStartedAt = Date()
                        viewModel.playSequence(isUserLine: false)
                    } label: {
                        Text("Play Reference")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(EntertainmentSecondaryButtonStyle())

                    Button {
                        let expected = expectedPlaybackDuration()
                        playbackStartedAt = Date()
                        viewModel.playSequence(isUserLine: true)
                        if address.difficulty == .hard {
                            DispatchQueue.main.asyncAfter(deadline: .now() + expected + 0.05) {
                                if let start = playbackStartedAt {
                                    let actual = Date().timeIntervalSince(start)
                                    viewModel.registerHardPlaybackFinishedWithinWindow(expectedSeconds: expected, actual: actual)
                                }
                            }
                        }
                    } label: {
                        Text("Play Yours")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(EntertainmentSecondaryButtonStyle())
                }

                Button {
                    submit()
                } label: {
                    Text("Submit Line")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(EntertainmentPrimaryButtonStyle())
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 16)
        }
        .entertainmentSceneBackground()
        .onDisappear {
            viewModel.stopPlayback()
        }
    }

    private var staffCanvas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            Canvas { context, size in
                let lineSpacing = size.height / 8
                for index in 0..<5 {
                    let y = lineSpacing * CGFloat(index + 1)
                    var line = Path()
                    line.move(to: CGPoint(x: 8, y: y))
                    line.addLine(to: CGPoint(x: size.width - 8, y: y))
                    context.stroke(line, with: .color(Color.appTextSecondary.opacity(0.55)), lineWidth: 1)
                }

                let columnWidth = (size.width - 16) / CGFloat(max(viewModel.stepCount, 1))
                for step in 0..<viewModel.stepCount {
                    let centerX = 8 + columnWidth * (CGFloat(step) + 0.5)
                    let pitch = viewModel.userPitches[step]
                    let y = size.height - lineSpacing - CGFloat(pitch) * (lineSpacing * 0.9)
                    let oval = Path(ellipseIn: CGRect(x: centerX - 9, y: y - 6, width: 18, height: 12))
                    let color = viewModel.playbackStep == step ? Color.appAccent : Color.appPrimary
                    context.fill(oval, with: .color(color))
                }
            }
            .frame(height: 160)
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<viewModel.stepCount, id: \.self) { step in
                        VStack(spacing: 8) {
                            Text("Step \(step + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                            Stepper(
                                "Pitch \(viewModel.userPitches[step] + 1)",
                                value: binding(for: step),
                                in: 0...6
                            )
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        }
                        .padding(12)
                        .entertainmentCardChrome(cornerRadius: 14, elevated: false)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .entertainmentInsetWell(cornerRadius: 18)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            if address.difficulty == .hard {
                Text("Hard tier checks pacing when you play your line—stay close to the pulse.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private func binding(for step: Int) -> Binding<Int> {
        Binding(
            get: { viewModel.userPitches[step] },
            set: { viewModel.userPitches[step] = $0 }
        )
    }

    private func expectedPlaybackDuration() -> TimeInterval {
        viewModel.stepPlaybackInterval * Double(viewModel.stepCount)
    }

    private func submit() {
        viewModel.stopPlayback()
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
