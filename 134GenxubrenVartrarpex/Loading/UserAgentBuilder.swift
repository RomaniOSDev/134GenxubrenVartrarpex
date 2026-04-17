//
//  UserAgentBuilder.swift
//  1TrulbargrovarStrinel
//
//  Builds a Safari-like User-Agent from actual device info (OS version, platform).
//  No hardcoding of device-specific values; WebView is not indicated.
//

import UIKit

enum UserAgentBuilder {

    /// Builds a User-Agent string that reflects the current device (OS version, platform)
    /// and does not indicate in-app WebView usage. Uses only runtime device info.
    static func build() -> String {
        let device = UIDevice.current
        let osVersion = device.systemVersion
        let osVersionUnderscore = osVersion.replacingOccurrences(of: ".", with: "_")
        let model = device.model
        let platform: String
        let cpuPart: String
        let tokPad = LoadingRuntimeStrings.uaIPadToken
        let tokPod = LoadingRuntimeStrings.uaIPodToken
        let podLinePrefix = LoadingRuntimeStrings.uaIPodLinePrefix
        if model.hasPrefix(tokPad) {
            platform = tokPad
            cpuPart = LoadingRuntimeStrings.uaCPUOSIPadFragment + osVersionUnderscore
        } else if model.hasPrefix(podLinePrefix) {
            platform = tokPod
            cpuPart = LoadingRuntimeStrings.uaCPUOSPhoneFragment + osVersionUnderscore
        } else {
            platform = LoadingRuntimeStrings.uaIPhoneToken
            cpuPart = LoadingRuntimeStrings.uaCPUOSPhoneFragment + osVersionUnderscore
        }

        let sep = LoadingRuntimeStrings.uaJoinSeparator
        return [
            LoadingRuntimeStrings.uaMozillaPrefix + platform + "; " + cpuPart + LoadingRuntimeStrings.uaLikeMacOSXSuffix,
            LoadingRuntimeStrings.uaWebKitFragment,
            LoadingRuntimeStrings.uaVersionPrefix + osVersion,
            LoadingRuntimeStrings.uaSafariSuffix
        ].joined(separator: sep)
    }
}
