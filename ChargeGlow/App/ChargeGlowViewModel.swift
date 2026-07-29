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
    @Published private(set) var statusMessage = "Run the physical-device spike before continuing."
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
                try? await ChargingActivityManager.shared.update(snapshot: snapshot)
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
            do {
                _ = try await ChargingActivityManager.shared.start(snapshot: snapshot)
                statusMessage = snapshot.percentage == nil
                    ? "Started, but iOS did not provide a battery percentage."
                    : "Live Activity started with a real battery snapshot."
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
            let result = await ChargingActivityManager.shared.endAll(snapshot: snapshot)
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
