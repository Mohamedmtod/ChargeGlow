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
            return String(localized: "Unknown")
        case .disconnected:
            return String(localized: "Disconnected")
        case .charging:
            return String(localized: "Charging")
        case .full:
            return String(localized: "Fully Charged")
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
    static let liveActivityFreshnessInterval: TimeInterval = 120

    let percentage: Int?
    let state: ChargingState
    let observedAt: Date

    var displayPercentage: String {
        percentage.map { "≈\($0)%" } ?? "—"
    }

    var liveActivityStaleDate: Date {
        observedAt.addingTimeInterval(Self.liveActivityFreshnessInterval)
    }
}

struct ChargingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let batteryPercentage: Int?
        let chargingState: ChargingState
        let lastUpdatedAt: Date
        let displayMessage: String
        let languageIdentifier: String?
    }

    let sessionID: String
    let themeID: String
    let startDate: Date
}

extension ChargingActivityAttributes.ContentState {
    init(
        snapshot: BatterySnapshot,
        message: String? = nil,
        languageIdentifier: String? = nil
    ) {
        batteryPercentage = snapshot.percentage
        chargingState = snapshot.state
        lastUpdatedAt = snapshot.observedAt
        displayMessage = message ?? snapshot.state.displayName
        self.languageIdentifier = languageIdentifier
    }
}
