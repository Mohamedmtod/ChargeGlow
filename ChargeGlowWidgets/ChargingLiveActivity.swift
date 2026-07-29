import ActivityKit
import SwiftUI
import WidgetKit

struct ChargingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChargingActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.92))
                .activitySystemActionForegroundColor(.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    NeonOrbitThemeView(
                        percentage: context.state.batteryPercentage,
                        state: context.state.chargingState,
                        compact: true
                    )
                    .frame(width: 42, height: 42)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    percentageText(context.state.batteryPercentage)
                        .font(.title3.bold())
                }

                DynamicIslandExpandedRegion(.center) {
                    Text("Neon Orbit")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(
                            context.state.chargingState.displayName,
                            systemImage: context.state.chargingState.symbolName
                        )
                        Spacer()
                        freshnessText(context: context)
                    }
                    .font(.caption)
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.chargingState.symbolName)
                    .foregroundStyle(context.state.chargingState == .full ? .green : .cyan)
                    .accessibilityLabel(context.state.chargingState.displayName)
            } compactTrailing: {
                percentageText(context.state.batteryPercentage)
                    .font(.caption.bold())
            } minimal: {
                NeonOrbitThemeView(
                    percentage: context.state.batteryPercentage,
                    state: context.state.chargingState,
                    compact: true
                )
                .padding(2)
            }
            .keylineTint(.purple)
        }
    }

    private func lockScreenView(
        context: ActivityViewContext<ChargingActivityAttributes>
    ) -> some View {
        HStack(spacing: 16) {
            NeonOrbitThemeView(
                percentage: context.state.batteryPercentage,
                state: context.state.chargingState
            )
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 5) {
                Text("Neon Orbit")
                    .textCase(.uppercase)
                    .font(.caption.bold())
                    .tracking(1.4)
                    .foregroundStyle(.cyan)

                percentageText(context.state.batteryPercentage)
                    .font(.title.bold())

                Label(
                    context.state.displayMessage,
                    systemImage: context.state.chargingState.symbolName
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 3) {
                    if context.isStale {
                        Text("Outdated · Updated")
                    } else {
                        Text("Updated")
                    }
                    Text(
                        context.state.lastUpdatedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                }
                    .font(.caption2)
                    .foregroundStyle(context.isStale ? Color.orange : Color.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func percentageText(_ percentage: Int?) -> some View {
        if let percentage {
            Text("≈\(percentage)%")
                .monospacedDigit()
        } else {
            Text("—")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Battery percentage unavailable")
        }
    }

    @ViewBuilder
    private func freshnessText(
        context: ActivityViewContext<ChargingActivityAttributes>
    ) -> some View {
        if context.isStale {
            Label("Reading outdated", systemImage: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
        } else {
            Text("Updated \(context.state.lastUpdatedAt, style: .time)")
                .foregroundStyle(.secondary)
        }
    }
}
