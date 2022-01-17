//
//  DeepButtonStyle.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI
struct DeepButtonStyle:ButtonStyle{
    
    var shadow:CGFloat = 6
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .shadow(radius: configuration.isPressed ? 0 : shadow)
            .scaleEffect(x: configuration.isPressed ? 0.98 : 1, y: configuration.isPressed ? 0.98 : 1)
            .customAnimation(.easeInOut)
    }
}
