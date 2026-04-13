import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case unexpectedData
    case osError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound: return "Claude Code credentials not found in Keychain"
        case .unexpectedData: return "Could not parse Keychain data"
        case .osError(let status): return "Keychain error: \(status)"
        }
    }
}

struct KeychainService {
    static let serviceName = "Claude Code-credentials"

    static func readCredentials() throws -> OAuthCredentials {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", serviceName, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw KeychainError.itemNotFound
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard !data.isEmpty else {
            throw KeychainError.unexpectedData
        }

        // security -w outputs base64-encoded password data with a trailing newline
        let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let decoded = Data(base64Encoded: raw) ?? raw.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        do {
            let wrapper = try JSONDecoder().decode(KeychainData.self, from: decoded)
            return wrapper.claudeAiOauth
        } catch {
            throw KeychainError.unexpectedData
        }
    }
}
