//
//  ImagePickerViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import TalkModels
import Photos

public final class ImagePickerViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    public var allImageItems: ContiguousArray<ImageItem> = []
    public var selectedImageItems: ContiguousArray<ImageItem> { allImageItems.filter({$0.isSelected}) }
    private let imageSize = CGSize(width: 128, height: 128)
    private let fetchCount = 50
    private var totalCount = 0
    private var offset = 0
    private var hasNext: Bool { totalCount > offset }
    private var isAuthorized: Bool = false
    private var isSetupBefore: Bool = false
    private var fetchResult: PHFetchResult<PHAsset>? = nil
    public override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    public typealias PHManagerResultType = (data: Data?, uti: String?, orientationProperty: CGImagePropertyOrientation?, info: [AnyHashable : Any]?)
    private typealias AthurizationResponse = CheckedContinuation<PHAuthorizationStatus, Never>
    private typealias FetchContinuation = CheckedContinuation<PHManagerResultType, Never>
    public var state: PHAuthorizationStatus = .notDetermined

    public lazy var option: PHImageRequestOptions = {
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        option.deliveryMode = .opportunistic
        option.resizeMode = .fast
        option.isNetworkAccessAllowed = false
        return option
    }()

    private lazy var opt: PHFetchOptions = {
        let opt = PHFetchOptions()
        opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opt.includeHiddenAssets = true
        return opt
    }()

    public var indexSet: IndexSet {
        return IndexSet(offset ..< min(offset + fetchCount, totalCount))
    }

    public func oneTimeSetup() {
        if isSetupBefore { return }
        isSetupBefore = true
        setTotalImageCount()
        state = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if state != .authorized {
            _ = Task { [weak self] in
                await self?.checkAceessAgain()
            }
        } else {
            isAuthorized = true
        }
    }

    private func checkAceessAgain() async {
        let state = await checkAuthorization()
        /// We should check if it is limited to not update the state
        if self.state != .limited {
            self.state = state
        }
        if state == .authorized {
            self.isAuthorized = true
            setTotalImageCount()
            self.loadImages()
        }
        if state != .authorized {
            animateObjectWillChange()
        }
    }

    public func setTotalImageCount() {
        let allImages = PHAsset.fetchAssets(with: .image, options: opt)
        totalCount = allImages.count
    }

    private func fetchImages() {
        Task {
            fetchResult = PHAsset.fetchAssets(with: .image, options: opt)
            let phAssets = fetchResult?.objects(at: indexSet) ?? []
            for asset in phAssets {
                let result = await self.requestThumbnailImage(asset)
                await MainActor.run {
                    self.appendImage(result, asset)
                }
            }
            await MainActor.run {
                offset = min(offset + fetchCount, totalCount)
                animateObjectWillChange()
            }
        }
    }

    private func requestThumbnailImage(_ object: PHAsset) async -> PHManagerResultType {
        return await requestImageDataAndOrientation(phAsset: object, options: option)
    }

    private func appendImage(_ result: PHManagerResultType, _ asset: PHAsset) {
        let resource = PHAssetResource.assetResources(for: asset).first
        let filename = resource?.originalFilename ?? "unknown"
        let isIniCloud = (result.info?[PHImageResultIsInCloudKey] as? NSNumber)?.boolValue ?? false
        if let data = result.data, !isIniCloud {
            if let item = self.allImageItems.first(where: { $0.id == asset.localIdentifier}) {
                item.imageData = data
                item.info = result.info
                item.animateObjectWillChange()
            } else {
                self.allImageItems.append(.init(id: asset.localIdentifier,
                                                imageData: data,
                                                width: asset.pixelWidth,
                                                height: asset.pixelHeight,
                                                phAsset: asset,
                                                isIniCloud: false,
                                                info: result.info,
                                                originalFilename: filename))
            }
        } else {
            PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: .default, options: option) { image, info in
                if let data = image?.pngData() {
                    if let item = self.allImageItems.first(where: { $0.id == asset.localIdentifier}) {
                        item.imageData = data
                        item.info = result.info
                        item.animateObjectWillChange()
                    } else {
                        self.allImageItems.append(.init(id: asset.localIdentifier,
                                                        imageData: data,
                                                        width: asset.pixelWidth,
                                                        height: asset.pixelHeight,
                                                        phAsset: asset,
                                                        isIniCloud: true,
                                                        info: result.info,
                                                        originalFilename: filename))
                    }
                }
            }
        }
    }

    public func loadImages() {
        if isAuthorized {
            fetchImages()
        } else {
            Task {
                await checkAuthorization()
            }
        }
    }

    @discardableResult
    public func checkAuthorization() async -> PHAuthorizationStatus {
        return await withCheckedContinuation { (continuation: AthurizationResponse) in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }


    public func requestImageDataAndOrientation(phAsset: PHAsset, options: PHImageRequestOptions) async -> PHManagerResultType {
        return await withCheckedContinuation { (continuation: FetchContinuation) in
            PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: options) { data, uti, orientationProperty, info in
                continuation.resume(returning: (data, uti, orientationProperty, info))
            }
        }
    }

    public func loadMore() {
        if !hasNext { return }
        self.loadImages()
    }

    public func clear() {
        clearSelected()
        offset = 0
        allImageItems = []
    }

    public func clearSelected() {
        selectedImageItems.forEach { item in
            item.isSelected = false
        }
    }

    public func toggleSelectedImage(_ item: ImageItem) async {
        if item.isSelected {
            item.isSelected = false
            item.animateObjectWillChange()
        } else {
            if let phAsset = item.phAsset as? PHAsset {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                let result = await self.requestImageDataAndOrientation(phAsset: phAsset, options: options)
                item.imageData = result.data ?? Data()
                item.isSelected = true
                item.animateObjectWillChange()
                animateObjectWillChange()
            }
        }
    }

    public func downloadFromiCloud(_ item: ImageItem) {
        guard let phAsset = item.phAsset as? PHAsset else { return }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.progressHandler = { (downloadingProgress, error, stop, info) in
            if let error {
                print("downloadin icould photo failed: \(error)")
            } else {
                Task {
                    await item.setDownloadProgress(downloadingProgress)
                    if downloadingProgress == 1.0 {
                        try? await Task.sleep(for: .seconds(0.1))
                        guard let newAsset = PHAsset.fetchAssets(withLocalIdentifiers: [phAsset.localIdentifier], options: self.opt).firstObject else { return }
                        let result = await self.requestThumbnailImage(newAsset)
                        item.imageData = result.data ?? Data()
                        item.info = result.info
                        item.phAsset = newAsset
                        item.isIniCloud = false
                        item.animateObjectWillChange()
                    }
                }
            }
        }
        Task {
            let _ = await self.requestImageDataAndOrientation(phAsset: phAsset, options: options)
        }
    }

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let _fetchResult = self.fetchResult, let _ = changeInstance.changeDetails(for: _fetchResult) {
            DispatchQueue.main.async {
                self.setTotalImageCount()
                self.offset = 0
                self.fetchImages()
            }
        }
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}
