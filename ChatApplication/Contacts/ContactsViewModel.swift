//
//  ContactsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation

class ContactsViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    @Published private(set) var maxContactsCountInServer = 0
    @Published private(set) var contactsVMS: [ContactViewModel] = []
    private(set) var selectedContacts: [Contact] = []
    @Published private(set) var searchedContactsVMS: [ContactViewModel] = []
    @Published var isLoading = false
    @Published var searchContactString: String = "" {
        didSet {
            searchContact()
        }
    }

    private(set) var canceableSet: Set<AnyCancellable> = []

    private(set) var firstSuccessResponse = false

    private var canLoadNextPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }

    init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getContacts()
            }
        }
        .store(in: &canceableSet)
        getContacts()
    }

    func onServerResponse(_ contacts: [Contact]?, _: String?, _ pagination: Pagination?, _: ChatError?) {
        if let contacts = contacts {
            firstSuccessResponse = true
            appendOrUpdateContact(contacts)
            hasNext = pagination?.hasNext ?? false
            setMaxContactsCountInServer(count: (pagination as? PaginationWithContentCount)?.totalCount ?? 0)
        }
        isLoading = false
    }

    func onCacheResponse(_ contacts: [Contact]?, _: String?, _ pagination: Pagination?, _: ChatError?) {
        if let contacts = contacts {
            appendOrUpdateContact(contacts)
            hasNext = pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func getContacts() {
        isLoading = true
        Chat.sharedInstance.getContacts(.init(count: count, offset: offset), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    func searchContact() {
        if searchContactString.count <= 0 {
            setSearchedContacts([])
            return
        }
        isLoading = true
        Chat.sharedInstance.searchContacts(.init(query: searchContactString)) { [weak self] contacts, _, _, _ in
            if let contacts = contacts {
                self?.setSearchedContacts(contacts)
            }
        }
    }

    func createThread(invitees: [Invitee]) {
        Chat.sharedInstance.createThread(.init(invitees: invitees, title: "", type: .normal)) { thread, _, _ in
            if let thread = thread {
                AppState.shared.selectedThread = thread
                AppState.shared.showThreadView = true
            }
        }
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
        offset = 0
        count = 15
        contactsVMS = []
    }

    func delete(indexSet: IndexSet) {
        let contacts = contactsVMS.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        contacts.forEach { contact in
            delete(contact.contact)
            reomve(contact.contact)
        }
    }

    func delete(_ contact: Contact) {
        if let contactId = contact.id {
            Chat.sharedInstance.removeContact(.init(contactId: contactId)) { [weak self] _, _, error in
                if error != nil {
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
            if let oldContactVM = contactsVMS.first(where: { $0.contact.id == contact.id }) {
                oldContactVM.contact.update(contact)
            } else {
                contactsVMS.append(ContactViewModel(contact: contact, contactsVM: self))
            }
        }
    }

    func insertContactsAtTop(_ contacts: [Contact]) {
        contactsVMS.insert(contentsOf: contacts.map { .init(contact: $0, contactsVM: self) }, at: 0)
    }

    func setMaxContactsCountInServer(count: Int) {
        maxContactsCountInServer = count
    }

    func reomve(_ contact: Contact) {
        guard let index = contactsVMS.firstIndex(where: { $0.contact == contact }) else { return }
        contactsVMS.remove(at: index)
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
        searchedContactsVMS = contacts.map { .init(contact: $0, contactsVM: self) }
    }

    func addContact(contactValue: String, firstName: String?, lastName: String?) {
        let isPhone = validatePhone(value: contactValue)
        let req: AddContactRequest = isPhone ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, uniqueId: nil) :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue, uniqueId: nil)
        Chat.sharedInstance.addContact(req) { [weak self] contacts, _, _ in
            if let contacts = contacts {
                self?.insertContactsAtTop(contacts)
            }
        }
    }

    func validatePhone(value: String) -> Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let result = phoneTest.evaluate(with: value)
        return result
    }
}
