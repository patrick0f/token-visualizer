import SwiftUI

struct UsageBar: View {
    let label: String
    let percentage: Double
    let resetText: String

    private var barColor: Color {
        switch UsageLevel.from(percentage) {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: max(0, geo.size.width * percentage / 100), height: 6)
                }
            }
            .frame(height: 6)

            Text("Resets in \(resetText)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
