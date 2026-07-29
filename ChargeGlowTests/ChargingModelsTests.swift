import Foundation
import XCTest
@testable import ChargeGlow

final class ChargingModelsTests: XCTestCase {
    func testThemeCatalogHasNineUniqueOrderedThemes() {
        let descriptors = ThemeCatalog.all
        let IDs = descriptors.map(\.id)

        XCTAssertEqual(descriptors.count, 9)
        XCTAssertEqual(Set(IDs).count, descriptors.count)
        XCTAssertEqual(
            IDs,
            [
                .neonOrbit,
                .auroraPulse,
                .emberCircuit,
                .aquaFlux,
                .plasmaCore,
                .lumenBloom,
                .frostCrystal,
                .retroWave,
                .candyPop
            ]
        )
        XCTAssertEqual(
            descriptors.map(\.sortOrder),
            [0, 1, 2, 3, 4, 5, 6, 7, 8]
        )
    }

    func testUnknownThemeResolvesToNeonOrbit() {
        XCTAssertEqual(
            ThemeCatalog.resolve("removed-theme"),
            .neonOrbit
        )
    }

    func testContentStateUsesRealSnapshot() {
        let observedAt = Date(timeIntervalSince1970: 123)
        let snapshot = BatterySnapshot(
            percentage: 64,
            apiPercentage: 63.7,
            state: .charging,
            observedAt: observedAt
        )

        let state = ChargingActivityAttributes.ContentState(
            snapshot: snapshot,
            languageIdentifier: "ar"
        )

        XCTAssertEqual(state.batteryPercentage, 64)
        XCTAssertEqual(state.batteryPercentageDecimal, 63.7)
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
            apiPercentage: 15.2,
            state: .charging,
            observedAt: observedAt
        )

        XCTAssertEqual(snapshot.displayPercentage, "≈15%")
        XCTAssertEqual(snapshot.detailedDisplayPercentage, "≈15.2%")
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

    func testSingleChargingTrendSampleIsCentered() {
        let rect = CGRect(x: 10, y: 20, width: 200, height: 100)
        let samples = [
            ChargingSessionSample(
                percentage: 50,
                observedAt: Date(timeIntervalSince1970: 1_000)
            )
        ]

        XCTAssertEqual(
            ChargingTrendGeometry.points(
                for: samples,
                in: rect
            ),
            [CGPoint(x: rect.midX, y: rect.midY)]
        )
    }

    func testFlatChargingTrendStaysInsideChartAndMovesForward() {
        let rect = CGRect(x: 0, y: 0, width: 240, height: 120)
        let startDate = Date(timeIntervalSince1970: 2_000)
        let samples = (0..<4).map { index in
            ChargingSessionSample(
                percentage: 55,
                observedAt: startDate.addingTimeInterval(
                    TimeInterval(index * 30)
                )
            )
        }

        let points = ChargingTrendGeometry.points(
            for: samples,
            in: rect
        )

        XCTAssertEqual(points.count, samples.count)
        XCTAssertTrue(
            points.allSatisfy { rect.contains($0) }
        )
        XCTAssertEqual(
            points.first?.y ?? -1,
            rect.midY,
            accuracy: 0.001
        )
        XCTAssertEqual(
            points.last?.y ?? -1,
            rect.midY,
            accuracy: 0.001
        )
        XCTAssertEqual(
            points.first?.x ?? -1,
            rect.minX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            points.last?.x ?? -1,
            rect.maxX,
            accuracy: 0.001
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
        XCTAssertNil(events[0].batteryPercentageDecimal)
        XCTAssertNil(events[0].appVersion)
        XCTAssertEqual(events[0].message, "ChargeGlow launched.")
    }
}
