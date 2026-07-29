import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = ChargeGlowViewModel()
    @Binding var appLanguage: AppLanguage

    private let cardColor = Color.white.opacity(0.07)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    readinessCard
                    batteryCard
                    controls
                    diagnosticsCard
                    limitationNotice
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.03, blue: 0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("ChargeGlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenu
                }
            }
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
            .onChange(of: scenePhase) { _, newPhase in
                viewModel.setApplicationActive(newPhase == .active)
            }
        }
        .tint(.cyan)
    }

    private var languageMenu: some View {
        Menu {
            Picker("App language", selection: $appLanguage) {
                Text("System")
                    .tag(AppLanguage.system)
                Text("English")
                    .tag(AppLanguage.english)
                Text("Arabic")
                    .tag(AppLanguage.arabic)
            }
        } label: {
            Label("Language", systemImage: "globe")
        }
        .accessibilityLabel("Language")
    }

    private var hero: some View {
        VStack(spacing: 14) {
            NeonOrbitThemeView(
                percentage: viewModel.snapshot.percentage,
                state: viewModel.snapshot.state
            )
            .frame(width: 150, height: 150)

            Text("Neon Orbit")
                .font(.title2.bold())

            Text("Charging Live Activity")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 3) {
                Text(
                    "Version \(BuildInfo.current.version) (\(BuildInfo.current.build))"
                )
                Text(BuildInfo.current.buildText)
            }
            .font(.caption.monospaced())
            .foregroundStyle(.cyan.opacity(0.85))
            .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var readinessCard: some View {
        VStack(spacing: 12) {
            statusRow(
                title: "Live Activities",
                symbol: viewModel.liveActivitiesEnabled
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill",
                color: viewModel.liveActivitiesEnabled ? .green : .orange
            ) {
                if viewModel.liveActivitiesEnabled {
                    Text("Enabled")
                } else {
                    Text("Disabled")
                }
            }

            Divider()

            statusRow(
                title: "ChargeGlow Activity",
                symbol: viewModel.activeActivityCount == 1
                    ? "bolt.circle.fill"
                    : "bolt.slash.circle",
                color: viewModel.activeActivityCount == 1 ? .cyan : .secondary
            ) {
                activityStatusText
            }
        }
        .chargeGlowCard(color: cardColor)
    }

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iOS battery API snapshot")
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.snapshot.displayPercentage)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Label {
                    chargingStateText
                } icon: {
                    Image(systemName: viewModel.snapshot.state.symbolName)
                }
                .foregroundStyle(.cyan)
            }

            Text(
                "Updated \(viewModel.snapshot.observedAt, format: .dateTime.hour().minute().second())"
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.snapshot.percentage == nil {
                Label(
                    "iOS did not provide a value. ChargeGlow will not estimate it.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            } else {
                Label(
                    "Approximate public API value; it can differ from the status bar.",
                    systemImage: "equal.circle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .chargeGlowCard(color: cardColor)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.startActivity()
            } label: {
                Label("Start Live Activity", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isWorking)

            HStack {
                Button {
                    viewModel.stopActivity()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .disabled(viewModel.isWorking)
        }
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Status", systemImage: "stethoscope")
                .font(.headline)

            statusMessageText
                .font(.subheadline)

            if let code = viewModel.diagnosticCode {
                Text("Diagnostic code: \(code)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.orange)
            }

            if let url = viewModel.diagnosticsURL {
                ShareLink(item: url) {
                    Label("Share diagnostics.json", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    viewModel.prepareDiagnosticsExport()
                } label: {
                    Label("Prepare diagnostics export", systemImage: "doc.badge.gearshape")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chargeGlowCard(color: cardColor)
    }

    private var limitationNotice: some View {
        Label(
            "ChargeGlow refreshes once per minute while foregrounded. After suspension, the Live Activity marks its last public API reading as outdated.",
            systemImage: "info.circle"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var activityStatusText: some View {
        switch viewModel.activeActivityCount {
        case 0:
            Text("Stopped")
        case 1:
            Text("Running")
        default:
            Text(
                "\(viewModel.activeActivityCount) activities (recovery required)"
            )
        }
    }

    @ViewBuilder
    private var chargingStateText: some View {
        switch viewModel.snapshot.state {
        case .unknown:
            Text("Unknown")
        case .disconnected:
            Text("Disconnected")
        case .charging:
            Text("Charging")
        case .full:
            Text("Fully Charged")
        }
    }

    @ViewBuilder
    private var statusMessageText: some View {
        switch viewModel.status {
        case .ready:
            Text("Ready to start a charging Live Activity.")
        case .startedWithoutPercentage:
            Text(
                "Started, but iOS did not provide a battery percentage."
            )
        case .startedWithLatestReading:
            Text(
                "Live Activity started with the latest public iOS battery reading."
            )
        case .ended(let count):
            Text("Ended \(count) ChargeGlow Live Activity.")
        case .alreadyStopped:
            Text("ChargeGlow was already stopped.")
        case .diagnosticsExportFailed:
            Text("Diagnostics export could not be prepared.")
        case .failure(let error):
            Text(errorDescriptionKey(for: error))
                + Text(" ")
                + Text(recoverySuggestionKey(for: error))
        }
    }

    private func errorDescriptionKey(
        for error: ChargingActivityError
    ) -> LocalizedStringKey {
        switch error {
        case .liveActivitiesNotAuthorized:
            return "Live Activities are disabled. Enable them in Settings and try again."
        case .batteryUnavailable:
            return "The battery level is currently unavailable. ChargeGlow will never estimate it."
        case .activityAlreadyRunning:
            return "A ChargeGlow Live Activity is already running."
        case .noActiveActivity:
            return "There is no ChargeGlow Live Activity to update or stop."
        case .activityStartFailed:
            return "ChargeGlow could not start the Live Activity."
        case .activityUpdateFailed:
            return "ChargeGlow could not update the Live Activity."
        case .activityEndFailed:
            return "ChargeGlow could not end the Live Activity."
        }
    }

    private func recoverySuggestionKey(
        for error: ChargingActivityError
    ) -> LocalizedStringKey {
        switch error {
        case .liveActivitiesNotAuthorized:
            return "Open Settings, select ChargeGlow, and enable Live Activities."
        case .batteryUnavailable:
            return "Unlock the device, open ChargeGlow once, and retry the automation."
        case .activityAlreadyRunning:
            return "Use Stop Charging Theme before starting another activity."
        case .noActiveActivity:
            return "Run Start Charging Theme first."
        case .activityStartFailed, .activityUpdateFailed, .activityEndFailed:
            return "Export diagnostics, then retry after reopening ChargeGlow."
        }
    }

    private func statusRow<Value: View>(
        title: LocalizedStringKey,
        symbol: String,
        color: Color,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol)
            }
                .foregroundStyle(color)
            Spacer()
            value()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
private extension View {
    func chargeGlowCard(color: Color) -> some View {
        padding(16)
            .background(color, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08))
            }
    }
}
