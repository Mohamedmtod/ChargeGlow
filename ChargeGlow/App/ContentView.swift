import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = ChargeGlowViewModel()
    @Binding var appLanguage: AppLanguage

    private let cardColor = Color.white.opacity(0.07)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    themeGallery
                    readinessCard
                    batteryCard
                    controls
                    diagnosticsCard
                    limitationNotice
                }
                .padding()
            }
            .background {
                ZStack {
                    LinearGradient(
                        colors: themeBackgroundColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Circle()
                        .fill(themeAccent.opacity(0.16))
                        .frame(width: 280, height: 280)
                        .blur(radius: 80)
                        .offset(x: 145, y: -250)

                    Circle()
                        .fill(themeSecondaryAccent.opacity(0.1))
                        .frame(width: 240, height: 240)
                        .blur(radius: 90)
                        .offset(x: -150, y: 330)
                }
                .ignoresSafeArea()
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 0.65),
                    value: viewModel.selectedThemeID
                )
            }
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
        .tint(themeAccent)
    }

    private var languageMenu: some View {
        Menu {
            Picker("App language", selection: $appLanguage) {
                Text("System")
                    .tag(AppLanguage.system)
                Text("Language option: English")
                    .tag(AppLanguage.english)
                Text("Language option: Arabic")
                    .tag(AppLanguage.arabic)
            }
        } label: {
            Label("Language", systemImage: "globe")
                .labelStyle(.iconOnly)
                .font(.body.bold())
                .frame(width: 36, height: 36)
                .background(
                    .ultraThinMaterial,
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .stroke(themeAccent.opacity(0.35))
                }
        }
        .accessibilityLabel("Language")
    }

    private var themeBackgroundColors: [Color] {
        switch viewModel.selectedThemeID {
        case .neonOrbit:
            return [
                .black,
                Color(red: 0.025, green: 0.02, blue: 0.08),
                Color(red: 0.05, green: 0.03, blue: 0.14)
            ]
        case .auroraPulse:
            return [
                .black,
                Color(red: 0.01, green: 0.11, blue: 0.14),
                Color(red: 0.10, green: 0.03, blue: 0.16)
            ]
        case .emberCircuit:
            return [
                .black,
                Color(red: 0.09, green: 0.02, blue: 0.01),
                Color(red: 0.18, green: 0.035, blue: 0.015)
            ]
        }
    }

    private var themeAccent: Color {
        switch viewModel.selectedThemeID {
        case .neonOrbit:
            return .cyan
        case .auroraPulse:
            return .mint
        case .emberCircuit:
            return .orange
        }
    }

    private var themeSecondaryAccent: Color {
        switch viewModel.selectedThemeID {
        case .neonOrbit:
            return .purple
        case .auroraPulse:
            return .pink
        case .emberCircuit:
            return .red
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ChargingThemeView(
                themeID: viewModel.selectedThemeID,
                percentage: viewModel.snapshot.percentage,
                state: viewModel.snapshot.state,
                animated: true
            )
            .frame(width: 150, height: 150)
            .id(viewModel.selectedThemeID)
            .transition(
                .scale(scale: 0.86)
                    .combined(with: .opacity)
            )

            themeNameText(viewModel.selectedThemeID)
                .font(.title2.bold())
                .contentTransition(.opacity)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            themeAccent
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

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
            .foregroundStyle(themeAccent.opacity(0.9))
            .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 28)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            themeAccent.opacity(0.65),
                            Color.white.opacity(0.08),
                            themeSecondaryAccent.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(
            color: themeAccent.opacity(0.2),
            radius: 24,
            y: 10
        )
    }

    private var themeGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Themes", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(themeAccent)

            Text("Choose the look for your next Live Activity.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 130),
                        spacing: 10
                    )
                ],
                spacing: 10
            ) {
                ForEach(ThemeCatalog.all) { descriptor in
                    themeCard(descriptor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chargeGlowCard(
            color: cardColor,
            accent: themeAccent
        )
        .sensoryFeedback(
            .selection,
            trigger: viewModel.selectedThemeID
        )
    }

    private func themeCard(
        _ descriptor: ThemeDescriptor
    ) -> some View {
        let isSelected = descriptor.id == viewModel.selectedThemeID

        return Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.42,
                        dampingFraction: 0.72
                    )
            ) {
                viewModel.selectTheme(descriptor.id)
            }
        } label: {
            VStack(spacing: 9) {
                ChargingThemeView(
                    themeID: descriptor.id,
                    percentage: viewModel.snapshot.percentage,
                    state: viewModel.snapshot.state,
                    animated: isSelected
                )
                .frame(width: 82, height: 82)

                themeNameText(descriptor.id)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)

                if isSelected {
                    Label(
                        "Selected",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption2)
                    .foregroundStyle(themeAccent)
                    .transition(
                        .scale(scale: 0.7)
                            .combined(with: .opacity)
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                isSelected
                    ? themeAccent.opacity(0.14)
                    : Color.white.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? themeAccent.opacity(0.7)
                            : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.025 : 0.985)
        .shadow(
            color: isSelected
                ? themeAccent.opacity(0.3)
                : Color.clear,
            radius: isSelected ? 12 : 0,
            y: isSelected ? 5 : 0
        )
        .animation(
            reduceMotion
                ? nil
                : .spring(
                    response: 0.42,
                    dampingFraction: 0.72
                ),
            value: isSelected
        )
    }

    private func themeNameText(_ themeID: ThemeID) -> Text {
        switch themeID {
        case .neonOrbit:
            return Text("Neon Orbit")
        case .auroraPulse:
            return Text("Aurora Pulse")
        case .emberCircuit:
            return Text("Ember Circuit")
        }
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
                color: viewModel.activeActivityCount == 1
                    ? themeAccent
                    : .secondary
            ) {
                activityStatusText
            }
        }
        .chargeGlowCard(
            color: cardColor,
            accent: themeAccent
        )
    }

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iOS battery API snapshot")
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.snapshot.displayPercentage)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                themeAccent
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Spacer()

                Label {
                    chargingStateText
                } icon: {
                    Image(systemName: viewModel.snapshot.state.symbolName)
                }
                .foregroundStyle(themeAccent)
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
        .chargeGlowCard(
            color: cardColor,
            accent: themeAccent
        )
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.startActivity()
            } label: {
                Label("Start Live Activity", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                ChargeGlowPrimaryButtonStyle(
                    accent: themeAccent,
                    secondaryAccent: themeSecondaryAccent,
                    reduceMotion: reduceMotion
                )
            )
            .disabled(viewModel.isWorking)

            HStack {
                Button {
                    viewModel.stopActivity()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    ChargeGlowSecondaryButtonStyle(
                        accent: themeAccent,
                        reduceMotion: reduceMotion
                    )
                )

                Button {
                    viewModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    ChargeGlowSecondaryButtonStyle(
                        accent: themeAccent,
                        reduceMotion: reduceMotion
                    )
                )
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
        .chargeGlowCard(
            color: cardColor,
            accent: themeAccent
        )
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
    func chargeGlowCard(
        color: Color,
        accent: Color
    ) -> some View {
        padding(16)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(color)
                    .overlay {
                        LinearGradient(
                            colors: [
                                accent.opacity(0.09),
                                Color.clear,
                                Color.white.opacity(0.025)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 22)
                        )
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.26),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(
                color: Color.black.opacity(0.26),
                radius: 16,
                y: 8
            )
    }
}

private struct ChargeGlowPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let accent: Color
    let secondaryAccent: Color
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                accent,
                                secondaryAccent
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
            }
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.24))
            }
            .shadow(
                color: accent.opacity(
                    configuration.isPressed ? 0.18 : 0.42
                ),
                radius: configuration.isPressed ? 7 : 16,
                y: configuration.isPressed ? 3 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.28,
                        dampingFraction: 0.72
                    ),
                value: configuration.isPressed
            )
    }
}

private struct ChargeGlowSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let accent: Color
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(accent)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(
                                accent.opacity(
                                    configuration.isPressed
                                        ? 0.16
                                        : 0.08
                                )
                            )
                    }
            }
            .overlay {
                Capsule()
                    .stroke(accent.opacity(0.3))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.82)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.28,
                        dampingFraction: 0.75
                    ),
                value: configuration.isPressed
            )
    }
}
