public struct AuthorizeResponse: Codable {
    public let result: AuthorizeResponseResult?
}

public struct AuthorizeResponseResult: Codable {
    public let identity: String?
    public let type: String?
    public let userId: String?
    public let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case expiresIn = "expires_in"
        case userId = "user_id"
        case type, identity
    }
}
