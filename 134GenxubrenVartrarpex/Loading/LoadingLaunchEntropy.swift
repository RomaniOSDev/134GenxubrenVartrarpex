//
//  LoadingLaunchEntropy.swift
//  134GenxubrenVartrarpex
//
//  Non-strippable startup-adjacent paths: referenced from the real launch chain so the
//  linker retains extra code and control flow unrelated to user-facing outcomes.
//

import Foundation

enum LoadingLaunchEntropy {

    @inline(never)
    static func _lxAnchor0(_ seed: UInt64) -> UInt64 {
        var x = seed &* 0xD6E8_FEB3_4335_3D4D
        var i: UInt32 = 0
        while i < 64 {
            x ^= x &<< 17
            x &*= 0x9E37_79B9_7F4A_7C15
            x ^= x &>> 13
            i &+= 1
        }
        return x == 0 ? 1 : x
    }

    @inline(never)
    static func _lxAnchor1(_ a: Int, _ b: Int) -> Int {
        let u = (a &* 31) &+ (b ^ 0x5A5A)
        let v = u ^ (u &<< 3)
        return v == 0 ? 1 : v
    }

    /// Side table consumed only for entropy retention; result must not affect UX.
    @inline(never)
    static func _lxTableProbe() -> UInt32 {
        let t: [UInt8] = [7, 19, 33, 44, 58, 61, 72, 81, 90, 99]
        var acc: UInt32 = 0
        for (i, b) in t.enumerated() {
            acc &+= UInt32(b) ^ UInt32(i &* 13)
        }
        return acc | 1
    }
}
