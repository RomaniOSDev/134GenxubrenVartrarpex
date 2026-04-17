//
//  ConfigManager.swift
//  1TrulbargrovarStrinel
//
//  Запрос к эндпоинту конфига: сбор тела (конверсия AppsFlyer + af_id, bundle_id, os, store_id, locale, опционально push_token, firebase_project_id),
//  POST, разбор ответа, сохранение url и expires.
//

import Foundation
import AppsFlyerLib

/// Ответ эндпоинта конфига
struct ConfigResponse {
    let ok: Bool
    let url: String?
    let expires: Int64?
    let message: String?
}

/// Ключи для сохранения url и expires
enum ConfigManagerKeys {
    static var savedURL: String { LoadingRuntimeStrings.configSavedURLKey }
    static var savedExpires: String { LoadingRuntimeStrings.configSavedExpiresKey }
}

/// Провайдер опциональных данных (Firebase). Установите из AppDelegate при инициализации Firebase.
enum ConfigManagerOptionalData {
    static var pushToken: String?
    static var firebaseProjectId: String?
}

/// Менеджер запроса конфига: формирует тело, отправляет POST, сохраняет url/expires.
final class ConfigManager {

    static let shared = ConfigManager()

    /// URL эндпоинта конфига.
    var configEndpointURL: URL? = URL(string: LoadingRuntimeStrings.configEndpointURLString)

    /// Store ID приложения (iOS — с префиксом "id").
    var storeId: String = LoadingRuntimeStrings.storeIdValue

    private init() {}

    // MARK: - Сохранённые url и expires

    var savedURL: URL? {
        guard let raw = UserDefaults.standard.string(forKey: ConfigManagerKeys.savedURL) else { return nil }
        return URL(string: raw)
    }

    var savedExpires: Int64? {
        let v = UserDefaults.standard.object(forKey: ConfigManagerKeys.savedExpires) as? Int64
            ?? (UserDefaults.standard.object(forKey: ConfigManagerKeys.savedExpires) as? Int).map { Int64($0) }
        return v
    }

    /// Ссылка действительна, если сохранена и срок не истёк (expires > текущее время устройства).
    var isSavedURLValid: Bool {
        guard savedURL != nil, let exp = savedExpires else { return false }
        return exp > Int64(Date().timeIntervalSince1970)
    }

    private func saveResponse(url: String?, expires: Int64?) {
        if let url = url {
            UserDefaults.standard.set(url, forKey: ConfigManagerKeys.savedURL)
        }
        if let expires = expires {
            UserDefaults.standard.set(expires, forKey: ConfigManagerKeys.savedExpires)
        }
    }

    // MARK: - Формирование тела запроса

    /// Собирает JSON тела запроса: данные конверсии (без изменений) + af_id, bundle_id, os, store_id, locale; при наличии — push_token, firebase_project_id.
    func buildRequestBody() -> Data? {
        var body: [String: Any] = [:]

        // Данные конверсии (и UDL) — все параметры в неизменённом виде
        if let conversionString = AppsFlyerManager.shared.conversionDataString,
           let data = conversionString.data(using: .utf8),
           let conversion = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (key, value) in conversion {
                body[key] = value
            }
        }

        let kAf = LoadingRuntimeStrings.bodyKeyAfId
        let kBundle = LoadingRuntimeStrings.bodyKeyBundleId
        let kOs = LoadingRuntimeStrings.bodyKeyOS
        let kStore = LoadingRuntimeStrings.bodyKeyStoreId
        let kLocale = LoadingRuntimeStrings.bodyKeyLocale
        let kPush = LoadingRuntimeStrings.bodyKeyPushToken
        let kFb = LoadingRuntimeStrings.bodyKeyFirebaseProjectId
        let vIos = LoadingRuntimeStrings.bodyValueIOS

        // Дополнительные параметры (не перезаписываем существующие ключи из конверсии)
        if body[kAf] == nil {
            body[kAf] = AppsFlyerLib.shared().getAppsFlyerUID()
        }
        if body[kBundle] == nil {
            body[kBundle] = Bundle.main.bundleIdentifier ?? ""
        }
        if body[kOs] == nil {
            body[kOs] = vIos
        }
        if body[kStore] == nil {
            body[kStore] = storeId
        }
        if body[kLocale] == nil {
            body[kLocale] = Locale.current.identifier
        }
        if let token = ConfigManagerOptionalData.pushToken, body[kPush] == nil {
            body[kPush] = token
        }
        if let projectId = ConfigManagerOptionalData.firebaseProjectId, body[kFb] == nil {
            body[kFb] = projectId
        }

        return try? JSONSerialization.data(withJSONObject: body)
    }

    // MARK: - Запрос к конфигу

    /// Выполняет POST к эндпоинту конфига. При успехе (200 и ok == true) сохраняет url и expires.
    func requestConfig(completion: @escaping (Result<ConfigResponse, Error>) -> Void) {
        guard let endpoint = configEndpointURL else {
            completion(.failure(ConfigError.missingEndpoint))
            return
        }
        guard let body = buildRequestBody() else {
            completion(.failure(ConfigError.failedToBuildBody))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = LoadingRuntimeStrings.httpMethodPOST
        request.setValue(LoadingRuntimeStrings.mimeApplicationJSON, forHTTPHeaderField: LoadingRuntimeStrings.httpHeaderContentType)
        request.httpBody = body
        request.timeoutInterval = 10

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let http = response as? HTTPURLResponse
            let statusCode = http?.statusCode ?? 0
            let parsed = self?.parseConfigResponse(data: data, statusCode: statusCode) ?? .failure(ConfigError.invalidResponse)
            if case .success(let config) = parsed, config.ok, let url = config.url {
                self?.saveResponse(url: url, expires: config.expires)
            }
            DispatchQueue.main.async {
                switch parsed {
                case .success(let c):
                    completion(.success(c))
                case .failure(let e):
                    completion(.failure(e))
                }
            }
        }
        task.resume()
    }

    private func parseConfigResponse(data: Data?, statusCode: Int) -> Result<ConfigResponse, Error> {
        guard let data = data else {
            return .failure(ConfigError.invalidResponse)
        }
        let ok = (statusCode == 200)
        var url: String?
        var expires: Int64?
        var message: String?
        let jkUrl = LoadingRuntimeStrings.jsonURLKey
        let jkExp = LoadingRuntimeStrings.jsonExpiresKey
        let jkMsg = LoadingRuntimeStrings.jsonMessageKey
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            url = json[jkUrl] as? String
            if let e = json[jkExp] as? Int64 {
                expires = e
            } else if let e = json[jkExp] as? Int {
                expires = Int64(e)
            }
            message = json[jkMsg] as? String
        }
        return .success(ConfigResponse(ok: ok, url: url, expires: expires, message: message))
    }
}

enum ConfigError: LocalizedError {
    case missingEndpoint
    case failedToBuildBody
    case invalidResponse
    var errorDescription: String? {
        switch self {
        case .missingEndpoint: return LoadingRuntimeStrings.errMissingEndpoint
        case .failedToBuildBody: return LoadingRuntimeStrings.errFailedBody
        case .invalidResponse: return LoadingRuntimeStrings.errInvalidResponse
        }
    }
}
