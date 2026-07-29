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

        let state = ChargingActivityAttributes.ContentState(snapshot: snapshot)

        XCTAssertEqual(state.batteryPercentage, 64)
        XCTAssertEqual(state.chargingState, .charging)
        XCTAssertEqual(state.lastUpdatedAt, observedAt)
        XCTAssertEqual(state.displayMessage, "Charging")
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
}
