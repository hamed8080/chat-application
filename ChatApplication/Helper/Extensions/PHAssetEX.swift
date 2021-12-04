//
//  PHAssetEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/24/21.
//

import Foundation
import Photos

extension PHAsset {
    var originalFilename: String? {
        return  PHAssetResource.assetResources(for: self).first?.originalFilename
    }
}
