import AppIntents
import SwiftUI

@main
struct ChargeGlowApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ChargeGlowShortcutsProvider.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    let transition = "\(oldPhase.logName) -> \(newPhase.logName)"
                    Task {
                        await DiagnosticsRecorder.shared.record(
                            category: "lifecycle",
                            message: "App scene changed: \(transition)."
                        )
                    }
                }
        }
    }
}

private extension ScenePhase {
    var logName: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}
