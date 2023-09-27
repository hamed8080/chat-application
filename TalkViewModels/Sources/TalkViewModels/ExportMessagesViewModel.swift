//
//  ExportMessagesViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Chat
import Foundation
import ChatModels
import Combine
import ChatCore
import ChatDTO

public protocol ExportMessagesViewModelProtocol {
    var thread: Conversation? { get set }
    var filePath: URL? { get set }
    var threadId: Int { get }
    func exportChats(startDate: Date, endDate: Date)
    func deleteFile()
}

public final class ExportMessagesViewModel: ObservableObject, ExportMessagesViewModelProtocol {
    public weak var thread: Conversation?
    public var threadId: Int { thread?.id ?? 0 }
    public var filePath: URL?
    private var cancelable: Set<AnyCancellable> = []

    public init() {
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] value in
                if case let .export(response) = value {
                    self?.onExport(response)
                }
            }
            .store(in: &cancelable)
    }

    private func onExport(_ response: ChatResponse<URL>) {
        filePath = response.result
        animateObjectWillChange()
    }

    public func exportChats(startDate: Date, endDate: Date) {
        let req = GetHistoryRequest(threadId: threadId, fromTime: UInt(startDate.millisecondsSince1970), toTime: UInt(endDate.millisecondsSince1970))
        ChatManager.activeInstance?.message.export(req)
    }

    public func deleteFile() {
        guard let url = filePath else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
