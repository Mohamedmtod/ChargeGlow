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

        let clamped = min(max(Double(level), 0), 1)
        let percentage = Int((clamped * 100).rounded())
        return min(max(percentage, 0), 100)
    }

    static func normalizeAPILevel(level: Float) -> Double? {
        guard level >= 0 else {
            return nil
        }

        let clamped = min(max(Double(level), 0), 1)
        return (clamped * 1_000).rounded() / 10
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
        let level = UIDevice.current.batteryLevel
        return BatterySnapshot(
            percentage: normalize(level: level),
            apiPercentage: normalizeAPILevel(level: level),
            state: map(state: UIDevice.current.batteryState),
            observedAt: Date()
        )
    }
}

enum ChargingTestPhase: String, Equatable, Sendable {
    case idle
    case running
    case completed
}

enum ChargingTestCompletionReason: String, Equatable, Sendable {
    case manual
    case disconnected
    case fullyCharged
    case appInactive
}

enum ChargingTestConfidence: String, Equatable, Sendable {
    case insufficient
    case indicative
    case strong
}

struct ChargingSessionSample: Equatable, Sendable {
    let percentage: Double
    let observedAt: Date
}

struct ChargingSessionTest: Equatable, Sendable {
    private(set) var phase: ChargingTestPhase = .idle
    private(set) var samples: [ChargingSessionSample] = []
    private(set) var endedAt: Date?
    private(set) var completionReason: ChargingTestCompletionReason?

    var startedAt: Date? {
        samples.first?.observedAt
    }

    var latestPercentage: Double? {
        samples.last?.percentage
    }

    var startPercentage: Double? {
        samples.first?.percentage
    }

    var gainedPercentagePoints: Double? {
        guard
            let startPercentage,
            let latestPercentage
        else {
            return nil
        }
        return max(latestPercentage - startPercentage, 0)
    }

    var sampleCount: Int {
        samples.count
    }

    var measurementDuration: TimeInterval {
        guard
            let startedAt,
            let latestObservation = samples.last?.observedAt
        else {
            return 0
        }
        let endpoint = endedAt ?? latestObservation
        return max(endpoint.timeIntervalSince(startedAt), 0)
    }

    var observedPercentagePointsPerHour: Double? {
        guard
            measurementDuration >= 300,
            samples.count >= 2,
            let gainedPercentagePoints,
            gainedPercentagePoints > 0
        else {
            return nil
        }

        let origin = samples[0].observedAt
        let points = samples.map {
            (
                x: $0.observedAt.timeIntervalSince(origin) / 3_600,
                y: $0.percentage
            )
        }
        let meanX =
            points.reduce(0) { $0 + $1.x } / Double(points.count)
        let meanY =
            points.reduce(0) { $0 + $1.y } / Double(points.count)
        let numerator = points.reduce(0) {
            $0 + ($1.x - meanX) * ($1.y - meanY)
        }
        let denominator = points.reduce(0) {
            $0 + pow($1.x - meanX, 2)
        }

        guard denominator > 0 else {
            return nil
        }
        return max(numerator / denominator, 0)
    }

    var confidence: ChargingTestConfidence {
        guard let gainedPercentagePoints else {
            return .insufficient
        }
        if
            measurementDuration >= 1_200,
            gainedPercentagePoints >= 4,
            sampleCount >= 10
        {
            return .strong
        }
        if
            measurementDuration >= 600,
            gainedPercentagePoints >= 2,
            sampleCount >= 5
        {
            return .indicative
        }
        return .insufficient
    }

    func elapsed(at date: Date) -> TimeInterval {
        guard let startedAt else {
            return 0
        }
        return max((endedAt ?? date).timeIntervalSince(startedAt), 0)
    }

    mutating func start(with snapshot: BatterySnapshot) -> Bool {
        guard
            snapshot.state == .charging,
            let percentage = snapshot.mostDetailedPercentage
        else {
            return false
        }

        phase = .running
        samples = [
            ChargingSessionSample(
                percentage: percentage,
                observedAt: snapshot.observedAt
            )
        ]
        endedAt = nil
        completionReason = nil
        return true
    }

    mutating func observe(_ snapshot: BatterySnapshot) {
        guard phase == .running else {
            return
        }

        if let percentage = snapshot.mostDetailedPercentage {
            appendSample(
                percentage: percentage,
                observedAt: snapshot.observedAt
            )
        }

        switch snapshot.state {
        case .disconnected:
            complete(
                at: snapshot.observedAt,
                reason: .disconnected
            )
        case .full:
            complete(
                at: snapshot.observedAt,
                reason: .fullyCharged
            )
        case .unknown, .charging:
            break
        }
    }

    mutating func stop(
        at date: Date,
        reason: ChargingTestCompletionReason = .manual
    ) {
        guard phase == .running else {
            return
        }
        complete(at: date, reason: reason)
    }

    mutating func reset() {
        self = ChargingSessionTest()
    }

    private mutating func appendSample(
        percentage: Double,
        observedAt: Date
    ) {
        guard
            let latestSample = samples.last,
            observedAt >= latestSample.observedAt
        else {
            return
        }

        let interval = observedAt.timeIntervalSince(
            latestSample.observedAt
        )
        guard interval >= 20 || percentage != latestSample.percentage else {
            return
        }

        samples.append(
            ChargingSessionSample(
                percentage: percentage,
                observedAt: observedAt
            )
        )
    }

    private mutating func complete(
        at date: Date,
        reason: ChargingTestCompletionReason
    ) {
        phase = .completed
        endedAt = max(date, startedAt ?? date)
        completionReason = reason
    }
}

@MainActor
final class BatteryMonitor: ObservableObject {
    private static let foregroundPollInterval: Duration = .seconds(30)

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
        let level = UIDevice.current.batteryLevel
        snapshot = BatterySnapshot(
            percentage: BatteryReader.normalize(level: level),
            apiPercentage: BatteryReader.normalizeAPILevel(level: level),
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
