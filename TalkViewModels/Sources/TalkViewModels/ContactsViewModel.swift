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

public final class ContactsViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    public private(set) var selectedContacts: ContiguousArray<Contact> = []
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var maxContactsCountInServer = 0
    public private(set) var contacts: ContiguousArray<Contact> = []
    @Published public var searchType: SearchParticipantType = .name
    @Published public private(set) var searchedContacts: ContiguousArray<Contact> = []
    @Published public var isLoading = false
    @Published public var searchContactString: String = ""
    public var blockedContacts: ContiguousArray<BlockedContactResponse> = []
    @Published public var createConversationType: ThreadTypes?
    @Published public var showTitleError: Bool = false
    @Published public var showConversaitonBuilder = false
    @Published public var showCreateConversationDetail = false
    @Published public var addContact: Contact?
    @Published public var editContact: Contact?
    @Published public var showAddOrEditContactSheet = false
    /// When the user initiates a create group/channel with the plus button in the Conversation List.
    @Published public var closeConversationContextMenu: Bool = false
    public var createdConversation: Conversation?
    @Published public var isCreateLoading = false
    @Published public var isInSelectionMode = false {
        didSet {
            selectedContacts = []
            animateObjectWillChange()
        }
    }

    @Published public var conversationTitle: String = ""
    @Published public var threadDescription: String = ""
    public var assetResources: [PHAssetResource] = []
    public var image: UIImage?

    /// Check public thread name.
    @Published public var isPublic: Bool = false
    @Published public var isPublicNameAvailable: Bool = false
    @Published public var isCehckingName: Bool = false
    @Published public var successAdded: Bool = false
    @Published public var userNotFound: Bool = false

    public var uploadProfileUniqueId: String?
    public var uploadProfileProgress: Int64?

    public init() {
        getContacts()
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

        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink{ [weak self] event in
                self?.onConversationEvent(event)
            }
            .store(in: &canceableSet)
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] value in
                self?.onUploadEvent(value)
            }
            .store(in: &canceableSet)
        $conversationTitle
            .sink { [weak self] newValue in
            if newValue.count >= 2 {
                self?.showTitleError = false
            }
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

    public func onConversationEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .created(let response):
            onCreateGroup(response)
        case .updatedInfo(let response):
            onEditGroup(response)
        case .isNameAvailable(let response):
            onIsNameAvailable(response)
        default:
            break
        }
    }

    public func onContacts(_ response: ChatResponse<[Contact]>) {
        if !response.cache, response.pop(prepend: "GET-CONTACTS") != nil {
            if let contacts = response.result {
                firstSuccessResponse = !response.cache
                appendOrUpdateContact(contacts)
                setMaxContactsCountInServer(count: response.contentCount ?? 0)
            }
            if !response.cache {
                hasNext = response.hasNext
            }
            isLoading = false
        }
    }

    func onBlockedList(_ response: ChatResponse<[BlockedContactResponse]>) {
        blockedContacts = .init(response.result ?? [])
    }

    public func getContacts() {
        isLoading = true
        let req = ContactsRequest(count: count, offset: offset)
        RequestsManager.shared.append(prepend: "GET-CONTACTS", value: req)
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
        RequestsManager.shared.append(prepend: "SEARCH-CONTACTS", value: req)
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
        hasNext = true
        offset = 0
        count = 15
        contacts = []
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
        if response.pop(prepend: "SEARCH-CONTACTS") != nil {
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

    public func moveToNextPage() {
        showCreateConversationDetail = true
    }

    public func createGroupWithSelectedContacts() {
        if conversationTitle.count < 2 {
            showTitleError = true
            return
        }
        guard let type = createConversationType else { return }
        isCreateLoading = true
        let invitees = selectedContacts.map { Invitee(id: "\($0.id ?? 0)", idType: .contactId) }
        let req = CreateThreadRequest(description: threadDescription,
                                      invitees: invitees,
                                      title: conversationTitle,
                                      type: isPublic ? type.publicType : type,
                                      uniqueName: isPublic ? UUID().uuidString : nil
        )
        RequestsManager.shared.append(prepend: "ConversationBuilder", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func onCreateGroup(_ response: ChatResponse<Conversation>) {
        if response.pop(prepend: "ConversationBuilder") != nil {
            isCreateLoading = false
            if let conversation = response.result {
                self.createdConversation = conversation
                editGroup()
            }
        }
    }

    public func editGroup() {
        isCreateLoading = true
        guard let createdConversation = createdConversation, let threadId = createdConversation.id else { return }
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
                                              userGroupHash: createdConversation.userGroupHash,
                                              hC: height,
                                              wC: width
            )
            uploadProfileUniqueId = imageRequest?.uniqueId
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: conversationTitle)
        RequestsManager.shared.append(prepend: "EditConversation", value: req, autoCancel: false)
        ChatManager.activeInstance?.conversation.updateInfo(req)
    }

    public func onEditGroup(_ response: ChatResponse<Conversation>) {
        if response.pop(prepend: "EditConversation") != nil {
            closeConversationContextMenu = true
            closeBuilder()
            isCreateLoading = false
            showCreateConversationDetail = false
            image = nil
            assetResources = []
            createConversationType = nil
            conversationTitle = ""
            if let conversation = createdConversation {
                /// It will fix a bug in small devices where they can not click on the buttons in the toolbar after the thread has been created.
                /// This bug is because a sheet prevents the view from being calculated correctly.
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
                    AppState.shared.showThread(thread: conversation)
                    self?.createdConversation = nil
                }
            }
        }
    }

    public func closeBuilder() {
        selectedContacts = []
        showConversaitonBuilder = false
        searchContactString = ""
        showTitleError = false
        isPublic = false
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
        guard let regex = try? Regex("^[a-zA-Z0-9]\\S*$") else { return false }
        return conversationTitle.contains(regex)
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .progress(let uniqueId, let progress):
            onUploadConversationProfile(uniqueId, progress)
        default:
            break
        }
    }

    private func onUploadConversationProfile(_ uniqueId: String, _ progress: UploadFileProgress?) {
        if uniqueId == uploadProfileUniqueId {
            uploadProfileProgress = progress?.percent ?? 0
            animateObjectWillChange()
        }
    }

}
