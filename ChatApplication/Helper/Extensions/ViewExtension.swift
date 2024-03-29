//
//  ViewExtension.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/28/21.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var canImportWebRTC: Bool {
        var canImoprt = false
        #if canImport(WebRTC)
            canImoprt = true
        #endif
        return canImoprt
    }
}
