import Combine
import Foundation
import UIKit

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
    @Published private(set) var snapshot = BatterySnapshot(
        percentage: nil,
        state: .unknown,
        observedAt: Date()
    )

    var onSnapshot: ((BatterySnapshot) -> Void)?

    private var observerTasks: [Task<Void, Never>] = []

    func start() {
        guard observerTasks.isEmpty else {
            return
        }

        UIDevice.current.isBatteryMonitoringEnabled = true
        publishCurrent()

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
                    self?.publishCurrent()
                }
            }
        }
    }

    func refresh() {
        publishCurrent()
    }

    func stop() {
        observerTasks.forEach { $0.cancel() }
        observerTasks.removeAll()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    private func publishCurrent() {
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
                message: "Battery snapshot observed while the app had execution time.",
                snapshot: observedSnapshot
            )
        }
        onSnapshot?(snapshot)
    }
}
