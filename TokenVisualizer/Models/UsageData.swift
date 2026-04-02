import Foundation

struct UsageBucket: Codable, Equatable {
    let utilization: Double
    let resetsAt: String

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    var resetDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: resetsAt) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: resetsAt)
    }

    var timeUntilReset: String {
        guard let reset = resetDate else { return "Unknown" }
        let interval = reset.timeIntervalSince(Date())
        if interval <= 0 { return "Now" }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

struct UsageResponse: Codable, Equatable {
    let fiveHour: UsageBucket
    let sevenDay: UsageBucket

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}

enum UsageLevel {
    case low, medium, high

    static func from(_ percentage: Double) -> UsageLevel {
        if percentage >= 80 { return .high }
        if percentage >= 50 { return .medium }
        return .low
    }
}
