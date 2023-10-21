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
    @Published public var showCreateGroup = false
    @Published public var showEditCreatedGroupDetail = false
    @Published public var editContact: Contact?
    @Published public var addContactSheet = false
    @Published public var isInSelectionMode = false
    @Published public var deleteDialog = false

    @Published public var editTitle: String = ""
    @Published public var threadDescription: String = ""
    @Published public var createdGroupParticpnats: [Participant] = []
    public var createdGroupConversation: Conversation?
    public var assetResources: [PHAssetResource] = []
    public var image: UIImage?

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

        NotificationCenter.default.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink{ [weak self] event in
                self?.onConversationEvent(event)
            }
            .store(in: &canceableSet)

        NotificationCenter.default.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink{ [weak self] event in
                self?.onParticipantsEvent(event)
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
            onBlockResponse(response)
        case let .unblocked(response):
            onUNBlockResponse(response)
        case let .blockedList(response):
            onBlockedList(response)
        default:
            break
        }
    }

    public func onConversationEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .created(let response):
            onCreateGroup(response)
        case .updatedInfo(let response):
            onEditCreatedGroup(response)
        default:
            break
        }
    }

    public func onParticipantsEvent(_ event: ParticipantEventTypes?) {
        switch event {
        case .participants(let response):
            onCreateGroupParticipants(response)
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

    public func deselectContacts() {
        selectedContacts = [] 
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

    public func block(_ contact: Contact) {
        let req = BlockRequest(contactId: contact.id)
        ChatManager.activeInstance?.contact.block(req)
    }

    public func unblock(_ blockedId: Int) {
        let req = UnBlockRequest(blockId: blockedId)
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

    public func createGroupWithSelectedContacts() {
        isLoading = true
        let invitees = selectedContacts.map { Invitee(id: "\($0.id ?? 0)", idType: .contactId) }
        let req = CreateThreadRequest(invitees: invitees, title: "Group", type: .normal)
        RequestsManager.shared.append(prepend: "CreateGroup", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func onCreateGroup(_ response: ChatResponse<Conversation>) {
        if response.value(prepend: "CreateGroup") != nil {
            isLoading = false
            if let conversation = response.result {
                self.createdGroupConversation = conversation
                showEditCreatedGroupDetail = true
                getCreatedGroupParticipants()
            }
        }
    }

    public func getCreatedGroupParticipants() {
        if let id = createdGroupConversation?.id {
            let req = ThreadParticipantRequest(request: .init(threadId: id), admin: false)
            RequestsManager.shared.append(prepend: "CreatedGroupParticipants", value: req)
            ChatManager.activeInstance?.conversation.participant.get(req)
        }
    }

    public func onCreateGroupParticipants(_ response: ChatResponse<[Participant]>) {
        if response.value(prepend: "CreatedGroupParticipants") != nil, let participnts = response.result {
            participnts.forEach { participant in
                participant.conversation = createdGroupConversation /// we do this because in memeber participants row we need to know the inviter of the conversation.
                createdGroupParticpnats.append(participant)
            }
            createdGroupParticpnats.sort(by: {$0.admin ?? false && !($1.admin ?? false)})
        }
    }

    public func submitEditCreatedGroup() {
        isLoading = true
        guard let threadId = createdGroupConversation?.id else { return }
        var imageRequest: UploadImageRequest?
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                              fileExtension: "png",
                                              fileName: assetResources.first?.originalFilename ?? "",
                                              isPublic: true,
                                              mimeType: "image/png",
                                              originalName: assetResources.first?.originalFilename ?? "",
                                              userGroupHash: createdGroupConversation?.userGroupHash,
                                              hC: height,
                                              wC: width
            )
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: editTitle)
        RequestsManager.shared.append(prepend: "EditGroup", value: req)
        ChatManager.activeInstance?.conversation.updateInfo(req)
    }

    public func onEditCreatedGroup(_ response: ChatResponse<Conversation>) {
        if response.value(prepend: "EditGroup") != nil {
            isLoading = false
            createdGroupConversation = nil
            showCreateGroup = false
            showEditCreatedGroupDetail = false
            image = nil
            selectedContacts = []
            assetResources = []
            createdGroupParticpnats = []
        }
    }
}
