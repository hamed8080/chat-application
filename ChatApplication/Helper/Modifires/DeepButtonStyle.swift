//
//  DeepButtonStyle.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI
struct DeepButtonStyle:ButtonStyle{

    var frame:CGSize = .init(width: CGFloat.infinity, height: CGFloat.infinity)
    var backgroundColor:Color = .primary
    var shadow:CGFloat = 6
    var cornerRadius:CGFloat = 0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: frame.width, height: frame.height)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: configuration.isPressed ? 0 : shadow)
            .scaleEffect(x: configuration.isPressed ? 0.98 : 1, y: configuration.isPressed ? 0.98 : 1)
            .customAnimation(.easeInOut)
    }
}
