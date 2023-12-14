//
//  AttachmentsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import TalkModels

public enum AttachmentType {
    case gallery
    case file
    case drop
    case map
    case contact
}

public struct AttachmentFile: Identifiable {
    public let id: UUID
    public let type: AttachmentType

    public var url: URL?
    public var request: Any?

    public var icon: String? {
        if type == .map {
            return "map.fill"
        } else if type == .file {
            return (request as? URL)?.fileExtension.nonCircleIconWithFileExtension ?? "doc.fill"
        } else if type == .drop {
            return (request as? DropItem)?.ext?.nonCircleIconWithFileExtension ?? "doc.fill"
        } else if type == .contact {
            return "person.fill"
        } else {
            return nil
        }
    }

    public var title: String? {
        if type == .map {
            return (request as? LocationItem)?.description
        } else if type == .gallery {
            return (request as? ImageItem)?.fileName
        } else if type == .file {
            return (request as? URL)?.fileName
        } else if type == .drop {
            return (request as? DropItem)?.name
        } else if type == .contact {
            return "contact"
        } else {
            return nil
        }
    }

    public var subtitle: String? {
        if type == .map {
            return (request as? LocationItem)?.name
        } else if type == .gallery {
            return ((request as? ImageItem)?.data.count ?? 0)?.toSizeString(locale: Language.preferredLocale)
        } else if type == .file {
            let item = request as? URL
            var size = 0
            if let url = item, let data = try? Data(contentsOf: url) {
                size = data.count
            }
            return "\(size.toSizeString(locale: Language.preferredLocale) ?? "") - \((request as? URL)?.fileExtension.uppercased() ?? "")"
        } else if type == .drop {
            let item = request as? DropItem
            return "\((item?.data?.count ?? 0)?.toSizeString(locale: Language.preferredLocale) ?? "") - \(item?.ext?.uppercased() ?? "")"
        } else if type == .contact {
            return "contact"
        } else {
            return nil
        }
    }

    public init(id: UUID = UUID(), type: AttachmentType = .file, url: URL? = nil, request: Any? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.request = request
    }
}

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
