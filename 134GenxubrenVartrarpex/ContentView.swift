//
//  ContentView.swift
//  134GenxubrenVartrarpex
//


import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainShellView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
