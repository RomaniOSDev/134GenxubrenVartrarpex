//
//  SettingsView.swift
//  134GenxubrenVartrarpex
//

import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Support and legal")
                    .font(.title3.bold())
                    .foregroundStyle(Color.appTextPrimary)

                Text("Rate the app or read our policies in your browser.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    settingsButton(
                        title: "Rate us",
                        systemImage: "star.fill",
                        tint: Color.appAccent,
                        action: rateApp
                    )

                    settingsButton(
                        title: "Privacy Policy",
                        systemImage: "hand.raised.fill",
                        tint: Color.appPrimary,
                        action: openPrivacyPolicy
                    )

                    settingsButton(
                        title: "Terms of Use",
                        systemImage: "doc.text.fill",
                        tint: Color.appPrimary,
                        action: openTermsOfUse
                    )
                }
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 20)
        }
        .entertainmentSceneBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private func settingsButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(tint.opacity(0.15)))
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
            }
            .padding(16)
            .entertainmentCardChrome(cornerRadius: 18, elevated: false)
        }
        .buttonStyle(.plain)
    }

    private func openPrivacyPolicy() {
        if let url = AppLegalLink.privacyPolicy.url {
            UIApplication.shared.open(url)
        }
    }

    private func openTermsOfUse() {
        if let url = AppLegalLink.termsOfUse.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
