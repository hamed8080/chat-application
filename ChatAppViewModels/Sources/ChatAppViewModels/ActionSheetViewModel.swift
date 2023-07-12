//
//  ActionSheetViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Photos
import UIKit
import ChatAppModels
import SwiftUI

public final class ActionSheetViewModel: ObservableObject {
    public var threadViewModel: ThreadViewModel
    public var allImageItems: [ImageItem] = []
    public var selectedImageItems: [ImageItem] = []
    private let imageSize = CGSize(width: 128, height: 128)
    public let fetchCount = 50
    public var totalCount = 0
    public var offset = 0
    public var hasNext: Bool { totalCount > offset }
    private var isAuthorized: Bool = false
    @Published public var selectedFileUrls: [URL] = [] {
        didSet {
            if selectedFileUrls.count != 0 {
                sendSelectedFile()
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

    public init(threadViewModel: ThreadViewModel) {
        self.threadViewModel = threadViewModel
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
        await animateObjectWillChane()
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
        }
    }

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
            await animateObjectWillChane()
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
                await animateObjectWillChane()
            }
        }
    }

    @MainActor
    private func animateObjectWillChane() {
        withAnimation {
            objectWillChange.send()
        }
    }

    public func sendSelectedPhotos() {
        threadViewModel.sendPhotos(selectedImageItems)
        refresh()
    }

    public func sendSelectedFile() {
        threadViewModel.sendFiles(selectedFileUrls)
        refresh()
    }

    public func loadMore() {
        if !hasNext { return }
        Task.detached(priority: .userInitiated) {
            await self.loadImages()
        }
    }

    public func refresh() {
        selectedImageItems = []
        offset = 0
        totalCount = 0
        allImageItems = []
    }
}
