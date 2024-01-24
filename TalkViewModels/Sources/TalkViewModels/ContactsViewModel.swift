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
import SwiftUI
import Photos
import TalkExtensions
import ChatTransceiver

public class ContactsViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    public var selectedContacts: ContiguousArray<Contact> = []
    public var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var maxContactsCountInServer = 0
    public var contacts: ContiguousArray<Contact> = []
    @Published public var searchType: SearchParticipantType = .name
    @Published public var searchedContacts: ContiguousArray<Contact> = []
    @Published public var isLoading = false
    @Published public var searchContactString: String = ""
    public var blockedContacts: ContiguousArray<BlockedContactResponse> = []
    @Published public var addContact: Contact?
    @Published public var editContact: Contact?
    @Published public var showAddOrEditContactSheet = false
    public var isBuilder: Bool = false
    @Published public var isInSelectionMode = false
    @Published public var successAdded: Bool = false
    @Published public var userNotFound: Bool = false

    public init(isBuilder: Bool = false) {
        self.isBuilder = isBuilder
        setupPublishers()
    }

    public func setupPublishers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getContacts()
                ChatManager.activeInstance?.contact.getBlockedList()
                self?.sync()
            }
        }
        .store(in: &canceableSet)
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
        NotificationCenter.connect.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink{ [weak self] event in
                self?.onContactEvent(event)
            }
            .store(in: &canceableSet)
    }

    public func onContactEvent(_ event: ContactEventTypes?) {
        switch event {
        case let .contacts(response):
            onSearchContacts(response)
            onContacts(response)
        case let .add(response):
            onAddContacts(response)
        case let .delete(response, deleted):
            onDeleteContacts(response, deleted)
        case let .blocked(response):
            onBlockResponse(response)
        case let .unblocked(response):
            onUNBlockResponse(response)
        case let .blockedList(response):
            onBlockedList(response)
        default:
            break
        }
    }

    public func onContacts(_ response: ChatResponse<[Contact]>) {
        if !response.cache, response.pop(prepend: "GET-CONTACTS\(isBuilder ? "-Builder" : "")") != nil {
            if let contacts = response.result {
                firstSuccessResponse = !response.cache
                appendOrUpdateContact(contacts)
                setMaxContactsCountInServer(count: response.contentCount ?? 0)
            }
            hasNext = response.hasNext
            isLoading = false
        }
    }

    func onBlockedList(_ response: ChatResponse<[BlockedContactResponse]>) {
        blockedContacts = .init(response.result ?? [])
    }

    public func getContacts() {
        isLoading = true
        let req = ContactsRequest(count: count, offset: offset)
        RequestsManager.shared.append(prepend: "GET-CONTACTS\(isBuilder ? "-Builder" : "")", value: req)
        ChatManager.activeInstance?.contact.get(req)
    }

    public func searchContacts(_ searchText: String) {
        isLoading = true
        let req: ContactsRequest
        if searchType == .username {
            req = ContactsRequest(userName: searchText)
        } else if searchType == .cellphoneNumber {
            req = ContactsRequest(cellphoneNumber: searchText)
        } else {
            req = ContactsRequest(query: searchText)
        }
        RequestsManager.shared.append(prepend: "SEARCH-CONTACTS\(isBuilder ? "-Builder" : "")", value: req)
        ChatManager.activeInstance?.contact.search(req)
    }

    public func onDeleteContacts(_ response: ChatResponse<[Contact]>, _ deleted: Bool) {
        if deleted {
            response.result?.forEach{ contact in
                searchedContacts.removeAll(where: {$0.id == contact.id})
                contacts.removeAll(where: {$0.id == contact.id})
            }
            animateObjectWillChange()
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
        searchContactString = ""
        firstSuccessResponse = false
        hasNext = true
        offset = 0
        count = 15
        showAddOrEditContactSheet = false
        isInSelectionMode = false
        addContact = nil
        editContact = nil
        successAdded = false
        userNotFound = false
        contacts = []
        blockedContacts = []
        selectedContacts = []
        searchedContacts = []
        maxContactsCountInServer = 0
        animateObjectWillChange()
    }

    public func deselectContacts() {
        selectedContacts = [] 
    }

    public func delete(indexSet: IndexSet) {
        let contacts = contacts.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        contacts.forEach { contact in
            delete(contact)
            reomve(contact)
        }
        animateObjectWillChange()
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
        animateObjectWillChange()
    }

    public func onAddContacts(_ response: ChatResponse<[Contact]>) {
        if response.error == nil, let contacts = response.result {
            contacts.forEach { newContact in
                if let index = self.contacts.firstIndex(where: {$0.id == newContact.id }) {
                    self.contacts[index].update(newContact)
                } else {
                    self.contacts.insert(newContact, at: 0)
                }
            }
            editContact = nil
            showAddOrEditContactSheet = false
            successAdded = true
            userNotFound = false
        } else if let error = response.error, error.code == 78 {
            userNotFound = true
        }
        isLoading = false
        animateObjectWillChange()
    }

    public func setMaxContactsCountInServer(count: Int) {
        maxContactsCountInServer = count
    }

    public func reomve(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0 == contact }) else { return }
        contacts.remove(at: index)
        animateObjectWillChange()
    }

    public func addToSelctedContacts(_ contact: Contact) {
        selectedContacts.append(contact)
    }

    public func removeToSelctedContacts(_ contact: Contact) {
        guard let index = selectedContacts.firstIndex(of: contact) else { return }
        selectedContacts.remove(at: index)
    }

    public func onSearchContacts(_ response: ChatResponse<[Contact]>) {
        if response.pop(prepend: "SEARCH-CONTACTS\(isBuilder ? "-Builder" : "")") != nil {
            isLoading = false
            searchedContacts = .init(response.result ?? [])
        }
    }

    public func addContact(contactValue: String, firstName: String?, lastName: String?) {
        isLoading = true
        let isNumber = isNumber(value: contactValue)
        if isNumber && contactValue.count < 10 {
            userNotFound = true
            isLoading = false
            return
        }
        let req: AddContactRequest = isNumber ?
            .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, typeCode: "default") :
            .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue, typeCode: "default")
        ChatManager.activeInstance?.contact.add(req)
    }

    public func firstContact(_ contact: Contact) -> Contact? {
        contacts.first { $0.id == contact.id }
    }

    public func isNumber(value: String) -> Bool {
        let phoneRegex = "^[0-9]*$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let result = phoneTest.evaluate(with: value)
        return result
    }

    public func block(_ contact: Contact) {
        let req = BlockRequest(contactId: contact.id)
        ChatManager.activeInstance?.contact.block(req)
    }

    public func unblock(_ blockedId: Int) {
        let req = UnBlockRequest(blockId: blockedId)
        ChatManager.activeInstance?.contact.unBlock(req)
    }

    public func unblockWith(_ contactId: Int) {
        let req = UnBlockRequest(contactId: contactId)
        ChatManager.activeInstance?.contact.unBlock(req)
    }

    public func onBlockResponse(_ response: ChatResponse<BlockedContactResponse>) {
        if let result = response.result {
            contacts.first(where: { $0.id == result.contact?.id })?.blocked = true
            blockedContacts.append(result)
            animateObjectWillChange()
        }
    }

    public func onUNBlockResponse(_ response: ChatResponse<BlockedContactResponse>) {
        if let result = response.result {
            contacts.first(where: { $0.id == result.contact?.id })?.blocked = false
            blockedContacts.removeAll(where: {$0.coreUserId == response.result?.coreUserId})
            animateObjectWillChange()
        }
    }

    public func isSelected(contact: Contact) -> Bool {
        selectedContacts.contains(contact)
    }

    public func toggleSelectedContact(contact: Contact) {
        withAnimation(.easeInOut) {
            if isSelected(contact: contact) {
                removeToSelctedContacts(contact)
            } else {
                addToSelctedContacts(contact)
            }
            animateObjectWillChange()
        }
    }

    public func sync() {
        if UserDefaults.standard.bool(forKey: "sync_contacts") == true {
            ChatManager.activeInstance?.contact.sync()
        }
    }
}
