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
    @Published public var isLoading = false

    public init() {
        conversations = AppState.shared.objectsContainer.threadsVM.threads
        contacts = AppState.shared.objectsContainer.contactsVM.contacts
        setupObservers()
    }

    func setupObservers() {
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.search(newValue)
            }
            .store(in: &cancellableSet)

        $searchText
            .filter{$0.count == 0}
            .sink { [weak self] newValue in
                self?.conversations = AppState.shared.objectsContainer.threadsVM.threads
                self?.contacts = AppState.shared.objectsContainer.contactsVM.contacts
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
        isLoading = true
        animateObjectWillChange()
        let req = ThreadsRequest(searchText: text)
        ChatManager.activeInstance?.conversation.get(req)

        let contactsReq = ContactsRequest(query: text)
        ChatManager.activeInstance?.contact.get(contactsReq)
    }

    private func onNewConversations(_ response: ChatResponse<[Conversation]>) {
        isLoading = false
        conversations.append(contentsOf: response.result ?? [])
        animateObjectWillChange()
    }

    private func onNewContacts(_ response: ChatResponse<[Contact]>) {
        contacts.append(contentsOf: response.result ?? [])
        animateObjectWillChange()
    }
}
