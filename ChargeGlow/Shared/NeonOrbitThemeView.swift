import SwiftUI

enum ThemeID: String, Codable, CaseIterable, Hashable, Sendable {
    case neonOrbit = "neon-orbit"
    case auroraPulse = "aurora-pulse"
    case emberCircuit = "ember-circuit"
    case aquaFlux = "aqua-flux"
    case plasmaCore = "plasma-core"
    case lumenBloom = "lumen-bloom"
}

struct ThemeDescriptor: Identifiable, Equatable, Sendable {
    let id: ThemeID
    let sortOrder: Int
}

enum ThemeCatalog {
    static let all: [ThemeDescriptor] = [
        ThemeDescriptor(id: .neonOrbit, sortOrder: 0),
        ThemeDescriptor(id: .auroraPulse, sortOrder: 1),
        ThemeDescriptor(id: .emberCircuit, sortOrder: 2),
        ThemeDescriptor(id: .aquaFlux, sortOrder: 3),
        ThemeDescriptor(id: .plasmaCore, sortOrder: 4),
        ThemeDescriptor(id: .lumenBloom, sortOrder: 5)
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
        case .aquaFlux:
            AquaFluxThemeView(
                percentage: percentage,
                state: state,
                compact: compact,
                animated: animated
            )
        case .plasmaCore:
            PlasmaCoreThemeView(
                percentage: percentage,
                state: state,
                compact: compact,
                animated: animated
            )
        case .lumenBloom:
            LumenBloomThemeView(
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
            case .aquaFlux:
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            case .plasmaCore:
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, .pink, .purple],
                            center: .center,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
            case .lumenBloom:
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.green, .mint, .yellow, .green],
                            center: .center
                        ),
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            dash: [2, 2]
                        )
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
                            .scaleEffect(
                                motionEnabled
                                    ? (haloPulse ? 1.35 : 0.78)
                                    : 1
                            )
                            .opacity(
                                motionEnabled
                                    ? (haloPulse ? 1 : 0.58)
                                    : 1
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

            ThemeBatteryReadout(
                percentage: percentage,
                state: state,
                compact: compact,
                accent: accent,
                animated: motionEnabled
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
    @State private var auroraRotation = 0.0

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
                .rotationEffect(.degrees(auroraRotation))

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
                accent: state.themeAccent,
                animated: motionEnabled
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
            auroraRotation = 0
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
            withAnimation(
                .linear(duration: 13)
                    .repeatForever(autoreverses: false)
            ) {
                auroraRotation = 360
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
                    .scaleEffect(
                        motionEnabled
                            ? (
                                circuitPulse
                                    ? 1 - Double(index) * 0.008
                                    : 0.94 + Double(index) * 0.012
                            )
                            : 1
                    )
                    .opacity(
                        motionEnabled
                            ? (
                                circuitPulse
                                    ? 0.9 - Double(index) * 0.12
                                    : 0.42 + Double(index) * 0.08
                            )
                            : 1
                    )
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
                accent: state == .charging ? .orange : state.themeAccent,
                animated: motionEnabled
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

private struct AquaFluxThemeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var wavePhase: CGFloat = 0
    @State private var bubbleDrift = false
    @State private var surfaceShimmer = false

    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let animated: Bool

    private var progress: Double {
        min(max(Double(percentage ?? 0) / 100, 0), 1)
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
                            Color(red: 0.02, green: 0.2, blue: 0.32),
                            Color(red: 0.01, green: 0.04, blue: 0.12)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: compact ? 35 : 110
                    )
                )

            LiquidWaveShape(
                fillLevel: CGFloat(progress),
                phase: wavePhase
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.82),
                        Color.blue.opacity(0.55),
                        Color.indigo.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .padding(compact ? 3 : 8)
            .clipShape(Circle())
            .shadow(
                color: Color.cyan.opacity(0.55),
                radius: compact ? 2 : 9
            )

            LiquidWaveShape(
                fillLevel: max(CGFloat(progress) - 0.045, 0),
                phase: wavePhase + .pi
            )
            .fill(Color.white.opacity(0.16))
            .padding(compact ? 3 : 8)
            .clipShape(Circle())

            GeometryReader { proxy in
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.65),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: compact ? 4 : 18,
                            height: compact ? 32 : 118
                        )
                        .rotationEffect(.degrees(24))
                        .offset(
                            x: surfaceShimmer
                                ? proxy.size.width * 0.48
                                : -proxy.size.width * 0.48
                        )
                        .blur(radius: compact ? 1 : 5)
                        .opacity(motionEnabled ? 0.24 : 0)
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            }
            .clipShape(Circle())
            .allowsHitTesting(false)

            GeometryReader { proxy in
                let diameter = min(
                    proxy.size.width,
                    proxy.size.height
                )

                ZStack {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.46))
                            .frame(
                                width: compact
                                    ? CGFloat(2 + index % 2)
                                    : CGFloat(4 + index % 3),
                                height: compact
                                    ? CGFloat(2 + index % 2)
                                    : CGFloat(4 + index % 3)
                            )
                            .offset(
                                x: diameter
                                    * (
                                        CGFloat(index) * 0.13
                                            - 0.2
                                    ),
                                y: bubbleDrift
                                    ? -diameter
                                        * (
                                            0.12
                                                + CGFloat(index) * 0.05
                                        )
                                    : diameter
                                        * (
                                            0.14
                                                - CGFloat(index) * 0.03
                                        )
                            )
                            .opacity(
                                motionEnabled
                                    ? (bubbleDrift ? 0.08 : 0.72)
                                    : 0.34
                            )
                    }
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            }
            .clipShape(Circle())
            .allowsHitTesting(false)

            Circle()
                .stroke(
                    Color.white.opacity(0.14),
                    lineWidth: compact ? 2 : 5
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.white, .cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 3 : 7,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.cyan.opacity(0.78),
                    radius: compact ? 2 : 7
                )

            ThemeBatteryReadout(
                percentage: percentage,
                state: state,
                compact: compact,
                accent: state == .charging ? .cyan : state.themeAccent,
                animated: motionEnabled
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
            wavePhase = 0
            bubbleDrift = false
            surfaceShimmer = false
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .linear(duration: 3.2)
                    .repeatForever(autoreverses: false)
            ) {
                wavePhase = .pi * 2
            }
            withAnimation(
                .easeInOut(duration: 2.2)
                    .repeatForever(autoreverses: true)
            ) {
                bubbleDrift = true
            }
            withAnimation(
                .easeInOut(duration: 3.8)
                    .repeatForever(autoreverses: true)
            ) {
                surfaceShimmer = true
            }
        }
    }
}

private struct PlasmaCoreThemeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var corePulse = false
    @State private var plasmaRotation = 0.0

    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let animated: Bool

    private var progress: Double {
        min(max(Double(percentage ?? 0) / 100, 0), 1)
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
                            Color.pink.opacity(0.24),
                            Color.purple.opacity(0.2),
                            Color.black.opacity(0.96)
                        ],
                        center: .center,
                        startRadius: compact ? 2 : 5,
                        endRadius: compact ? 28 : 82
                    )
                )

            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.clear,
                                index == 1 ? .pink : .purple,
                                .white.opacity(0.7),
                                Color.clear
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(
                            lineWidth: compact ? 1 : 2,
                            lineCap: .round,
                            dash: compact ? [2, 4] : [7, 10]
                        )
                    )
                    .frame(
                        width: compact ? 34 : 112,
                        height: compact
                            ? CGFloat(14 + index * 3)
                            : CGFloat(42 + index * 9)
                    )
                    .rotationEffect(
                        .degrees(
                            plasmaRotation
                                * Double(
                                    index.isMultiple(of: 2) ? 1 : -1
                                )
                                + Double(index) * 58
                        )
                    )
                    .opacity(0.72 - Double(index) * 0.12)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            .pink,
                            .purple,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: compact ? 13 : 38
                    )
                )
                .frame(
                    width: compact ? 22 : 68,
                    height: compact ? 22 : 68
                )
                .scaleEffect(
                    motionEnabled
                        ? (corePulse ? 1.12 : 0.82)
                        : 0.94
                )
                .opacity(
                    motionEnabled
                        ? (corePulse ? 0.95 : 0.56)
                        : 0.7
                )
                .hueRotation(
                    .degrees(
                        motionEnabled
                            ? (corePulse ? 16 : -12)
                            : 0
                    )
                )
                .blur(radius: compact ? 1 : 3)
                .shadow(
                    color: Color.pink.opacity(0.9),
                    radius: compact ? 3 : 14
                )

            Circle()
                .stroke(
                    Color.white.opacity(0.12),
                    lineWidth: compact ? 2 : 5
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.pink, .white, .purple, .pink],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 3 : 7,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.pink.opacity(0.8),
                    radius: compact ? 2 : 8
                )

            ThemeBatteryReadout(
                percentage: percentage,
                state: state,
                compact: compact,
                accent: state == .charging ? .pink : state.themeAccent,
                animated: motionEnabled
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
            corePulse = false
            plasmaRotation = 0
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 1.35)
                    .repeatForever(autoreverses: true)
            ) {
                corePulse = true
            }
            withAnimation(
                .linear(duration: 8.5)
                    .repeatForever(autoreverses: false)
            ) {
                plasmaRotation = 360
            }
        }
    }
}

private struct LumenBloomThemeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var bloomPulse = false
    @State private var bloomRotation = 0.0

    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let animated: Bool

    private var progress: Double {
        min(max(Double(percentage ?? 0) / 100, 0), 1)
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
                            Color.green.opacity(0.18),
                            Color(red: 0.015, green: 0.1, blue: 0.07),
                            Color.black.opacity(0.94)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: compact ? 30 : 90
                    )
                )

            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    index.isMultiple(of: 2)
                                        ? Color.mint
                                        : Color.yellow,
                                    Color.green.opacity(0.14)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: compact ? 6 : 18,
                            height: compact ? 18 : 58
                        )
                        .scaleEffect(
                            motionEnabled
                                ? (
                                    bloomPulse
                                        ? (
                                            index.isMultiple(of: 2)
                                                ? 1.08
                                                : 0.92
                                        )
                                        : (
                                            index.isMultiple(of: 2)
                                                ? 0.92
                                                : 1.08
                                        )
                                )
                                : 1
                        )
                        .offset(y: compact ? -11 : -38)
                        .rotationEffect(
                            .degrees(
                                Double(index) * 45
                                    + bloomRotation
                            )
                        )
                        .opacity(
                            0.34
                                + Double(index % 3) * 0.13
                        )
                        .shadow(
                            color: Color.mint.opacity(0.5),
                            radius: compact ? 1 : 5
                        )
                }
            }
            .scaleEffect(
                motionEnabled
                    ? (bloomPulse ? 1.04 : 0.84)
                    : 0.92
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            .yellow,
                            .green,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: compact ? 10 : 30
                    )
                )
                .frame(
                    width: compact ? 19 : 58,
                    height: compact ? 19 : 58
                )
                .opacity(bloomPulse ? 0.95 : 0.68)
                .shadow(
                    color: Color.green.opacity(0.8),
                    radius: compact ? 2 : 10
                )

            Circle()
                .stroke(
                    Color.white.opacity(0.11),
                    lineWidth: compact ? 2 : 5
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.green, .mint, .yellow, .green],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: compact ? 3 : 7,
                        lineCap: .round,
                        dash: compact ? [] : [5, 3]
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.green.opacity(0.78),
                    radius: compact ? 2 : 8
                )

            ThemeBatteryReadout(
                percentage: percentage,
                state: state,
                compact: compact,
                accent: state == .charging ? .mint : state.themeAccent,
                animated: motionEnabled
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
            bloomPulse = false
            bloomRotation = 0
            guard motionEnabled else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 1.9)
                    .repeatForever(autoreverses: true)
            ) {
                bloomPulse = true
            }
            withAnimation(
                .linear(duration: 18)
                    .repeatForever(autoreverses: false)
            ) {
                bloomRotation = 360
            }
        }
    }
}

private struct LiquidWaveShape: Shape {
    var fillLevel: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let normalizedLevel = min(max(fillLevel, 0), 1)
        let waterline = rect.height * (1 - normalizedLevel)
        let amplitude = max(rect.height * 0.035, 1)
        let step = max(rect.width / 48, 1)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: waterline))

        var x: CGFloat = 0
        while x <= rect.width {
            let normalizedX = x / max(rect.width, 1)
            let y = waterline
                + sin(normalizedX * .pi * 2 + phase)
                    * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(
            to: CGPoint(
                x: rect.width,
                y: rect.height
            )
        )
        path.closeSubpath()
        return path
    }
}

private struct ThemeBatteryReadout: View {
    @State private var energyPulse = false

    let percentage: Int?
    let state: ChargingState
    let compact: Bool
    let accent: Color
    let animated: Bool

    private var energyActive: Bool {
        animated && state == .charging
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    accent.opacity(
                        energyActive
                            ? (energyPulse ? 0.52 : 0.12)
                            : 0
                    ),
                    lineWidth: compact ? 1 : 2
                )
                .blur(radius: compact ? 1 : 4)
                .scaleEffect(
                    energyActive
                        ? (energyPulse ? 1.12 : 0.94)
                        : 1
                )
                .frame(
                    width: compact ? 31 : 71,
                    height: compact ? 31 : 71
                )

            Circle()
                .fill(
                    Color.black.opacity(
                        compact ? 0.58 : 0.46
                    )
                )
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    accent.opacity(0.42),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: compact ? 0.7 : 1
                        )
                }
                .shadow(
                    color: Color.black.opacity(0.42),
                    radius: compact ? 2 : 7
                )
                .frame(
                    width: compact ? 30 : 68,
                    height: compact ? 30 : 68
                )

            VStack(spacing: compact ? 0 : 3) {
                Image(systemName: state.symbolName)
                    .font(compact ? .system(size: 8) : .caption)
                    .foregroundStyle(accent)
                    .scaleEffect(
                        energyActive
                            ? (energyPulse ? 1.16 : 0.9)
                            : 1
                    )
                    .shadow(
                        color: accent.opacity(
                            energyActive
                                ? (energyPulse ? 0.82 : 0.18)
                                : 0
                        ),
                        radius: compact ? 1 : 4
                    )

                Text(percentage.map { "≈\($0)" } ?? "—")
                    .font(
                        compact
                            ? .system(size: 10, weight: .bold)
                            : .title2.bold()
                    )
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                    .frame(
                        maxWidth: compact ? 27 : 62
                    )
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
        .accessibilityHidden(true)
        .task(id: energyActive) { @MainActor in
            energyPulse = false
            guard energyActive else {
                return
            }
            await Task.yield()
            withAnimation(
                .easeInOut(duration: 1.15)
                    .repeatForever(autoreverses: true)
            ) {
                energyPulse = true
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
