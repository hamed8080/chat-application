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
    @Published public var searchedContacts: ContiguousArray<Contact> = []
    @Published public var searchText: String = ""
    private var count = 15
    private var offset = 0
    private var cancelable: Set<AnyCancellable> = []
    private(set) var hasNext: Bool = true
    public var isLoading = false
    private var canLoadMore: Bool { hasNext && !isLoading }
    @Published public var selectedFilterThreadType: ThreadTypes?
    @Published public var showUnreadConversations: Bool? = nil
    private var cachedAttribute: [String: AttributedString] = [:]
    public var isInSearchMode: Bool { searchText.count > 0 || (!searchedConversations.isEmpty || !searchedContacts.isEmpty) }

    public init() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink{ [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] newValue in
                if newValue.first == "@", newValue.count > 2 {
                    self?.reset()
                    let startIndex = newValue.index(newValue.startIndex, offsetBy: 1)
                    let newString = newValue[startIndex..<newValue.endIndex]
                    self?.searchPublicThreads(String(newString))
                } else if newValue.first != "@" && !newValue.isEmpty {
                    self?.reset()
                    self?.searchThreads(newValue, new: self?.showUnreadConversations)
                    self?.searchContacts(newValue)
                } else if newValue.count == 0, self?.hasNext == false {
                    self?.reset()
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
        NotificationCenter.contact.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink{ [weak self] event in
                self?.onContactEvent(event)
            }
            .store(in: &cancelable)

        $showUnreadConversations.sink { [weak self] newValue in
            if (self?.showUnreadConversations ?? false) == newValue { return } // when the user taps on the close button on the toolbar
            if newValue == true {
                self?.getUnreadConversations()
            } else if newValue == false {
                self?.resetUnreadConversations()
            }
        }
        .store(in: &cancelable)
    }

    public func loadMore() {
        if !canLoadMore { return }
        offset = count + offset
        searchThreads(searchText, new: showUnreadConversations, loadMore: true)
    }

    private func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threads(let response):
            setHasNextOnResponse(response)
            onPublicThreadSearch(response)
            onSearch(response)
            onSearchLoadMore(response)
        default:
            break
        }
    }

    private func onContactEvent(_ event: ContactEventTypes?) {
        switch event {
        case let .contacts(response):
            onSearchContacts(response)
        default:
            break
        }
    }

    private func searchThreads(_ text: String, new: Bool? = nil, loadMore: Bool = false) {
        if !canLoadMore { return }
        isLoading = true
        let req = ThreadsRequest(searchText: text, count: count, offset: offset, new: new)
        RequestsManager.shared.append(prepend: loadMore ? "SEARCH-LOAD-MORE" : "SEARCH", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    private func searchPublicThreads(_ text: String) {
        if !canLoadMore { return }
        isLoading = true
        let req = ThreadsRequest(count: count, offset: offset, name: text, type: .publicGroup)
        RequestsManager.shared.append(prepend: "SEARCH-PUBLIC-THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    private func onSearch(_ response: ChatResponse<[Conversation]>) {
        isLoading = false
        if !response.cache, let threads = response.result, response.pop(prepend: "SEARCH") != nil {
            searchedConversations.append(contentsOf: threads)
        }
    }

    private func onSearchLoadMore(_ response: ChatResponse<[Conversation]>) {
        isLoading = false
        if !response.cache, let threads = response.result, response.pop(prepend: "SEARCH-LOAD-MORE") != nil {
            searchedConversations.append(contentsOf: threads)
        }
    }

    private func onPublicThreadSearch(_ response: ChatResponse<[Conversation]>) {
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

    private func searchContacts(_ searchText: String) {
        if searchText.isEmpty { return }
        let req: ContactsRequest
        if searchText.lowercased().contains("uname:") {
            let startIndex = searchText.index(searchText.startIndex, offsetBy: 6)
            let searchResultValue = String(searchText[startIndex..<searchText.endIndex])
            req = ContactsRequest(userName: searchResultValue)
        } else if searchText.lowercased().contains("tel:") {
            let startIndex = searchText.index(searchText.startIndex, offsetBy: 4)
            let searchResultValue = String(searchText[startIndex..<searchText.endIndex])
            req = ContactsRequest(cellphoneNumber: searchResultValue)
        } else {
            req = ContactsRequest(query: searchText)
        }
        RequestsManager.shared.append(prepend: "SEARCH-CONTACTS-IN-THREADS-LIST", value: req)
        ChatManager.activeInstance?.contact.search(req)
    }

    private func onSearchContacts(_ response: ChatResponse<[Contact]>) {
        if !response.cache, response.pop(prepend: "SEARCH-CONTACTS-IN-THREADS-LIST") != nil {
            if let contacts = response.result {
                self.searchedContacts.removeAll()
                self.searchedContacts.append(contentsOf: contacts)
            }
        }
    }

    public func closedSearchUI() {
        reset()
        searchText = ""
        showUnreadConversations = false
    }

    public func reset() {
        isLoading = false
        hasNext = true
        searchedConversations.removeAll()
        searchedContacts.removeAll()
        cachedAttribute.removeAll()
        offset = 0
    }

    private func getUnreadConversations() {
        reset()
        searchThreads(searchText, new: true)
        searchContacts(searchText)
    }

    private func resetUnreadConversations() {
        reset()
        searchThreads(searchText, new: nil)
        searchContacts(searchText)
    }

    public func attributdTitle(for title: String) -> AttributedString {
        if let cached = cachedAttribute.first(where: {$0.key == title})?.value {
            return cached
        }
        let attr = NSMutableAttributedString(string: title)
        attr.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor(named: "accent")!
        ], range: findRangeOfTitleToHighlight(title))
        cachedAttribute[title] = AttributedString(attr)
        return AttributedString(attr)
    }

    private func findRangeOfTitleToHighlight(_ title: String) -> NSRange {
        return NSString(string: title).range(of: searchText)
    }

    private func onCancelTimer(key: String) {
        if isLoading {
            isLoading = false
            animateObjectWillChange()
        }
    }
}
