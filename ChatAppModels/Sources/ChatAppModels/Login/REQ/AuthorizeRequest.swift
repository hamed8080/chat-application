public struct AuthorizeRequest: Encodable {
    public let identity: String
    public let keyId: String

    public init(identity: String, keyId: String) {
        self.identity = identity
        self.keyId = keyId
    }

    private enum CodingKeys: String, CodingKey {
        case identity
    }
}
