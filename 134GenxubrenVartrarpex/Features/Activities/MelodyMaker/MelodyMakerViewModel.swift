//
//  MelodyMakerViewModel.swift
//  134GenxubrenVartrarpex
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

@MainActor
final class MelodyMakerViewModel: ObservableObject {
    @Published var userPitches: [Int]
    @Published private(set) var targetPitches: [Int]
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playbackStep: Int = -1
    @Published private(set) var hardBeatWindowOK: Bool = true

    let address: LevelAddress
    let stepCount: Int
    let staffSteps: Int = 7

    private let startedAt: Date
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var playbackTask: Task<Void, Never>?

    private let hardTempoBPM: Double

    var stepPlaybackInterval: TimeInterval {
        address.difficulty == .hard ? max(0.12, 60 / hardTempoBPM) : 0.28
    }

    init(address: LevelAddress) {
        self.address = address
        self.startedAt = Date()
        let config = MelodyMakerViewModel.config(for: address)
        stepCount = config.steps
        hardTempoBPM = config.bpm
        targetPitches = MelodyMakerViewModel.makeTarget(length: config.steps, seed: Self.seed(for: address))
        userPitches = Array(repeating: 3, count: config.steps)
    }

    private static func seed(for address: LevelAddress) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(address.activity.rawValue)
        hasher.combine(address.difficulty.rawValue)
        hasher.combine(address.levelIndex)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    private static func config(for address: LevelAddress) -> (steps: Int, bpm: Double) {
        let level = address.levelIndex
        switch address.difficulty {
        case .easy:
            return (min(4 + level, 12), 96 + Double(level) * 2)
        case .normal:
            return (min(6 + level, 15), 104 + Double(level) * 2)
        case .hard:
            return (min(8 + level, 16), 118 + Double(level) * 3)
        }
    }

    private static func makeTarget(length: Int, seed: UInt64) -> [Int] {
        var generator = SeededGenerator(seed: seed)
        return (0..<length).map { _ in
            Int.random(in: 0..<7, using: &generator)
        }
    }

    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
        mutating func next() -> UInt64 {
            state &+= 0x6A09E667F3BCC909
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    func midi(forPitchIndex pitch: Int) -> Int {
        let scale: [Int] = [0, 2, 4, 5, 7, 9, 11]
        let clamped = max(0, min(6, pitch))
        return 60 + scale[clamped]
    }

    func playSequence(isUserLine: Bool) {
        playbackTask?.cancel()
        let sequence = isUserLine ? userPitches.map { midi(forPitchIndex: $0) } : targetPitches.map { midi(forPitchIndex: $0) }
        let interval: TimeInterval
        if address.difficulty == .hard {
            interval = max(0.12, 60 / hardTempoBPM)
        } else {
            interval = 0.28
        }
        isPlaying = true
        playbackStep = -1
        playbackTask = Task { @MainActor in
            await prepareEngineIfNeeded()
            for index in sequence.indices {
                if Task.isCancelled { break }
                playbackStep = index
                await playNote(midi: sequence[index], duration: max(0.08, interval * 0.85))
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            playbackStep = -1
            isPlaying = false
        }
    }

    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        player?.stop()
        playbackStep = -1
        isPlaying = false
    }

    private func prepareEngineIfNeeded() async {
        if engine != nil { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        if let format {
            engine.connect(player, to: engine.mainMixerNode, format: format)
            try? engine.start()
            self.engine = engine
            self.player = player
        }
    }

    private func playNote(midi: Int, duration: TimeInterval) async {
        guard let player else { return }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }

        let midiNote = Double(midi)
        let exponent = (midiNote - 69.0) / 12.0
        let frequency = 440.0 * pow(2.0, exponent)

        let rate = format.sampleRate
        let rawFrames = duration * rate
        let frameCount = AVAudioFrameCount(max(1, rawFrames))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let count = Int(frameCount)
        if let channelList = buffer.floatChannelData {
            let channel = channelList[0]
            Self.writeSineSamples(channel: channel, totalFrames: count, sampleRate: rate, frequency: frequency)
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
        player.play()

        let nanos = duration * 1_000_000_000.0
        let nanoseconds = UInt64(nanos)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    /// Fills a mono float buffer; isolated to ease Swift type-checking.
    private static func writeSineSamples(
        channel: UnsafeMutablePointer<Float>,
        totalFrames: Int,
        sampleRate: Double,
        frequency: Double
    ) {
        let twoPi: Double = Double.pi * 2.0
        let denomAttack = Double(totalFrames) * 0.08
        let denomRelease = Double(totalFrames) * 0.2

        var frameIndex = 0
        while frameIndex < totalFrames {
            let t = Double(frameIndex) / sampleRate
            let frameD = Double(frameIndex)
            let attackPhase = frameD / denomAttack
            let releasePhase = Double(totalFrames - frameIndex) / denomRelease
            let attack = min(1.0, attackPhase)
            let release = min(1.0, releasePhase)
            let envelope = attack * release
            let radians = twoPi * frequency * t
            let sample = sin(radians) * 0.25 * envelope
            channel[frameIndex] = Float(sample)
            frameIndex += 1
        }
    }

    func evaluateOutcome() -> (stars: Int, duration: TimeInterval, accuracy: Double) {
        let duration = Date().timeIntervalSince(startedAt)
        let matches = zip(userPitches, targetPitches).filter { $0 == $1 }.count
        let ratio = stepCount == 0 ? 0 : Double(matches) / Double(stepCount)
        let accuracy = ratio * 100
        let stars: Int
        if ratio >= 0.99 {
            stars = 3
        } else if ratio >= 0.75 {
            stars = 2
        } else if ratio >= 0.5 {
            stars = 1
        } else {
            stars = 0
        }
        if address.difficulty == .hard && !hardBeatWindowOK && stars > 1 {
            return (max(1, stars - 1), duration, accuracy)
        }
        return (stars, duration, accuracy)
    }

    func registerHardPlaybackFinishedWithinWindow(expectedSeconds: Double, actual: Double) {
        let drift = abs(actual - expectedSeconds)
        if drift > max(0.35, expectedSeconds * 0.12) {
            hardBeatWindowOK = false
        }
    }
}
