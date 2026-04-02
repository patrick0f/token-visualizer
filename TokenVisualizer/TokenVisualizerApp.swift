import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationService.shared.requestPermission()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.findStatusItem()
            self.registerHotkey()
        }
    }

    private func findStatusItem() {
        for window in NSApp.windows {
            let windowName = String(describing: type(of: window))
            if windowName.contains("NSStatusBarWindow") || windowName.contains("MenuBarExtra") {
                if let item = window.value(forKey: "statusItem") as? NSStatusItem {
                    self.statusItem = item
                    return
                }
            }
        }
        // Fallback: try all windows for the key
        for window in NSApp.windows {
            if let item = window.value(forKey: "statusItem") as? NSStatusItem {
                self.statusItem = item
                return
            }
        }
    }

    private func registerHotkey() {
        HotkeyService.shared.register { [weak self] in
            self?.togglePopover()
        }
    }

    func togglePopover() {
        guard let button = statusItem?.button else {
            findStatusItem()
            guard let button = statusItem?.button else { return }
            button.performClick(nil)
            return
        }
        button.performClick(nil)
    }
}

@main
struct TokenVisualizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var api = UsageAPIService()
    private let watcher = StatuslineWatcher()
    @State private var hasStarted = false

    var body: some Scene {
        MenuBarExtra("TokenVisualizer", systemImage: "chart.bar.fill") {
            UsagePopover(api: api)
                .onAppear {
                    guard !hasStarted else { return }
                    hasStarted = true
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
