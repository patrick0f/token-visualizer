import Foundation

struct KeychainData: Codable {
    let claudeAiOauth: OAuthCredentials
}

struct OAuthCredentials: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Double

    var isExpired: Bool {
        let expiry = Date(timeIntervalSince1970: expiresAt / 1000)
        return Date() >= expiry
    }
}
