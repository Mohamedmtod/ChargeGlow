import Foundation
import XCTest
@testable import ChargeGlow

final class AppPreferencesStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ChargeGlowTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsToNeonOrbit() async {
        let store = AppPreferencesStore(defaults: defaults)

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
        let store = AppPreferencesStore(defaults: defaults)

        await store.setSelectedThemeID("aurora-pulse")

        let reloadedStore = AppPreferencesStore(defaults: defaults)
        let selectedThemeID = await reloadedStore.selectedThemeID()
        XCTAssertEqual(selectedThemeID, "aurora-pulse")
    }

    func testLegacyPreferencesMigrateWithoutLosingTheme() async throws {
        let legacyData = try JSONSerialization.data(
            withJSONObject: ["selectedThemeID": "ember-circuit"]
        )
        defaults.set(
            legacyData,
            forKey: AppPreferencesStore.defaultStorageKey
        )
        let store = AppPreferencesStore(defaults: defaults)

        let migrated = await store.load()

        XCTAssertEqual(
            migrated.schemaVersion,
            AppPreferences.currentSchemaVersion
        )
        XCTAssertEqual(migrated.selectedThemeID, "ember-circuit")
    }

    func testEmptyThemeFallsBackToDefault() async {
        let store = AppPreferencesStore(defaults: defaults)

        await store.setSelectedThemeID("")

        let selectedThemeID = await store.selectedThemeID()
        XCTAssertEqual(selectedThemeID, AppPreferences.defaultThemeID)
    }
}
