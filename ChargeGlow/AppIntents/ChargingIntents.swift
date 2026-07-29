import AppIntents
import Foundation
import OSLog

struct StartChargingThemeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Charging Theme"
    static let description = IntentDescription(
        "Starts the selected ChargeGlow Live Activity using the current real battery reading."
    )

    func perform() async -> some IntentResult & ProvidesDialog {
        let snapshot = await BatteryReader.capture()

        do {
            _ = try await ChargingActivityManager.shared.start(snapshot: snapshot)
            if snapshot.percentage == nil {
                await DiagnosticsRecorder.shared.record(
                    category: "battery",
                    level: .error,
                    message: "Start intent received an unavailable battery level.",
                    diagnosticCode: ChargingActivityError.batteryUnavailable.diagnosticCode
                )
                return .result(
                    dialog: "ChargeGlow started, but iOS did not provide a battery percentage."
                )
            }
            return .result(dialog: "ChargeGlow started with the current battery reading.")
        } catch let error as ChargingActivityError {
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
        let snapshot = await BatteryReader.capture()
        let result = await ChargingActivityManager.shared.endAll(snapshot: snapshot)

        switch result {
        case .ended:
            return .result(dialog: "ChargeGlow stopped.")
        case .nothingToEnd:
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
