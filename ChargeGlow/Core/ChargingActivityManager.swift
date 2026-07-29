import ActivityKit
import Foundation
import OSLog

struct ActivityRecoveryResult: Equatable, Sendable {
    let retainedActivityID: String?
    let endedDuplicateCount: Int
}

enum ActivityEndResult: Equatable, Sendable {
    case ended(count: Int)
    case nothingToEnd
}

protocol ChargingActivityManaging: Sendable {
    func recover(correlationID: String?) async -> ActivityRecoveryResult
    func start(
        snapshot: BatterySnapshot,
        correlationID: String?
    ) async throws -> String
    func update(
        snapshot: BatterySnapshot,
        correlationID: String?
    ) async throws
    func endAll(
        snapshot: BatterySnapshot?,
        correlationID: String?
    ) async -> ActivityEndResult
    func activeActivityCount() async -> Int
}

actor ChargingActivityManager: ChargingActivityManaging {
    static let shared = ChargingActivityManager()

    private typealias ChargingActivity = Activity<ChargingActivityAttributes>

    func recover(correlationID: String? = nil) async -> ActivityRecoveryResult {
        let activities = ChargingActivity.activities
        await DiagnosticsRecorder.shared.record(
            category: "activity",
            level: .debug,
            message: "Recovery inspected \(activities.count) active activities.",
            correlationID: correlationID,
            activeActivityCount: activities.count
        )
        let descriptors = activities.map {
            ActivityDescriptor(id: $0.id, startDate: $0.attributes.startDate)
        }
        let plan = ActivityLifecyclePlanner.recoveryPlan(for: descriptors)

        for activity in activities where plan.IDsToEnd.contains(activity.id) {
            let finalState = ChargingActivityAttributes.ContentState(
                batteryPercentage: activity.content.state.batteryPercentage,
                chargingState: .disconnected,
                lastUpdatedAt: Date(),
                displayMessage: String(
                    localized: "Duplicate activity ended during recovery"
                ),
                languageIdentifier:
                    activity.content.state.languageIdentifier
            )
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        if !plan.IDsToEnd.isEmpty {
            await DiagnosticsRecorder.shared.record(
                category: "activity",
                level: .error,
                message: "Recovery ended \(plan.IDsToEnd.count) duplicate activities.",
                correlationID: correlationID,
                activeActivityCount: 1
            )
        }

        return ActivityRecoveryResult(
            retainedActivityID: plan.retainedID,
            endedDuplicateCount: plan.IDsToEnd.count
        )
    }

    func start(
        snapshot: BatterySnapshot,
        correlationID: String? = nil
    ) async throws -> String {
        _ = await recover(correlationID: correlationID)

        do {
            try ActivityLifecyclePlanner.validateStart(
                authorized: ActivityAuthorizationInfo().areActivitiesEnabled,
                existingActivities: ChargingActivity.activities.map {
                    ActivityDescriptor(id: $0.id, startDate: $0.attributes.startDate)
                }
            )
        } catch let error as ChargingActivityError {
            await record(
                error: error,
                operation: "start",
                correlationID: correlationID
            )
            throw error
        } catch {
            await record(
                error: .activityStartFailed,
                operation: "start",
                correlationID: correlationID
            )
            throw ChargingActivityError.activityStartFailed
        }

        let languageIdentifier =
            await selectedLanguageIdentifier()
        let selectedTheme =
            await AppPreferencesStore.shared.selectedTheme()
        let attributes = ChargingActivityAttributes(
            sessionID: UUID().uuidString,
            themeID: selectedTheme.rawValue,
            startDate: Date()
        )
        let content = ActivityContent(
            state: ChargingActivityAttributes.ContentState(
                snapshot: snapshot,
                languageIdentifier: languageIdentifier
            ),
            staleDate: snapshot.liveActivityStaleDate
        )

        do {
            let activity = try ChargingActivity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            await DiagnosticsRecorder.shared.record(
                category: "activity",
                message: "Started Live Activity \(activity.id).",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: 1
            )
            return activity.id
        } catch {
            await record(
                error: .activityStartFailed,
                operation: "start",
                correlationID: correlationID
            )
            throw ChargingActivityError.activityStartFailed
        }
    }

    func update(
        snapshot: BatterySnapshot,
        correlationID: String? = nil
    ) async throws {
        let recovery = await recover(correlationID: correlationID)
        guard
            let activeID = recovery.retainedActivityID,
            let activity = ChargingActivity.activities.first(where: { $0.id == activeID })
        else {
            throw ChargingActivityError.noActiveActivity
        }

        let current = activity.content.state
        let languageIdentifier =
            await selectedLanguageIdentifier()
        guard
            current.languageIdentifier != languageIdentifier
                || ActivityLifecyclePlanner.shouldUpdateActivity(
                currentPercentage: current.batteryPercentage,
                currentState: current.chargingState,
                lastUpdatedAt: current.lastUpdatedAt,
                with: snapshot
            )
        else {
            await DiagnosticsRecorder.shared.record(
                category: "activity",
                level: .debug,
                message: "Activity update skipped because the snapshot was unchanged.",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: 1
            )
            return
        }

        let content = ActivityContent(
            state: ChargingActivityAttributes.ContentState(
                snapshot: snapshot,
                languageIdentifier: languageIdentifier
            ),
            staleDate: snapshot.liveActivityStaleDate
        )
        await activity.update(content)
        await DiagnosticsRecorder.shared.record(
            category: "activity",
            level: .debug,
            message: "Updated Live Activity \(activity.id) with a public iOS battery snapshot.",
            correlationID: correlationID,
            snapshot: snapshot,
            activeActivityCount: 1
        )
    }

    func endAll(
        snapshot: BatterySnapshot? = nil,
        correlationID: String? = nil
    ) async -> ActivityEndResult {
        let activities = ChargingActivity.activities
        let IDs = ActivityLifecyclePlanner.IDsToEnd(
            for: activities.map {
                ActivityDescriptor(id: $0.id, startDate: $0.attributes.startDate)
            }
        )

        guard !IDs.isEmpty else {
            await DiagnosticsRecorder.shared.record(
                category: "activity",
                message: "Stop requested with no active ChargeGlow activities.",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: 0
            )
            return .nothingToEnd
        }

        for activity in activities {
            let finalState = ChargingActivityAttributes.ContentState(
                batteryPercentage: snapshot?.percentage ?? activity.content.state.batteryPercentage,
                chargingState: .disconnected,
                lastUpdatedAt: snapshot?.observedAt ?? Date(),
                displayMessage: String(localized: "Charger disconnected"),
                languageIdentifier:
                    activity.content.state.languageIdentifier
            )
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        await DiagnosticsRecorder.shared.record(
            category: "activity",
            message: "Ended \(activities.count) ChargeGlow activities.",
            correlationID: correlationID,
            snapshot: snapshot,
            activeActivityCount: 0
        )
        return .ended(count: activities.count)
    }

    func activeActivityCount() async -> Int {
        ChargingActivity.activities.count
    }

    private func selectedLanguageIdentifier() async -> String {
        let appLanguage =
            await AppPreferencesStore.shared.appLanguage()
        return appLanguage.languageIdentifier
    }

    private func record(
        error: ChargingActivityError,
        operation: String,
        correlationID: String?
    ) async {
        await DiagnosticsRecorder.shared.record(
            category: "activity",
            level: .error,
            message: "\(operation) failed: \(error.localizedDescription)",
            diagnosticCode: error.diagnosticCode,
            correlationID: correlationID,
            activeActivityCount: ChargingActivity.activities.count
        )
    }
}
