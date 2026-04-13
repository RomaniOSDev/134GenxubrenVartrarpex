//
//  AppLegalLink.swift
//  134GenxubrenVartrarpex
//

import Foundation

enum AppLegalLink: String {
    case privacyPolicy = "https://genxubren134vartrarpex.site/privacy/100"
    case termsOfUse = "https://genxubren134vartrarpex.site/terms/100"

    var url: URL? {
        URL(string: rawValue)
    }
}
