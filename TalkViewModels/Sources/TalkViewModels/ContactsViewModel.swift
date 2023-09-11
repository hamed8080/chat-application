//
//  ContactsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import ChatModels
import TalkModels
import ChatCore
import ChatDTO

public final class ContactsViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    public private(set) var selectedContacts: [Contact] = []
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var maxContactsCountInServer = 0
    @Published public private(set) var contacts: [Contact] = []
    @Published public private(set) var searchedContacts: [Contact] = []
    @Published public var isLoading = false
    @Published public var searchContactString: String = ""
    private var searchUniqueId: String?
    public var blockedContacts: [BlockedContactResponse] = []

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getContacts()
                ChatManager.activeInstance?.contact.getBlockedList()
                self?.sync()
            }
        }
        .store(in: &canceableSet)
        getContacts()
        setupPublishers()
    }

    public func setupPublishers() {
        $searchContactString
            .filter { $0.count == 0 }
            .sink { [weak self] newValue in
                if newValue.count == 0 {
                    self?.searchedContacts = []
                }
            }
            .store(in: &canceableSet)
        $searchContactString
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.searchContacts(searchText)
            }
            .store(in: &canceableSet)
        NotificationCenter.default.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink{ [weak self] event in
                self?.onContactEvent(event)
            }
            .store(in: &canceableSet)
    }

    public func onContactEvent(_ event: ContactEventTypes?) {
        switch event {
        case let .contacts(response):
            if searchUniqueId == response.uniqueId {
                onSearchContacts(response)
            } else {
                onContacts(response)
            }
        case let .add(response):
            onAddContacts(response)
        case let .delete(response, deleted):
            onDeleteContacts(response, deleted)
        case let .blocked(response):
            onBlockUNBlockResponse(response, true)
        case let .unblocked(response):
            onBlockUNBlockResponse(response, false)
        case let .blockedList(response):
            onBlockedList(response)
        default:
            break
        }
    }

    public func onContacts(_ response: ChatResponse<[Contact]>) {
        if let contacts = response.result {
            firstSuccessResponse = !response.cache
            appendOrUpdateContact(contacts)
            hasNext = response.hasNext
            setMaxContactsCountInServer(count: response.contentCount ?? 0)
        }
        isLoading = false
    }

    func onBlockedList(_ response: ChatResponse<[BlockedContactResponse]>) {
        blockedContacts = response.result ?? []
    }

    public func getContacts() {
        isLoading = true
        ChatManager.activeInstance?.contact.get(.init(count: count, offset: offset))
    }

    public func searchContacts(_ searchText: String) {
        isLoading = true
        let req = ContactsRequest(query: searchText)
        searchUniqueId = req.uniqueId
        ChatManager.activeInstance?.contact.search(req)
    }

    public func onDeleteContacts(_ response: ChatResponse<[Contact]>, _ deleted: Bool) {
        if deleted {
            response.result?.forEach{ contact in
                contacts.removeAll(where: {$0.id == contact.id})
            }
        }
    }

    public func loadMore() {
        if !canLoadNextPage { return }
        preparePaginiation()
        getContacts()
    }

    public func preparePaginiation() {
        offset = count + offset
    }

    public func refresh() {
        clear()
        getContacts()
    }

    public func clear() {
        hasNext = false
        offset = 0
        count = 15
        contacts = []
        selectedContacts = []
        searchedContacts = []
        maxContactsCountInServer = 0
    }

    public func delete(indexSet: IndexSet) {
        let contacts = contacts.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        contacts.forEach { contact in
            delete(contact)
            reomve(contact)
        }
    }

    public func delete(_ contact: Contact) {
        if let contactId = contact.id {
            ChatManager.activeInstance?.contact.remove(.init(contactId: contactId))
        }
    }

    public func deleteSelectedItems() {
        selectedContacts.forEach { contact in
            reomve(contact)
            delete(contact)
        }
    }

    public func appendOrUpdateContact(_ contacts: [Contact]) {
        // Remove all contacts that were cached, to prevent duplication.
        contacts.forEach { contact in
            if let oldContact = self.contacts.first(where: { $0.id == contact.id }) {
                oldContact.update(contact)
            } else {
                self.contacts.append(contact)
            }
        }
    }

    public func onAddContacts(_ response: ChatResponse<[Contact]>) {
        if let contacts = response.result {
            self.contacts.insert(contentsOf: contacts, at: 0)
        }
    }

    public func setMaxContactsCountInServer(count: Int) {
        maxContactsCountInServer = count
    }

    public func reomve(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0 == contact }) else { return }
        contacts.remove(at: index)
    }

    public func addToSelctedContacts(_ contact: Contact) {
        selectedContacts.append(contact)
    }

    public func removeToSelctedContacts(_ contact: Contact) {
        guard let index = selectedContacts.firstIndex(of: contact) else { return }
        selectedContacts.remove(at: index)
    }

    public func onSearchContacts(_ response: ChatResponse<[Contact]>) {
        isLoading = false
        searchedContacts = response.result ?? []
    }

    public func addContact(contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue)
        ChatManager.activeInstance?.contact.add(req)
    }

    public func firstContact(_ contact: Contact) -> Contact? {
        contacts.first { $0.id == contact.id }
    }

    public func validatePhone(value: String) -> Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let result = phoneTest.evaluate(with: value)
        return result
    }

    public func blockOrUnBlock(_ contact: Contact) {
        let findedContact = firstContact(contact)
        if findedContact?.blocked == false {
            let req = BlockRequest(contactId: contact.id)
            ChatManager.activeInstance?.contact.block(req)
        } else {
            let req = UnBlockRequest(contactId: contact.id)
            ChatManager.activeInstance?.contact.unBlock(req)
        }
    }

    public func onBlockUNBlockResponse(_ response: ChatResponse<BlockedContactResponse>, _ block: Bool) {
        if let result = response.result {
            contacts.first(where: { $0.id == result.contact?.id })?.blocked = block
            animateObjectWillChange()
        }
    }

    public func isSelected(contact: Contact) -> Bool {
        selectedContacts.contains(contact)
    }

    public func toggleSelectedContact(contact: Contact) {
        if isSelected(contact: contact) {
            removeToSelctedContacts(contact)
        } else {
            addToSelctedContacts(contact)
        }
        animateObjectWillChange()
    }

    public func sync() {
        if UserDefaults.standard.bool(forKey: "sync_contacts") == true {
            ChatManager.activeInstance?.contact.sync()
        }
    }

    public func updateContact(contact _: Contact, contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue)
        ChatManager.activeInstance?.contact.add(req)

//        ChatManager.activeInstance?.updateContact(req) { [weak self] response in
//            response.result?.forEach { updatedContact in
//                if updatedContact.id == contactId {
//                    if let index = self?.contacts.firstIndex(where: { $0.id == updatedContact.id }) {
//                        self?.contacts[index].update(updatedContact)
//                        self?.objectWillChange.send()
//                    }
//                }
//            }
//        }
    }
}
