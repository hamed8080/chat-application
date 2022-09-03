//
//  ActionSheetViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Photos
import UIKit
import FanapPodChatSDK

class ActionSheetViewModel : ObservableObject{

    @Published
    var allImageItems : [ImageItem] = []
    
    @Published
    var selectedImageItems : [ImageItem] = []
    let fetchCount = 10
    var totalCount = 0
    var offset     = 0
    
    var hasNext:Bool{
        return offset < totalCount
    }
    
    var indexSet:IndexSet{
        let lastIndex = min(offset + fetchCount, totalCount - 1)
        if lastIndex == -1 {
            return IndexSet()//if the user install app for first time and not accepted the permission to aceess photo gallery it cause crash cause index is equal -1
        }
        if offset + 1 >= lastIndex{
            return IndexSet()
        }
        return IndexSet(self.offset + 1...lastIndex)
    }
    
    @Published
    var isLoading = false
    
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
        setTotalImageCount()
    }
    
    func setTotalImageCount(){
        let options = PHFetchOptions()
        options.includeHiddenAssets = true
        let allImages = PHAsset.fetchAssets(with: .image, options: options)
        totalCount = allImages.count
    }
    
    func loadImages(){
  
        isLoading = true
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                if self.totalCount == 0{
                    self.setTotalImageCount()
                }
                let fetchResults = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                DispatchQueue.global(qos: .background).async {
                    fetchResults.enumerateObjects(at: self.indexSet, options: .concurrent) { object, index, stop in
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        options.deliveryMode = .fastFormat
                        let imageSize = CGSize(width: 96, height: 96)
                        PHImageManager.default().requestImage(for: object, targetSize: imageSize, contentMode: .aspectFit, options: options) { image, dict in
                            if let image = image{
                                DispatchQueue.main.async {
                                    self.allImageItems.append(.init(image: image, phAsset: object))
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    self.offset = self.offset + self.fetchCount
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
    
    func loadMore(){
        if !hasNext{return}
        loadImages()
    }

    func sendLocation(_ coordinate: CLLocationCoordinate2D){
        if let threadId = threadViewModel.model.thread?.id, let userGroupHash = threadViewModel.model.thread?.userGroupHash {
            let center = Cordinate(lat: coordinate.latitude, lng: coordinate.longitude)
            Chat.sharedInstance.sendLocationMessage(.init(mapCenter: center, threadId: threadId, userGroupHash: userGroupHash))
            Chat.sharedInstance.sendTextMessage(.init(threadId: threadId, textMessage: "", messageType: .LOCATION))
        }
    }
}

struct ImageItem : Hashable{
    var image:UIImage
    var phAsset:PHAsset
}
