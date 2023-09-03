public struct SSOTokenResponse: Codable {
    public let accessToken: String?
    public let expiresIn: Int
    public let refreshToken: String?
    public let scope: String?
    public let tokenType: String?
    public let idToken: String?
    public let deviceUID: String?

    public init(accessToken: String? = nil, expiresIn: Int, idToken: String? = nil, refreshToken: String? = nil, scope: String? = nil, tokenType: String? = nil, deviceUID: String? = nil) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
        self.deviceUID = deviceUID
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case expiresIn = "expiresIn"
        case refreshToken = "refreshToken"
        case tokenType = "tokenType"
        case idToken = "idToken"
        case deviceUID = "deviceUid"
        case scope = "scope"
    }
}
