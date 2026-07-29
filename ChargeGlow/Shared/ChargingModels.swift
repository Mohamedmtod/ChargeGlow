import ActivityKit
import Foundation

enum ChargingState: String, Codable, CaseIterable, Hashable, Sendable {
    case unknown
    case disconnected
    case charging
    case full

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .disconnected:
            return "Disconnected"
        case .charging:
            return "Charging"
        case .full:
            return "Fully Charged"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .disconnected:
            return "bolt.slash"
        case .charging:
            return "bolt.fill"
        case .full:
            return "checkmark.circle.fill"
        }
    }
}
struct BatterySnapshot: Codable, Equatable, Sendable {
    let percentage: Int?
    let state: ChargingState
    let observedAt: Date

    var displayPercentage: String {
        percentage.map { "\($0)%" } ?? "—"
    }
}

struct ChargingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let batteryPercentage: Int?
        let chargingState: ChargingState
        let lastUpdatedAt: Date
        let displayMessage: String
    }

    let sessionID: String
    let themeID: String
    let startDate: Date
}

extension ChargingActivityAttributes.ContentState {
    init(snapshot: BatterySnapshot, message: String? = nil) {
        batteryPercentage = snapshot.percentage
        chargingState = snapshot.state
        lastUpdatedAt = snapshot.observedAt
        displayMessage = message ?? snapshot.state.displayName
    }
}
