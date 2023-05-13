public struct VerifyRequest: Encodable {
    public let identity: String
    public let keyId: String
    public let otp: String

    public init(identity: String, keyId: String, otp: String) {
        self.identity = identity
        self.keyId = keyId
        self.otp = otp
    }

    private enum CodingKeys: String, CodingKey {
        case otp, identity
    }
}
