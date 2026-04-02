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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.osError(status)
        }
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        do {
            let wrapper = try JSONDecoder().decode(KeychainData.self, from: data)
            return wrapper.claudeAiOauth
        } catch {
            throw KeychainError.unexpectedData
        }
    }
}
