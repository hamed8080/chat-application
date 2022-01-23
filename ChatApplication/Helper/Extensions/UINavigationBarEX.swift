//
//  UINavigationBarEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/19/21.
//

import UIKit
extension UINavigationBar {
    static func changeAppearance(clear: Bool) {
        let appearance = UINavigationBarAppearance()
        
        if clear {
            appearance.configureWithTransparentBackground()
        } else {
            appearance.configureWithDefaultBackground()
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
