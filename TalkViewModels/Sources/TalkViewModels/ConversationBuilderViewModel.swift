//
//  ConversationBuilderViewModel.swift
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

public final class ConversationBuilderViewModel: ContactsViewModel {
    public var uploadProfileUniqueId: String?
    public var uploadProfileProgress: Int64?
    public var createdConversation: Conversation?
    @Published public var isUploading: Bool = false
    private var uploadedImageFileMetaData: FileMetaData?
    @Published public var isCreateLoading = false
    @Published public var createConversationType: ThreadTypes?
    @Published var imageUploadingFailed: Bool = false
    /// Check public thread name.
    @Published public var isPublic: Bool = false
    @Published public var isPublicNameAvailable: Bool = false
    @Published public var isCehckingName: Bool = false
    @Published public var conversationTitle: String = ""
    @Published public var threadDescription: String = ""
    public var assetResources: [PHAssetResource] = []
    public var image: UIImage?
    @Published public var showTitleError: Bool = false
    @Published public var show = false
    @Published public var dismiss = false

    public init() {
        super.init(isBuilder: true)
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

    public func show(type: ThreadTypes) {
        if contacts.isEmpty {
            getContacts()
        }
        show = true
        createConversationType = type
    }

    public func startUploadingImage() {
        isUploading = true
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            let imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                                  fileExtension: "png",
                                                  fileName: assetResources.first?.originalFilename ?? "",
                                                  isPublic: true,
                                                  mimeType: "image/png",
                                                  originalName: assetResources.first?.originalFilename ?? "",
                                                  hC: height,
                                                  wC: width
            )
            uploadProfileUniqueId = imageRequest.uniqueId
            ChatManager.activeInstance?.file.upload(imageRequest)
        }
    }

    public func cancelUploadImage() {
        guard let uploadProfileUniqueId = uploadProfileUniqueId else { return }
        resetImageUploading()
        animateObjectWillChange()
        ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadProfileUniqueId, action: .cancel)
    }

    public func createGroup() {
        if conversationTitle.count < 2 {
            showTitleError = true
            return
        }
        guard let type = createConversationType else { return }
        isCreateLoading = true
        let invitees = selectedContacts.map { Invitee(id: "\($0.id ?? 0)", idType: .contactId) }
        let req = CreateThreadRequest(description: threadDescription,
                                      image: uploadedImageFileMetaData?.file?.link,
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
            clear()
            if let conversation = response.result {
                if #available(iOS 17, *) {
                    AppState.shared.showThread(thread: conversation, created: true)
                } else {
                    /// It will prevent a bug on small deveice can not click on the back button after creation.
                    Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                        AppState.shared.showThread(thread: conversation, created: true)
                    }
                }
            }
        }
    }

    public override func clear() {
        super.clear()
        dimissAnResetDismiss()
        resetImageUploading()
        createdConversation = nil
        isCreateLoading = false
        createConversationType = nil
        /// Check public thread name.
        isPublic = false
        isPublicNameAvailable = false
        isCehckingName = false
        conversationTitle = ""
        threadDescription = ""
        showTitleError = false
    }

    public func resetImageUploading() {
        uploadedImageFileMetaData = nil
        uploadProfileUniqueId = nil
        uploadProfileProgress = nil
        image = nil
        isUploading = false
        imageUploadingFailed = false
        assetResources = []
    }

    func dimissAnResetDismiss() {
        dismiss = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.dismiss = false
        }
    }

    private func onUploadCompleted(_ uniqueId: String, _ fileMetaData: FileMetaData?, _ data: Data?, _ error: Error?) {
        /// We have to check the unique id due to if the user update the image in EditConversation the updaload lead to set uploadedImageFileMetaData.
        if data != nil, error == nil, uniqueId == uploadProfileUniqueId {
            isUploading = false
            uploadProfileProgress = nil
            self.uploadedImageFileMetaData = fileMetaData
        } else if error != nil {
            imageUploadingFailed = true
        }
    }

    private func onUploadConversationProfile(_ uniqueId: String, _ progress: UploadFileProgress?) {
        if uniqueId == uploadProfileUniqueId {
            uploadProfileProgress = progress?.percent ?? 0
            animateObjectWillChange()
        }
    }

    private func onConversationEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .created(let response):
            onCreateGroup(response)
        case .isNameAvailable(let response):
            onIsNameAvailable(response)
        default:
            break
        }
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .progress(let uniqueId, let progress):
            onUploadConversationProfile(uniqueId, progress)
        case .completed(let uniqueId, let fileMetaData, let data, let error):
            onUploadCompleted(uniqueId, fileMetaData, data, error)
        default:
            break
        }
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

    deinit {
        print("deinit ConversationBuilderViewModel")
    }
}
