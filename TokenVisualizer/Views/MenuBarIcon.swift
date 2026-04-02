import SwiftUI

struct MenuBarIcon: View {
    let usage: UsageResponse?

    private var level: UsageLevel {
        guard let usage else { return .low }
        let maxUtil = max(usage.fiveHour.utilization, usage.sevenDay.utilization)
        return UsageLevel.from(maxUtil)
    }

    private var iconColor: Color {
        switch level {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 12))
            if let usage {
                Text("\(Int(usage.fiveHour.utilization))%")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(iconColor)
    }
}
