//
//  UIEdgeInsets+.swift
//
//
//  Created by hamed on 1/2/24.
//

import UIKit

public extension UIEdgeInsets {
    init(all value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }

    init(hosrizontal value: CGFloat) {
        self.init(top: 0, left: value, bottom: 0, right: value)
    }

    init(vertical value: CGFloat) {
        self.init(top: value, left: 0, bottom: value, right: 0)
    }
}
