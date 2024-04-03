//
//  AttachmentsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import TalkModels

public final class FilePickerViewModel: ObservableObject {
    @Published public var selectedFileUrls: [URL] = []

    func clear() {
        selectedFileUrls.removeAll()
    }
}

public final class AttachmentsViewModel: ObservableObject {
    public private(set)var attachments: [AttachmentFile] = []
    @Published public var isExpanded: Bool = false
    public var allImageItems: ContiguousArray<ImageItem> = []
    public var filePickerViewModel: FilePickerViewModel = .init()

    public init() {}

    public func addSelectedPhotos(imageItem: ImageItem) {
        attachments.removeAll(where: {$0.type != .gallery})
        allImageItems.append(imageItem)
        attachments.append(.init(id: imageItem.id, type: .gallery, request: imageItem))
        animateObjectWillChange()
    }

    public func addSelectedFile() {
        attachments.removeAll(where: {$0.type != .file})
        filePickerViewModel.selectedFileUrls.forEach { fileItem in
            attachments.append(.init(type: .file, request: fileItem))
        }
        animateObjectWillChange()
    }

    public func addFileURL(url: URL) {
        attachments.removeAll(where: {$0.type != .file})
        attachments.append(.init(type: .file, request: url))
        animateObjectWillChange()
    }

    public func clear() {
        allImageItems.removeAll()
        filePickerViewModel.clear()
        attachments.removeAll()
        animateObjectWillChange()
    }

    public func append(attachments: [AttachmentFile]) {
        self.attachments.removeAll(where: {$0.type != attachments.first?.type})
        self.attachments.append(contentsOf: attachments)
        animateObjectWillChange()
    }

    public func remove(_ attachment: AttachmentFile) {
        attachments.removeAll(where: {$0.id == attachment.id})
        allImageItems.removeAll(where: {$0.id == attachment.id})
        animateObjectWillChange()
    }
}
