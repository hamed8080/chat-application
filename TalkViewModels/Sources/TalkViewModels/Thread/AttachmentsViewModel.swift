//
//  AttachmentsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Chat
import UniformTypeIdentifiers
import UIKit
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
    private weak var viewModel: ThreadViewModel?

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

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

    public func onDocumentPicker(_ urls: [URL]) {
        viewModel?.attachmentsViewModel.filePickerViewModel.selectedFileUrls = urls
        viewModel?.attachmentsViewModel.addSelectedFile()
        viewModel?.sheetType = nil
        viewModel?.animateObjectWillChange()
        Task { [weak self] in
            await self?.viewModel?.scrollVM.scrollToEmptySpace()
        }
    }

    public func onPickerResult(_ itemProviders: [NSItemProvider]) {
        processItemProviders(itemProviders)
        Task { [weak self] in
            await self?.viewModel?.scrollVM.scrollToEmptySpace()
        }
    }

    private func processItemProviders(_ itemProviders: [NSItemProvider]) {
        itemProviders.forEach { provider in
            let name = provider.suggestedName ?? "unknown"
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                _ = provider.loadDataRepresentation(for: .movie) { data, error in
                    if let data = data {
                        Task { [weak self] in
                            await self?.processVideo(data: data, name: name)
                        }
                    }
                }
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadObject(ofClass: UIImage.self) { item, error in
                    if let image = item as? UIImage {
                        Task { [weak self] in
                            await self?.processImage(image: image, name: name)
                        }
                    }
                }
            }
        }
    }

    private func processImage(image: UIImage, name: String) async {
        let data = await lessThanTwoMegabyteImage(image: image, quality: 100) ?? .init()
        let image = UIImage(data: data) ?? .init()
        let item = ImageItem(data: data,
                             width: Int(image.size.width),
                             height: Int(image.size.height),
                             originalFilename: name)
        await MainActor.run {
            viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            viewModel?.animateObjectWillChange() /// Send button to appear
        }
    }

    private func processVideo(data: Data, name: String) async {
        let item = ImageItem(isVideo: true,
                             data: data,
                             width: 0,
                             height: 0,
                             originalFilename: name)
        await MainActor.run {
            viewModel?.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            viewModel?.animateObjectWillChange() /// Send button to appear
        }
    }

    private func lessThanTwoMegabyteImage(image: UIImage, quality: CGFloat) async -> Data? {
        let data = autoreleasepool { image.jpegData(compressionQuality: quality / 100.0) }
        // It means the compression won't work anymore than this.
        if quality == 1 {
            return data
        }
        if let data = data, data.count > 2_000_000 {
            return await lessThanTwoMegabyteImage(image: image, quality: max(1, quality - 40.0))
        }
        return data
    }
}
