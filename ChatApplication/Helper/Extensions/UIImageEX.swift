//
//  UIImageEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/30/21.
//

import Foundation
import UIKit
extension UIImage{
    
    static var appIcon:UIImage? {
        guard let infoPlist = Bundle.main.infoDictionary else { return nil }
        guard let bundleIcons = infoPlist["CFBundleIcons"] as? NSDictionary else { return nil }
        guard let bundlePrimaryIcon = bundleIcons["CFBundlePrimaryIcon"] as? NSDictionary else { return nil }
        guard let bundleIconFiles = bundlePrimaryIcon["CFBundleIconFiles"] as? NSArray else { return nil }
        guard let appIcon = bundleIconFiles.lastObject as? String else { return nil }
        return UIImage(named: appIcon)
    }
}
