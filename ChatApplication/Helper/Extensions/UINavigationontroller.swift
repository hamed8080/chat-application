//
//  UINavigationontroller.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/26/21.
//

import UIKit

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
