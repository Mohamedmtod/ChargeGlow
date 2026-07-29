import ActivityKit
import Combine
import Foundation

@MainActor
final class ChargeGlowViewModel: ObservableObject {
    @Published private(set) var snapshot = BatterySnapshot(
        percentage: nil,
        state: .unknown,
        observedAt: Date()
    )
    @Published private(set) var liveActivitiesEnabled = false
    @Published private(set) var activeActivityCount = 0
    @Published private(set) var statusMessage = "Ready to start a charging Live Activity."
    @Published private(set) var diagnosticCode: String?
    @Published private(set) var diagnosticsURL: URL?
    @Published private(set) var isWorking = false

    let batteryMonitor = BatteryMonitor()

    var activityStatus: String {
        switch activeActivityCount {
        case 0:
            return "Stopped"
        case 1:
            return "Running"
        default:
            return "\(activeActivityCount) activities (recovery required)"
        }
    }

    func startMonitoring() {
        batteryMonitor.onSnapshot = { [weak self] snapshot in
            guard let self else {
                return
            }
            self.snapshot = snapshot
            Task {
                let activityCount =
                    await ChargingActivityManager.shared.activeActivityCount()

                if ActivityLifecyclePlanner.shouldEndForBatteryState(
                    snapshot.state,
                    activeActivityCount: activityCount
                ) {
                    let correlationID = UUID().uuidString
                    await DiagnosticsRecorder.shared.record(
                        category: "fallback",
                        message: "Observed charger disconnection; ending the active activity.",
                        correlationID: correlationID,
                        snapshot: snapshot,
                        activeActivityCount: activityCount
                    )
                    let result = await ChargingActivityManager.shared.endAll(
                        snapshot: snapshot,
                        correlationID: correlationID
                    )
                    await DiagnosticsRecorder.shared.record(
                        category: "fallback",
                        message: result.diagnosticMessage,
                        correlationID: correlationID,
                        snapshot: snapshot,
                        activeActivityCount: 0
                    )
                } else {
                    try? await ChargingActivityManager.shared.update(snapshot: snapshot)
                }
                await self.refreshStatus()
            }
        }
        batteryMonitor.start()

        Task {
            await refreshStatus()
            await DiagnosticsRecorder.shared.record(
                category: "app",
                message: "ChargeGlow launched."
            )
        }
    }

    func stopMonitoring() {
        batteryMonitor.stop()
    }

    func setApplicationActive(_ isActive: Bool) {
        batteryMonitor.setApplicationActive(isActive)
    }

    func refresh() {
        batteryMonitor.refresh()
        Task {
            await refreshStatus()
        }
    }

    func startActivity() {
        guard !isWorking else {
            return
        }
        isWorking = true
        diagnosticCode = nil

        Task {
            let freshSnapshot = await BatteryReader.capture()
            snapshot = freshSnapshot
            let correlationID = UUID().uuidString
            await DiagnosticsRecorder.shared.record(
                category: "ui",
                message: "Manual Start button tapped.",
                correlationID: correlationID,
                snapshot: freshSnapshot,
                activeActivityCount: activeActivityCount
            )
            do {
                _ = try await ChargingActivityManager.shared.start(
                    snapshot: freshSnapshot,
                    correlationID: correlationID
                )
                statusMessage = freshSnapshot.percentage == nil
                    ? "Started, but iOS did not provide a battery percentage."
                    : "Live Activity started with the latest public iOS battery reading."
            } catch let error as ChargingActivityError {
                show(error)
            } catch {
                show(.activityStartFailed)
            }
            await refreshStatus()
            isWorking = false
        }
    }

    func stopActivity() {
        guard !isWorking else {
            return
        }
        isWorking = true
        diagnosticCode = nil

        Task {
            let correlationID = UUID().uuidString
            await DiagnosticsRecorder.shared.record(
                category: "ui",
                message: "Manual Stop button tapped.",
                correlationID: correlationID,
                snapshot: snapshot,
                activeActivityCount: activeActivityCount
            )
            let result = await ChargingActivityManager.shared.endAll(
                snapshot: snapshot,
                correlationID: correlationID
            )
            switch result {
            case .ended(let count):
                statusMessage = "Ended \(count) ChargeGlow Live Activity."
            case .nothingToEnd:
                statusMessage = "ChargeGlow was already stopped."
            }
            await refreshStatus()
            isWorking = false
        }
    }

    func prepareDiagnosticsExport() {
        Task {
            diagnosticsURL = await DiagnosticsRecorder.shared.exportURL()
            if diagnosticsURL == nil {
                statusMessage = "Diagnostics export could not be prepared."
            }
        }
    }

    private func refreshStatus() async {
        liveActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        _ = await ChargingActivityManager.shared.recover()
        activeActivityCount = await ChargingActivityManager.shared.activeActivityCount()
    }

    private func show(_ error: ChargingActivityError) {
        statusMessage = "\(error.localizedDescription) \(error.recoverySuggestion)"
        diagnosticCode = error.diagnosticCode
    }
}

private extension ActivityEndResult {
    var diagnosticMessage: String {
        switch self {
        case .ended(let count):
            return "Disconnect fallback ended \(count) activities."
        case .nothingToEnd:
            return "Disconnect fallback found nothing to end."
        }
    }
}
