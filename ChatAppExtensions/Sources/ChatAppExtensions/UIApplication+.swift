//
//  UIApplication+.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//

import Foundation
import SwiftUI
import UIKit

public enum WindowMode {
    case iPhone
    case ipadFullScreen
    case ipadSlideOver
    case ipadOneThirdSplitView
    case ipadHalfSplitView
    case ipadTwoThirdSplitView
    case unknown
}

public extension UIApplication {
    func windowMode() -> WindowMode {
        let screenRect = UIScreen.main.bounds
        let activeWindowScene = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).first as? UIWindowScene
        let appRect = activeWindowScene?.windows.first?.bounds ?? .zero

        let isInHalfThreshold = isInThereshold(a: appRect.width, b: abs(screenRect.width - (screenRect.width / 2)))
        let isInOneThirdThreshold = isInThereshold(a: appRect.width, b: abs(screenRect.width - (screenRect.width / (8/10))))
        let isInTwoThirdThreshold = isInThereshold(a: appRect.width, b: abs(screenRect.width - (screenRect.width * (3/10))))
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            return .iPhone
        } else if (screenRect == appRect) {
            return .ipadFullScreen
        } else if (appRect.size.height < screenRect.size.height) {
            return .ipadSlideOver
        } else if isInHalfThreshold {
            return .ipadHalfSplitView
        } else if isInTwoThirdThreshold {
            return .ipadTwoThirdSplitView
        } else if isInOneThirdThreshold {
            return .ipadOneThirdSplitView
        } else {
            return .unknown
        }
    }

    private func isInThereshold(a: CGFloat, b: CGFloat) -> Bool {
        let threshold = 0.1 // 10% threshold
        if abs(a - b) / ((a + b) / 2) < threshold {
            return true
        } else {
            return false
        }
    }
}
