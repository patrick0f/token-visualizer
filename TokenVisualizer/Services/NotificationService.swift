import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private var firedThresholds: Set<String> = []
    private let thresholds: [Double] = [80, 95]

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkThresholds(usage: UsageResponse) {
        checkBucket(name: "Session", percentage: usage.fiveHour.utilization, resetText: usage.fiveHour.timeUntilReset)
        checkBucket(name: "Weekly", percentage: usage.sevenDay.utilization, resetText: usage.sevenDay.timeUntilReset)
    }

    private func checkBucket(name: String, percentage: Double, resetText: String) {
        for threshold in thresholds {
            let key = "\(name)_\(Int(threshold))"

            if percentage >= threshold && !firedThresholds.contains(key) {
                firedThresholds.insert(key)
                sendNotification(
                    title: "\(name) usage at \(Int(percentage))%",
                    body: "Resets in \(resetText)",
                    isCritical: threshold >= 95
                )
            } else if percentage < threshold {
                firedThresholds.remove(key)
            }
        }
    }

    private func sendNotification(title: String, body: String, isCritical: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if isCritical {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
