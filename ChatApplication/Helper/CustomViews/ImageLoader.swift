//
//  ImageLoader.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import UIKit
class ImageLoader : ObservableObject{
    
    private (set) var didChange = PassthroughSubject<UIImage?,Never>()
    private var data:Data? = nil
    
    var image:UIImage?{
        guard let data = data else{return nil}
        return UIImage(data: data)
    }
    
    init(url:String?) {
        guard let stringUrl = url , let url = URL(string: stringUrl) else {
            data = nil
            return
        }
        let task = URLSession.shared.dataTask(with: url){[weak self] data,response ,error in
            if let data = data{
                DispatchQueue.main.async {
                    self?.data = data
                    self?.didChange.send(self?.image)
                }
            }
        }
        task.resume()
    }
}
