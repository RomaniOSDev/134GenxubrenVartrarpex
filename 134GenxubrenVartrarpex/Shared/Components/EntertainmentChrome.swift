//
//  EntertainmentChrome.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

// MARK: - Screen & atmosphere

extension View {
    /// Layered gradient “room” behind scroll content (no hardcoded colors — app palette only).
    func entertainmentSceneBackground() -> some View {
        background(
            ZStack {
                Color.appBackground
                LinearGradient(
                    colors: [
                        Color.appSurface.opacity(0.52),
                        Color.appBackground,
                        Color.appBackground,
                        Color.appSurface.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color.appPrimary.opacity(0.14), Color.clear],
                    center: UnitPoint(x: 0.15, y: 0.12),
                    startRadius: 10,
                    endRadius: 380
                )
                RadialGradient(
                    colors: [Color.appAccent.opacity(0.1), Color.clear],
                    center: UnitPoint(x: 0.92, y: 0.35),
                    startRadius: 20,
                    endRadius: 280
                )
            }
            .ignoresSafeArea()
        )
    }

    /// Slightly softer variant for nested stacks (e.g. onboarding).
    func entertainmentAtmosphereBackground() -> some View {
        background(
            ZStack {
                Color.appBackground
                LinearGradient(
                    colors: [
                        Color.appSurface.opacity(0.45),
                        Color.appBackground,
                        Color.appSurface.opacity(0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )
    }
}

// MARK: - Cards & wells (depth)

extension View {
    /// Raised card: base fill + light top / shade bottom + rim + double shadow.
    func entertainmentCardChrome(cornerRadius: CGFloat = 20, elevated: Bool = true) -> some View {
        let r = cornerRadius
        let shadowOpacity = elevated ? 0.3 : 0.18
        let shadowRadius: CGFloat = elevated ? 18 : 11
        let shadowY: CGFloat = elevated ? 9 : 5

        return background {
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(Color.appSurface)
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appTextPrimary.opacity(0.1),
                                Color.clear,
                                Color.black.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(0.42),
                                Color.appPrimary.opacity(0.18),
                                Color.appAccent.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
            .shadow(color: Color.appPrimary.opacity(0.09), radius: 26, y: 5)
        }
    }

    /// Recessed panel (grids, staff, inner blocks).
    func entertainmentInsetWell(cornerRadius: CGFloat = 16) -> some View {
        let r = cornerRadius
        return background {
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.35),
                                Color.appBackground.opacity(0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appTextPrimary.opacity(0.04), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .stroke(Color.black.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.55), radius: 8, y: 4)
        }
    }
}
