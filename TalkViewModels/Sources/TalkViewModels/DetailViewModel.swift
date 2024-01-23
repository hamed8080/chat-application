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
        lhs.participant?.id == rhs.participant?.id || lhs.thread?.id == rhs.thread?.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread?.id)
        hasher.combine(participant?.id)
    }

    private(set) var cancelable: Set<AnyCancellable> = []
    public var participant: Participant?
    public var thread: Conversation?
    public var isInMyContact: Bool { participant?.contactId != nil }
    public var canBlock: Bool { thread == nil }
    public var title: String { thread?.title ?? participant?.name ?? "" }
    public var notSeenString: String? { participant?.notSeenDuration?.localFormattedTime }
    public var cellPhoneNumber: String? { participant?.cellphoneNumber }
    public var isBlock: Bool { participant?.blocked == true }
    public var bio: String? { participant?.chatProfileVO?.bio }
    public var showInfoGroupBox: Bool { bio != nil || cellPhoneNumber != nil || canBlock == true }
    public var url: String? { thread?.computedImageURL ?? participant?.image }
    public var mutualThreads: ContiguousArray<Conversation> = []
    public weak var threadVM: ThreadViewModel?
    @Published public var isPublic = false

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
    public var canEditContact: Bool { !isGroup && participant != nil }
    public var canShowEditButton: Bool {
        if thread?.type == .selfThread { return false }
        if thread?.group == true && thread?.admin == true {
            return true
        } else if participant?.contactId != nil && (thread?.group == false || thread?.group == nil) {
            return true
        } else {
            return false
        }
    }
    public var uploadProfileUniqueId: String?
    public var uploadProfileProgress: Int64?
    public var canShowUserActions: Bool {
        (thread?.group == nil || thread?.group == false) && thread?.type != .selfThread
    }

    public init(participant: Participant) {
        self.participant = participant
        setup()
    }

    public init(thread: Conversation, threadVM: ThreadViewModel? = nil) {
        self.thread = thread
        self.threadVM = threadVM
        if thread.group == false || thread.group == nil {
            participant = self.threadVM?.participantsViewModel.participants.first(where: {$0.id != AppState.shared.user?.id && $0.auditor == false })
        }
        setup()
    }

    public func setup() {
        isPublic = thread?.type?.isPrivate == false
        editTitle = title
        threadDescription = thread?.description ?? ""
        fetchMutualThreads()
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.connect.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] value in
                self?.onContactEvent(value)
            }
            .store(in: &cancelable)

        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] value in
                self?.onUploadEvent(value)
            }
            .store(in: &cancelable)
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
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        default:
            break
        }
    }

    private func onContactEvent(_ event: ContactEventTypes) {
        switch event {
        case .blocked(let chatResponse):
            onBlock(chatResponse)
        case .unblocked(let chatResponse):
            onUNBlock(chatResponse)
        case .add(let chatResponse):
            onAddContact(chatResponse)
        case .delete(let response, let deleted):
            onDeletedContact(response, deleted)
        default:
            break
        }
    }

    public func createThread() {
        if let contactId = participant?.contactId {
            AppState.shared.openThread(contact: .init(id: contactId))
        } else if let user = participant {
            AppState.shared.openThread(participant: user)
        }
    }

    public func copyPhone() {
        guard let phone = cellPhoneNumber else { return }
        UIPasteboard.general.string = phone
    }

    public func blockUnBlock() {
        let unblcokReq = UnBlockRequest(contactId: participant?.contactId, userId: participant?.coreUserId)
        let blockReq = BlockRequest(contactId: participant?.contactId, userId: participant?.coreUserId)
        if participant?.blocked == true {
            RequestsManager.shared.append(value: unblcokReq)
            ChatManager.activeInstance?.contact.unBlock(unblcokReq)
        } else {
            RequestsManager.shared.append(value: blockReq)
            ChatManager.activeInstance?.contact.block(blockReq)
        }
    }

    private func onBlock(_ response: ChatResponse<BlockedContactResponse>) {
        if response.result != nil {
            participant?.blocked = true
            animateObjectWillChange()
        }
    }

    private func onUNBlock(_ response: ChatResponse<BlockedContactResponse>) {
        if response.result != nil {
            participant?.blocked = false
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
        guard let userId = (thread?.partner ?? participant?.id) else { return }
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
        if let req = response.pop(prepend: "CHANGE-TO-PUBLIC") as? ChangeThreadTypeRequest {
            thread?.uniqueName = req.uniqueName
        }
        animateObjectWillChange()
    }

    private func onAddContact(_ response: ChatResponse<[Contact]>) {
        response.result?.forEach{ contact in
            if contact.user?.username == participant?.username {
                participant?.contactId = contact.id
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
        if response.contains(prepend: "EditGroup") {
            image = nil
            isLoading = false
            showEditGroup = false
            uploadProfileUniqueId = nil
            uploadProfileProgress = nil
            threadVM?.animateObjectWillChange()
        }
    }

    public func showEditContactOrEditGroup(contactsVM: ContactsViewModel) {
        if participant?.contactId != nil {
            contactsVM.editContact = participant?.toContact
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

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == thread?.id {
            dismiss = true
        }
    }

    private func onDeletedContact(_ response: ChatResponse<[Contact]>, _ deleted: Bool) {
        if deleted {
            if response.result?.first?.id == participant?.contactId {
                participant?.contactId = nil
                animateObjectWillChange()
            }
        }
    }

    deinit{
        print("deinit DetailViewModel")
    }
}
