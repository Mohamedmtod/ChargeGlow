import Foundation
import XCTest
@testable import ChargeGlow

final class ChargingModelsTests: XCTestCase {
    func testContentStateUsesRealSnapshot() {
        let observedAt = Date(timeIntervalSince1970: 123)
        let snapshot = BatterySnapshot(
            percentage: 64,
            state: .charging,
            observedAt: observedAt
        )

        let state = ChargingActivityAttributes.ContentState(
            snapshot: snapshot,
            languageIdentifier: "ar"
        )

        XCTAssertEqual(state.batteryPercentage, 64)
        XCTAssertEqual(state.chargingState, .charging)
        XCTAssertEqual(state.lastUpdatedAt, observedAt)
        XCTAssertEqual(state.displayMessage, snapshot.state.displayName)
        XCTAssertEqual(state.languageIdentifier, "ar")
    }

    func testUnavailablePercentageIsNotFabricated() {
        let snapshot = BatterySnapshot(
            percentage: nil,
            state: .unknown,
            observedAt: Date()
        )

        let state = ChargingActivityAttributes.ContentState(snapshot: snapshot)

        XCTAssertNil(state.batteryPercentage)
        XCTAssertEqual(snapshot.displayPercentage, "—")
    }

    func testAvailablePercentageIsMarkedApproximateAndBecomesStale() {
        let observedAt = Date(timeIntervalSince1970: 1_000)
        let snapshot = BatterySnapshot(
            percentage: 15,
            state: .charging,
            observedAt: observedAt
        )

        XCTAssertEqual(snapshot.displayPercentage, "≈15%")
        XCTAssertEqual(
            snapshot.liveActivityStaleDate,
            observedAt.addingTimeInterval(120)
        )
    }

    func testTypedErrorsHaveStableDiagnosticCodes() {
        XCTAssertEqual(
            ChargingActivityError.liveActivitiesNotAuthorized.diagnosticCode,
            "CG-ACT-001"
        )
        XCTAssertEqual(
            ChargingActivityError.batteryUnavailable.diagnosticCode,
            "CG-BAT-001"
        )
        XCTAssertFalse(
            ChargingActivityError.activityStartFailed.recoverySuggestion.isEmpty
        )
    }

    func testLegacyDiagnosticsRemainDecodable() throws {
        let legacyJSON = """
        [
          {
            "category": "app",
            "id": "55BA4775-1384-44E9-95C8-086E743BD6CB",
            "level": "info",
            "message": "ChargeGlow launched.",
            "timestamp": "2026-07-29T05:45:08Z"
          }
        ]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let events = try decoder.decode(
            [DiagnosticEvent].self,
            from: Data(legacyJSON.utf8)
        )

        XCTAssertEqual(events.count, 1)
        XCTAssertNil(events[0].sequence)
        XCTAssertNil(events[0].correlationID)
        XCTAssertNil(events[0].appVersion)
        XCTAssertEqual(events[0].message, "ChargeGlow launched.")
    }
}
