import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case english
    case arabic

    var id: String {
        rawValue
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .arabic:
            return Locale(identifier: "ar")
        }
    }
}

struct AppPreferences: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    static let defaultThemeID = "neon-orbit"

    var schemaVersion: Int
    var selectedThemeID: String
    var appLanguage: AppLanguage

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        selectedThemeID: String = Self.defaultThemeID,
        appLanguage: AppLanguage = .system
    ) {
        self.schemaVersion = schemaVersion
        self.selectedThemeID = selectedThemeID
        self.appLanguage = appLanguage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(
            Int.self,
            forKey: .schemaVersion
        ) ?? 0
        selectedThemeID = try container.decodeIfPresent(
            String.self,
            forKey: .selectedThemeID
        ) ?? Self.defaultThemeID
        appLanguage = (
            try? container.decodeIfPresent(
                AppLanguage.self,
                forKey: .appLanguage
            )
        ) ?? .system
    }

    func migrated() -> AppPreferences {
        AppPreferences(
            schemaVersion: Self.currentSchemaVersion,
            selectedThemeID: selectedThemeID.isEmpty
                ? Self.defaultThemeID
                : selectedThemeID,
            appLanguage: appLanguage
        )
    }
}

actor AppPreferencesStore {
    static let shared = AppPreferencesStore()
    static let defaultStorageKey = "chargeglow.preferences"

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        suiteName: String? = nil,
        storageKey: String = AppPreferencesStore.defaultStorageKey
    ) {
        if let suiteName {
            guard let suiteDefaults = UserDefaults(suiteName: suiteName) else {
                preconditionFailure(
                    "Could not create UserDefaults suite \(suiteName)"
                )
            }
            defaults = suiteDefaults
        } else {
            defaults = .standard
        }
        self.storageKey = storageKey
    }

    func load() -> AppPreferences {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? decoder.decode(AppPreferences.self, from: data)
        else {
            return AppPreferences()
        }

        let migrated = decoded.migrated()
        if migrated != decoded {
            persist(migrated)
        }
        return migrated
    }

    func selectedThemeID() -> String {
        load().selectedThemeID
    }

    func appLanguage() -> AppLanguage {
        load().appLanguage
    }

    func setSelectedThemeID(_ themeID: String) {
        var preferences = load()
        preferences.selectedThemeID = themeID.isEmpty
            ? AppPreferences.defaultThemeID
            : themeID
        preferences.schemaVersion = AppPreferences.currentSchemaVersion
        persist(preferences)
    }

    func setAppLanguage(_ appLanguage: AppLanguage) {
        var preferences = load()
        preferences.appLanguage = appLanguage
        preferences.schemaVersion = AppPreferences.currentSchemaVersion
        persist(preferences)
    }

    func reset() {
        defaults.removeObject(forKey: storageKey)
    }

    private func persist(_ preferences: AppPreferences) {
        guard let data = try? encoder.encode(preferences) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }
}
