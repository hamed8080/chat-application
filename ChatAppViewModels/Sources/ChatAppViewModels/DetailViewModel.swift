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

public final class DetailViewModel: ObservableObject {
    private(set) var cancellableSet: Set<AnyCancellable> = []
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
    @Published public var isLoading: Bool = false
    @Published public var participantViewModel: ParticipantsViewModel?
    @Published public var mutualThreads: [Conversation] = []

    @Published public var editTitle: String = ""
    @Published public var searchText: String = ""
    @Published public var image: UIImage?
    @Published public var addToContactSheet: Bool = false
    @Published public var threadDescription: String = ""
    @Published public var isInEditMode = false
    @Published public var showImagePicker: Bool = false
    @Published public var assetResources: [PHAssetResource] = []

    public init(thread: Conversation? = nil, contact: Contact? = nil, user: Participant? = nil) {
        self.user = user
        self.thread = thread
        self.contact = contact
        if let thread = thread {
            participantViewModel = ParticipantsViewModel(thread: thread)
        }
        participantViewModel?.$isLoading.sink { [weak self] newValue in
            self?.isLoading = newValue
        }
        .store(in: &cancellableSet)
        editTitle = title
        threadDescription = thread?.description ?? ""
        fetchMutualThreads()
    }

    public func createThread() {
        if let contact = contact {
            let invitees = [Invitee(id: "\(contact.id ?? 0)", idType: .contactId)]
            AppState.shared.showThread(invitees: invitees)
        } else if let user = user {
            let invitees = [Invitee(id: "\(user.coreUserId ?? 0)", idType: .userId)]
            AppState.shared.showThread(invitees: invitees)
        }
    }

    public func copyPhone() {
        guard let phone = cellPhoneNumber else { return }
        UIPasteboard.general.string = phone
    }

    public func blockUnBlock() {
        ChatManager.activeInstance?.blockContact(.init(userId: contact?.userId ?? user?.coreUserId)) { response in
            if let contact = response.result {
                self.contact?.blocked = contact.blocked
                self.user?.blocked = contact.blocked
            }
        }
    }

    public func updateThreadInfo() {
        guard let threadId = thread?.id else { return }
        var imageRequest: UploadImageRequest?
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                              hC: height,
                                              wC: width,
                                              fileExtension: "png",
                                              fileName: assetResources.first?.originalFilename,
                                              mimeType: "image/png",
                                              originalName: assetResources.first?.originalFilename,
                                              userGroupHash: thread?.userGroupHash,
                                              isPublic: true)
        }

        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: editTitle)
        ChatManager.activeInstance?.updateThreadInfo(req) { _ in } uploadProgress: { _, _ in } completion: { _ in }
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
        ChatManager.activeInstance?.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    public func unmute(_ threadId: Int) {
        ChatManager.activeInstance?.unmuteThread(.init(subjectId: threadId), completion: onUnMuteChanged)
    }

    public func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = true
            objectWillChange.send()
        }
    }

    public func onUnMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = false
            objectWillChange.send()
        }
    }

    public func fetchMutualThreads() {
        guard let userId = (thread?.partner ?? contact?.userId ?? user?.id) else { return }
        let invitee = Invitee(id: "\(userId)", idType: .userId)
        ChatManager.activeInstance?.mutualGroups(.init(toBeUser: invitee)) { [weak self] response in
            if let threads = response.result {
                self?.mutualThreads = threads
            }
        }
    }

    public func toggleThreadVisibility() {
        guard let thread = thread, let threadId = thread.id else { return }
        let type: ThreadTypes = thread.isPrivate ? thread.publicType : thread.privateType
        ChatManager.activeInstance?.changeThreadType(.init(threadId: threadId, type: type)) { [weak self] response in
            if let thread = response.result {
                self?.thread?.type = thread.type
                self?.objectWillChange.send()
            }
        }
    }
}
