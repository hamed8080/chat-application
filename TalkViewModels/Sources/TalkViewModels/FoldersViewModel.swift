//
//  FoldersViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import ChatModels
import TalkModels
import ChatCore
import ChatDTO
import TalkExtensions
import OSLog

public final class FoldersViewModel: ObservableObject {
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var cancelable: Set<AnyCancellable> = []
    private(set) var hasNext: Bool = true
    public var isLoading = false
    private var canLoadMore: Bool { hasNext && !isLoading }
    private var threadsVM: ThreadsViewModel { AppState.shared.objectsContainer.threadsVM }
    public var selectedFolder: Tag?
    public var threads: ContiguousArray<Conversation> = []

    public init() {
        NotificationCenter.default.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink{ [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
        RequestsManager.shared.$cancelRequest
            .sink { [weak self] newValue in
                if let newValue {
                    self?.onCancelTimer(key: newValue)
                }
            }
            .store(in: &cancelable)
    }

    public func loadMore() {
        if !canLoadMore { return }
        offset = count + offset
    }

    public func getThreadsInsideFolder(_ folder: Tag) {
        self.selectedFolder = folder
        let threadIds = folder.tagParticipants?.compactMap(\.conversation?.id) ?? []
        getThreadsWith(threadIds)
    }

    public func getThreadsWith(_ threadIds: [Int]) {
        if threadIds.count == 0 { return }
        isLoading = true
        let req = ThreadsRequest(threadIds: threadIds)
        RequestsManager.shared.append(prepend: "CONVERSATION-INSIDE-FOLDER", value: req)
        ChatManager.activeInstance?.conversation.get(req)
        animateObjectWillChange()
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threads(let response):
            onConversationInsideFolder(response)
        default:
            break
        }
    }

    private func onConversationInsideFolder(_ response: ChatResponse<[Conversation]>) {
        if response.value(prepend: "CONVERSATION-INSIDE-FOLDER") != nil {
            threads.append(contentsOf: response.result ?? [])
            animateObjectWillChange()
        }
    }

    private func setHasNextOnResponse(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, response.result?.count ?? 0 > 0 {
            hasNext = response.hasNext
        }
    }

    private func onCancelTimer(key: String) {
        isLoading = false
        animateObjectWillChange()
    }
}
