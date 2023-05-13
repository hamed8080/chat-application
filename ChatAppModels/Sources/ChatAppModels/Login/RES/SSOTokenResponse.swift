public struct SSOTokenResponse: Codable {
    public let result: SSOTokenResponseResult?
}

public struct SSOTokenResponseResult: Codable {
    public let accessToken: String?
    public let expiresIn: Int
    public let idToken: String?
    public let refreshToken: String?
    public let scope: String?
    public let tokenType: String?

    public init(accessToken: String? = nil, expiresIn: Int, idToken: String? = nil, refreshToken: String? = nil, scope: String? = nil, tokenType: String? = nil) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case scope
    }
}
