import AppIntents
import SwiftUI

@main
struct ChargeGlowApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appLanguage = AppLanguage.system

    init() {
        ChargeGlowShortcutsProvider.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appLanguage: $appLanguage)
                .preferredColorScheme(.dark)
                .environment(\.locale, appLanguage.locale)
                .environment(
                    \.layoutDirection,
                    appLanguage.layoutDirection
                )
                .task {
                    appLanguage =
                        await AppPreferencesStore.shared.appLanguage()
                }
                .onChange(of: appLanguage) { _, newLanguage in
                    Task {
                        await AppPreferencesStore.shared.setAppLanguage(
                            newLanguage
                        )
                    }
                }
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

private extension AppLanguage {
    var layoutDirection: LayoutDirection {
        switch self {
        case .arabic:
            return .rightToLeft
        case .english:
            return .leftToRight
        case .system:
            return Locale.current.language.characterDirection == .rightToLeft
                ? .rightToLeft
                : .leftToRight
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
