//
//  LoadingViewController.swift
//  1TrulbargrovarStrinel
//
//  Показывает загрузку в стиле приложения (градиент + анимированный индикатор), запрашивает конфиг,
//  затем переходит на ContentView или WebviewVC. Адаптируется под портрет и ландшафт.
//  Максимальное время загрузки — 15 секунд.
//

import UIKit
import SwiftUI

/// Максимальное ожидание данных конверсии перед конфиг-запросом.
private let conversionDataWaitInterval: TimeInterval = 10
/// Окно свежести conversion-данных для fast-path при старте.
private let conversionDataFreshnessWindow: TimeInterval = 10
/// Максимальное время загрузки (сек): при нормальном интернете не должно превышать 15.
private let maxLoadingTimeInterval: TimeInterval = 15

/// Задержка перед стартом обычного config-flow (когда нет pending push URL).
private let ordinaryStartDelayInterval: TimeInterval = 5

final class LoadingViewController: UIViewController {

    private let _lcHost0 = UIHostingController(rootView: AnyView(LoadingView()))
    private var _lcDone0 = false
    private var _lcTOut0: DispatchWorkItem?
    private var _lcWait0: DispatchWorkItem?
    private var _lcObs0: NSObjectProtocol?
    private var _lcReq0 = false
    private var _lcOrd0: DispatchWorkItem?
    /// Флаг: config-flow уже запущен (или запланирован) — повторно не стартуем.
    private var _lcFlw0 = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let p0 = Int(LoadingLaunchEntropy._lxAnchor0(0x9A2C_41EE_D721_B003) & 0xffff)
        _ = LoadingLaunchEntropy._lxAnchor1(p0, MemoryLayout.size(ofValue: self))
        _ = LoadingLaunchEntropy._lxTableProbe()
        addChild(_lcHost0)
        view.addSubview(_lcHost0.view)
        _lcHost0.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _lcHost0.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _lcHost0.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _lcHost0.view.topAnchor.constraint(equalTo: view.topAnchor),
            _lcHost0.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        _lcHost0.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _lcBeginFlow()
    }

    private func _lcBeginFlow() {
        if _lcDone0 { return }
        if let pushURL = PushNotificationURLRouter.shared.consumePendingURL() {
            // Push-ветка: отменяем отложенный обычный старт, открываем WebView сразу (без HEAD-проверки —
            // редиректы и ATS обрабатывает WKWebView так же, как в других приложениях).
            _lcOrd0?.cancel()
            _lcOrd0 = nil
            _lcFlw0 = true
            _lcDone0 = true
            _lcSwapRoot(with: WebviewVC(url: pushURL))
            return
        }

        // Обычный старт: запускаем config-flow не сразу, а после задержки.
        // Это стабилизирует поведение на TestFlight, когда приложение уходит в background/foreground.
        guard !_lcFlw0, _lcOrd0 == nil else { return }
        _lcFlw0 = true
        _lcShowLoad()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self._lcOrd0 = nil
            guard !self._lcDone0, self._lcFlw0 else { return }
            self._lcFlowNoPush()
        }
        _lcOrd0 = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + ordinaryStartDelayInterval, execute: workItem)
    }

    private func _lcFlowNoPush() {
        if _lcDone0 { return }
        _lcFlw0 = true
        _lcShowLoad()

        NetworkAvailability.checkConnection { [weak self] isConnected in
            guard let self = self, !self._lcDone0 else { return }
            if !isConnected {
                self._lcShowOffline()
                return
            }
            self._lcFlowNet()
        }
    }

    private func _lcFlowNet() {
        if _lcDone0 { return }
        let config = ConfigManager.shared
        _lcReq0 = false

        // Таймаут: по истечении принудительно завершаем загрузку
        _lcTOut0 = DispatchWorkItem { [weak self] in
            self?._lcFinishTimeout()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + maxLoadingTimeInterval, execute: _lcTOut0!)

        // Есть действительная сохранённая ссылка — сразу показываем WebView
        if config.isSavedURLValid, let url = config.savedURL {
            _lcAbortTimers()
            _lcGoWeb(url: url)
            return
        }

        _lcAwaitConv()
    }

    private func _lcShowLoad() {
        _lcHost0.rootView = AnyView(LoadingView())
    }

    private func _lcShowOffline() {
        _lcFlw0 = false
        _lcAbortTimers()
        _lcHost0.rootView = AnyView(
            NoInternetView(
                onRetry: { [weak self] in
                    self?._lcBeginFlow()
                }
            )
        )
    }

    private func _lcAbortTimers() {
        _lcTOut0?.cancel()
        _lcTOut0 = nil
        _lcOrd0?.cancel()
        _lcOrd0 = nil
        _lcWait0?.cancel()
        _lcWait0 = nil
        if let observer = _lcObs0 {
            NotificationCenter.default.removeObserver(observer)
            _lcObs0 = nil
        }
    }

    private func _lcFinishTimeout() {
        guard !_lcDone0 else { return }
        // If the config request already started, don't override the UI decision by timeout.
        // The request itself has its own timeout interval.
        if _lcReq0 { return }
        _lcAbortTimers()
        _lcFlw0 = false
        _lcGoAppOrSaved()
    }

    private func _lcRunCfgReq() {
        guard !_lcDone0, !_lcReq0 else { return }
        _lcReq0 = true
        // From this point the in-flight request timeout controls the flow.
        // Prevent the global loading timeout from forcing ContentView while we are awaiting the response.
        _lcTOut0?.cancel()
        _lcTOut0 = nil
        _lcWait0?.cancel()
        _lcWait0 = nil
        if let observer = _lcObs0 {
            NotificationCenter.default.removeObserver(observer)
            _lcObs0 = nil
        }

        ConfigManager.shared.requestConfig { [weak self] result in
            guard let self = self, !self._lcDone0 else { return }
            self._lcAbortTimers()
            switch result {
            case .success(let response):
                if response.ok, let urlString = response.url, let url = URL(string: urlString) {
                    self._lcGoWeb(url: url)
                } else {
                    self._lcGoAppOrSaved()
                }
            case .failure:
                self._lcGoAppOrSaved()
            }
        }
    }

    private func _lcAwaitConv() {
        // Fast-path только для свежих conversion-данных,
        // чтобы не использовать устаревшее значение из прошлых запусков.
        if AppsFlyerManager.shared.hasFreshConversionData(within: conversionDataFreshnessWindow) {
            _lcRunCfgReq()
            return
        }

        // Subscribe first, then re-check to avoid a race where AppsFlyer posts the notification
        // between the initial nil check and observer registration.
        _lcObs0 = NotificationCenter.default.addObserver(
            forName: .appsFlyerConversionDataReady,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?._lcRunCfgReq()
        }

        // Stage 2: if conversion data didn't arrive in time, proceed with config request
        // without conversion payload (so we don't block UX with ContentView fallback).
        _lcWait0 = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard !self._lcDone0, !self._lcReq0 else { return }
            if AppsFlyerManager.shared.conversionDataString == nil {
                self._lcRunCfgReq()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + conversionDataWaitInterval, execute: _lcWait0!)

        // Close the race window: if data became available right before/while subscribing,
        // trigger the request immediately.
        if AppsFlyerManager.shared.hasFreshConversionData(within: conversionDataFreshnessWindow) {
            _lcRunCfgReq()
        }
    }

    /// При ошибке: если есть сохранённая ссылка — WebView с ней, иначе — ContentView.
    private func _lcGoAppOrSaved() {
        if let url = ConfigManager.shared.savedURL {
            _lcGoWeb(url: url)
        } else {
            _lcGoSwiftUI()
        }
    }

    private func _lcGoWeb(url: URL) {
        NotificationPermissionManager.shared.shouldShowCustomNotificationScreen { [weak self] shouldShow in
            guard let self = self, !self._lcDone0 else { return }
            self._lcDone0 = true
            if shouldShow {
                let notificationVC = NotificationPermissionViewController(url: url, window: self.view.window)
                self._lcSwapRoot(with: notificationVC)
            } else {
                self._lcSwapRoot(with: WebviewVC(url: url))
            }
        }
    }

    private func _lcGoSwiftUI() {
        _lcDone0 = true
        let content = UIHostingController(rootView: ContentView())
        _lcSwapRoot(with: content)
    }

    private func _lcSwapRoot(with vc: UIViewController) {
        guard let window = view.window else { return }
        window.rootViewController = vc
    }
}
