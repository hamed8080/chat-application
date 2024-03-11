//
//  ThreadOrContactPickerViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels
import Combine
import ChatDTO
import ChatCore
import Chat

public class ThreadOrContactPickerViewModel: ObservableObject {
    private var cancellableSet: Set<AnyCancellable> = .init()
    @Published public var searchText: String = ""
    public var conversations: ContiguousArray<Conversation> = .init()
    public var contacts:ContiguousArray<Contact> = .init()
    @Published public var isLoadingConversation = false
    @Published public var isLoadingContacts = false
    public var isIsSearchMode = false
    private var count: Int = 25
    private var offset: Int = 0
    private var hasNextConversation: Bool = true

    private var contactsCount: Int = 25
    private var contactsOffset: Int = 0
    private var hasNextContacts: Bool = true

    public init() {
        getContacts()
        getThreads()
        setupObservers()
    }

    func setupObservers() {
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.isIsSearchMode = true
                self?.search(newValue)
            }
            .store(in: &cancellableSet)

        $searchText
            .filter { $0.count == 0 }
            .sink { [weak self] _ in
                if self?.isIsSearchMode == true {
                    self?.isIsSearchMode = false
                    self?.reset()
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.thread.publisher(for: .thread)
            .map({$0.object as? ThreadEventTypes})
            .sink { [weak self] event in
                if case let .threads(response) = event {
                    self?.onNewConversations(response)
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.contact.publisher(for: .contact)
            .map({$0.object as? ContactEventTypes})
            .sink { [weak self] event in
                if case let .contacts(response) = event {
                    self?.onNewContacts(response)
                }
            }
            .store(in: &cancellableSet)
    }

    func search(_ text: String) {
        conversations.removeAll()
        contacts.removeAll()
        isLoadingConversation = true
        isLoadingContacts = true
        animateObjectWillChange()

        let req = ThreadsRequest(searchText: text)
        RequestsManager.shared.append(prepend: "GET_THREADS_IN_SELECT_THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)

        let contactsReq = ContactsRequest(query: text)
        RequestsManager.shared.append(prepend: "GET_CONTCATS_IN_SELECT_CONTACT", value: contactsReq)
        ChatManager.activeInstance?.contact.get(contactsReq)
    }

    private func onNewConversations(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, response.pop(prepend: "GET_THREADS_IN_SELECT_THREAD") != nil {
            isLoadingConversation = false
            hasNextConversation = response.hasNext
            conversations.append(contentsOf: response.result ?? [])
            animateObjectWillChange()
        }
    }

    private func onNewContacts(_ response: ChatResponse<[Contact]>) {
        if !response.cache, response.pop(prepend: "GET_CONTCATS_IN_SELECT_CONTACT") != nil {
            isLoadingContacts = false
            hasNextContacts = response.hasNext
            contacts.append(contentsOf: response.result ?? [])
            animateObjectWillChange()
        }
    }

    public func loadMore() {
        if isLoadingConversation || !hasNextConversation { return }
        offset += count
        getThreads()
    }

    public func getThreads() {
        isLoadingConversation = true
        let req = ThreadsRequest(count: count, offset: offset)
        RequestsManager.shared.append(prepend: "GET_THREADS_IN_SELECT_THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func loadMoreContacts() {
        if isLoadingContacts || !hasNextContacts { return }
        contactsOffset += contactsCount
        getContacts()
    }

    public func getContacts() {
        isLoadingContacts = true
        let req = ContactsRequest(count: contactsCount, offset: contactsOffset)
        RequestsManager.shared.append(prepend: "GET_CONTCATS_IN_SELECT_CONTACT", value: req)
        ChatManager.activeInstance?.contact.get(req)
    }

    public func cancelObservers() {
        cancellableSet.forEach { cancelable in
            cancelable.cancel()
        }
    }

    public func reset() {
        isLoadingContacts = false
        isLoadingConversation = false
        offset = 0
        contactsOffset = 0
        hasNextConversation = true
        hasNextContacts = true
        getContacts()
        getThreads()
    }
}
