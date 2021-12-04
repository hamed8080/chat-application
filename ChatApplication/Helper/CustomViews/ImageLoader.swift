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
    
    init(url:String? , fileMetaData:String? = nil,token:String? = nil) {
        let fileMetaDataModel = try? JSONDecoder().decode(FileMetaData.self, from: fileMetaData?.data(using: .utf8) ?? Data())
        let smallImageFileUrl = getPodspaceSmallImage(fileHash: fileMetaDataModel?.fileHash)
        guard let stringUrl = url , let url = URL(string: smallImageFileUrl ?? stringUrl) else {
            data = nil
            return
        }
        if let cacheImageData = CacheFileManager.sharedInstance.getImageProfileCache(url: url.absoluteString, group: AppGroup.group){
            self.data = cacheImageData
            self.didChange.send(image)
        }
        var urlrequest = URLRequest(url: url)
        
        if let token = token {
            urlrequest.addValue(token, forHTTPHeaderField: "_token_")
            urlrequest.addValue("1", forHTTPHeaderField: "_token_issuer_")
        }
        let task = URLSession.shared.dataTask(with: urlrequest){[weak self] data,response ,error in
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
    
    func getPodspaceSmallImage(fileHash:String?)->String?{
        guard let fileHash = fileHash else {return nil}
        let smallImageFileUrl = "https://podspace.pod.ir/api/images/\(fileHash)?size=SMALL"
        return smallImageFileUrl
    }
}
