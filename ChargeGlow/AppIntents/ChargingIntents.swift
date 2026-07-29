import AppIntents
import Foundation

struct StartChargingThemeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Charging Theme"
    static let description = IntentDescription(
        "Starts the selected ChargeGlow Live Activity using the current public iOS battery reading."
    )

    func perform() async -> some IntentResult & ProvidesDialog {
        let correlationID = UUID().uuidString
        let countBeforeStart = await ChargingActivityManager.shared.activeActivityCount()
        await DiagnosticsRecorder.shared.record(
            category: "intents",
            message: "Start Charging Theme intent invoked.",
            correlationID: correlationID,
            activeActivityCount: countBeforeStart
        )

        let snapshot = await BatteryReader.capture()
        await DiagnosticsRecorder.shared.record(
            category: "intents",
            level: .debug,
            message: "Start intent captured a battery snapshot.",
            correlationID: correlationID,
            snapshot: snapshot,
            activeActivityCount: countBeforeStart
        )

        do {
            let activityID = try await ChargingActivityManager.shared.start(
                snapshot: snapshot,
                correlationID: correlationID
            )
            await DiagnosticsRecorder.shared.record(
                category: "intents",
                message: "Start intent completed with activity \(activityID).",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: 1
            )
            if snapshot.percentage == nil {
                await DiagnosticsRecorder.shared.record(
                    category: "battery",
                    level: .error,
                    message: "Start intent received an unavailable battery level.",
                    diagnosticCode: ChargingActivityError.batteryUnavailable.diagnosticCode,
                    correlationID: correlationID,
                    snapshot: snapshot,
                    activeActivityCount: 1
                )
                return .result(
                    dialog: "ChargeGlow started, but iOS did not provide a battery percentage."
                )
            }
            return .result(dialog: "ChargeGlow started with the current iOS battery reading.")
        } catch let error as ChargingActivityError {
            let countAfterFailure = await ChargingActivityManager.shared.activeActivityCount()
            await DiagnosticsRecorder.shared.record(
                category: "intents",
                level: .error,
                message: "Start intent finished with \(error.diagnosticCode).",
                diagnosticCode: error.diagnosticCode,
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: countAfterFailure
            )
            switch error {
            case .liveActivitiesNotAuthorized:
                return .result(
                    dialog: "Live Activities are disabled. Enable them in Settings, then try again."
                )
            case .activityAlreadyRunning:
                return .result(dialog: "ChargeGlow is already running.")
            default:
                return .result(
                    dialog: "ChargeGlow could not start. Open the app and export diagnostics."
                )
            }
        } catch {
            await DiagnosticsRecorder.shared.record(
                category: "intents",
                level: .error,
                message: "Start intent finished with an unexpected error.",
                diagnosticCode: ChargingActivityError.activityStartFailed.diagnosticCode,
                correlationID: correlationID,
                snapshot: snapshot
            )
            return .result(
                dialog: "ChargeGlow could not start. Open the app and export diagnostics."
            )
        }
    }
}
struct StopChargingThemeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Charging Theme"
    static let description = IntentDescription(
        "Ends every ChargeGlow Live Activity. Repeating this action is safe."
    )

    func perform() async -> some IntentResult & ProvidesDialog {
        let correlationID = UUID().uuidString
        let countBeforeStop = await ChargingActivityManager.shared.activeActivityCount()
        await DiagnosticsRecorder.shared.record(
            category: "intents",
            message: "Stop Charging Theme intent invoked.",
            correlationID: correlationID,
            activeActivityCount: countBeforeStop
        )

        let snapshot = await BatteryReader.capture()
        await DiagnosticsRecorder.shared.record(
            category: "intents",
            level: .debug,
            message: "Stop intent captured a battery snapshot.",
            correlationID: correlationID,
            snapshot: snapshot,
            activeActivityCount: countBeforeStop
        )
        let result = await ChargingActivityManager.shared.endAll(
            snapshot: snapshot,
            correlationID: correlationID
        )

        switch result {
        case .ended(let count):
            await DiagnosticsRecorder.shared.record(
                category: "intents",
                message: "Stop intent completed and ended \(count) activities.",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: 0
            )
            return .result(dialog: "ChargeGlow stopped.")
        case .nothingToEnd:
            await DiagnosticsRecorder.shared.record(
                category: "intents",
                message: "Stop intent completed with nothing to end.",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: 0
            )
            return .result(dialog: "ChargeGlow was already stopped.")
        }
    }
}

struct ChargeGlowShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartChargingThemeIntent(),
            phrases: [
                "Start \(.applicationName)",
                "Start my charging theme with \(.applicationName)"
            ],
            shortTitle: "Start Charging Theme",
            systemImageName: "bolt.circle.fill"
        )

        AppShortcut(
            intent: StopChargingThemeIntent(),
            phrases: [
                "Stop \(.applicationName)",
                "Stop my charging theme with \(.applicationName)"
            ],
            shortTitle: "Stop Charging Theme",
            systemImageName: "bolt.slash.circle"
        )
    }
}
