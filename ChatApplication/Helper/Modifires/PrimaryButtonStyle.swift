//
//  PrimaryButtonStyle.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI
struct PrimaryButtonStyle:ButtonStyle{
    
    let bgColor: Color
    let cornerRadius:CGFloat
    let textColor:Color
    let minHeight:CGFloat
    
    init(bgColor:Color = Color(named: "text_color_blue"),textColor:Color = Color.white,minHeight:CGFloat = 56, cornerRadius:CGFloat = 8){
        self.bgColor      = bgColor
        self.cornerRadius = cornerRadius
        self.textColor    = textColor
        self.minHeight    = minHeight
    }
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader{ reader in
            configuration.label
                .frame(minWidth: reader.size.width, minHeight: minHeight, alignment: .center)
                .foregroundColor(configuration.isPressed ? textColor.opacity(0.90) : textColor)
                .background(configuration.isPressed ? bgColor.opacity(0.8) : bgColor)
                .cornerRadius(cornerRadius)
                .font(.subheadline.weight(.black))
                .shadow(radius: configuration.isPressed ? 0 : 6)
                .scaleEffect(x: configuration.isPressed ? 0.98 : 1, y: configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut, value: configuration.isPressed)
        }
        .frame(maxHeight: 56, alignment: .center)
    }
}
