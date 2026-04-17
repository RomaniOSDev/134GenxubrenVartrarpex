//
//  AppsFlyerManager.swift
//  1TrulbargrovarStrinel
//
//  Менеджер AppsFlyer: получение данных конверсии и UDL, сохранение в строку для отправки на сервер.
//  При af_status == "Organic" выполняется повторный запрос конверсии через 5 секунд (Get the conversion data).
//

import Foundation
import AppsFlyerLib

extension Notification.Name {
    static var appsFlyerConversionDataReady: Notification.Name {
        Notification.Name(LoadingRuntimeStrings.afConversionNotificationName)
    }
}

/// Ключ для сохранения строки с данными конверсии (для отправки на сервер)
enum AppsFlyerManagerKeys {
    static var conversionDataString: String { LoadingRuntimeStrings.afConversionStorageKey }
    static var conversionDataUpdatedAt: String { LoadingRuntimeStrings.afConversionUpdatedAtKey }
}

/// Менеджер AppsFlyer: конверсия + UDL. Не изменяет набор параметров из ответа.
final class AppsFlyerManager: NSObject {

    static let shared = AppsFlyerManager()

    /// Строка с данными конверсии (и при наличии — UDL) в формате JSON для отправки на сервер.
    /// Используются первые полученные значения при совпадении ключей (сначала конверсия, затем UDL).
    private(set) var conversionDataString: String? {
        get {
            UserDefaults.standard.string(forKey: AppsFlyerManagerKeys.conversionDataString)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppsFlyerManagerKeys.conversionDataString)
        }
    }

    /// Время последнего обновления conversionDataString (unix timestamp).
    private(set) var conversionDataUpdatedAt: TimeInterval? {
        get {
            let value = UserDefaults.standard.double(forKey: AppsFlyerManagerKeys.conversionDataUpdatedAt)
            return value > 0 ? value : nil
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: AppsFlyerManagerKeys.conversionDataUpdatedAt)
            } else {
                UserDefaults.standard.removeObject(forKey: AppsFlyerManagerKeys.conversionDataUpdatedAt)
            }
        }
    }

    /// Возвращает true, если conversion-данные были обновлены недавно (в пределах окна свежести).
    func hasFreshConversionData(within seconds: TimeInterval) -> Bool {
        guard conversionDataString != nil, let updatedAt = conversionDataUpdatedAt else { return false }
        return Date().timeIntervalSince1970 - updatedAt <= seconds
    }

    /// Текущие сырые данные конверсии (для слияния с UDL и повторной проверки)
    private var _afM0: [AnyHashable: Any]?

    /// Флаг: ожидаем повторный запрос конверсии через 5 сек из‑за Organic
    private var _afM1 = false

    /// Задержка перед повторным запросом конверсии при Organic (секунды)
    private let _afOrganicRetry: TimeInterval = 5

    private override init() {
        super.init()
    }

    // MARK: - Обработка конверсии (AppsFlyerLibDelegate вызывается из AppDelegate)

    /// Вызывать при успешном получении данных конверсии (onConversionDataSuccess).
    /// Сохраняет данные без изменения набора параметров. При af_status == "Organic" планирует повтор через 5 сек.
    func handleConversionDataSuccess(_ installData: [AnyHashable: Any]) {
        // Первые полученные данные имеют приоритет — сохраняем только если ещё не сохраняли итоговую строку из конверсии
        let statusKey = LoadingRuntimeStrings.afStatusKey
        let status = installData[statusKey] as? String
        if status == LoadingRuntimeStrings.afOrganicValue && !_afM1 {
            _afM1 = true
            _afM0 = installData
            _afScheduleRetry()
            return
        }

        _afApply(installData)
    }

    /// Вызывать при ошибке получения конверсии (onConversionDataFail).
    func handleConversionDataFail(_ error: Error?) {
        // При ошибке можно сохранить пустой объект или не менять предыдущее значение — по необходимости
    }

    /// Применить данные конверсии: слить с уже имеющимися UDL и сохранить итог в строку.
    /// Не изменяет список ключей из ответа; при совпадении ключей используются первые полученные значения.
    private func _afApply(_ installData: [AnyHashable: Any]) {
        _afM0 = installData
        _afMergePersist()
    }

    /// Повторный запрос конверсии через 5 секунд (Get the conversion data).
    private func _afScheduleRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + _afOrganicRetry) { [weak self] in
            self?._afPerformRetry()
        }
    }

    /// Выполнить повторный запрос конверсии через API SDK (start with completionHandler).
    private func _afPerformRetry() {
        AppsFlyerLib.shared().start(completionHandler: { [weak self] dictionary, error in
            DispatchQueue.main.async {
                if let dict = dictionary, !dict.isEmpty {
                    self?._afApply(dict as [AnyHashable: Any])
                } else if let data = self?._afM0 {
                    // Если повторный вызов не вернул данные — сохраняем то, что было (Organic)
                    self?._afMergePersist()
                }
                self?._afM1 = false
            }
        })
    }

    // MARK: - Deep linking (UDL)

    /// Данные UDL для слияния с конверсией. При совпадении ключей приоритет у уже сохранённых (первые полученные).
    private var _afUdl: [AnyHashable: Any]?

    /// Вызывать при успешном разрешении deep link (didResolveDeepLink, status == .found).
    /// Передавать словарь из DeepLink (clickEvent и т.д.) в виде [AnyHashable: Any].
    func handleDeepLinkData(_ deepLinkPayload: [AnyHashable: Any]) {
        _afUdl = deepLinkPayload
        _afMergePersist()
    }

    /// Слить конверсию и UDL: сначала конверсия, затем UDL; при совпадении ключа оставляем первое значение.
    /// Результат сохраняется в conversionDataString в виде JSON-строки.
    private func _afMergePersist() {
        var merged: [String: Any] = [:]

        if let conversion = _afM0 {
            for (key, value) in conversion {
                guard let k = key as? String else { continue }
                if merged[k] == nil {
                    merged[k] = value
                }
            }
        }

        if let udl = _afUdl {
            for (key, value) in udl {
                guard let k = key as? String else { continue }
                if merged[k] == nil {
                    merged[k] = value
                }
            }
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: merged),
              let string = String(data: jsonData, encoding: .utf8) else {
            return
        }
        conversionDataString = string
        conversionDataUpdatedAt = Date().timeIntervalSince1970
        NotificationCenter.default.post(name: .appsFlyerConversionDataReady, object: nil)
    }

    /// Сброс сохранённой строки (например для тестов).
    func clearStoredConversionString() {
        conversionDataString = nil
        conversionDataUpdatedAt = nil
        _afM0 = nil
        _afUdl = nil
        _afM1 = false
    }
}
