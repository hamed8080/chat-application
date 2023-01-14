//
//  Data+.swift
//  ChatApplication
//
//  Created by hamed on 12/31/22.
//

import Foundation
import ImageIO

extension Data {
    /// 50% faster than normal UIImage resizing.
    /// It only steram small amount of data to memory and it will result to smaller bytes feed to memory.
    /// This also leads to less dirty Pages in memory.
    func imageScale(width: Int) -> (image: CGImage, properties: [String: Any])? {
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, nil) else { return nil }
        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
        let opt: [NSString: Any] = [kCGImageSourceThumbnailMaxPixelSize: width, kCGImageSourceCreateThumbnailFromImageAlways: true]
        guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, opt as CFDictionary) else { return nil }
        return (scaledImage, properties as! [String: Any])
    }
}
