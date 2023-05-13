public struct Config: Codable {
    public var socketAddresss: String
    public var ssoHost: String
    public var platformHost: String
    public var fileServer: String
    public var serverName: String
    public var debugToken: String?
    public var server: String

    public init(socketAddresss: String, ssoHost: String, platformHost: String, fileServer: String, serverName: String, debugToken: String? = nil, server: String) {
        self.socketAddresss = socketAddresss
        self.ssoHost = ssoHost
        self.platformHost = platformHost
        self.fileServer = fileServer
        self.serverName = serverName
        self.debugToken = debugToken
        self.server = server
    }
}
