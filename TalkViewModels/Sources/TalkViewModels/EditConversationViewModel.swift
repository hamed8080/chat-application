//
//  EditConversationViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import UIKit
import ChatModels
import ChatCore
import Combine
import Photos
import ChatTransceiver
import TalkModels
import ChatDTO
import Chat

public final class EditConversationViewModel: ObservableObject, Hashable {
    public static func == (lhs: EditConversationViewModel, rhs: EditConversationViewModel) -> Bool {
        lhs.thread.id == rhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread.id)
    }

    public weak var threadVM: ThreadViewModel?
    private(set) var cancelable: Set<AnyCancellable> = []
    public var uploadProfileUniqueId: String?
    public var uploadProfileProgress: Int64?
    public var image: UIImage?
    public var assetResources: [PHAssetResource] = []
    @Published public var isLoading = false
    @Published public var isPublic = false
    @Published public var editTitle: String = ""
    @Published public var threadDescription: String = ""
    public var dismiss: Bool = false
    public var thread: Conversation { threadVM?.thread ?? .init() }

    public init(threadVM: ThreadViewModel?) {
        self.threadVM = threadVM
        editTitle = thread.title ?? ""
        threadDescription = thread.description ?? ""
        isPublic = thread.type?.isPrivate == false
        registerObservers()
    }

    private func registerObservers() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
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

    /// If the image information '' is nil we have to send a name for our file unless we will end up with an error from podspace,
    /// so we have to fill it with UUID().uuidString.
    public func submitEditGroup() {
        isLoading = true
        guard let threadId = thread.id else { return }
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
                                              userGroupHash: thread.userGroupHash,
                                              hC: height,
                                              wC: width
            )
            uploadProfileUniqueId = imageRequest?.uniqueId
        }
        if thread.type?.isPrivate == false, isPublic == false {
            switchToPrivateType()
        } else if thread.type?.isPrivate == true, isPublic == true {
            switchPublicType()
        }
        let req = UpdateThreadInfoRequest(description: threadDescription, threadId: threadId, threadImage: imageRequest, title: editTitle)
        RequestsManager.shared.append(prepend: "EditGroup", value: req, autoCancel: false)
        ChatManager.activeInstance?.conversation.updateInfo(req)
    }

    public func onEditGroup(_ response: ChatResponse<Conversation>) {
        if response.contains(prepend: "EditGroup") {
            image = nil
            isLoading = false
            uploadProfileUniqueId = nil
            uploadProfileProgress = nil
            dismiss = true
            threadVM?.animateObjectWillChange()
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .updatedInfo(let response):
            onEditGroup(response)
        case .changedType(let chatResponse):
            onChangeThreadType(chatResponse)
        default:
            break
        }
    }

    public func switchToPrivateType() {
        AppState.shared.objectsContainer.threadsVM.makeThreadPrivate(thread)
    }

    public func switchPublicType() {
        AppState.shared.objectsContainer.threadsVM.makeThreadPublic(thread)
    }

    public func toggleThreadVisibility() {
        guard let threadId = thread.id, let type = thread.type else { return }
        let typeValue: ThreadTypes = type.isPrivate == true ? type.publicType : type.privateType
        let req = ChangeThreadTypeRequest(threadId: threadId, type: typeValue)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.changeType(req)
    }

    private func onChangeThreadType(_ response: ChatResponse<Conversation>) {
        self.thread.type = response.result?.type
        isPublic = thread.type?.isPrivate == false
        if let req = response.pop(prepend: "CHANGE-TO-PUBLIC") as? ChangeThreadTypeRequest {
            thread.uniqueName = req.uniqueName
        }
        animateObjectWillChange()
    }

    deinit{
        print("deinit EditConversationViewModel")
    }
}
