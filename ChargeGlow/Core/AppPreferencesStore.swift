import Foundation

struct AppPreferences: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let defaultThemeID = "neon-orbit"

    var schemaVersion: Int
    var selectedThemeID: String

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        selectedThemeID: String = Self.defaultThemeID
    ) {
        self.schemaVersion = schemaVersion
        self.selectedThemeID = selectedThemeID
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
    }

    func migrated() -> AppPreferences {
        AppPreferences(
            schemaVersion: Self.currentSchemaVersion,
            selectedThemeID: selectedThemeID.isEmpty
                ? Self.defaultThemeID
                : selectedThemeID
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
        defaults: UserDefaults = .standard,
        storageKey: String = AppPreferencesStore.defaultStorageKey
    ) {
        self.defaults = defaults
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

    func setSelectedThemeID(_ themeID: String) {
        var preferences = load()
        preferences.selectedThemeID = themeID.isEmpty
            ? AppPreferences.defaultThemeID
            : themeID
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
