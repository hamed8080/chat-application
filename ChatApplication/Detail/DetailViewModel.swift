//
//  DetailViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation
import Photos
import SwiftUI

final class DetailViewModel: ObservableObject {
    private(set) var cancellableSet: Set<AnyCancellable> = []
    var user: Participant?
    var contact: Contact?
    var thread: Conversation?
    var isInMyContact: Bool { (user?.contactId != nil || contact != nil) && thread == nil }
    var canBlock: Bool { thread == nil }
    var title: String { thread?.title ?? user?.name ?? contact?.user?.name ?? "\(contact?.firstName ?? "") \(contact?.lastName ?? "")" }
    var notSeenString: String? { ContactRow.getDate(notSeenDuration: user?.notSeenDuration ?? contact?.notSeenDuration) }
    var cellPhoneNumber: String? { contact?.cellphoneNumber ?? user?.cellphoneNumber }
    var isBlock: Bool { contact?.blocked == true || user?.blocked == true }
    var bio: String? { contact?.user?.chatProfileVO?.bio ?? user?.chatProfileVO?.bio }
    var showInfoGroupBox: Bool { bio != nil || cellPhoneNumber != nil || canBlock == true }
    var url: String? { thread?.computedImageURL ?? user?.image ?? contact?.image }
    @Published var isLoading: Bool = false
    @Published var participantViewModel: ParticipantsViewModel?
    @Published var mutualThreads: [Conversation] = []

    @Published var editTitle: String = ""
    @Published var searchText: String = ""
    @Published var image: UIImage?
    @Published var addToContactSheet: Bool = false
    @Published var threadDescription: String = ""
    @Published var isInEditMode = false
    @Published var showImagePicker: Bool = false
    @Published var assetResources: [PHAssetResource] = []

    init(thread: Conversation? = nil, contact: Contact? = nil, user: Participant? = nil) {
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

    func createThread() {
        if let contact = contact {
            let invitees = [Invitee(id: "\(contact.id ?? 0)", idType: .contactId)]
            AppState.shared.showThread(invitees: invitees)
        } else if let user = user {
            let invitees = [Invitee(id: "\(user.coreUserId ?? 0)", idType: .userId)]
            AppState.shared.showThread(invitees: invitees)
        }
    }

    func copyPhone() {
        guard let phone = cellPhoneNumber else { return }
        UIPasteboard.general.string = phone
    }

    func blockUnBlock() {
        ChatManager.activeInstance?.blockContact(.init(userId: contact?.userId ?? user?.coreUserId)) { response in
            if let contact = response.result {
                self.contact?.blocked = contact.blocked
                self.user?.blocked = contact.blocked
            }
        }
    }

    func updateThreadInfo() {
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

    func toggleMute() {
        guard let threadId = thread?.id else { return }
        if thread?.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    func mute(_ threadId: Int) {
        ChatManager.activeInstance?.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func unmute(_ threadId: Int) {
        ChatManager.activeInstance?.unmuteThread(.init(subjectId: threadId), completion: onUnMuteChanged)
    }

    func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = true
            objectWillChange.send()
        }
    }

    func onUnMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = false
            objectWillChange.send()
        }
    }

    func fetchMutualThreads() {
        guard let userId = (thread?.partner ?? contact?.userId ?? user?.id) else { return }
        let invitee = Invitee(id: "\(userId)", idType: .userId)
        ChatManager.activeInstance?.mutualGroups(.init(toBeUser: invitee)) { [weak self] response in
            if let threads = response.result {
                self?.mutualThreads = threads
            }
        }
    }
}
