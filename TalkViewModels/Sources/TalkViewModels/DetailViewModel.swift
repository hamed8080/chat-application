//
//  DetailViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import Photos
import SwiftUI
import ChatDTO
import TalkModels
import ChatCore
import ChatModels
import TalkExtensions
import ChatTransceiver

public final class DetailViewModel: ObservableObject, Hashable {
    public static func == (lhs: DetailViewModel, rhs: DetailViewModel) -> Bool {
        lhs.user?.id == rhs.user?.id || lhs.thread?.id == rhs.thread?.id || lhs.contact?.id == rhs.contact?.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(contact?.id)
        hasher.combine(thread?.id)
        hasher.combine(user?.id)
    }

    private(set) var cancelable: Set<AnyCancellable> = []
    public var user: Participant?
    public var contact: Contact?
    public var thread: Conversation?
    public var isInMyContact: Bool { (user?.contactId != nil || contact != nil) && thread == nil }
    public var canBlock: Bool { thread == nil }
    public var title: String { thread?.title ?? user?.name ?? contact?.user?.name ?? "\(contact?.firstName ?? "") \(contact?.lastName ?? "")" }
    public var notSeenString: String? { user?.notSeenDuration?.localFormattedTime ?? contact?.notSeenDuration?.localFormattedTime }
    public var cellPhoneNumber: String? { contact?.cellphoneNumber ?? user?.cellphoneNumber }
    public var isBlock: Bool { contact?.blocked == true || user?.blocked == true }
    public var bio: String? { contact?.user?.chatProfileVO?.bio ?? user?.chatProfileVO?.bio }
    public var showInfoGroupBox: Bool { bio != nil || cellPhoneNumber != nil || canBlock == true }
    public var url: String? { thread?.computedImageURL ?? user?.image ?? contact?.image }
    public var participantViewModel: ParticipantsViewModel? { threadVM?.participantsViewModel }
    public var mutualThreads: ContiguousArray<Conversation> = []
    public weak var threadVM: ThreadViewModel?
    public var p2pPartnerContact: Contact?
    public var isPublic = false

    @Published public var editTitle: String = ""
    public var searchText: String = ""
    public var image: UIImage?
    @Published public var showAddToContactSheet: Bool = false
    @Published public var threadDescription: String = ""
    @Published public var isInEditMode = false
    public var assetResources: [PHAssetResource] = []
    @Published public var dismiss = false
    @Published public var isLoading = false
    @Published public var showEditGroup = false
    @Published public var showContactEditSheet: Bool = false
    public var isGroup: Bool { thread?.group == true }
    public var canEditContact: Bool { !isGroup && p2pPartnerContact != nil }
    public var canShowEditButton: Bool {(thread?.canEditInfo == true || user?.contactId != nil || canEditContact) && thread?.type != .selfThread }
    public var partner: Participant?
    public var partnerContact: Contact?
    public var uploadProfileUniqueId: String?
    public var uploadProfileProgress: Int64?

    public init(thread: Conversation? = nil, threadVM: ThreadViewModel? = nil, contact: Contact? = nil, user: Participant? = nil) {
        self.user = user
        self.thread = thread
        self.contact = contact
        self.threadVM = threadVM
        isPublic = thread?.type?.isPrivate == false
        editTitle = title
        threadDescription = thread?.description ?? ""
        fetchMutualThreads()
        NotificationCenter.default.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] value in
                self?.onParticipantEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] value in
                self?.onContactEvent(value)
            }
            .store(in: &cancelable)

        NotificationCenter.default.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] value in
                self?.onUploadEvent(value)
            }
            .store(in: &cancelable)
        participantViewModel?.objectWillChange.sink { [weak self] _ in
            self?.user = self?.participantViewModel?.participants.first(where: { $0.id == thread?.partner})
            self?.animateObjectWillChange()
        }
        .store(in: &cancelable)
        if thread?.group == false || thread?.group == nil {
            getUserData()
        }
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

    private func onParticipantEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .participants(let response):
            onP2PParticipant(response)
        default:
            break
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .changedType(let chatResponse):
            onChangeThreadType(chatResponse)
        case .mutual(let chatResponse):
            onMutual(chatResponse)
        case .mute(let response):
            onMuteChanged(response)
        case .unmute(let response):
            onUnMuteChanged(response)
        case .updatedInfo(let response):
            onEditGroup(response)
        case .deleted(let response):
            onDeleteThread(response)
        case .left(let response):
            onLeftThread(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        default:
            break
        }
    }

    private func onContactEvent(_ event: ContactEventTypes) {
        switch event {
        case .contacts(let response):
            onP2PContact(response)
        case .blocked(let chatResponse):
            onBlock(chatResponse)
        case .unblocked(let chatResponse):
            onUNBlock(chatResponse)
        case .add(let chatResponse):
            onAddContact(chatResponse)
        default:
            break
        }
    }

    public func createThread() {
        if let contact = contact {
            AppState.shared.openThread(contact: contact)
        } else if let user = user {
            AppState.shared.openThread(participant: user)
        }
    }

    public func copyPhone() {
        guard let phone = cellPhoneNumber else { return }
        UIPasteboard.general.string = phone
    }

    public func blockUnBlock() {
        if contact?.blocked == true {
            let req = UnBlockRequest(userId: contact?.userId ?? user?.coreUserId)
            RequestsManager.shared.append(value: req)
            ChatManager.activeInstance?.contact.unBlock(req)
        } else {
            let req = BlockRequest(userId: contact?.userId ?? user?.coreUserId)
            RequestsManager.shared.append(value: req)
            ChatManager.activeInstance?.contact.block(req)
        }
    }

    private func onBlock(_ response: ChatResponse<BlockedContactResponse>) {
        if response.result != nil {
            self.contact?.blocked = true
            user?.blocked = true
            animateObjectWillChange()
        }
    }

    private func onUNBlock(_ response: ChatResponse<BlockedContactResponse>) {
        if response.result != nil {
            self.contact?.blocked = false
            user?.blocked = false
            animateObjectWillChange()
        }
    }

    public func toggleMute() {
        guard let threadId = thread?.id else { return }
        if thread?.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    public func mute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.mute(req)
    }

    public func unmute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.unmute(req)
    }

    public func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = true
            animateObjectWillChange()
        }
    }

    public func onUnMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = false
            animateObjectWillChange()
        }
    }

    public func fetchMutualThreads() {
        guard let userId = (thread?.partner ?? contact?.userId ?? user?.id) else { return }
        let invitee = Invitee(id: "\(userId)", idType: .userId)
        let req = MutualGroupsRequest(toBeUser: invitee)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.mutual(req)
    }

    private func onMutual(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            mutualThreads = .init(threads)
            animateObjectWillChange()
        }
    }

    public func toggleThreadVisibility() {
        guard let thread = thread, let threadId = thread.id, let type = thread.type else { return }
        let typeValue: ThreadTypes = type.isPrivate == true ? type.publicType : type.privateType
        let req = ChangeThreadTypeRequest(threadId: threadId, type: typeValue)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.changeType(req)
    }

    private func onChangeThreadType(_ response: ChatResponse<Conversation>) {
        self.thread?.type = response.result?.type
        isPublic = thread?.type?.isPrivate == false
        if let req = response.value(prepend: "CHANGE-TO-PUBLIC") as? ChangeThreadTypeRequest {
            thread?.uniqueName = req.uniqueName
        }
        animateObjectWillChange()
    }

    private func onAddContact(_ response: ChatResponse<[Contact]>) {
        response.result?.forEach{ contact in
            if contact.user?.username == user?.username {
                user?.contactId = contact.id
            }
        }
        animateObjectWillChange()
    }

    /// If the image information '' is nil we have to send a name for our file unless we will end up with an error from podspace,
    /// so we have to fill it with UUID().uuidString.
    public func submitEditGroup() {
        isLoading = true
        guard let threadId = thread?.id else { return }
        var imageRequest: UploadImageRequest?
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                              fileExtension: "png",
                                              fileName: assetResources.first?.originalFilename ?? UUID().uuidString,
                                              isPublic: true,
                                              mimeType: "image/png",
                                              originalName: assetResources.first?.originalFilename ?? UUID().uuidString,
                                              userGroupHash: thread?.userGroupHash,
                                              hC: height,
                                              wC: width
            )
            uploadProfileUniqueId = imageRequest?.uniqueId
        }
        if thread?.type?.isPrivate == false, isPublic == false {
            switchToPrivateType()
        } else if thread?.type?.isPrivate == true, isPublic == true {
            switchPublicType()
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: editTitle)
        RequestsManager.shared.append(prepend: "EditGroup", value: req, autoCancel: false)
        ChatManager.activeInstance?.conversation.updateInfo(req)
    }

    public func switchToPrivateType() {
        guard let conversation = thread else { return }
        AppState.shared.objectsContainer.threadsVM.makeThreadPrivate(conversation)
    }

    public func switchPublicType() {
        guard let conversation = thread else { return }
        AppState.shared.objectsContainer.threadsVM.makeThreadPublic(conversation)
    }

    public func onEditGroup(_ response: ChatResponse<Conversation>) {
        if response.value(prepend: "EditGroup") != nil {
            image = nil
            isLoading = false
            showEditGroup = false
            uploadProfileUniqueId = nil
            uploadProfileProgress = nil
        }
    }

    public func showEditContactOrEditGroup(contactsVM: ContactsViewModel) {
        if user?.contactId != nil || p2pPartnerContact != nil {
            contactsVM.editContact = p2pPartnerContact ?? user?.toContact
            showContactEditSheet.toggle()
        } else if thread?.canEditInfo == true {
            showEditGroup.toggle()
        }
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == thread?.id {
            dismiss = true
        }
    }

    private func onLeftThread(_ response: ChatResponse<User>) {
        if response.subjectId == thread?.id, response.result?.id == AppState.shared.user?.id {
            dismiss = true
        } else {
            participantViewModel?.removeParticipant(.init(id: response.result?.id))
            animateObjectWillChange()
        }
    }

    private func getUserData() {
        guard let threadId = thread?.id else { return }
        let req = ThreadParticipantRequest(threadId: threadId)
        RequestsManager.shared.append(prepend: "GET-P2P-DETAIL", value: req)
        ChatManager.activeInstance?.conversation.participant.get(req)
    }

    private func onP2PParticipant(_ response: ChatResponse<[Participant]>) {
        if response.value(prepend: "GET-P2P-DETAIL") != nil, let partner = response.result?.first(where: {$0.id == thread?.partner}) {
            self.partner = partner
            animateObjectWillChange()
            let req = ContactsRequest(id: partner.contactId)
            RequestsManager.shared.append(prepend: "GET-P2P-CONTACT-DETAIL", value: req)
            ChatManager.activeInstance?.contact.get(req)
        }
    }

    private func onP2PContact(_ response: ChatResponse<[Contact]>) {
        if response.value(prepend: "GET-P2P-CONTACT-DETAIL") != nil, let partnerContact = response.result?.first(where: {$0.id == partner?.contactId}) {
            self.partnerContact = partnerContact
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == thread?.id {
            dismiss = true
        }
    }

    deinit{
        print("deinit DetailViewModel")
    }
}
