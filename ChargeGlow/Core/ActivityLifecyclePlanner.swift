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
    static let minimumSameValueRefreshInterval: TimeInterval = 5

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

    static func shouldUpdateActivity(
        currentPercentage: Int?,
        currentDecimalPercentage: Double?,
        currentState: ChargingState,
        lastUpdatedAt: Date,
        with snapshot: BatterySnapshot
    ) -> Bool {
        let currentDetailedPercentage =
            currentDecimalPercentage
                ?? currentPercentage.map { Double($0) }

        return currentPercentage != snapshot.percentage
            || currentDetailedPercentage
                != snapshot.mostDetailedPercentage
            || currentState != snapshot.state
            || snapshot.observedAt.timeIntervalSince(lastUpdatedAt)
                >= minimumSameValueRefreshInterval
    }
}
