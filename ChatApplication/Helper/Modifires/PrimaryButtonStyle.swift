//
//  PrimaryButtonStyle.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI
struct PrimaryButtonStyle:ButtonStyle{
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader{ reader in
            configuration.label
                .frame(minWidth: reader.size.width, minHeight: 56, alignment: .center)
                .foregroundColor(configuration.isPressed ? Color.white.opacity(0.90) : Color.white)
                .background(configuration.isPressed ? Color(named: "text_color_blue").opacity(0.8) : Color(named: "text_color_blue"))
                .cornerRadius(8)
                .font(.subheadline.weight(.black))
                .shadow(radius: configuration.isPressed ? 0 : 6)
                .scaleEffect(x: configuration.isPressed ? 0.98 : 1, y: configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut)
        }
        .frame(maxHeight: 56, alignment: .center)
    }
}
