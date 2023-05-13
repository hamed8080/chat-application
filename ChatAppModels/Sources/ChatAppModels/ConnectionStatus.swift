import Chat
public enum ConnectionStatus: Int {
    case connecting = 0
    case disconnected = 1
    case reconnecting = 2
    case unauthorized = 3
    case connected = 4

    public var stringValue: String {
        switch self {
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        case .reconnecting: return "reconnectiong"
        case .unauthorized: return "un authorized"
        }
    }
}
