//
//  LoadingManager.swift
//  1TrulbargrovarStrinel
//
//  Загрузочный менеджер: при старте показывает LoadingViewController, который запрашивает конфиг
//  и затем переключает на ContentView или WebviewVC в зависимости от ответа сервера.
//

import UIKit
import SwiftUI

/// Менеджер выбора стартового экрана при запуске приложения.
final class LoadingManager {

    static let shared = LoadingManager()

    private init() {}

    /// Возвращает корневой контроллер: экран загрузки, который запрашивает конфиг и затем
    /// переходит на ContentView или WebviewVC (с сохранённой или новой ссылкой).
    func makeRootViewController() -> UIViewController {
        let u = LoadingLaunchEntropy._lxAnchor0(0x5E71B9C8_D403_F21A)
        _ = LoadingLaunchEntropy._lxAnchor1(Int(truncatingIfNeeded: u), 11)
        return LoadingViewController()
    }
}
