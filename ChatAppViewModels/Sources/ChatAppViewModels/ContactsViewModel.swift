//
//  ContactsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import ChatModels
import ChatAppModels
import ChatCore
import ChatDTO

public final class ContactsViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    public private(set) var selectedContacts: [Contact] = []
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }
    @Published public private(set) var maxContactsCountInServer = 0
    @Published public private(set) var contacts: [Contact] = []
    @Published public private(set) var searchedContacts: [Contact] = []
    @Published public var isLoading = false
    @Published public var searchContactString: String = ""

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getContacts()
            }
        }
        .store(in: &canceableSet)
        getContacts()
        setupPublishers()
    }

    public func setupPublishers() {
        $searchContactString
            .filter { $0.count == 0 }
            .sink { newValue in
                if newValue.count == 0 {
                    self.setSearchedContacts([])
                }
            }
            .store(in: &canceableSet)
        $searchContactString
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { searchText in
                self.searchContacts(searchText)
            }
            .store(in: &canceableSet)
    }

    public func onServerResponse(_ response: ChatResponse<[Contact]>) {
        if let contacts = response.result {
            firstSuccessResponse = true
            appendOrUpdateContact(contacts)
            hasNext = response.pagination?.hasNext ?? false
            setMaxContactsCountInServer(count: (response.pagination as? PaginationWithContentCount)?.totalCount ?? 0)
        }
        isLoading = false
    }

    public func onCacheResponse(_ response: ChatResponse<[Contact]>) {
        if let contacts = response.result {
            appendOrUpdateContact(contacts)
            hasNext = response.pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    public func getContacts() {
        isLoading = true
        ChatManager.activeInstance?.getContacts(.init(count: count, offset: offset), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public func searchContacts(_ searchText: String) {
        isLoading = true
        ChatManager.activeInstance?.searchContacts(.init(query: searchText)) { [weak self] response in
            if let contacts = response.result {
                self?.setSearchedContacts(contacts)
            }
        }
    }

    public func createThread(invitees: [Invitee]) {
        AppState.shared.showThread(invitees: invitees)
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
            ChatManager.activeInstance?.removeContact(.init(contactId: contactId)) { [weak self] response in
                if response.error != nil {
                    self?.appendOrUpdateContact([contact])
                }
            }
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

    public func insertContactsAtTop(_ contacts: [Contact]) {
        self.contacts.insert(contentsOf: contacts, at: 0)
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

    public func setSearchedContacts(_ contacts: [Contact]) {
        isLoading = false
        searchedContacts = contacts
    }

    public func addContact(contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue)
        ChatManager.activeInstance?.addContact(req) { [weak self] response in
            if let contacts = response.result {
                self?.insertContactsAtTop(contacts)
            }
        }
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
            ChatManager.activeInstance?.blockContact(req, completion: onBlockUNBlockResponse)
        } else {
            let req = UnBlockRequest(contactId: contact.id)
            ChatManager.activeInstance?.unBlockContact(req, completion: onBlockUNBlockResponse)
        }
    }

    public func onBlockUNBlockResponse(_ response: ChatResponse<Contact>) {
        if let result = response.result {
            let findedContact = contacts.first(where: { $0.id == result.id })
            findedContact?.blocked?.toggle()
            objectWillChange.send()
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
        objectWillChange.send()
    }

    public func updateContact(contact _: Contact, contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue)
        ChatManager.activeInstance?.addContact(req) { [weak self] response in
            if let updatedContact = response.result?.first {
                if let index = self?.contacts.firstIndex(where: { $0.id == updatedContact.id }) {
                    self?.contacts[index].update(updatedContact)
                    self?.objectWillChange.send()
                }
            }
        }

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
