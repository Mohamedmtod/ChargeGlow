import Foundation
import XCTest
@testable import ChargeGlow

final class ActivityLifecyclePlannerTests: XCTestCase {
    func testRecoveryWithNoActivities() {
        let plan = ActivityLifecyclePlanner.recoveryPlan(for: [])

        XCTAssertNil(plan.retainedID)
        XCTAssertTrue(plan.IDsToEnd.isEmpty)
    }

    func testRecoveryKeepsNewestActivity() {
        let old = ActivityDescriptor(
            id: "old",
            startDate: Date(timeIntervalSince1970: 10)
        )
        let newest = ActivityDescriptor(
            id: "new",
            startDate: Date(timeIntervalSince1970: 20)
        )
        let middle = ActivityDescriptor(
            id: "middle",
            startDate: Date(timeIntervalSince1970: 15)
        )

        let plan = ActivityLifecyclePlanner.recoveryPlan(
            for: [old, newest, middle]
        )

        XCTAssertEqual(plan.retainedID, "new")
        XCTAssertEqual(plan.IDsToEnd, ["middle", "old"])
    }

    func testStartRequiresAuthorization() {
        XCTAssertThrowsError(
            try ActivityLifecyclePlanner.validateStart(
                authorized: false,
                existingActivities: []
            )
        ) { error in
            XCTAssertEqual(
                error as? ChargingActivityError,
                .liveActivitiesNotAuthorized
            )
        }
    }

    func testDuplicateStartIsRejected() {
        let activity = ActivityDescriptor(id: "active", startDate: Date())

        XCTAssertThrowsError(
            try ActivityLifecyclePlanner.validateStart(
                authorized: true,
                existingActivities: [activity]
            )
        ) { error in
            XCTAssertEqual(
                error as? ChargingActivityError,
                .activityAlreadyRunning
            )
        }
    }

    func testStopIsIdempotentAtPlanningBoundary() {
        XCTAssertEqual(ActivityLifecyclePlanner.IDsToEnd(for: []), [])

        let activity = ActivityDescriptor(id: "active", startDate: Date())
        XCTAssertEqual(
            ActivityLifecyclePlanner.IDsToEnd(for: [activity]),
            ["active"]
        )
    }

    func testDisconnectFallbackRequiresAnActiveActivity() {
        XCTAssertTrue(
            ActivityLifecyclePlanner.shouldEndForBatteryState(
                .disconnected,
                activeActivityCount: 1
            )
        )
        XCTAssertFalse(
            ActivityLifecyclePlanner.shouldEndForBatteryState(
                .disconnected,
                activeActivityCount: 0
            )
        )
        XCTAssertFalse(
            ActivityLifecyclePlanner.shouldEndForBatteryState(
                .charging,
                activeActivityCount: 1
            )
        )
    }

    func testActivityUpdatesForChangedOrAgedBatterySnapshots() {
        let lastUpdatedAt = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(
            ActivityLifecyclePlanner.shouldUpdateActivity(
                currentPercentage: 45,
                currentDecimalPercentage: 45,
                currentState: .charging,
                lastUpdatedAt: lastUpdatedAt,
                with: BatterySnapshot(
                    percentage: 50,
                    state: .charging,
                    observedAt: lastUpdatedAt.addingTimeInterval(1)
                )
            )
        )
        XCTAssertTrue(
            ActivityLifecyclePlanner.shouldUpdateActivity(
                currentPercentage: 45,
                currentDecimalPercentage: 45,
                currentState: .charging,
                lastUpdatedAt: lastUpdatedAt,
                with: BatterySnapshot(
                    percentage: 45,
                    state: .charging,
                    observedAt: lastUpdatedAt.addingTimeInterval(60)
                )
            )
        )
        XCTAssertFalse(
            ActivityLifecyclePlanner.shouldUpdateActivity(
                currentPercentage: 45,
                currentDecimalPercentage: 45,
                currentState: .charging,
                lastUpdatedAt: lastUpdatedAt,
                with: BatterySnapshot(
                    percentage: 45,
                    state: .charging,
                    observedAt: lastUpdatedAt.addingTimeInterval(1)
                )
            )
        )
        XCTAssertTrue(
            ActivityLifecyclePlanner.shouldUpdateActivity(
                currentPercentage: 45,
                currentDecimalPercentage: 45.1,
                currentState: .charging,
                lastUpdatedAt: lastUpdatedAt,
                with: BatterySnapshot(
                    percentage: 45,
                    apiPercentage: 45.2,
                    state: .charging,
                    observedAt: lastUpdatedAt.addingTimeInterval(1)
                )
            )
        )
    }
}
