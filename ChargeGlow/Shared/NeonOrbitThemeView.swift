import SwiftUI

enum ThemeID: String, Codable, CaseIterable, Hashable, Sendable {
    case neonOrbit = "neon-orbit"
    case auroraPulse = "aurora-pulse"
    case emberCircuit = "ember-circuit"
}

struct ThemeDescriptor: Identifiable, Equatable, Sendable {
    let id: ThemeID
    let sortOrder: Int
}

enum ThemeCatalog {
    static let all: [ThemeDescriptor] = [
        ThemeDescriptor(id: .neonOrbit, sortOrder: 0),
        ThemeDescriptor(id: .auroraPulse, sortOrder: 1),
        ThemeDescriptor(id: .emberCircuit, sortOrder: 2)
    ]

    static func resolve(_ rawValue: String) -> ThemeID {
        ThemeID(rawValue: rawValue) ?? .neonOrbit
    }
}

struct ChargingThemeView: View {
    let themeID: ThemeID
    let percentage: Int?
    let state: ChargingState
    var compact = false

    var body: some View {
        switch themeID {
        case .neonOrbit:
            NeonOrbitThemeView(
                percentage: percentage,
                state: state,
                compact: compact
            )
        case .auroraPulse:
            AuroraPulseThemeView(
                percentage: percentage,
                state: state,
                compact: compact
            )
        case .emberCircuit:
            EmberCircuitThemeView(
                percentage: percentage,
                state: state,
                compact: compact
            )
        }
    }
}

struct ChargingThemeMark: View {
    let themeID: ThemeID
    let state: ChargingState

    var body: some View {
        ZStack {
            switch themeID {
            case .neonOrbit:
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .purple],
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
            case .auroraPulse:
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.mint, .cyan, .purple, .pink],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
            case .emberCircuit:
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            }

            Image(systemName: state.symbolName)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
    }
}

struct NeonOrbitThemeView: View {
    @Environment(\.locale) private var locale

    let percentage: Int?
    let state: ChargingState
    var compact = false

    private var progress: Double {
        Double(percentage ?? 0) / 100
    }

    private var accent: Color {
        switch state {
        case .full:
            return .green
        case .disconnected:
            return .secondary
        case .unknown:
            return .orange
        case .charging:
            return .cyan
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: compact ? 3 : 7)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.purple, .blue, accent, .purple],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 3 : 7,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: compact ? 0 : 3) {
                Image(systemName: state.symbolName)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(accent)

                Text(percentage.map { "≈\($0)" } ?? "—")
                    .font(compact ? .caption2.bold() : .title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(.white)

                if !compact {
                    Text("%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            themeAccessibilityDescription(
                percentage: percentage,
                state: state,
                locale: locale
            )
        )
    }
}

private struct AuroraPulseThemeView: View {
    @Environment(\.locale) private var locale

    let percentage: Int?
    let state: ChargingState
    let compact: Bool

    private var progress: Double {
        Double(percentage ?? 0) / 100
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.24),
                            Color.purple.opacity(0.16),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: compact ? 24 : 70
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: compact ? 2 : 5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.mint, .cyan, .purple, .pink],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 4 : 9,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.35),
                            Color.purple.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: compact ? 12 : 32,
                    height: compact ? 28 : 82
                )
                .blur(radius: compact ? 2 : 5)

            ThemeBatteryReadout(
                percentage: percentage,
                state: state,
                compact: compact,
                accent: state.themeAccent
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            themeAccessibilityDescription(
                percentage: percentage,
                state: state,
                locale: locale
            )
        )
    }
}

private struct EmberCircuitThemeView: View {
    @Environment(\.locale) private var locale

    let percentage: Int?
    let state: ChargingState
    let compact: Bool

    private var progress: Double {
        Double(percentage ?? 0) / 100
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 8 : 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.04, blue: 0.02),
                            Color.black.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: compact ? 6 : 18)
                    .stroke(
                        Color.orange.opacity(0.32 - Double(index) * 0.08),
                        lineWidth: compact ? 1 : 2
                    )
                    .padding(CGFloat(index) * (compact ? 3 : 9) + 3)
            }

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.yellow, .orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 3 : 7,
                        lineCap: .square
                    )
                )
                .padding(compact ? 5 : 15)
                .rotationEffect(.degrees(-90))

            ThemeBatteryReadout(
                percentage: percentage,
                state: state,
                compact: compact,
                accent: state == .charging ? .orange : state.themeAccent
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            themeAccessibilityDescription(
                percentage: percentage,
                state: state,
                locale: locale
            )
        )
    }
}

private struct ThemeBatteryReadout: View {
    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: compact ? 0 : 3) {
            Image(systemName: state.symbolName)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(accent)

            Text(percentage.map { "≈\($0)" } ?? "—")
                .font(compact ? .caption2.bold() : .title2.bold())
                .monospacedDigit()
                .foregroundStyle(.white)

            if !compact {
                Text("%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension ChargingState {
    var themeAccent: Color {
        switch self {
        case .full:
            return .green
        case .disconnected:
            return .secondary
        case .unknown:
            return .orange
        case .charging:
            return .cyan
        }
    }
}

private func themeAccessibilityDescription(
    percentage: Int?,
    state: ChargingState,
    locale: Locale
) -> String {
    let stateName = localizedStateName(state, locale: locale)
    if let percentage {
        return String(
            format: String(
                localized: "Approximately %lld percent, %@",
                locale: locale
            ),
            locale: locale,
            percentage,
            stateName
        )
    }
    return String(
        format: String(
            localized: "Battery percentage unavailable, %@",
            locale: locale
        ),
        locale: locale,
        stateName
    )
}

private func localizedStateName(
    _ state: ChargingState,
    locale: Locale
) -> String {
    switch state {
    case .unknown:
        return String(localized: "Unknown", locale: locale)
    case .disconnected:
        return String(localized: "Disconnected", locale: locale)
    case .charging:
        return String(localized: "Charging", locale: locale)
    case .full:
        return String(localized: "Fully Charged", locale: locale)
    }
}
