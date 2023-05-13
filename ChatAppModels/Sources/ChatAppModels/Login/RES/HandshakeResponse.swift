public struct HandshakeResponse: Codable {
    public let result: HandshakeResponseResult?
    public let reference: String?
    public let status: Int
    public let error: String?
    public let message: String?
    public let timestamp: String?
    public let path: String?

    public init(result: HandshakeResponseResult?, reference: String?, status: Int, error: String?, message: String?, timestamp: String?, path: String?) {
        self.result = result
        self.reference = reference
        self.status = status
        self.error = error
        self.message = message
        self.timestamp = timestamp
        self.path = path
    }
}
