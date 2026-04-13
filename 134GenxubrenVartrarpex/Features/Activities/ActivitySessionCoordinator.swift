//
//  ActivitySessionCoordinator.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct ActivitySessionCoordinator: View {
    @Binding var path: NavigationPath
    let address: LevelAddress

    var body: some View {
        Group {
            switch address.activity {
            case .colorSymphony:
                ColorSymphonyActivityScreen(path: $path, address: address)
            case .melodyMaker:
                MelodyMakerActivityScreen(path: $path, address: address)
            case .adventureSketch:
                AdventureSketchActivityScreen(path: $path, address: address)
            }
        }
        .entertainmentSceneBackground()
    }
}
