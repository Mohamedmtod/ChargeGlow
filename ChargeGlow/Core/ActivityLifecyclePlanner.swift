import Foundation

struct ActivityDescriptor: Equatable, Sendable {
    let id: String
    let startDate: Date
}

struct ActivityRecoveryPlan: Equatable, Sendable {
    let retainedID: String?
    let IDsToEnd: [String]
}

enum ActivityLifecyclePlanner {
    static func recoveryPlan(
        for activities: [ActivityDescriptor]
    ) -> ActivityRecoveryPlan {
        let sorted = activities.sorted { lhs, rhs in
            if lhs.startDate == rhs.startDate {
                return lhs.id < rhs.id
            }
            return lhs.startDate > rhs.startDate
        }

        return ActivityRecoveryPlan(
            retainedID: sorted.first?.id,
            IDsToEnd: Array(sorted.dropFirst().map(\.id))
        )
    }

    static func validateStart(
        authorized: Bool,
        existingActivities: [ActivityDescriptor]
    ) throws {
        guard authorized else {
            throw ChargingActivityError.liveActivitiesNotAuthorized
        }

        guard existingActivities.isEmpty else {
            throw ChargingActivityError.activityAlreadyRunning
        }
    }

    static func IDsToEnd(
        for activities: [ActivityDescriptor]
    ) -> [String] {
        activities.map(\.id)
    }

    static func shouldEndForBatteryState(
        _ state: ChargingState,
        activeActivityCount: Int
    ) -> Bool {
        state == .disconnected && activeActivityCount > 0
    }
}
