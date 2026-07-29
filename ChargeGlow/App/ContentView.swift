import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = ChargeGlowViewModel()
    @State private var ambientDrift = false
    @Binding var appLanguage: AppLanguage

    private let cardColor = Color.white.opacity(0.07)

    private var ambientMotionEnabled: Bool {
        !reduceMotion && scenePhase == .active
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    themeGallery
                    readinessCard
                    batteryCard
                    chargingSessionTestCard
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
                        .scaleEffect(
                            ambientMotionEnabled
                                ? (ambientDrift ? 1.08 : 0.92)
                                : 1
                        )
                        .offset(
                            x: ambientDrift ? 158 : 135,
                            y: ambientDrift ? -268 : -238
                        )

                    Circle()
                        .fill(themeSecondaryAccent.opacity(0.1))
                        .frame(width: 240, height: 240)
                        .blur(radius: 90)
                        .scaleEffect(
                            ambientMotionEnabled
                                ? (ambientDrift ? 0.92 : 1.08)
                                : 1
                        )
                        .offset(
                            x: ambientDrift ? -132 : -158,
                            y: ambientDrift ? 305 : 345
                        )
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
            .task(id: ambientMotionEnabled) { @MainActor in
                ambientDrift = false
                guard ambientMotionEnabled else {
                    return
                }
                await Task.yield()
                withAnimation(
                    .easeInOut(duration: 7.5)
                        .repeatForever(autoreverses: true)
                ) {
                    ambientDrift = true
                }
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
                .chargeGlowGlassCircle()
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
        case .aquaFlux:
            return [
                .black,
                Color(red: 0.01, green: 0.09, blue: 0.16),
                Color(red: 0.015, green: 0.18, blue: 0.28)
            ]
        case .plasmaCore:
            return [
                .black,
                Color(red: 0.13, green: 0.015, blue: 0.17),
                Color(red: 0.22, green: 0.025, blue: 0.13)
            ]
        case .lumenBloom:
            return [
                .black,
                Color(red: 0.01, green: 0.12, blue: 0.07),
                Color(red: 0.08, green: 0.18, blue: 0.025)
            ]
        case .frostCrystal:
            return [
                .black,
                Color(red: 0.015, green: 0.11, blue: 0.2),
                Color(red: 0.08, green: 0.2, blue: 0.3)
            ]
        case .retroWave:
            return [
                .black,
                Color(red: 0.15, green: 0.015, blue: 0.2),
                Color(red: 0.28, green: 0.035, blue: 0.14)
            ]
        case .candyPop:
            return [
                .black,
                Color(red: 0.18, green: 0.025, blue: 0.13),
                Color(red: 0.3, green: 0.08, blue: 0.05)
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
        case .aquaFlux:
            return .cyan
        case .plasmaCore:
            return .pink
        case .lumenBloom:
            return .mint
        case .frostCrystal:
            return .cyan
        case .retroWave:
            return .pink
        case .candyPop:
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
        case .aquaFlux:
            return .blue
        case .plasmaCore:
            return .purple
        case .lumenBloom:
            return .yellow
        case .frostCrystal:
            return .blue
        case .retroWave:
            return .orange
        case .candyPop:
            return .pink
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ChargingThemeView(
                themeID: viewModel.selectedThemeID,
                percentage: viewModel.snapshot.percentage,
                apiPercentage: viewModel.snapshot.apiPercentage,
                state: viewModel.snapshot.state,
                animated: scenePhase == .active
            )
            .frame(width: 150, height: 150)
            .padding(10)
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
        .chargeGlowHeroGlass(
            accent: themeAccent,
            secondaryAccent: themeSecondaryAccent
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

            ChargeGlowGlassContainer(spacing: 10) {
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
                    apiPercentage: viewModel.snapshot.apiPercentage,
                    state: viewModel.snapshot.state,
                    compact: true,
                    animated: isSelected
                )
                .frame(width: 82, height: 82)
                .clipped()

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
            .chargeGlowThemeTile(
                accent: themeAccent,
                isSelected: isSelected
            )
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
        case .aquaFlux:
            return Text("Aqua Flux")
        case .plasmaCore:
            return Text("Plasma Core")
        case .lumenBloom:
            return Text("Lumen Bloom")
        case .frostCrystal:
            return Text("Frost Crystal")
        case .retroWave:
            return Text("Retro Wave")
        case .candyPop:
            return Text("Candy Pop")
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
                batteryAPIPercentageText
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

                Text(
                    "The decimal is the raw public API value rounded to one decimal; it may still change in coarse steps."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .chargeGlowCard(
            color: cardColor,
            accent: themeAccent
        )
    }

    @ViewBuilder
    private var batteryAPIPercentageText: some View {
        if let percentage = viewModel.snapshot.mostDetailedPercentage {
            HStack(spacing: 0) {
                Text("≈")
                Text(
                    percentage,
                    format: .number.precision(
                        .fractionLength(1)
                    )
                )
                Text("%")
            }
        } else {
            Text("—")
        }
    }

    private var chargingSessionTestCard: some View {
        let test = viewModel.chargingSessionTest

        return VStack(alignment: .leading, spacing: 12) {
            Label(
                "Charging Session Test",
                systemImage: "gauge.with.dots.needle.67percent"
            )
            .font(.headline)
            .foregroundStyle(themeAccent)

            Text(
                "Measures the observed battery gain while ChargeGlow remains open."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Label(
                "Uses every accepted public API sample to fit a more stable observed trend.",
                systemImage: "function"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)

            Divider()

            switch test.phase {
            case .idle:
                if
                    viewModel.snapshot.state == .charging,
                    viewModel.snapshot.mostDetailedPercentage != nil
                {
                    Label(
                        "Ready. Keep the same cable, charger, screen use, and temperature during the test.",
                        systemImage: "checkmark.circle"
                    )
                    .foregroundStyle(.green)
                } else {
                    Label(
                        "Connect a charger and wait for iOS to report Charging.",
                        systemImage: "powerplug"
                    )
                    .foregroundStyle(.orange)
                }

                Button {
                    viewModel.startChargingSessionTest()
                } label: {
                    Label(
                        "Start Charging Test",
                        systemImage: "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    ChargeGlowSecondaryButtonStyle(
                        accent: themeAccent,
                        reduceMotion: reduceMotion
                    )
                )
                .disabled(
                    viewModel.snapshot.state != .charging
                        || viewModel.snapshot.mostDetailedPercentage == nil
                )

            case .running:
                chargingTestMetrics(test)

                Label(
                    "Keep ChargeGlow open on screen for at least 15–20 minutes for a more useful comparison.",
                    systemImage: "timer"
                )
                .font(.caption)
                .foregroundStyle(.orange)

                Button {
                    viewModel.stopChargingSessionTest()
                } label: {
                    Label("Stop Charging Test", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    ChargeGlowSecondaryButtonStyle(
                        accent: themeAccent,
                        reduceMotion: reduceMotion
                    )
                )

            case .completed:
                chargingTestMetrics(test)

                HStack {
                    Label(
                        "Measurement confidence",
                        systemImage: "waveform.path.ecg"
                    )
                    Spacer()
                    chargingTestConfidenceText(test.confidence)
                        .foregroundStyle(
                            chargingTestConfidenceColor(test.confidence)
                        )
                }

                chargingTestCompletionText(test.completionReason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.resetChargingSessionTest()
                } label: {
                    Label("Reset Test", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    ChargeGlowSecondaryButtonStyle(
                        accent: themeAccent,
                        reduceMotion: reduceMotion
                    )
                )
            }

            Divider()

            Label(
                "This is not a wattage, safety, authenticity, or hardware-quality test. Compare chargers only under similar conditions.",
                systemImage: "exclamationmark.shield"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chargeGlowCard(
            color: cardColor,
            accent: themeAccent
        )
    }

    @ViewBuilder
    private func chargingTestMetrics(
        _ test: ChargingSessionTest
    ) -> some View {
        ChargingTrendChart(
            samples: test.samples,
            accent: themeAccent,
            animated:
                ambientMotionEnabled
                    && test.phase == .running
        )

        statusRow(
            title: "Elapsed",
            symbol: "timer",
            color: themeAccent
        ) {
            if test.phase == .running {
                TimelineView(
                    .periodic(
                        from: .now,
                        by: 1
                    )
                ) { context in
                    Text(
                        chargingTestDurationText(
                            test.elapsed(at: context.date)
                        )
                    )
                    .monospacedDigit()
                }
            } else {
                Text(
                    chargingTestDurationText(
                        test.measurementDuration
                    )
                )
                .monospacedDigit()
            }
        }

        statusRow(
            title: "Start level",
            symbol: "battery.25percent",
            color: themeAccent
        ) {
            chargingTestPercentageText(test.startPercentage)
        }

        statusRow(
            title: "Latest level",
            symbol: "battery.75percent",
            color: themeAccent
        ) {
            chargingTestPercentageText(test.latestPercentage)
        }

        statusRow(
            title: "Battery gain",
            symbol: "battery.100percent",
            color: themeAccent
        ) {
            if let gain = test.gainedPercentagePoints {
                HStack(spacing: 3) {
                    Text(
                        gain,
                        format: .number.precision(
                            .fractionLength(1)
                        )
                    )
                    Text("points")
                }
            } else {
                Text("Unavailable")
            }
        }

        statusRow(
            title: "Observed rate",
            symbol: "speedometer",
            color: themeAccent
        ) {
            if let rate = test.observedPercentagePointsPerHour {
                HStack(spacing: 3) {
                    Text(
                        rate,
                        format: .number.precision(
                            .fractionLength(1)
                        )
                    )
                    Text("points/hour")
                }
            } else {
                Text("Waiting for enough change")
            }
        }

        statusRow(
            title: "Samples",
            symbol: "chart.dots.scatter",
            color: themeAccent
        ) {
            Text("\(test.sampleCount)")
        }
    }

    @ViewBuilder
    private func chargingTestPercentageText(
        _ percentage: Double?
    ) -> some View {
        if let percentage {
            HStack(spacing: 0) {
                Text("≈")
                Text(
                    percentage,
                    format: .number.precision(
                        .fractionLength(1)
                    )
                )
                Text("%")
            }
            .monospacedDigit()
        } else {
            Text("Unavailable")
        }
    }

    private func chargingTestDurationText(
        _ duration: TimeInterval
    ) -> String {
        let totalSeconds = max(Int(duration.rounded(.down)), 0)
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(
                format: "%02d:%02d:%02d",
                hours,
                minutes,
                seconds
            )
        }
        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }

    private func chargingTestConfidenceColor(
        _ confidence: ChargingTestConfidence
    ) -> Color {
        switch confidence {
        case .insufficient:
            return .orange
        case .indicative:
            return .blue
        case .strong:
            return .green
        }
    }

    private func chargingTestConfidenceText(
        _ confidence: ChargingTestConfidence
    ) -> Text {
        switch confidence {
        case .insufficient:
            return Text("Insufficient")
        case .indicative:
            return Text("Indicative")
        case .strong:
            return Text("Strong")
        }
    }

    private func chargingTestCompletionText(
        _ reason: ChargingTestCompletionReason?
    ) -> Text {
        switch reason {
        case .some(.manual):
            return Text("Test stopped manually.")
        case .some(.disconnected):
            return Text("Test ended when the charger disconnected.")
        case .some(.fullyCharged):
            return Text("Test ended when the battery became full.")
        case .some(.appInactive):
            return Text("Test ended when ChargeGlow left the foreground.")
        case .none:
            return Text("Test completed.")
        }
    }

    private var controls: some View {
        ChargeGlowGlassContainer(spacing: 10) {
            VStack(spacing: 10) {
                Button {
                    viewModel.startActivity()
                } label: {
                    Label(
                        "Start Live Activity",
                        systemImage: "bolt.fill"
                    )
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
                        Label(
                            "Refresh",
                            systemImage: "arrow.clockwise"
                        )
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
            "ChargeGlow samples every 30 seconds while foregrounded. After suspension, the Live Activity marks its last public API reading as outdated.",
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

private struct ChargingTrendChart: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reveal: CGFloat = 1
    @State private var latestPointPulse = false

    let samples: [ChargingSessionSample]
    let accent: Color
    let animated: Bool

    private var motionEnabled: Bool {
        animated && !reduceMotion
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(
                    "Live sample graph",
                    systemImage: "chart.xyaxis.line"
                )
                .font(.caption.bold())
                .foregroundStyle(accent)

                Spacer()

                if samples.count < 2 {
                    Text("Waiting for more samples")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { proxy in
                let insetRect = proxy.frame(in: .local).insetBy(
                    dx: 12,
                    dy: 14
                )
                let points = ChargingTrendGeometry.points(
                    for: samples,
                    in: insetRect
                )

                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent.opacity(0.15),
                                    Color.black.opacity(0.32)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    ChargingTrendGrid()
                        .stroke(
                            Color.white.opacity(0.08),
                            style: StrokeStyle(
                                lineWidth: 0.7,
                                dash: [3, 5]
                            )
                        )
                        .padding(12)

                    if samples.count >= 2 {
                        ChargingTrendAreaShape(samples: samples)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(0.34),
                                        accent.opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)

                        ChargingTrendLineShape(
                            samples: samples,
                            reveal: reveal
                        )
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, accent, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .shadow(color: accent.opacity(0.7), radius: 5)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                    }

                    ForEach(
                        Array(points.enumerated()),
                        id: \.offset
                    ) { index, point in
                        let isLatest = index == points.count - 1

                        Circle()
                            .fill(
                                isLatest
                                    ? Color.white
                                    : accent
                            )
                            .overlay {
                                Circle()
                                    .stroke(
                                        accent.opacity(0.75),
                                        lineWidth: 1
                                    )
                            }
                            .frame(
                                width: isLatest
                                    ? 8
                                    : 5,
                                height: isLatest
                                    ? 8
                                    : 5
                            )
                            .shadow(
                                color: accent,
                                radius: isLatest
                                    ? 6
                                    : 2
                            )
                            .scaleEffect(
                                isLatest
                                    && motionEnabled
                                    && latestPointPulse
                                        ? 1.35
                                        : 1
                            )
                            .position(point)
                    }
                }
            }
            .frame(height: 138)

            Text(
                "Lines connect real samples; no intermediate battery readings are invented."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                "Charging trend based on \(samples.count) real samples."
            )
        )
        .onAppear {
            animateReveal()
        }
        .onChange(of: samples.count) { _, _ in
            animateReveal()
        }
        .task(id: motionEnabled) { @MainActor in
            latestPointPulse = false
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
            ) {
                latestPointPulse = true
            }
        }
    }

    @MainActor
    private func animateReveal() {
        guard motionEnabled, samples.count >= 2 else {
            reveal = 1
            return
        }
        reveal = 0
        withAnimation(.easeOut(duration: 0.75)) {
            reveal = 1
        }
    }
}

private enum ChargingTrendGeometry {
    static func points(
        for samples: [ChargingSessionSample],
        in rect: CGRect
    ) -> [CGPoint] {
        guard
            let first = samples.first,
            let last = samples.last
        else {
            return []
        }

        let percentages = samples.map(\.percentage)
        let minimum = percentages.min() ?? first.percentage
        let maximum = percentages.max() ?? first.percentage
        let range = max(maximum - minimum, 1)
        let lowerBound = max(minimum - range * 0.18, 0)
        let upperBound = min(maximum + range * 0.18, 100)
        let verticalRange = max(upperBound - lowerBound, 1)
        let duration = max(
            last.observedAt.timeIntervalSince(first.observedAt),
            1
        )

        return samples.map { sample in
            let xProgress = sample.observedAt
                .timeIntervalSince(first.observedAt) / duration
            let yProgress =
                (sample.percentage - lowerBound) / verticalRange
            return CGPoint(
                x: rect.minX + rect.width * xProgress,
                y: rect.maxY - rect.height * yProgress
            )
        }
    }
}

private struct ChargingTrendLineShape: Shape {
    let samples: [ChargingSessionSample]
    var reveal: CGFloat

    var animatableData: CGFloat {
        get { reveal }
        set { reveal = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let points = ChargingTrendGeometry.points(
            for: samples,
            in: rect
        )
        guard let first = points.first else {
            return Path()
        }

        var path = Path()
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path.trimmedPath(
            from: 0,
            to: min(max(reveal, 0), 1)
        )
    }
}

private struct ChargingTrendAreaShape: Shape {
    let samples: [ChargingSessionSample]

    func path(in rect: CGRect) -> Path {
        let points = ChargingTrendGeometry.points(
            for: samples,
            in: rect
        )
        guard
            let first = points.first,
            let last = points.last
        else {
            return Path()
        }

        var path = Path()
        path.move(to: CGPoint(x: first.x, y: rect.maxY))
        path.addLine(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ChargingTrendGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for index in 1..<4 {
            let y = rect.minY
                + rect.height * CGFloat(index) / 4
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        for index in 1..<4 {
            let x = rect.minX
                + rect.width * CGFloat(index) / 4
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return path
    }
}

private struct ChargeGlowGlassContainer<Content: View>: View {
    let spacing: CGFloat?
    let content: Content

    init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

private extension View {
    @ViewBuilder
    func chargeGlowGlassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            background(
                .ultraThinMaterial,
                in: Circle()
            )
        }
    }

    @ViewBuilder
    func chargeGlowHeroGlass(
        accent: Color,
        secondaryAccent: Color
    ) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(
                .regular.tint(accent.opacity(0.12)),
                in: RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.6),
                            Color.white.opacity(0.12),
                            secondaryAccent.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(
                color: accent.opacity(0.18),
                radius: 24,
                y: 10
            )
        } else {
            background(
                .ultraThinMaterial,
                in: RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.65),
                            Color.white.opacity(0.08),
                            secondaryAccent.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
            }
            .shadow(
                color: accent.opacity(0.2),
                radius: 24,
                y: 10
            )
        }
    }

    @ViewBuilder
    func chargeGlowThemeTile(
        accent: Color,
        isSelected: Bool
    ) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(
                .regular
                    .tint(
                        accent.opacity(
                            isSelected ? 0.22 : 0.07
                        )
                    )
                    .interactive(),
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    isSelected
                        ? accent.opacity(0.72)
                        : Color.white.opacity(0.1),
                    lineWidth: isSelected ? 1.4 : 0.8
                )
            }
        } else {
            background(
                isSelected
                    ? accent.opacity(0.14)
                    : Color.white.opacity(0.04),
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    isSelected
                        ? accent.opacity(0.7)
                        : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 1
                )
            }
        }
    }

    func chargeGlowCard(
        color: Color,
        accent: Color
    ) -> some View {
        padding(16)
            .modifier(
                ChargeGlowCardGlassModifier(
                    color: color,
                    accent: accent
                )
            )
    }
}

private struct ChargeGlowCardGlassModifier: ViewModifier {
    let color: Color
    let accent: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.tint(accent.opacity(0.08)),
                    in: RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
                .overlay {
                    cardBorder
                }
                .shadow(
                    color: Color.black.opacity(0.22),
                    radius: 16,
                    y: 8
                )
        } else {
            content
                .background {
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
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
                            RoundedRectangle(
                                cornerRadius: 22,
                                style: .continuous
                            )
                        )
                    }
                }
                .overlay {
                    cardBorder
                }
                .shadow(
                    color: Color.black.opacity(0.26),
                    radius: 16,
                    y: 8
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(
            cornerRadius: 22,
            style: .continuous
        )
        .stroke(
            LinearGradient(
                colors: [
                    accent.opacity(0.26),
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
    }
}

private struct ChargeGlowPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let accent: Color
    let secondaryAccent: Color
    let reduceMotion: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            baseLabel(configuration)
                .glassEffect(
                    .regular
                        .tint(accent.opacity(0.42))
                        .interactive(),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.22))
                }
                .shadow(
                    color: accent.opacity(
                        configuration.isPressed ? 0.18 : 0.35
                    ),
                    radius: configuration.isPressed ? 7 : 14,
                    y: configuration.isPressed ? 3 : 7
                )
                .chargeGlowButtonMotion(
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    reduceMotion: reduceMotion
                )
        } else {
            baseLabel(configuration)
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
                .chargeGlowButtonMotion(
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    reduceMotion: reduceMotion
                )
        }
    }

    private func baseLabel(
        _ configuration: Configuration
    ) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
    }
}

private struct ChargeGlowSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let accent: Color
    let reduceMotion: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            baseLabel(configuration)
                .glassEffect(
                    .regular
                        .tint(
                            accent.opacity(
                                configuration.isPressed
                                    ? 0.2
                                    : 0.1
                            )
                        )
                        .interactive(),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(accent.opacity(0.28))
                }
                .chargeGlowButtonMotion(
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    reduceMotion: reduceMotion
                )
        } else {
            baseLabel(configuration)
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
                .chargeGlowButtonMotion(
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    reduceMotion: reduceMotion
                )
        }
    }

    private func baseLabel(
        _ configuration: Configuration
    ) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(accent)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
    }
}

private extension View {
    func chargeGlowButtonMotion(
        isPressed: Bool,
        isEnabled: Bool,
        reduceMotion: Bool
    ) -> some View {
        scaleEffect(isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.28,
                        dampingFraction: 0.74
                    ),
                value: isPressed
            )
    }
}
