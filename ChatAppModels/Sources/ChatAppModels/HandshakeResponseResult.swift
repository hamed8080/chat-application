public struct HandshakeResponseResult: Codable {
    public let keyId: String?
    public let expiresIn: Int

    public init(keyId: String? = nil, expiresIn: Int) {
        self.keyId = keyId
        self.expiresIn = expiresIn
    }
}
