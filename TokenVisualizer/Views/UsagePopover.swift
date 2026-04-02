import SwiftUI

struct UsagePopover: View {
    @ObservedObject var api: UsageAPIService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let usage = api.usage {
                UsageBar(
                    label: "Current session",
                    percentage: usage.fiveHour.utilization,
                    resetText: usage.fiveHour.timeUntilReset
                )

                UsageBar(
                    label: "Weekly \u{2014} All models",
                    percentage: usage.sevenDay.utilization,
                    resetText: usage.sevenDay.timeUntilReset
                )
            } else if let error = api.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                if let lastUpdated = api.lastUpdated {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        if let source = api.lastSource {
                            Text("via \(source)")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                Button {
                    Task { await api.fetch() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(api.isLoading)
            }

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { LaunchAtLogin.isEnabled },
                set: { LaunchAtLogin.isEnabled = $0 }
            ))
            .font(.system(size: 13))
            .toggleStyle(.checkbox)

            Button("Quit TokenVisualizer") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 13))
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 280)
    }
}
