//
//  ImageLoader.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import UIKit
import FanapPodChatSDK

class ImageLoader : ObservableObject{
    
    private (set) var didChange = PassthroughSubject<UIImage?,Never>()
    private var data:Data? = nil
    
    var image:UIImage?{
        guard let data = data else{return nil}
        return UIImage(data: data)
    }
    
    init(url:String? , fileMetaData:String?, size:ImageSize? = nil,token:String? = nil) {
        
        if let fileMetaData = fileMetaData,
           let fileMetaDataModel = try? JSONDecoder().decode(FileMetaData.self, from: fileMetaData.data(using: .utf8) ?? Data()),
           let hashCode = fileMetaDataModel.fileHash{
            Chat.sharedInstance.getImage(req: .init(hashCode:hashCode, size: size ?? .SMALL)) { progress in
                
            } completion: { data, imageModel, error in
                self.data = data
                self.didChange.send(self.image)
            } cacheResponse: { data, imageModel, error in
                self.data = data
                self.didChange.send(self.image)
            }
        }else if let urlString = url, let url = URL(string:urlString) {
            let task = URLSession.shared.dataTask(with: URLRequest(url: url)){[weak self] data,response ,error in
                if let data = data{
                    DispatchQueue.main.async {
                        self?.data = data
                        self?.didChange.send(self?.image)
                        CacheFileManager.sharedInstance.saveImageProfile(url: url.absoluteString, data: data, group: AppGroup.group)
                    }
                }
            }
            task.resume()
        }
    }
}
