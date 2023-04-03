//
//  StartThreadModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation

struct StartThreadModel {
    private(set) var count = 15
    private(set) var offset = 0
    private(set) var totalCount = 0
    private(set) var threads: [Conversation] = []

    func hasNext() -> Bool {
        threads.count < totalCount
    }

    mutating func preparePaginiation() {
        offset = count + offset
    }

    mutating func setContentCount(totalCount: Int) {
        self.totalCount = totalCount
    }

    mutating func setThreads(threads: [Conversation]) {
        self.threads = threads
    }

    mutating func appendThreads(threads: [Conversation]) {
        self.threads.append(contentsOf: threads)
    }

    mutating func clear() {
        offset = 0
        count = 15
        totalCount = 0
        threads = []
    }

    mutating func pinThread(_ thread: Conversation) {
        threads.first(where: { $0.id == thread.id })?.pin = true
    }

    mutating func unpinThread(_ thread: Conversation) {
        threads.first(where: { $0.id == thread.id })?.pin = false
    }

    mutating func removeThread(_ thread: Conversation) {
        guard let index = threads.firstIndex(of: thread) else { return }
        threads.remove(at: index)
    }
}

extension StartThreadModel {
    mutating func setupPreview() {
        appendThreads(threads: MockData.generateThreads())
    }
}
