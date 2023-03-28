//
//  ExportMessagesViewModel.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import FanapPodChatSDK
import Foundation

protocol ExportMessagesViewModelProtocol {
    func setup(_ thread: Conversation)
    var thread: Conversation? { get }
    var filePath: URL? { get set }
    var threadId: Int { get }
    func exportChats(startDate: Date, endDate: Date)
    func deleteFile()
}

final class ExportMessagesViewModel: ObservableObject, ExportMessagesViewModelProtocol {
    var thread: Conversation?
    var threadId: Int { thread?.id ?? 0 }
    @Published var filePath: URL?

    init() {}

    func setup(_ thread: Conversation) {
        self.thread = thread
    }

    func exportChats(startDate: Date, endDate: Date) {
        ChatManager.activeInstance?.exportChat(.init(threadId: threadId, fromTime: UInt(startDate.millisecondsSince1970), toTime: UInt(endDate.millisecondsSince1970))) { [weak self] response in
            self?.filePath = response.result
            self?.objectWillChange.send()
        }
    }

    func deleteFile() {
        guard let url = filePath else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
