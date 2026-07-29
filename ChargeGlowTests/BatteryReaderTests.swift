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
}
