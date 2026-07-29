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
    let apiPercentage: Double?
    let state: ChargingState
    let observedAt: Date

    init(
        percentage: Int?,
        apiPercentage: Double? = nil,
        state: ChargingState,
        observedAt: Date
    ) {
        self.percentage = percentage
        self.apiPercentage = apiPercentage
        self.state = state
        self.observedAt = observedAt
    }

    var mostDetailedPercentage: Double? {
        apiPercentage ?? percentage.map { Double($0) }
    }

    var displayPercentage: String {
        percentage.map { "≈\($0)%" } ?? "—"
    }

    var detailedDisplayPercentage: String {
        guard let mostDetailedPercentage else {
            return "—"
        }
        return String(
            format: "≈%.1f%%",
            mostDetailedPercentage
        )
    }

    var liveActivityStaleDate: Date {
        observedAt.addingTimeInterval(Self.liveActivityFreshnessInterval)
    }
}

struct ExternalElectricalMeasurement: Equatable, Sendable {
    let voltage: Double?
    let currentMilliamps: Double?

    var currentAmps: Double? {
        guard let currentMilliamps = Self.valid(currentMilliamps) else {
            return nil
        }
        return currentMilliamps / 1_000
    }

    var powerWatts: Double? {
        guard
            let voltage = Self.valid(voltage),
            let currentAmps
        else {
            return nil
        }

        let power = voltage * currentAmps
        return power.isFinite ? power : nil
    }

    var isComplete: Bool {
        powerWatts != nil
    }

    static func parse(
        _ text: String,
        locale: Locale
    ) -> Double? {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.isLenient = false

        if let value = formatter.number(from: trimmed)?.doubleValue {
            return value
        }

        let numeralMap = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"
        ]
        var normalized = trimmed
        for (localizedDigit, latinDigit) in numeralMap {
            normalized = normalized.replacingOccurrences(
                of: localizedDigit,
                with: latinDigit
            )
        }
        normalized = normalized
            .replacingOccurrences(of: "٫", with: ".")
            .replacingOccurrences(of: ",", with: ".")

        return Double(normalized)
    }

    private static func valid(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value > 0 else {
            return nil
        }
        return value
    }
}

struct ChargingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let batteryPercentage: Int?
        let batteryPercentageDecimal: Double?
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
        batteryPercentageDecimal = snapshot.apiPercentage
        chargingState = snapshot.state
        lastUpdatedAt = snapshot.observedAt
        displayMessage = message ?? snapshot.state.displayName
        self.languageIdentifier = languageIdentifier
    }
}
