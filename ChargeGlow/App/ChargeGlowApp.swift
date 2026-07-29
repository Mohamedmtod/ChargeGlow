import AppIntents
import Combine
import SwiftUI

@main
struct ChargeGlowApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var languageController =
        AppLanguageController()

    init() {
        ChargeGlowShortcutsProvider.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                appLanguage: Binding(
                    get: { languageController.selection },
                    set: { languageController.select($0) }
                )
            )
                .preferredColorScheme(.dark)
                .environment(
                    \.locale,
                    languageController.selection.locale
                )
                .environment(
                    \.layoutDirection,
                    languageController.selection.layoutDirection
                )
                .task {
                    await languageController.load()
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

@MainActor
private final class AppLanguageController: ObservableObject {
    @Published private(set) var selection = AppLanguage.system

    private var userSelectedLanguage = false
    private var persistenceTask: Task<Void, Never>?

    func load() async {
        let storedLanguage =
            await AppPreferencesStore.shared.appLanguage()
        guard !userSelectedLanguage else {
            return
        }
        selection = storedLanguage
    }

    func select(_ language: AppLanguage) {
        userSelectedLanguage = true
        selection = language

        let previousTask = persistenceTask
        persistenceTask = Task {
            await previousTask?.value
            await AppPreferencesStore.shared.setAppLanguage(language)
            let snapshot = await BatteryReader.capture()
            try? await ChargingActivityManager.shared.update(
                snapshot: snapshot,
                correlationID: nil
            )
        }
    }
}

private extension AppLanguage {
    var layoutDirection: LayoutDirection {
        switch resolved {
        case .arabic:
            return .rightToLeft
        case .english, .system:
            return .leftToRight
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
