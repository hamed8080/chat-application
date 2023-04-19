import Chat
import ChatModels

public struct StartThreadModel {
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var totalCount = 0
    public private(set) var threads: [Conversation] = []

    public init() {}

    public func hasNext() -> Bool {
        threads.count < totalCount
    }

    public mutating func preparePaginiation() {
        offset = count + offset
    }

    public mutating func setContentCount(totalCount: Int) {
        self.totalCount = totalCount
    }

    public mutating func setThreads(threads: [Conversation]) {
        self.threads = threads
    }

    public mutating func appendThreads(threads: [Conversation]) {
        self.threads.append(contentsOf: threads)
    }

    public mutating func clear() {
        offset = 0
        count = 15
        totalCount = 0
        threads = []
    }

    public mutating func pinThread(_ thread: Conversation) {
        threads.first(where: { $0.id == thread.id })?.pin = true
    }

    public mutating func unpinThread(_ thread: Conversation) {
        threads.first(where: { $0.id == thread.id })?.pin = false
    }

    public mutating func removeThread(_ thread: Conversation) {
        guard let index = threads.firstIndex(of: thread) else { return }
        threads.remove(at: index)
    }
}
