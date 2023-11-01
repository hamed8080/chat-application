//
//  AttachmentsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Photos
import UIKit
import TalkModels
import SwiftUI
import TalkExtensions
import Additive

public enum AttachmentType {
    case gallery
    case file
    case drop
    case map
    case contact
    case voice
}

public struct AttachmentFile: Identifiable {
    public var id: UUID = UUID()
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
        } else if type == .voice {
            return "waveform"
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
        } else if type == .voice {
            return "recording"
        } else {
            return nil
        }
    }

    public var subtitle: String? {
        if type == .map {
            return (request as? LocationItem)?.name
        } else if type == .gallery {
            return ((request as? ImageItem)?.imageData.count ?? 0)?.toSizeString
        } else if type == .file {
            let item = request as? URL
            var size = 0
            if let url = item, let data = try? Data(contentsOf: url) {
                size = data.count
            }
            return "\(size.toSizeString ?? "") - \((request as? URL)?.fileExtension.uppercased() ?? "")"
        } else if type == .drop {
            let item = request as? DropItem
            return "\((item?.data?.count ?? 0)?.toSizeString ?? "") - \(item?.ext?.uppercased() ?? "")"
        } else if type == .contact {
            return "contact"
        } else if type == .voice {
            return "recording"
        } else {
            return nil
        }
    }

    public init(type: AttachmentType = .file, url: URL? = nil, request: Any? = nil) {
        self.type = type
        self.url = url
        self.request = request
    }
}

public final class AttachmentsViewModel: ObservableObject {
    public private(set)var attachments: [AttachmentFile] = []
    public weak var threadViewModel: ThreadViewModel?
    public var allImageItems: [ImageItem] = []
    public var selectedImageItems: [ImageItem] = []
    private let imageSize = CGSize(width: 128, height: 128)
    public let fetchCount = 50
    public var totalCount = 0
    public var offset = 0
    public var hasNext: Bool { totalCount > offset }
    private var isAuthorized: Bool = false
    private var isSetupBefore: Bool = false
    @Published public var isExpanded: Bool = false
    @Published public var selectedFileUrls: [URL] = [] {
        didSet {
            if selectedFileUrls.count != 0 {
                addSelectedFile()
            }
        }
    }

    public lazy var option: PHImageRequestOptions = {
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        option.deliveryMode = .opportunistic
        option.resizeMode = .exact
        option.isNetworkAccessAllowed = true
        return option
    }()

    private lazy var opt: PHFetchOptions = {
        let opt = PHFetchOptions()
        opt.includeHiddenAssets = true
        return opt
    }()

    public var indexSet: IndexSet {
        let lastIndex = min(offset + fetchCount, totalCount - 1)
        if lastIndex == -1 {
            return IndexSet() // if the user install app for first time and not accepted the permission to aceess photo gallery it cause crash cause index is equal -1
        }
        if offset + 1 >= lastIndex {
            return IndexSet()
        }
        return IndexSet(offset + 1 ... lastIndex)
    }

    public init() {}

    public func oneTimeSetup() {
        if isSetupBefore { return }
        isSetupBefore = true
        setTotalImageCount()
        let state = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if state != .authorized {
            _ = Task {
                if await checkAuthorization() == .authorized {
                    self.isAuthorized = true
                    setTotalImageCount()
                    await self.loadImages()
                }
            }
        } else {
            isAuthorized = true
        }
    }

    public func setTotalImageCount() {
        let allImages = PHAsset.fetchAssets(with: .image, options: opt)
        totalCount = allImages.count
    }

    private func fetchImages() async {
        let fetchResults = PHAsset.fetchAssets(with: .image, options: opt)
        let phAssets = fetchResults.objects(at: indexSet)
        for asset in phAssets {
            let tuple = await self.requestImage(asset)
            self.appendImage(tuple.0, tuple.1, tuple.2)
        }
        animateObjectWillChange()
    }

    private func requestImage(_ object: PHAsset) async -> (UIImage?, PHAsset, [AnyHashable: Any]?) {
        typealias FetchContinuation = CheckedContinuation<(UIImage?, PHAsset, [AnyHashable: Any]?), Never>
        return await withCheckedContinuation { (continuation: FetchContinuation )  in
            PHImageManager.default().requestImage(for: object, targetSize: imageSize, contentMode: .default, options: option) { image, info in
                continuation.resume(returning: (image, object, info))
            }
        }
    }

    private func appendImage(_ image: UIImage?, _ object: PHAsset, _ info: [AnyHashable: Any]?) {
        if let image {
            let filename = PHAssetResource.assetResources(for: object).first?.originalFilename ?? "unknown"
            self.allImageItems.append(.init(imageData: image.pngData() ?? Data(),
                                            width: object.pixelWidth,
                                            height: object.pixelHeight,
                                            phAsset: object,
                                            info: info,
                                            originalFilename: filename))
        }
    }

    public func loadImages() async {
        if isAuthorized {
            await fetchImages()
            offset += fetchCount
        } else {
            await checkAuthorization()
        }
    }

    @discardableResult
    public func checkAuthorization() async -> PHAuthorizationStatus {
        typealias AthurizationResponse = CheckedContinuation<PHAuthorizationStatus, Never>
        return await withCheckedContinuation { (continuation: AthurizationResponse) in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    public func requestImageDataAndOrientation(phAsset: PHAsset, options: PHImageRequestOptions) async -> Data? {
        typealias ImageDataResponse = CheckedContinuation<Data?, Never>
        return await withCheckedContinuation { (continuation: ImageDataResponse) in
            PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: options) { data, uti, _, _ in
                continuation.resume(returning: data)
            }
        }
    }

    public func toggleSelectedImage(_ item: ImageItem) async {
        if let index = selectedImageItems.firstIndex(where: { $0.phAsset === item.phAsset }) {
            selectedImageItems.remove(at: index)
            animateObjectWillChange()
        } else {
            if let phAsset = item.phAsset as? PHAsset {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                let data = await self.requestImageDataAndOrientation(phAsset: phAsset, options: options)
                let item = ImageItem(imageData: data ?? Data(),
                                     width: phAsset.pixelWidth,
                                     height: phAsset.pixelHeight,
                                     phAsset: phAsset,
                                     originalFilename: item.fileName)
                self.selectedImageItems.append(item)
                animateObjectWillChange()
            }
        }
    }

    public func addSelectedPhotos() {
        attachments.removeAll(where: {$0.type != .gallery})
        selectedImageItems.forEach { imageItem in
            attachments.append(.init(type: .gallery, request: imageItem))
        }
        animateObjectWillChange()
        threadViewModel?.sheetType = nil
        threadViewModel?.animateObjectWillChange()
        refresh()
    }

    public func addSelectedFile() {
        attachments.removeAll(where: {$0.type != .file})
        selectedFileUrls.forEach { fileItem in
            attachments.append(.init(type: .file, request: fileItem))
        }
        animateObjectWillChange()
        refresh()
    }

    public func loadMore() {
        if !hasNext { return }
        Task.detached(priority: .userInitiated) {
            await self.loadImages()
        }
    }

    public func refresh() {
        selectedFileUrls = []
        selectedImageItems = []
        offset = 0
        allImageItems = []
    }

    public func clear() {
        refresh()
        attachments.removeAll()
    }

    public func append(attachments: [AttachmentFile]) {
        self.attachments.removeAll(where: {$0.type != attachments.first?.type})
        self.attachments.append(contentsOf: attachments)
        animateObjectWillChange()
    }

    public func remove(_ attachment: AttachmentFile) {
        attachments.removeAll(where: {$0.id == attachment.id})
        animateObjectWillChange()
    }
}
