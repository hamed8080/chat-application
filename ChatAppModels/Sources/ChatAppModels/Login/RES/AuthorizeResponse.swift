public struct AuthorizeResponse: Codable {
    public let expiresIn: Int?
    public let identity: String?
    public let type: String?
    public let userId: String?
    public let codeLength: Int?
    public let sentBefore: Bool?

    enum CodingKeys: String, CodingKey {
        case expiresIn = "expires_in"
        case identity = "identity"
        case type = "type"
        case userId = "user_id"
        case codeLength = "codeLength"
        case sentBefore = "sent_before"
    }
}
