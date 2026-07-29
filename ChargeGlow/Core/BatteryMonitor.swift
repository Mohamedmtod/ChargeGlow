import Combine
import Foundation
import UIKit

protocol BatterySnapshotProviding: Sendable {
    func capture() async -> BatterySnapshot
}

struct SystemBatterySnapshotProvider: BatterySnapshotProviding {
    func capture() async -> BatterySnapshot {
        await BatteryReader.capture()
    }
}

enum BatteryReader {
    @MainActor
    static func capture() async -> BatterySnapshot {
        UIDevice.current.isBatteryMonitoringEnabled = true

        var snapshot = currentSnapshot()
        if snapshot.percentage == nil {
            await Task.yield()
            snapshot = currentSnapshot()
        }
        return snapshot
    }

    static func normalize(level: Float) -> Int? {
        guard level >= 0 else {
            return nil
        }

        let percentage = Int((level * 100).rounded())
        return min(max(percentage, 0), 100)
    }

    static func map(state: UIDevice.BatteryState) -> ChargingState {
        switch state {
        case .unknown:
            return .unknown
        case .unplugged:
            return .disconnected
        case .charging:
            return .charging
        case .full:
            return .full
        @unknown default:
            return .unknown
        }
    }

    @MainActor
    private static func currentSnapshot() -> BatterySnapshot {
        BatterySnapshot(
            percentage: normalize(level: UIDevice.current.batteryLevel),
            state: map(state: UIDevice.current.batteryState),
            observedAt: Date()
        )
    }
}

@MainActor
final class BatteryMonitor: ObservableObject {
    private static let foregroundPollInterval: Duration = .seconds(60)

    @Published private(set) var snapshot = BatterySnapshot(
        percentage: nil,
        state: .unknown,
        observedAt: Date()
    )

    var onSnapshot: ((BatterySnapshot) -> Void)?

    private var observerTasks: [Task<Void, Never>] = []
    private var foregroundPollingTask: Task<Void, Never>?

    func start() {
        guard observerTasks.isEmpty else {
            return
        }

        UIDevice.current.isBatteryMonitoringEnabled = true
        publishCurrent(trigger: "monitor start")

        let notifications = [
            UIDevice.batteryLevelDidChangeNotification,
            UIDevice.batteryStateDidChangeNotification
        ]

        observerTasks = notifications.map { name in
            Task { @MainActor [weak self] in
                for await _ in NotificationCenter.default.notifications(named: name) {
                    guard !Task.isCancelled else {
                        return
                    }
                    let trigger = name == UIDevice.batteryLevelDidChangeNotification
                        ? "battery-level notification"
                        : "battery-state notification"
                    self?.publishCurrent(trigger: trigger)
                }
            }
        }
        startForegroundPolling()
    }

    func refresh() {
        publishCurrent(trigger: "manual refresh")
    }

    func setApplicationActive(_ isActive: Bool) {
        guard !observerTasks.isEmpty else {
            return
        }

        if isActive {
            publishCurrent(trigger: "foreground activation")
            startForegroundPolling()
        } else {
            stopForegroundPolling()
        }
    }

    func stop() {
        observerTasks.forEach { $0.cancel() }
        observerTasks.removeAll()
        stopForegroundPolling()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    private func startForegroundPolling() {
        guard foregroundPollingTask == nil else {
            return
        }

        foregroundPollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: Self.foregroundPollInterval)
                } catch {
                    return
                }

                guard !Task.isCancelled else {
                    return
                }
                self?.publishCurrent(trigger: "foreground poll")
            }
        }
    }

    private func stopForegroundPolling() {
        foregroundPollingTask?.cancel()
        foregroundPollingTask = nil
    }

    private func publishCurrent(trigger: String) {
        snapshot = BatterySnapshot(
            percentage: BatteryReader.normalize(level: UIDevice.current.batteryLevel),
            state: BatteryReader.map(state: UIDevice.current.batteryState),
            observedAt: Date()
        )
        let observedSnapshot = snapshot
        Task {
            await DiagnosticsRecorder.shared.record(
                category: "battery",
                level: .debug,
                message: "Public iOS battery snapshot observed via \(trigger).",
                snapshot: observedSnapshot
            )
        }
        onSnapshot?(snapshot)
    }
}
