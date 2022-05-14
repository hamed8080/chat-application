//
//  UrlEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/26/21.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

extension URL{
    
    var mimeType:String{
        let pathExtension = self.pathExtension
        if let mimetype = UTType(filenameExtension: pathExtension)?.preferredMIMEType{
            return mimetype as String
        }
        return "application/octet-stream"
    }

    var fileName:String{
        self.deletingPathExtension().lastPathComponent
    }

    var fileExtension:String{
        self.pathExtension.lowercased()
    }
}
