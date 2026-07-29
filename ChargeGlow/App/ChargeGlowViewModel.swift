import ActivityKit
import Combine
import Foundation

enum ChargeGlowStatus: Equatable {
    case ready
    case startedWithoutPercentage
    case startedWithLatestReading
    case ended(Int)
    case alreadyStopped
    case diagnosticsExportFailed
    case failure(ChargingActivityError)
}

@MainActor
final class ChargeGlowViewModel: ObservableObject {
    @Published private(set) var snapshot = BatterySnapshot(
        percentage: nil,
        state: .unknown,
        observedAt: Date()
    )
    @Published private(set) var liveActivitiesEnabled = false
    @Published private(set) var activeActivityCount = 0
    @Published private(set) var selectedThemeID = ThemeID.neonOrbit
    @Published private(set) var status = ChargeGlowStatus.ready
    @Published private(set) var diagnosticCode: String?
    @Published private(set) var diagnosticsURL: URL?
    @Published private(set) var isWorking = false
    @Published private(set) var chargingSessionTest = ChargingSessionTest()

    let batteryMonitor: BatteryMonitor
    private let batterySnapshotProvider: any BatterySnapshotProviding
    private let activityManager: any ChargingActivityManaging
    private var themePersistenceTask: Task<Void, Never>?

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

    func startMonitoring() {
        batteryMonitor.onSnapshot = { [weak self] snapshot in
            guard let self else {
                return
            }
            self.snapshot = snapshot
            self.observeChargingSessionTest(snapshot)
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
            selectedThemeID =
                await AppPreferencesStore.shared.selectedTheme()
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
        if
            !isActive,
            chargingSessionTest.phase == .running
        {
            batteryMonitor.refresh()
            var test = chargingSessionTest
            test.stop(at: Date(), reason: .appInactive)
            chargingSessionTest = test
            let endingSnapshot = snapshot
            Task {
                await DiagnosticsRecorder.shared.record(
                    category: "charger-test",
                    message: "Charging session test ended because the app left the foreground. \(test.diagnosticSummary)",
                    snapshot: endingSnapshot
                )
            }
        }
        batteryMonitor.setApplicationActive(isActive)
    }

    func refresh() {
        batteryMonitor.refresh()
        Task {
            await refreshStatus()
        }
    }

    @discardableResult
    func startChargingSessionTest() -> Bool {
        batteryMonitor.refresh()
        var test = ChargingSessionTest()
        let startingSnapshot = snapshot
        guard test.start(with: startingSnapshot) else {
            return false
        }
        chargingSessionTest = test
        Task {
            await DiagnosticsRecorder.shared.record(
                category: "charger-test",
                message: "Started foreground charging session test.",
                snapshot: startingSnapshot
            )
        }
        return true
    }

    func stopChargingSessionTest() {
        batteryMonitor.refresh()
        var test = chargingSessionTest
        test.stop(at: Date())
        guard test != chargingSessionTest else {
            return
        }
        chargingSessionTest = test
        let endingSnapshot = snapshot
        Task {
                await DiagnosticsRecorder.shared.record(
                    category: "charger-test",
                    message: "Stopped foreground charging session test manually. \(test.diagnosticSummary)",
                    snapshot: endingSnapshot
                )
        }
    }

    func resetChargingSessionTest() {
        var test = chargingSessionTest
        test.reset()
        chargingSessionTest = test
    }

    func selectTheme(_ themeID: ThemeID) {
        guard themeID != selectedThemeID else {
            return
        }
        selectedThemeID = themeID

        let previousTask = themePersistenceTask
        themePersistenceTask = Task {
            await previousTask?.value
            await AppPreferencesStore.shared.setSelectedTheme(themeID)
        }
    }

    func startActivity() {
        guard !isWorking else {
            return
        }
        isWorking = true
        diagnosticCode = nil
        let pendingThemeSave = themePersistenceTask

        Task {
            await pendingThemeSave?.value
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
                status = freshSnapshot.percentage == nil
                    ? .startedWithoutPercentage
                    : .startedWithLatestReading
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
                status = .ended(count)
            case .nothingToEnd:
                status = .alreadyStopped
            }
            await refreshStatus()
            isWorking = false
        }
    }

    func prepareDiagnosticsExport() {
        Task {
            diagnosticsURL = await DiagnosticsRecorder.shared.exportURL()
            if diagnosticsURL == nil {
                status = .diagnosticsExportFailed
            }
        }
    }

    private func refreshStatus() async {
        liveActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        _ = await activityManager.recover(correlationID: nil)
        activeActivityCount = await activityManager.activeActivityCount()
    }

    private func observeChargingSessionTest(
        _ snapshot: BatterySnapshot
    ) {
        let previousPhase = chargingSessionTest.phase
        var test = chargingSessionTest
        test.observe(snapshot)
        guard test != chargingSessionTest else {
            return
        }
        chargingSessionTest = test

        if
            previousPhase == .running,
            test.phase == .completed
        {
            let reason = test.completionReason?.rawValue ?? "unknown"
            Task {
                await DiagnosticsRecorder.shared.record(
                    category: "charger-test",
                    message: "Charging session test completed: \(reason). \(test.diagnosticSummary)",
                    snapshot: snapshot
                )
            }
        }
    }

    private func show(_ error: ChargingActivityError) {
        status = .failure(error)
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

private extension ChargingSessionTest {
    var diagnosticSummary: String {
        let gain = gainedPercentagePoints.map {
            String(format: "%.2f", $0)
        } ?? "unavailable"
        let rate = observedPercentagePointsPerHour.map {
            String(format: "%.2f", $0)
        } ?? "unavailable"
        return "durationSeconds=\(Int(measurementDuration)); gainPoints=\(gain); samples=\(sampleCount); ratePointsPerHour=\(rate); confidence=\(confidence.rawValue)."
    }
}
