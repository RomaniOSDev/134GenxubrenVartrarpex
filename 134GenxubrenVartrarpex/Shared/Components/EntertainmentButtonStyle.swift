//
//  EntertainmentButtonStyle.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct EntertainmentPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent,
                                    Color.appPrimary,
                                    Color.appPrimary.opacity(0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appTextPrimary.opacity(0.22), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(configuration.isPressed ? 0.12 : 0))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appTextPrimary.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: Color.appPrimary.opacity(configuration.isPressed ? 0.2 : 0.42), radius: 14, y: 7)
            .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct EntertainmentSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appSurface)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appTextPrimary.opacity(0.08),
                                    Color.clear,
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(0.55),
                                Color.appPrimary.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.12 : 0.22), radius: 12, y: 5)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

extension View {
    func entertainmentScreenPadding() -> some View {
        padding(.horizontal, 16)
    }
}
