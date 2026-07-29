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
    var animated = false

    var body: some View {
        switch themeID {
        case .neonOrbit:
            NeonOrbitThemeView(
                percentage: percentage,
                state: state,
                compact: compact,
                animated: animated
            )
        case .auroraPulse:
            AuroraPulseThemeView(
                percentage: percentage,
                state: state,
                compact: compact,
                animated: animated
            )
        case .emberCircuit:
            EmberCircuitThemeView(
                percentage: percentage,
                state: state,
                compact: compact,
                animated: animated
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var haloPulse = false
    @State private var orbitRotation = 0.0

    let percentage: Int?
    let state: ChargingState
    var compact = false
    var animated = false

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

    private var motionEnabled: Bool {
        animated && !compact && !reduceMotion
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.2))
                .blur(radius: compact ? 4 : 14)
                .scaleEffect(
                    motionEnabled
                        ? (haloPulse ? 1.08 : 0.88)
                        : 1
                )
                .opacity(
                    motionEnabled
                        ? (haloPulse ? 0.62 : 0.25)
                        : 0.22
                )

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: compact ? 3 : 7)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.clear,
                            .purple,
                            .cyan,
                            Color.clear
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 1 : 2,
                        lineCap: .round,
                        dash: compact ? [2, 5] : [3, 11]
                    )
                )
                .padding(compact ? 2 : 5)
                .rotationEffect(.degrees(orbitRotation))
                .opacity(0.75)

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
                .shadow(color: accent.opacity(0.8), radius: compact ? 2 : 8)

            if let percentage {
                GeometryReader { proxy in
                    let diameter = min(
                        proxy.size.width,
                        proxy.size.height
                    )
                    let radius =
                        diameter / 2 - (compact ? 2 : 5)

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(
                                width: compact ? 3 : 7,
                                height: compact ? 3 : 7
                            )
                            .shadow(
                                color: accent,
                                radius: compact ? 2 : 7
                            )
                            .offset(y: -radius)
                            .rotationEffect(
                                .degrees(
                                    Double(percentage) * 3.6
                                )
                            )
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                }
                .allowsHitTesting(false)
            }

            VStack(spacing: compact ? 0 : 3) {
                Image(systemName: state.symbolName)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(accent)

                Text(percentage.map { "≈\($0)" } ?? "—")
                    .font(compact ? .caption2.bold() : .title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: percentage)

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
        .task(id: motionEnabled) { @MainActor in
            haloPulse = false
            orbitRotation = 0
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
            ) {
                haloPulse = true
            }
            withAnimation(
                .linear(duration: 7)
                    .repeatForever(autoreverses: false)
            ) {
                orbitRotation = 360
            }
        }
    }
}

private struct AuroraPulseThemeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var auroraShift = false
    @State private var pulse = false

    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let animated: Bool

    private var progress: Double {
        Double(percentage ?? 0) / 100
    }

    private var motionEnabled: Bool {
        animated && !compact && !reduceMotion
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

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.mint.opacity(0.35),
                                Color.cyan.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: compact ? 10 : 34,
                        height: compact ? 34 : 110
                    )
                    .rotationEffect(
                        .degrees(auroraShift ? 28 : -24)
                    )
                    .offset(
                        x: auroraShift
                            ? (compact ? 4 : 17)
                            : (compact ? -5 : -20)
                    )
                    .blur(radius: compact ? 2 : 7)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.pink.opacity(0.28),
                                Color.purple.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: compact ? 12 : 40,
                        height: compact ? 30 : 105
                    )
                    .rotationEffect(
                        .degrees(auroraShift ? -32 : 20)
                    )
                    .offset(
                        x: auroraShift
                            ? (compact ? -5 : -19)
                            : (compact ? 5 : 18)
                    )
                    .blur(radius: compact ? 2 : 8)
            }
            .clipShape(Circle())

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.mint.opacity(0.7),
                            Color.purple.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: compact ? 1 : 3
                )
                .scaleEffect(
                    motionEnabled
                        ? (pulse ? 1.04 : 0.86)
                        : 1
                )
                .opacity(
                    motionEnabled
                        ? (pulse ? 0.2 : 0.72)
                        : 0.44
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
                .shadow(
                    color: Color.cyan.opacity(0.75),
                    radius: compact ? 2 : 8
                )

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
                .scaleEffect(
                    motionEnabled
                        ? (pulse ? 1.08 : 0.9)
                        : 1
                )

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
        .task(id: motionEnabled) { @MainActor in
            auroraShift = false
            pulse = false
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 2.6)
                    .repeatForever(autoreverses: true)
            ) {
                auroraShift = true
            }
            withAnimation(
                .easeInOut(duration: 1.7)
                    .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }
}

private struct EmberCircuitThemeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var circuitPulse = false
    @State private var sparksRotation = 0.0
    @State private var tracePhase = 0.0

    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let animated: Bool

    private var progress: Double {
        Double(percentage ?? 0) / 100
    }

    private var motionEnabled: Bool {
        animated && !compact && !reduceMotion
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
                    .shadow(
                        color: Color.orange.opacity(
                            circuitPulse ? 0.55 : 0.12
                        ),
                        radius: circuitPulse
                            ? (compact ? 2 : 7)
                            : 0
                    )
            }

            Circle()
                .fill(Color.orange.opacity(circuitPulse ? 0.22 : 0.08))
                .blur(radius: compact ? 4 : 14)
                .scaleEffect(circuitPulse ? 0.92 : 0.58)

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
                        lineCap: .round,
                        dash: compact ? [] : [12, 4],
                        dashPhase: tracePhase
                    )
                )
                .padding(compact ? 5 : 15)
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.orange.opacity(0.85),
                    radius: compact ? 2 : 7
                )

            GeometryReader { proxy in
                let diameter = min(
                    proxy.size.width,
                    proxy.size.height
                )
                let radius = diameter * 0.39

                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                index == 0
                                    ? Color.yellow
                                    : Color.orange
                            )
                            .frame(
                                width: compact ? 2 : 5,
                                height: compact ? 2 : 5
                            )
                            .shadow(
                                color: .orange,
                                radius: compact ? 1 : 5
                            )
                            .offset(y: -radius)
                            .rotationEffect(
                                .degrees(
                                    sparksRotation
                                        + Double(index) * 120
                                )
                            )
                    }
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            }
            .allowsHitTesting(false)

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
        .task(id: motionEnabled) { @MainActor in
            circuitPulse = false
            sparksRotation = 0
            tracePhase = 0
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 1.25)
                    .repeatForever(autoreverses: true)
            ) {
                circuitPulse = true
            }
            withAnimation(
                .linear(duration: 8)
                    .repeatForever(autoreverses: false)
            ) {
                sparksRotation = 360
            }
            withAnimation(
                .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
            ) {
                tracePhase = -32
            }
        }
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
                .contentTransition(.numericText())
                .animation(.snappy, value: percentage)

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
