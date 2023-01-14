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

class DetailViewModel: ObservableObject {
    @Published var imageLoader: ImageLoader?
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

    init(thread: Conversation? = nil, contact: Contact? = nil, user: Participant? = nil) {
        self.user = user
        self.thread = thread
        self.contact = contact
        let url = thread?.computedImageURL ?? user?.image ?? contact?.image
        imageLoader = ImageLoader(url: url ?? "", userName: title, size: .SMALL)
        imageLoader?.fetch()
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
        ChatManager.activeInstance.blockContact(.init(userId: contact?.userId ?? user?.coreUserId)) { response in
            if let contact = response.result {
                self.contact?.blocked = contact.blocked
                self.user?.blocked = contact.blocked
            }
        }
    }

    func updateThreadInfo(_ title: String, _ description: String, image: UIImage?, assetResources: [PHAssetResource]?) {
        guard let threadId = thread?.id else { return }
        var imageRequest: UploadImageRequest?
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                              hC: height,
                                              wC: width,
                                              fileExtension: "png",
                                              fileName: assetResources?.first?.originalFilename,
                                              mimeType: "image/png",
                                              originalName: assetResources?.first?.originalFilename,
                                              userGroupHash: thread?.userGroupHash,
                                              isPublic: true)
        }

        let req = UpdateThreadInfoRequest(description: description, threadId: threadId, threadImage: imageRequest, title: title)
        ChatManager.activeInstance.updateThreadInfo(req) { _ in } uploadProgress: { _, _ in } completion: { _ in }
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
        ChatManager.activeInstance.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func unmute(_ threadId: Int) {
        ChatManager.activeInstance.unmuteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute?.toggle()
            objectWillChange.send()
        }
    }
}
