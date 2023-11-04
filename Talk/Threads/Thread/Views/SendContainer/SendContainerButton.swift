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
    let textColor: Color
    let text: String?
    let action: (() -> Void)?

    init(image: String? = nil,
         text: String? = nil,
         imageColor: Color = Color.App.primary,
         textColor: Color = Color.App.hint,
         action: (() -> Void)? = nil
    ) {
        self.image = image
        self.text = text
        self.action = action
        self.textColor = textColor
        self.imageColor = imageColor
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
                    .frame(width: 14, height: 14)
            }
            if let text {
                Text(text)
                    .foregroundStyle(textColor)
            }
        }
        .frame(width: 36, height: 36)
        .buttonStyle(.borderless)
        .fontWeight(.light)
    }
}


struct SendContainerButton_Previews: PreviewProvider {
    static var previews: some View {
        SendContainerButton()
    }
}
