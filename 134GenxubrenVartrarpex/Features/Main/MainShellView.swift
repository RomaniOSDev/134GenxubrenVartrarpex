//
//  MainShellView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct MainShellView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selection: AppTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selection {
                case .home:
                    NavigationStack {
                        HomeView(
                            onOpenActivities: { selection = .activities },
                            onOpenProfile: { selection = .profile }
                        )
                    }
                case .activities:
                    NavigationStack {
                        ActivitiesRootView()
                    }
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .entertainmentSceneBackground()
    }

    private var customTabBar: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: symbol(for: tab))
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.title)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection == tab ? Color.appBackground : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 8)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent.opacity(0.95), Color.appPrimary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.appPrimary.opacity(0.45), radius: 12, y: 5)
                                .shadow(color: Color.black.opacity(0.22), radius: 6, y: 3)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.title))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background {
            ZStack(alignment: .top) {
                Color.appSurface
                LinearGradient(
                    colors: [Color.appTextPrimary.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
                .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [Color.appAccent.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 2)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 22, y: -10)
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: -4)
    }

    private func symbol(for tab: AppTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .activities: return "sparkles"
        case .profile: return "person.crop.circle"
        }
    }
}

extension AppTab: CaseIterable {
    static var allCases: [AppTab] { [.home, .activities, .profile] }
}
