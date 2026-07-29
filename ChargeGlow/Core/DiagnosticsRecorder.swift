import Foundation
import OSLog

enum DiagnosticLevel: String, Sendable {
    case debug
    case info
    case error
    case fault
}

struct DiagnosticEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let category: String
    let level: String
    let message: String
    let diagnosticCode: String?
}

actor DiagnosticsRecorder {
    static let shared = DiagnosticsRecorder()

    private let subsystem = "com.mohamedalaa.chargeglow.spike"
    private let maximumEvents = 500
    private var events: [DiagnosticEvent] = []
    private var hasLoadedEvents = false

    func record(
        category: String,
        level: DiagnosticLevel = .info,
        message: String,
        diagnosticCode: String? = nil
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        switch level {
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.critical("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        }

        loadEventsIfNeeded()
        events.append(
            DiagnosticEvent(
                id: UUID(),
                timestamp: Date(),
                category: category,
                level: level.rawValue,
                message: message,
                diagnosticCode: diagnosticCode
            )
        )

        if events.count > maximumEvents {
            events.removeFirst(events.count - maximumEvents)
        }

        persistEvents()
    }

    func exportURL() -> URL? {
        loadEventsIfNeeded()
        persistEvents()
        return try? diagnosticsURL()
    }

    private func loadEventsIfNeeded() {
        guard !hasLoadedEvents else {
            return
        }
        hasLoadedEvents = true

        guard
            let url = try? diagnosticsURL(),
            let data = try? Data(contentsOf: url)
        else {
            return
        }

        events = (try? JSONDecoder.chargeGlow.decode([DiagnosticEvent].self, from: data)) ?? []
    }

    private func persistEvents() {
        guard
            let url = try? diagnosticsURL(),
            let data = try? JSONEncoder.chargeGlow.encode(events)
        else {
            return
        }

        try? data.write(to: url, options: .atomic)
    }

    private func diagnosticsURL() throws -> URL {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("ChargeGlow", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory.appendingPathComponent("diagnostics.json")
    }
}

private extension JSONEncoder {
    static var chargeGlow: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var chargeGlow: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
