//
//  ExportMessagesViewModel.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import Chat
import Foundation
import ChatModels

public protocol ExportMessagesViewModelProtocol {
    func setup(_ thread: Conversation)
    var thread: Conversation? { get }
    var filePath: URL? { get set }
    var threadId: Int { get }
    func exportChats(startDate: Date, endDate: Date)
    func deleteFile()
}

public final class ExportMessagesViewModel: ObservableObject, ExportMessagesViewModelProtocol {
    public var thread: Conversation?
    public var threadId: Int { thread?.id ?? 0 }
    @Published public var filePath: URL?

    public init() {}

    public func setup(_ thread: Conversation) {
        self.thread = thread
    }

    public func exportChats(startDate: Date, endDate: Date) {
        ChatManager.activeInstance?.exportChat(.init(threadId: threadId, fromTime: UInt(startDate.millisecondsSince1970), toTime: UInt(endDate.millisecondsSince1970))) { [weak self] response in
            self?.filePath = response.result
            self?.objectWillChange.send()
        }
    }

    public func deleteFile() {
        guard let url = filePath else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
