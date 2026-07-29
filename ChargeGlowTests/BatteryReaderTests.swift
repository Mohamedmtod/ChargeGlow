import UIKit
import XCTest
@testable import ChargeGlow

final class BatteryReaderTests: XCTestCase {
    func testUnknownBatteryLevelRemainsUnavailable() {
        XCTAssertNil(BatteryReader.normalize(level: -1))
    }

    func testBatteryLevelConversionAndClamping() {
        XCTAssertEqual(BatteryReader.normalize(level: 0), 0)
        XCTAssertEqual(BatteryReader.normalize(level: 0.504), 50)
        XCTAssertEqual(BatteryReader.normalize(level: 1), 100)
        XCTAssertEqual(BatteryReader.normalize(level: 1.4), 100)
    }

    func testBatteryStateMapping() {
        XCTAssertEqual(BatteryReader.map(state: .unknown), .unknown)
        XCTAssertEqual(BatteryReader.map(state: .unplugged), .disconnected)
        XCTAssertEqual(BatteryReader.map(state: .charging), .charging)
        XCTAssertEqual(BatteryReader.map(state: .full), .full)
    }

    func testChargingSessionRequiresAvailableChargingSnapshot() {
        var test = ChargingSessionTest()

        let disconnectedStart = test.start(
            with: BatterySnapshot(
                percentage: 40,
                state: .disconnected,
                observedAt: Date()
            )
        )
        XCTAssertFalse(disconnectedStart)
        let unavailableStart = test.start(
            with: BatterySnapshot(
                percentage: nil,
                state: .charging,
                observedAt: Date()
            )
        )
        XCTAssertFalse(unavailableStart)
        XCTAssertEqual(test.phase, .idle)
    }

    func testChargingSessionCalculatesIndicativeObservedRate() {
        let startDate = Date(timeIntervalSince1970: 1_000)
        var test = ChargingSessionTest()
        let started = test.start(
            with: BatterySnapshot(
                percentage: 20,
                state: .charging,
                observedAt: startDate
            )
        )
        XCTAssertTrue(started)

        for minute in [2, 4, 6, 8, 10] {
            test.observe(
                BatterySnapshot(
                    percentage: 20 + minute / 3,
                    state: .charging,
                    observedAt: startDate.addingTimeInterval(
                        TimeInterval(minute * 60)
                    )
                )
            )
        }

        XCTAssertEqual(test.gainedPercentagePoints, 3)
        XCTAssertEqual(test.sampleCount, 6)
        XCTAssertEqual(test.confidence, .indicative)
        XCTAssertEqual(
            test.observedPercentagePointsPerHour ?? 0,
            18,
            accuracy: 0.001
        )
    }

    func testChargingSessionReachesStrongConfidence() {
        let startDate = Date(timeIntervalSince1970: 2_000)
        var test = ChargingSessionTest()
        let started = test.start(
            with: BatterySnapshot(
                percentage: 30,
                state: .charging,
                observedAt: startDate
            )
        )
        XCTAssertTrue(started)

        for sample in 1...10 {
            test.observe(
                BatterySnapshot(
                    percentage: 30 + sample / 2,
                    state: .charging,
                    observedAt: startDate.addingTimeInterval(
                        TimeInterval(sample * 120)
                    )
                )
            )
        }

        XCTAssertEqual(test.gainedPercentagePoints, 5)
        XCTAssertEqual(test.confidence, .strong)
    }

    func testChargingSessionEndsOnDisconnect() {
        let startDate = Date(timeIntervalSince1970: 3_000)
        var test = ChargingSessionTest()
        let started = test.start(
            with: BatterySnapshot(
                percentage: 50,
                state: .charging,
                observedAt: startDate
            )
        )
        XCTAssertTrue(started)

        test.observe(
            BatterySnapshot(
                percentage: 52,
                state: .disconnected,
                observedAt: startDate.addingTimeInterval(600)
            )
        )

        XCTAssertEqual(test.phase, .completed)
        XCTAssertEqual(test.completionReason, .disconnected)
        XCTAssertEqual(test.gainedPercentagePoints, 2)
    }

    func testChargingSessionCanEndWhenAppLeavesForeground() {
        let startDate = Date(timeIntervalSince1970: 4_000)
        var test = ChargingSessionTest()
        let started = test.start(
            with: BatterySnapshot(
                percentage: 60,
                state: .charging,
                observedAt: startDate
            )
        )
        XCTAssertTrue(started)

        test.stop(
            at: startDate.addingTimeInterval(120),
            reason: .appInactive
        )

        XCTAssertEqual(test.phase, .completed)
        XCTAssertEqual(test.completionReason, .appInactive)
        XCTAssertEqual(test.elapsed(at: Date()), 120)
    }

    func testChargingSessionEndsWhenBatteryBecomesFull() {
        let startDate = Date(timeIntervalSince1970: 5_000)
        var test = ChargingSessionTest()
        let started = test.start(
            with: BatterySnapshot(
                percentage: 98,
                state: .charging,
                observedAt: startDate
            )
        )
        XCTAssertTrue(started)

        test.observe(
            BatterySnapshot(
                percentage: 100,
                state: .full,
                observedAt: startDate.addingTimeInterval(900)
            )
        )

        XCTAssertEqual(test.phase, .completed)
        XCTAssertEqual(test.completionReason, .fullyCharged)
        XCTAssertEqual(test.latestPercentage, 100)
    }
}
