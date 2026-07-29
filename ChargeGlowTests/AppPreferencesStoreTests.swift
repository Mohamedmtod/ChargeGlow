import Foundation
import XCTest
@testable import ChargeGlow

final class AppPreferencesStoreTests: XCTestCase {
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "ChargeGlowTests.\(UUID().uuidString)"
    }

    override func tearDown() {
        if
            let suiteName,
            let defaults = UserDefaults(suiteName: suiteName)
        {
            defaults.removePersistentDomain(forName: suiteName)
        }
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsToNeonOrbit() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        let preferences = await store.load()

        XCTAssertEqual(
            preferences.schemaVersion,
            AppPreferences.currentSchemaVersion
        )
        XCTAssertEqual(
            preferences.selectedThemeID,
            AppPreferences.defaultThemeID
        )
        XCTAssertEqual(preferences.appLanguage, .system)
    }

    func testSelectedThemePersists() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        await store.setSelectedTheme(.plasmaCore)

        let reloadedStore = AppPreferencesStore(suiteName: suiteName)
        let selectedTheme = await reloadedStore.selectedTheme()
        XCTAssertEqual(selectedTheme, .plasmaCore)
    }

    func testLegacyPreferencesMigrateWithoutLosingTheme() async throws {
        let legacyData = try JSONSerialization.data(
            withJSONObject: ["selectedThemeID": "ember-circuit"]
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(
            legacyData,
            forKey: AppPreferencesStore.defaultStorageKey
        )
        let store = AppPreferencesStore(suiteName: suiteName)

        let migrated = await store.load()

        XCTAssertEqual(
            migrated.schemaVersion,
            AppPreferences.currentSchemaVersion
        )
        XCTAssertEqual(migrated.selectedThemeID, "ember-circuit")
        XCTAssertEqual(migrated.appLanguage, .system)
    }

    func testEmptyThemeFallsBackToDefault() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        await store.setSelectedThemeID("")

        let selectedThemeID = await store.selectedThemeID()
        XCTAssertEqual(selectedThemeID, AppPreferences.defaultThemeID)
    }

    func testUnknownThemeFallsBackToNeonOrbit() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        await store.setSelectedThemeID("removed-theme")

        let selectedTheme = await store.selectedTheme()
        XCTAssertEqual(selectedTheme, .neonOrbit)
    }

    func testUnknownStoredThemeMigratesToNeonOrbit() async throws {
        let data = try JSONSerialization.data(
            withJSONObject: [
                "schemaVersion": AppPreferences.currentSchemaVersion,
                "selectedThemeID": "removed-theme",
                "appLanguage": AppLanguage.english.rawValue
            ]
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(data, forKey: AppPreferencesStore.defaultStorageKey)
        let store = AppPreferencesStore(suiteName: suiteName)

        let preferences = await store.load()

        XCTAssertEqual(
            preferences.selectedThemeID,
            ThemeID.neonOrbit.rawValue
        )
        XCTAssertEqual(preferences.appLanguage, .english)
    }

    func testAppLanguagePersists() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        await store.setAppLanguage(.arabic)

        let reloadedStore = AppPreferencesStore(suiteName: suiteName)
        let appLanguage = await reloadedStore.appLanguage()
        XCTAssertEqual(appLanguage, .arabic)
    }

    func testUnknownStoredLanguageFallsBackToSystem() async throws {
        let data = try JSONSerialization.data(
            withJSONObject: [
                "schemaVersion": AppPreferences.currentSchemaVersion,
                "selectedThemeID": "aurora-pulse",
                "appLanguage": "unsupported-language"
            ]
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(data, forKey: AppPreferencesStore.defaultStorageKey)
        let store = AppPreferencesStore(suiteName: suiteName)

        let preferences = await store.load()

        XCTAssertEqual(preferences.selectedThemeID, "aurora-pulse")
        XCTAssertEqual(preferences.appLanguage, .system)
    }

    func testSystemLanguageResolvesArabicLanguageIdentifiers() {
        XCTAssertEqual(
            AppLanguage.resolveSystemLanguage(
                preferredLocalization: "ar"
            ),
            .arabic
        )
        XCTAssertEqual(
            AppLanguage.resolveSystemLanguage(
                preferredLocalization: "ar-EG"
            ),
            .arabic
        )
    }

    func testSystemLanguageDefaultsUnsupportedLanguagesToEnglish() {
        XCTAssertEqual(
            AppLanguage.resolveSystemLanguage(
                preferredLocalization: "en-GB"
            ),
            .english
        )
        XCTAssertEqual(
            AppLanguage.resolveSystemLanguage(
                preferredLocalization: "fr"
            ),
            .english
        )
        XCTAssertEqual(
            AppLanguage.resolveSystemLanguage(
                preferredLocalization: nil
            ),
            .english
        )
    }
}
