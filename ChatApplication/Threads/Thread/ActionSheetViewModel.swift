//
//  ActionSheetViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Photos
import UIKit

class ActionSheetViewModel : ObservableObject{

    @Published
    var allImageItems : [ImageItem] = []
    
    @Published
    var selectedImageItems : [ImageItem] = []
    
    @Published
    var selectedFileUrl : URL?{
        didSet{
            if selectedFileUrl != nil {
                sendSelectedFile()
            }
        }
    }
    
    var threadViewModel:ThreadViewModel
    
    init(threadViewModel:ThreadViewModel){
        self.threadViewModel = threadViewModel
    }
    
    func fecthAllPhotos(){
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                let allPhotosAsset = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                allPhotosAsset.enumerateObjects { object, index, stop in
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    options.deliveryMode = .fastFormat
                    let imageSize = CGSize(width: 96, height: 96)
                    PHImageManager.default().requestImage(for: object, targetSize: imageSize, contentMode: .aspectFit, options: options) { image, dict in
                        if let image = image{
                            self.allImageItems.append(.init(image: image, phAsset: object))
                        }
                    }
                }
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
    
    func toggleSelectedImage(_ item: ImageItem){
        if let index = selectedImageItems.firstIndex(where: {$0.phAsset === item.phAsset}){
            selectedImageItems.remove(at: index)
        }else{
            selectedImageItems.append(item)
        }
    }
    
    func sendSelectedPhotos(){
        selectedImageItems.forEach { item in
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            option.deliveryMode = .highQualityFormat
            option.resizeMode = .exact
            option.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(for: item.phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { uiImage, info in
                self.threadViewModel.sendPhotos(uiImage: uiImage, info: info, item: item)
            }
        }
    }
    
    func sendSelectedFile(){
        if let selectedFileUrl = selectedFileUrl {
            threadViewModel.sendFile(selectedFileUrl: selectedFileUrl)
        }
    }
    
    func clearSelectedPhotos(){
        selectedImageItems.removeAll()
    }
}

struct ImageItem : Hashable{
    var image:UIImage
    var phAsset:PHAsset
}
