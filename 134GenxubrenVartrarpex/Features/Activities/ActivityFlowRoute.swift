//
//  ActivityFlowRoute.swift
//  134GenxubrenVartrarpex
//

import Foundation

enum ActivityFlowRoute: Hashable {
    case levels(ActivityKind)
    case session(LevelAddress)
    case feedback(ActivityOutcome)
}
