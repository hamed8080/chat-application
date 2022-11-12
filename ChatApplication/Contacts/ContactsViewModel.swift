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

    @Published
    private(set) var maxContactsCountInServer = 0

    @Published
    private(set) var contacts: [Contact] = []

    @Published
    private(set) var selectedContacts: [Contact] = []

    @Published
    private(set) var searchedContacts: [Contact] = []

    @Published
    var isLoading = false

    @Published
    public var isInEditMode = false

    @Published
    public var navigateToAddOrEditContact = false

    @Published
    var searchContactString :String = "" {
        didSet {
            searchContact()
        }
    }

    private(set) var canceableSet: Set<AnyCancellable> = []

    private(set) var firstSuccessResponse = false

    private var canLoadNextPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .CONNECTED }

    init() {
        AppState.shared.$connectionStatus.sink { status in
            if self.firstSuccessResponse == false, status == .CONNECTED {
                self.getContacts()
            }
        }
        .store(in: &canceableSet)
        getContacts()
    }

    func onServerResponse(_ contacts: [Contact]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let contacts = contacts {
            firstSuccessResponse = true
            appendContacts(contacts)
            hasNext = pagination?.hasNext ?? false
            setMaxContactsCountInServer(count: (pagination as? PaginationWithContentCount)?.totalCount ?? 0)
        }
        isLoading = false
    }

    func onCacheResponse(_ contacts: [Contact]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let contacts = contacts {
            appendContacts(contacts)
            hasNext = pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .CONNECTED {
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
        Chat.sharedInstance.searchContacts(.init(query: searchContactString)) { contacts, _, _, _ in
            if let contacts = contacts {
                self.setSearchedContacts(contacts)
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
        isLoading = true
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
        contacts = []
    }

    func setupPreview() {
        setContacts(contacts: MockData.generateContacts())
    }

    func delete(indexSet: IndexSet) {
        let contacts = contacts.enumerated().filter { indexSet.contains($0.offset) }.map { $0.element }
        contacts.forEach { contact in
            delete(contact)
            reomve(contact)
        }
    }

    func delete(_ contact: Contact) {
        if let contactId = contact.id {
            Chat.sharedInstance.removeContact(.init(contactId: contactId)) { _, _, error in
                if error != nil {
                    self.appendContacts([contact])
                }
            }
        }
    }

    func toggleSelectedContact(_ contact: Contact, _ isSelected: Bool) {
        if isSelected {
            addToSelctedContacts(contact)
        } else {
            removeToSelctedContacts(contact)
        }
    }

    func deleteSelectedItems() {
        selectedContacts.forEach { contact in
            reomve(contact)
            delete(contact)
        }
    }

    func blockOrUnBlock(_ contact: Contact) {
        if contact.blocked == false {
            let req = BlockRequest(contactId: contact.id)
            Chat.sharedInstance.blockContact(req, completion: onBlockUNBlockResponse)
        } else {
            let req = UnBlockRequest(contactId: contact.id)
            Chat.sharedInstance.unBlockContact(req, completion: onBlockUNBlockResponse)
        }
    }

    func onBlockUNBlockResponse(_ contact: BlockedContact?, _ uniqueId: String?, _ error: ChatError?) {
        if let contact = contact, let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index].blocked?.toggle()
        }
    }

    func setContacts(contacts: [Contact]?) {
        if let contacts = contacts {
            self.contacts = contacts
        }
    }

    func appendContacts(_ contacts: [Contact]) {
        self.contacts.append(contentsOf: contacts)
    }

    func insertContactsAtTop(_ contacts: [Contact]) {
        self.contacts.insert(contentsOf: contacts, at: 0)
    }

    func setMaxContactsCountInServer(count: Int) {
        maxContactsCountInServer = count
    }

    func reomve(_ contact: Contact) {
        guard let index = contacts.firstIndex(of: contact) else { return }
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
        searchedContacts = contacts
    }
}
