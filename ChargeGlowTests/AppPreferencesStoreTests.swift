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
    }

    func testSelectedThemePersists() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        await store.setSelectedThemeID("aurora-pulse")

        let reloadedStore = AppPreferencesStore(suiteName: suiteName)
        let selectedThemeID = await reloadedStore.selectedThemeID()
        XCTAssertEqual(selectedThemeID, "aurora-pulse")
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
    }

    func testEmptyThemeFallsBackToDefault() async {
        let store = AppPreferencesStore(suiteName: suiteName)

        await store.setSelectedThemeID("")

        let selectedThemeID = await store.selectedThemeID()
        XCTAssertEqual(selectedThemeID, AppPreferences.defaultThemeID)
    }
}
