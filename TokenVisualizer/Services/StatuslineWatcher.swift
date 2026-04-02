import Foundation

struct StatuslineRateLimits: Codable {
    let fiveHour: StatuslineBucket
    let sevenDay: StatuslineBucket

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }

    func toUsageResponse() -> UsageResponse {
        UsageResponse(
            fiveHour: fiveHour.toUsageBucket(),
            sevenDay: sevenDay.toUsageBucket()
        )
    }
}

struct StatuslineBucket: Codable {
    let usedPercentage: Double
    let resetsAt: Double

    enum CodingKeys: String, CodingKey {
        case usedPercentage = "used_percentage"
        case resetsAt = "resets_at"
    }

    func toUsageBucket() -> UsageBucket {
        let date = Date(timeIntervalSince1970: resetsAt)
        let formatter = ISO8601DateFormatter()
        return UsageBucket(
            utilization: usedPercentage,
            resetsAt: formatter.string(from: date)
        )
    }
}

final class StatuslineWatcher: ObservableObject, @unchecked Sendable {
    static let filePath = "/tmp/token-visualizer-usage.json"

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    var onUpdate: ((UsageResponse) -> Void)?

    func start() {
        readFile()
        watchFile()
    }

    func stop() {
        source?.cancel()
        source = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func watchFile() {
        source?.cancel()
        if fileDescriptor >= 0 { close(fileDescriptor) }

        fileDescriptor = open(Self.filePath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.watchFile()
            }
            return
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: .global()
        )

        src.setEventHandler { [weak self] in
            let flags = src.data
            if flags.contains(.delete) || flags.contains(.rename) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.watchFile()
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.readFile()
            }
        }

        src.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }

        source = src
        src.resume()
    }

    private func readFile() {
        guard let data = FileManager.default.contents(atPath: Self.filePath) else { return }
        guard let parsed = try? JSONDecoder().decode(StatuslineRateLimits.self, from: data) else { return }
        onUpdate?(parsed.toUsageResponse())
    }
}
