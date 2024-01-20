//
//  ThreadsSearchViewModel.swift
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

public final class ThreadsSearchViewModel: ObservableObject {
    @Published public var searchedConversations: ContiguousArray<Conversation> = []
    @Published public var searchText: String = ""
    public private(set) var count = 15
    public private(set) var offset = 0
    public private(set) var cancelable: Set<AnyCancellable> = []
    private(set) var hasNext: Bool = true
    public var isLoading = false
    private var canLoadMore: Bool { hasNext && !isLoading }
    @Published public var selectedFilterThreadType: ThreadTypes?
    @Published public var searchType: SearchParticipantType = .name

    public init() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink{ [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
        $searchType.sink { [weak self] newValue in
            self?.offset = 0
            self?.hasNext = true
        }
        .store(in: &cancelable)
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] newValue in
                if newValue.first == "@", newValue.count > 2 {
                    self?.hasNext = true
                    let startIndex = newValue.index(newValue.startIndex, offsetBy: 1)
                    let newString = newValue[startIndex..<newValue.endIndex]
                    self?.searchPublicThreads(String(newString))
                } else if newValue.first != "@" && !newValue.isEmpty {
                    self?.hasNext = true
                    self?.searchThreads(newValue)
                } else if newValue.count == 0, self?.hasNext == false {
                    self?.offset = 0
                    self?.hasNext = true
                }
            }
            .store(in: &cancelable)
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
    }

    public func loadMore() {
        if !canLoadMore { return }
        offset = count + offset
        searchThreads(searchText)
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threads(let response):
            setHasNextOnResponse(response)
            onPublicThreadSearch(response)
            onSearch(response)
        default:
            break
        }
    }

    public func searchThreads(_ text: String) {
        if !canLoadMore { return }
        isLoading = true
        searchedConversations.removeAll()
        offset = 0
        var newText = text
        if searchType == .username {
            newText = "uname:\(newText)"
        } else if searchType == .cellphoneNumber {
            newText = "tel:\(newText)"
        }
        let req = ThreadsRequest(searchText: newText, count: count, offset: offset)
        RequestsManager.shared.append(prepend: "SEARCH", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func searchPublicThreads(_ text: String) {
        if !canLoadMore { return }
        isLoading = true
        searchedConversations.removeAll()
        let req = ThreadsRequest(count: count, offset: offset, name: text, type: .publicGroup)
        RequestsManager.shared.append(prepend: "SEARCH-PUBLIC-THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    func onSearch(_ response: ChatResponse<[Conversation]>) {
        isLoading = false
        if !response.cache, let threads = response.result, response.pop(prepend: "SEARCH") != nil {
            searchedConversations.append(contentsOf: threads)
        }
    }

    func onPublicThreadSearch(_ response: ChatResponse<[Conversation]>) {
        isLoading = false
        if !response.cache, let threads = response.result, response.pop(prepend: "SEARCH-PUBLIC-THREAD") != nil {
            searchedConversations.append(contentsOf: threads)
        }
    }

    private func setHasNextOnResponse(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, response.result?.count ?? 0 > 0 {
            hasNext = response.hasNext
        }
    }

    private func onCancelTimer(key: String) {
        if isLoading {
            isLoading = false
            animateObjectWillChange()
        }
    }
}
