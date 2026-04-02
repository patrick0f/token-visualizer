import SwiftUI

@main
struct TokenVisualizerApp: App {
    @StateObject private var api = UsageAPIService()
    private let watcher = StatuslineWatcher()
    @State private var hasStarted = false

    var body: some Scene {
        MenuBarExtra("TokenVisualizer", systemImage: "chart.bar.fill") {
            UsagePopover(api: api)
                .onAppear {
                    guard !hasStarted else { return }
                    hasStarted = true
                    NotificationService.shared.requestPermission()
                    setupWatcher()
                    Task { await api.fetch() }
                    startAutoRefresh()
                }
        }
        .menuBarExtraStyle(.window)
    }

    private func setupWatcher() {
        watcher.onUpdate = { response in
            Task { @MainActor in
                self.api.updateFromStatusline(response)
            }
        }
        watcher.start()
    }

    private func startAutoRefresh() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { @MainActor in
                await self.api.fetch()
            }
        }
    }
}
