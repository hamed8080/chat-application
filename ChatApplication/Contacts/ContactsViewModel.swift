//
//  ContactsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation

final class ContactsViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    private(set) var selectedContacts: [Contact] = []
    private(set) var canceableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }
    @Published private(set) var maxContactsCountInServer = 0
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var searchedContacts: [Contact] = []
    @Published var isLoading = false
    @Published var searchContactString: String = ""

    init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getContacts()
            }
        }
        .store(in: &canceableSet)
        getContacts()
        setupPublishers()
    }

    func setupPublishers() {
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

    func onServerResponse(_ response: ChatResponse<[Contact]>) {
        if let contacts = response.result {
            firstSuccessResponse = true
            appendOrUpdateContact(contacts)
            hasNext = response.pagination?.hasNext ?? false
            setMaxContactsCountInServer(count: (response.pagination as? PaginationWithContentCount)?.totalCount ?? 0)
        }
        isLoading = false
    }

    func onCacheResponse(_ response: ChatResponse<[Contact]>) {
        if let contacts = response.result {
            appendOrUpdateContact(contacts)
            hasNext = response.pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func getContacts() {
        isLoading = true
        ChatManager.activeInstance?.getContacts(.init(count: count, offset: offset), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    func searchContacts(_ searchText: String) {
        isLoading = true
        ChatManager.activeInstance?.searchContacts(.init(query: searchText)) { [weak self] response in
            if let contacts = response.result {
                self?.setSearchedContacts(contacts)
            }
        }
    }

    func createThread(invitees: [Invitee]) {
        AppState.shared.showThread(invitees: invitees)
    }

    func loadMore() {
        if !canLoadNextPage { return }
        preparePaginiation()
        getContacts()
    }

    func preparePaginiation() {
        offset = count + offset
    }

    func refresh() {
        clear()
        getContacts()
    }

    func clear() {
        hasNext = false
        offset = 0
        count = 15
        contacts = []
        selectedContacts = []
        searchedContacts = []
        maxContactsCountInServer = 0
    }

    func delete(indexSet: IndexSet) {
        let contacts = contacts.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        contacts.forEach { contact in
            delete(contact)
            reomve(contact)
        }
    }

    func delete(_ contact: Contact) {
        if let contactId = contact.id {
            ChatManager.activeInstance?.removeContact(.init(contactId: contactId)) { [weak self] response in
                if response.error != nil {
                    self?.appendOrUpdateContact([contact])
                }
            }
        }
    }

    func deleteSelectedItems() {
        selectedContacts.forEach { contact in
            reomve(contact)
            delete(contact)
        }
    }

    func appendOrUpdateContact(_ contacts: [Contact]) {
        // Remove all contacts that were cached, to prevent duplication.
        contacts.forEach { contact in
            if let oldContact = self.contacts.first(where: { $0.id == contact.id }) {
                oldContact.update(contact)
            } else {
                self.contacts.append(contact)
            }
        }
    }

    func insertContactsAtTop(_ contacts: [Contact]) {
        self.contacts.insert(contentsOf: contacts, at: 0)
    }

    func setMaxContactsCountInServer(count: Int) {
        maxContactsCountInServer = count
    }

    func reomve(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0 == contact }) else { return }
        contacts.remove(at: index)
    }

    func addToSelctedContacts(_ contact: Contact) {
        selectedContacts.append(contact)
    }

    func removeToSelctedContacts(_ contact: Contact) {
        guard let index = selectedContacts.firstIndex(of: contact) else { return }
        selectedContacts.remove(at: index)
    }

    func setSearchedContacts(_ contacts: [Contact]) {
        isLoading = false
        searchedContacts = contacts
    }

    func addContact(contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, uniqueId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue, uniqueId: nil)
        ChatManager.activeInstance?.addContact(req) { [weak self] response in
            if let contacts = response.result {
                self?.insertContactsAtTop(contacts)
            }
        }
    }

    func firstContact(_ contact: Contact) -> Contact? {
        contacts.first { $0.id == contact.id }
    }

    func validatePhone(value: String) -> Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let result = phoneTest.evaluate(with: value)
        return result
    }

    func blockOrUnBlock(_ contact: Contact) {
        let findedContact = firstContact(contact)
        if findedContact?.blocked == false {
            let req = BlockRequest(contactId: contact.id)
            ChatManager.activeInstance?.blockContact(req, completion: onBlockUNBlockResponse)
        } else {
            let req = UnBlockRequest(contactId: contact.id)
            ChatManager.activeInstance?.unBlockContact(req, completion: onBlockUNBlockResponse)
        }
    }

    func onBlockUNBlockResponse(_ response: ChatResponse<Contact>) {
        if let result = response.result {
            let findedContact = contacts.first(where: { $0.id == result.id })
            findedContact?.blocked?.toggle()
            objectWillChange.send()
        }
    }

    func isSelected(contact: Contact) -> Bool {
        selectedContacts.contains(contact)
    }

    func toggleSelectedContact(contact: Contact) {
        if isSelected(contact: contact) {
            removeToSelctedContacts(contact)
        } else {
            addToSelctedContacts(contact)
        }
        objectWillChange.send()
    }

    func updateContact(contact _: Contact, contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, uniqueId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue, uniqueId: nil)
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
