//
//  ExportMessagesViewModel.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import FanapPodChatSDK
import Foundation

protocol ExportMessagesViewModelProtocol {
    init(thread: Conversation)
    var thread: Conversation { get }
    var filePath: URL? { get set }
    var threadId: Int { get }
    func exportChats(startDate: Date, endDate: Date)
    func deleteFile()
}

class ExportMessagesViewModel: ObservableObject, ExportMessagesViewModelProtocol {
    let thread: Conversation

    @Published var filePath: URL?

    var threadId: Int { thread.id ?? 0 }

    required init(thread: Conversation) {
        self.thread = thread
    }

    func exportChats(startDate: Date, endDate: Date) {
        Chat.sharedInstance.exportChat(.init(threadId: threadId, fromTime: UInt(startDate.millisecondsSince1970), toTime: UInt(endDate.millisecondsSince1970))) { [weak self] fileUrl, _, _ in
            self?.filePath = fileUrl
        }
    }

    func deleteFile() {
        guard let url = filePath else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
