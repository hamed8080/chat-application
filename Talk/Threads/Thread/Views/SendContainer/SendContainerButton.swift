//
//  SendContainerButton.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkUI

struct SendContainerButton: View {
    let image: String?
    let imageColor: Color
    let fontWeight: Font.Weight
    let textColor: Color
    let text: String?
    let action: (() -> Void)?

    init(image: String? = nil,
         text: String? = nil,
         imageColor: Color = Color.App.accent,
         fontWeight: Font.Weight = .medium,
         textColor: Color = Color.App.textSecondary,
         action: (() -> Void)? = nil
    ) {
        self.image = image
        self.text = text
        self.action = action
        self.textColor = textColor
        self.imageColor = imageColor
        self.fontWeight = fontWeight
    }

    var body: some View {
        Button {
            withAnimation {
                action?()
            }
        } label: {
            if let image {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(imageColor)
                    .fontWeight(fontWeight)
                    .frame(width: 12, height: 12)
            }
            if let text {
                Text(text)
                    .foregroundStyle(textColor)
            }
        }
        .frame(width: 36, height: 36)
        .buttonStyle(.borderless)
        .fontWeight(.medium)
    }
}


struct SendContainerButton_Previews: PreviewProvider {
    static var previews: some View {
        SendContainerButton()
    }
}
