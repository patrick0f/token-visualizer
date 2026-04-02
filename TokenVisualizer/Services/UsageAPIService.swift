
import Foundation

enum APIError: Error, LocalizedError {
    case rateLimited
    case httpError(Int)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .rateLimited: return "Rate limited — try again later"
        case .httpError(let code): return "HTTP \(code)"
        case .networkError(let err): return err.localizedDescription
        case .invalidResponse: return "Invalid API response"
        }
    }
}

@MainActor
final class UsageAPIService: ObservableObject {
    @Published var usage: UsageResponse?
    @Published var lastUpdated: Date?
    @Published var lastSource: String?
    @Published var error: String?
    @Published var isLoading = false

    private let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let refreshURL = URL(string: "https://console.anthropic.com/v1/oauth/token")!
    private var cachedToken: String?
    private var tokenExpiry: Date?

    func updateFromStatusline(_ response: UsageResponse) {
        if let existing = usage {
            var merged = response
            if merged.extraUsage == nil, let extra = existing.extraUsage {
                merged = UsageResponse(fiveHour: merged.fiveHour, sevenDay: merged.sevenDay, extraUsage: extra)
            }
            usage = merged
        } else {
            usage = response
        }
        lastUpdated = Date()
        lastSource = "statusline"
        error = nil
    }

    func fetch() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let token = try await getValidToken()
            let data = try await fetchUsage(token: token)
            let decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
            usage = decoded
            lastUpdated = Date()
        } catch let err as KeychainError {
            error = err.localizedDescription
        } catch let err as APIError {
            error = err.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func getValidToken() async throws -> String {
        if let token = cachedToken, let expiry = tokenExpiry, Date() < expiry {
            return token
        }

        let credentials = try KeychainService.readCredentials()

        if !credentials.isExpired {
            cachedToken = credentials.accessToken
            tokenExpiry = Date(timeIntervalSince1970: credentials.expiresAt / 1000)
            return credentials.accessToken
        }

        return try await refreshToken(credentials.refreshToken)
    }

    private func refreshToken(_ refreshToken: String) async throws -> String {
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        struct RefreshResponse: Codable {
            let accessToken: String
            let expiresIn: Int

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case expiresIn = "expires_in"
            }
        }

        let refreshed = try JSONDecoder().decode(RefreshResponse.self, from: data)
        cachedToken = refreshed.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(refreshed.expiresIn))
        return refreshed.accessToken
    }

    private func fetchUsage(token: String) async throws -> Data {
        var request = URLRequest(url: usageURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 429 {
            throw APIError.rateLimited
        }
        guard http.statusCode == 200 else {
            throw APIError.httpError(http.statusCode)
        }

        return data
    }
}
