//
//  UrlEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/26/21.
//

import Foundation
import MobileCoreServices

extension URL{
    
    var mimeType:String{
        let pathExtension = self.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
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
