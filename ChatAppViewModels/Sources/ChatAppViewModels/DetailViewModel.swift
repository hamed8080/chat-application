//
//  DetailViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import Photos
import SwiftUI
import ChatExtensions
import ChatDTO
import ChatAppModels
import ChatCore
import ChatModels

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
    public var notSeenString: String? { user?.notSeenString ?? contact?.notSeenString }
    public var cellPhoneNumber: String? { contact?.cellphoneNumber ?? user?.cellphoneNumber }
    public var isBlock: Bool { contact?.blocked == true || user?.blocked == true }
    public var bio: String? { contact?.user?.chatProfileVO?.bio ?? user?.chatProfileVO?.bio }
    public var showInfoGroupBox: Bool { bio != nil || cellPhoneNumber != nil || canBlock == true }
    public var url: String? { thread?.computedImageURL ?? user?.image ?? contact?.image }
    public var participantViewModel: ParticipantsViewModel?
    public var mutualThreads: [Conversation] = []
    public weak var threadVM: ThreadViewModel?

    public var editTitle: String = ""
    public var searchText: String = ""
    public var image: UIImage?
    @Published public var showAddToContactSheet: Bool = false
    public var threadDescription: String = ""
    @Published public var isInEditMode = false
    @Published public var showImagePicker: Bool = false
    public var assetResources: [PHAssetResource] = []
    private var requests: [String: Any] = [:]
    @Published public var dismiss = false

    public init(thread: Conversation? = nil, contact: Contact? = nil, user: Participant? = nil) {
        self.user = user
        self.thread = thread
        self.contact = contact
        if let thread = thread {
            participantViewModel = ParticipantsViewModel(thread: thread)
        }
        editTitle = title
        threadDescription = thread?.description ?? ""
        fetchMutualThreads()
        NotificationCenter.default.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .contact)
            .compactMap { $0.object as? ContactEventTypes }
            .sink { [weak self] value in
                self?.onContactEvent(value)
            }
            .store(in: &cancelable)
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
            requests[req.uniqueId] = req
            ChatManager.activeInstance?.contact.unBlock(req)
        } else {
            let req = BlockRequest(userId: contact?.userId ?? user?.coreUserId)
            requests[req.uniqueId] = req
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

    public func updateThreadInfo() {
        guard let threadId = thread?.id else { return }
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
                                              userGroupHash: thread?.userGroupHash,
                                              hC: height,
                                              wC: width
            )
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: editTitle)
        ChatManager.activeInstance?.conversation.updateInfo(req)
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
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.conversation.mute(req)
    }

    public func unmute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        requests[req.uniqueId] = req
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
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.conversation.mutual(req)
    }

    private func onMutual(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            mutualThreads = threads
            animateObjectWillChange()
        }
    }

    public func toggleThreadVisibility() {
        guard let thread = thread, let threadId = thread.id else { return }
        let type: ThreadTypes = thread.isPrivate ? thread.publicType : thread.privateType
        let req = ChangeThreadTypeRequest(threadId: threadId, type: type)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.conversation.changeType(req)
    }

    private func onChangeThreadType(_ response: ChatResponse<Conversation>) {
        self.thread?.type = response.result?.type
        animateObjectWillChange()
    }
}
