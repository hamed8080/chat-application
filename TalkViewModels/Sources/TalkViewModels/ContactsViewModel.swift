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
    @Published public var createConversationType: ThreadTypes?
    @Published public var showConversaitonBuilder = false
    @Published public var showEditCreatedConversationDetail = false
    @Published public var editContact: Contact?
    @Published public var showAddOrEditContactSheet = false
    @Published public var isInSelectionMode = false {
        didSet {
            selectedContacts = []
            animateObjectWillChange()
        }
    }
    @Published public var deleteDialog = false

    @Published public var conversationTitle: String = ""
    @Published public var threadDescription: String = ""
    @Published public var createdConversationParticpnats: [Participant] = []
    public var createdConversation: Conversation?
    public var assetResources: [PHAssetResource] = []
    public var image: UIImage?

    /// Check public thread name.
    @Published public var isPublic: Bool = false
    @Published public var isPublicNameAvailable: Bool = false
    @Published public var isCehckingName: Bool = false

    public init() {
        getContacts()
        setupPublishers()
    }

    public func setupPublishers() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
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
        case .isNameAvailable(let response):
            onIsNameAvailable(response)
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
            contacts.forEach { newContact in
                if let index = self.contacts.firstIndex(where: {$0.id == newContact.id }) {
                    self.contacts[index].update(newContact)
                } else {
                    self.contacts.insert(newContact, at: 0)
                }
            }
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
        guard let type = createConversationType else { return }
        isLoading = true
        let invitees = selectedContacts.map { Invitee(id: "\($0.id ?? 0)", idType: .contactId) }
        let req = CreateThreadRequest(invitees: invitees, title: String(localized: .init(type.stringValue ?? "")), type: type)
        RequestsManager.shared.append(prepend: "ConversationBuilder", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func onCreateGroup(_ response: ChatResponse<Conversation>) {
        if response.value(prepend: "ConversationBuilder") != nil {
            isLoading = false
            if let conversation = response.result {
                self.createdConversation = conversation
                showEditCreatedConversationDetail = true
                getCreatedGroupParticipants()
            }
        }
    }

    public func getCreatedGroupParticipants() {
        if let id = createdConversation?.id {
            let req = ThreadParticipantRequest(request: .init(threadId: id), admin: false)
            RequestsManager.shared.append(prepend: "CreatedConversationParticipants", value: req)
            ChatManager.activeInstance?.conversation.participant.get(req)
        }
    }

    public func onCreateGroupParticipants(_ response: ChatResponse<[Participant]>) {
        if response.value(prepend: "CreatedConversationParticipants") != nil, let participnts = response.result {
            participnts.forEach { participant in
                participant.conversation = createdConversation /// we do this because in memeber participants row we need to know the inviter of the conversation.
                createdConversationParticpnats.append(participant)
            }
            createdConversationParticpnats.sort(by: {$0.admin ?? false && !($1.admin ?? false)})
        }
    }

    public func submitEditCreatedGroup() {
        isLoading = true
        guard let threadId = createdConversation?.id else { return }
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
                                              userGroupHash: createdConversation?.userGroupHash,
                                              hC: height,
                                              wC: width
            )
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: conversationTitle)
        RequestsManager.shared.append(prepend: "EditConversation", value: req)
        ChatManager.activeInstance?.conversation.updateInfo(req)
    }

    public func onEditCreatedGroup(_ response: ChatResponse<Conversation>) {
        if response.value(prepend: "EditConversation") != nil {
            closeBuilder()
            isLoading = false
            createdConversation = nil
            showEditCreatedConversationDetail = false
            image = nil
            assetResources = []
            createdConversationParticpnats = []
            createConversationType = nil
            conversationTitle = ""
        }
    }

    public func closeBuilder() {
        selectedContacts = []
        showConversaitonBuilder = false
        searchContactString = ""
        AppState.shared.navViewModel?.threadsViewModel?.sheetType = nil
    }

    public func checkPublicName(_ title: String) {
        if titleIsValid {
            isCehckingName = true
            ChatManager.activeInstance?.conversation.isNameAvailable(.init(name: title))
        }
    }

    private func onIsNameAvailable(_ response: ChatResponse<PublicThreadNameAvailableResponse>) {
        if conversationTitle == response.result?.name {
            self.isPublicNameAvailable = true
        }
        isCehckingName = false
    }

    public var titleIsValid: Bool {
        if conversationTitle.isEmpty { return false }
        if !isPublic { return true }
        let regex = try! Regex("^[a-zA-Z0-9]\\S*$")
        return conversationTitle.contains(regex)
    }
}
