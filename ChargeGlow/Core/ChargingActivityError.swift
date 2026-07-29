import Foundation

enum ChargingActivityError: Error, Equatable, LocalizedError, Sendable {
    case liveActivitiesNotAuthorized
    case batteryUnavailable
    case activityAlreadyRunning
    case noActiveActivity
    case activityStartFailed
    case activityUpdateFailed
    case activityEndFailed

    var diagnosticCode: String {
        switch self {
        case .liveActivitiesNotAuthorized:
            return "CG-ACT-001"
        case .batteryUnavailable:
            return "CG-BAT-001"
        case .activityAlreadyRunning:
            return "CG-ACT-002"
        case .noActiveActivity:
            return "CG-ACT-003"
        case .activityStartFailed:
            return "CG-ACT-004"
        case .activityUpdateFailed:
            return "CG-ACT-005"
        case .activityEndFailed:
            return "CG-ACT-006"
        }
    }

    var errorDescription: String? {
        switch self {
        case .liveActivitiesNotAuthorized:
            return String(
                localized: "Live Activities are disabled. Enable them in Settings and try again."
            )
        case .batteryUnavailable:
            return String(
                localized: "The battery level is currently unavailable. ChargeGlow will never estimate it."
            )
        case .activityAlreadyRunning:
            return String(localized: "A ChargeGlow Live Activity is already running.")
        case .noActiveActivity:
            return String(
                localized: "There is no ChargeGlow Live Activity to update or stop."
            )
        case .activityStartFailed:
            return String(localized: "ChargeGlow could not start the Live Activity.")
        case .activityUpdateFailed:
            return String(localized: "ChargeGlow could not update the Live Activity.")
        case .activityEndFailed:
            return String(localized: "ChargeGlow could not end the Live Activity.")
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .liveActivitiesNotAuthorized:
            return String(
                localized: "Open Settings, select ChargeGlow, and enable Live Activities."
            )
        case .batteryUnavailable:
            return String(
                localized: "Unlock the device, open ChargeGlow once, and retry the automation."
            )
        case .activityAlreadyRunning:
            return String(
                localized: "Use Stop Charging Theme before starting another activity."
            )
        case .noActiveActivity:
            return String(localized: "Run Start Charging Theme first.")
        case .activityStartFailed, .activityUpdateFailed, .activityEndFailed:
            return String(
                localized: "Export diagnostics, then retry after reopening ChargeGlow."
            )
        }
    }
}
