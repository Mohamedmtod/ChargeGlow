import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChargeGlowViewModel()

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
            .navigationTitle("ChargeGlow Spike")
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
        }
        .tint(.cyan)
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

            Text("Physical-device feasibility build")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 3) {
                Text(BuildInfo.current.versionText)
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
                value: viewModel.liveActivitiesEnabled ? "Enabled" : "Disabled",
                symbol: viewModel.liveActivitiesEnabled
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill",
                color: viewModel.liveActivitiesEnabled ? .green : .orange
            )

            Divider()

            statusRow(
                title: "ChargeGlow Activity",
                value: viewModel.activityStatus,
                symbol: viewModel.activeActivityCount == 1
                    ? "bolt.circle.fill"
                    : "bolt.slash.circle",
                color: viewModel.activeActivityCount == 1 ? .cyan : .secondary
            )
        }
        .chargeGlowCard(color: cardColor)
    }

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Real battery snapshot")
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.snapshot.displayPercentage)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Label(
                    viewModel.snapshot.state.displayName,
                    systemImage: viewModel.snapshot.state.symbolName
                )
                .foregroundStyle(.cyan)
            }

            Text("Updated \(viewModel.snapshot.observedAt.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.snapshot.percentage == nil {
                Label(
                    "iOS did not provide a value. ChargeGlow will not estimate it.",
                    systemImage: "exclamationmark.triangle"
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

            Text(viewModel.statusMessage)
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
            "Battery updates are real only while iOS gives the app execution time. The last known value remains visible after suspension.",
            systemImage: "info.circle"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }

    private func statusRow(
        title: String,
        value: String,
        symbol: String,
        color: Color
    ) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .foregroundStyle(color)
            Spacer()
            Text(value)
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
