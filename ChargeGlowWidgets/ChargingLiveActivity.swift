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
                    localizedView(
                        languageIdentifier:
                            context.state.languageIdentifier
                    ) {
                        ChargingThemeView(
                            themeID: ThemeCatalog.resolve(
                                context.attributes.themeID
                            ),
                            percentage: context.state.batteryPercentage,
                            state: context.state.chargingState,
                            compact: true
                        )
                        .frame(width: 42, height: 42)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    localizedView(
                        languageIdentifier:
                            context.state.languageIdentifier
                    ) {
                        percentageText(context.state.batteryPercentage)
                            .font(.title3.bold())
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    localizedView(
                        languageIdentifier:
                            context.state.languageIdentifier
                    ) {
                        themeNameText(
                            ThemeCatalog.resolve(
                                context.attributes.themeID
                            )
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    localizedView(
                        languageIdentifier:
                            context.state.languageIdentifier
                    ) {
                        HStack {
                            Label {
                                chargingStateText(
                                    context.state.chargingState
                                )
                            } icon: {
                                Image(
                                    systemName:
                                        context.state.chargingState.symbolName
                                )
                            }
                            Spacer()
                            freshnessText(context: context)
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                localizedView(
                    languageIdentifier:
                        context.state.languageIdentifier
                ) {
                    ChargingThemeMark(
                        themeID: ThemeCatalog.resolve(
                            context.attributes.themeID
                        ),
                        state: context.state.chargingState
                    )
                    .frame(width: 22, height: 22)
                    .accessibilityLabel(
                        chargingStateText(
                            context.state.chargingState
                        )
                    )
                }
            } compactTrailing: {
                localizedView(
                    languageIdentifier:
                        context.state.languageIdentifier
                ) {
                    percentageText(context.state.batteryPercentage)
                        .font(.caption.bold())
                }
            } minimal: {
                localizedView(
                    languageIdentifier:
                        context.state.languageIdentifier
                ) {
                    ChargingThemeView(
                        themeID: ThemeCatalog.resolve(
                            context.attributes.themeID
                        ),
                        percentage: context.state.batteryPercentage,
                        state: context.state.chargingState,
                        compact: true
                    )
                    .padding(2)
                }
            }
            .keylineTint(.purple)
        }
    }

    private func lockScreenView(
        context: ActivityViewContext<ChargingActivityAttributes>
    ) -> some View {
        HStack(spacing: 16) {
            ChargingThemeView(
                themeID: ThemeCatalog.resolve(
                    context.attributes.themeID
                ),
                percentage: context.state.batteryPercentage,
                state: context.state.chargingState
            )
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 5) {
                themeNameText(
                    ThemeCatalog.resolve(
                        context.attributes.themeID
                    )
                )
                .textCase(.uppercase)
                .font(.caption.bold())
                .tracking(1.4)
                .foregroundStyle(.cyan)

                percentageText(context.state.batteryPercentage)
                    .font(.title.bold())

                Label {
                    chargingStateText(context.state.chargingState)
                } icon: {
                    Image(
                        systemName:
                            context.state.chargingState.symbolName
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 3) {
                    if context.isStale {
                        Text("Outdated · Updated")
                    } else {
                        Text("Updated")
                    }
                    Text(context.state.lastUpdatedAt, style: .time)
                }
                    .font(.caption2)
                    .foregroundStyle(context.isStale ? Color.orange : Color.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .environment(
            \.locale,
            activityLocale(
                languageIdentifier: context.state.languageIdentifier
            )
        )
        .environment(
            \.layoutDirection,
            activityLayoutDirection(
                languageIdentifier: context.state.languageIdentifier
            )
        )
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

    private func chargingStateText(_ state: ChargingState) -> Text {
        switch state {
        case .unknown:
            return Text("Unknown")
        case .disconnected:
            return Text("Disconnected")
        case .charging:
            return Text("Charging")
        case .full:
            return Text("Fully Charged")
        }
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
        }
    }

    private func localizedView<Content: View>(
        languageIdentifier: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .environment(
                \.locale,
                activityLocale(
                    languageIdentifier: languageIdentifier
                )
            )
            .environment(
                \.layoutDirection,
                activityLayoutDirection(
                    languageIdentifier: languageIdentifier
                )
            )
    }

    private func activityLocale(
        languageIdentifier: String?
    ) -> Locale {
        guard let languageIdentifier else {
            return .autoupdatingCurrent
        }
        return Locale(identifier: languageIdentifier)
    }

    private func activityLayoutDirection(
        languageIdentifier: String?
    ) -> LayoutDirection {
        let locale = activityLocale(
            languageIdentifier: languageIdentifier
        )
        return locale.language.characterDirection == .rightToLeft
            ? .rightToLeft
            : .leftToRight
    }
}
