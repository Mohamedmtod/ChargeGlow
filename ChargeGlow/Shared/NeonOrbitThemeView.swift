import SwiftUI

struct NeonOrbitThemeView: View {
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
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        if let percentage {
            return String(
                format: String(localized: "Approximately %lld percent, %@"),
                locale: Locale.current,
                percentage,
                state.displayName
            )
        }
        return String(
            format: String(localized: "Battery percentage unavailable, %@"),
            locale: Locale.current,
            state.displayName
        )
    }
}
