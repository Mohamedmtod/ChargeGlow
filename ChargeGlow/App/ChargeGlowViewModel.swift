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
    @Published private(set) var statusMessage = String(
        localized: "Ready to start a charging Live Activity."
    )
    @Published private(set) var diagnosticCode: String?
    @Published private(set) var diagnosticsURL: URL?
    @Published private(set) var isWorking = false

    let batteryMonitor: BatteryMonitor
    private let batterySnapshotProvider: any BatterySnapshotProviding
    private let activityManager: any ChargingActivityManaging

    init(
        batteryMonitor: BatteryMonitor = BatteryMonitor(),
        batterySnapshotProvider: any BatterySnapshotProviding =
            SystemBatterySnapshotProvider(),
        activityManager: any ChargingActivityManaging =
            ChargingActivityManager.shared
    ) {
        self.batteryMonitor = batteryMonitor
        self.batterySnapshotProvider = batterySnapshotProvider
        self.activityManager = activityManager
    }

    var activityStatus: String {
        switch activeActivityCount {
        case 0:
            return String(localized: "Stopped")
        case 1:
            return String(localized: "Running")
        default:
            return String(
                format: String(localized: "%lld activities (recovery required)"),
                locale: Locale.current,
                activeActivityCount
            )
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
                    await self.activityManager.activeActivityCount()

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
                    let result = await self.activityManager.endAll(
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
                    try? await self.activityManager.update(
                        snapshot: snapshot,
                        correlationID: nil
                    )
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
            let freshSnapshot = await batterySnapshotProvider.capture()
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
                _ = try await activityManager.start(
                    snapshot: freshSnapshot,
                    correlationID: correlationID
                )
                statusMessage = freshSnapshot.percentage == nil
                    ? String(
                        localized: "Started, but iOS did not provide a battery percentage."
                    )
                    : String(
                        localized: "Live Activity started with the latest public iOS battery reading."
                    )
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
            let result = await activityManager.endAll(
                snapshot: snapshot,
                correlationID: correlationID
            )
            switch result {
            case .ended(let count):
                statusMessage = String(
                    format: String(localized: "Ended %lld ChargeGlow Live Activity."),
                    locale: Locale.current,
                    count
                )
            case .nothingToEnd:
                statusMessage = String(localized: "ChargeGlow was already stopped.")
            }
            await refreshStatus()
            isWorking = false
        }
    }

    func prepareDiagnosticsExport() {
        Task {
            diagnosticsURL = await DiagnosticsRecorder.shared.exportURL()
            if diagnosticsURL == nil {
                statusMessage = String(
                    localized: "Diagnostics export could not be prepared."
                )
            }
        }
    }

    private func refreshStatus() async {
        liveActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        _ = await activityManager.recover(correlationID: nil)
        activeActivityCount = await activityManager.activeActivityCount()
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
