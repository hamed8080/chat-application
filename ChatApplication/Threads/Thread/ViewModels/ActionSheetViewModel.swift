//
//  ActionSheetViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Photos
import UIKit

final class ActionSheetViewModel: ObservableObject {
    var threadViewModel: ThreadViewModel
    @Published var allImageItems: [ImageItem] = []
    @Published var selectedImageItems: [ImageItem] = []
    private let imageSize = CGSize(width: 72, height: 72)
    let fetchCount = 10
    var totalCount = 0
    var offset = 0
    var hasNext: Bool { totalCount > offset }
    private var isAuthorized: Bool = false
    @Published var isLoading = false
    @Published var selectedFileUrls: [URL] = [] {
        didSet {
            if selectedFileUrls.count != 0 {
                sendSelectedFile()
            }
        }
    }

    lazy var option: PHImageRequestOptions = {
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        option.deliveryMode = .highQualityFormat
        option.resizeMode = .exact
        option.isNetworkAccessAllowed = true
        return option
    }()

    private lazy var opt: PHFetchOptions = {
        let opt = PHFetchOptions()
        opt.includeHiddenAssets = true
        return opt
    }()

    var indexSet: IndexSet {
        let lastIndex = min(offset + fetchCount, totalCount - 1)
        if lastIndex == -1 {
            return IndexSet() // if the user install app for first time and not accepted the permission to aceess photo gallery it cause crash cause index is equal -1
        }
        if offset + 1 >= lastIndex {
            return IndexSet()
        }
        return IndexSet(offset + 1 ... lastIndex)
    }

    init(threadViewModel: ThreadViewModel) {
        self.threadViewModel = threadViewModel
        setTotalImageCount()
        checkAuthorization()
    }

    func setTotalImageCount() {
        let allImages = PHAsset.fetchAssets(with: .image, options: opt)
        totalCount = allImages.count
    }

    private func fetchImages() {
        let fetchResults = PHAsset.fetchAssets(with: .image, options: opt)
        fetchResults.enumerateObjects(at: indexSet, options: .concurrent) { [weak self] object, _, _ in
            self?.requestImage(object)
            self?.hideLoading()
        }
    }

    private func requestImage(_ object: PHAsset) {
        PHImageManager.default().requestImage(for: object, targetSize: imageSize, contentMode: .aspectFit, options: option) { [weak self] image, info in
            self?.appendImage(image, object, info)
        }
    }

    private func appendImage(_ image: UIImage?, _ object: PHAsset, _ info: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            if let image {
                self.allImageItems.append(.init(image: image, phAsset: object, info: info))
            }
        }
    }

    func loadImages() {
        isLoading = true
        if isAuthorized {
            DispatchQueue.global(qos: .background).async {
                self.fetchImages()
                self.offset += self.fetchCount
            }
        }
    }

    func hideLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

    func checkAuthorization() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .authorized:
                self.isAuthorized = true
            case .denied, .restricted:
                print("Not allowed")
            case .notDetermined:
                print("Not determined yet")
            case .limited:
                print("Not determined yet")
            @unknown default:
                print("Not determined yet")
            }
        }
    }

    func toggleSelectedImage(_ item: ImageItem) {
        if let index = selectedImageItems.firstIndex(where: { $0.phAsset === item.phAsset }) {
            selectedImageItems.remove(at: index)
        } else {
            selectedImageItems.append(item)
        }
    }

    func sendSelectedPhotos() {
        threadViewModel.sendPhotos(selectedImageItems)
        refresh()
    }

    func sendSelectedFile() {
        threadViewModel.sendFiles(selectedFileUrls)
        refresh()
    }

    func loadMore() {
        if !hasNext { return }
        loadImages()
    }

    func refresh() {
        selectedImageItems = []
        offset = 0
        totalCount = 0
        allImageItems = []
        isLoading = false
    }
}

struct ImageItem: Hashable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    let id = UUID().uuidString
    var image: UIImage
    var phAsset: PHAsset
    var info: [AnyHashable: Any]?
    var fileName: String? { phAsset.originalFilename }
}
