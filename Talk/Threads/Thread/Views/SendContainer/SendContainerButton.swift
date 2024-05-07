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
    @GestureState private var isTouching = false

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
        HStack(spacing: 4) {
            if let image {
                Image(systemName: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(imageColor)
                    .fontWeight(fontWeight)
                    .frame(width: 18, height: 18)
            }
            if let text {
                Text(text)
                    .foregroundStyle(textColor)
            }
        }
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
        .gesture(tapGesture.simultaneously(with: touchDownGesture))
        .opacity(isTouching ? 0.5 : 1.0)
        .background(Color.clear)
        .foregroundColor(Color.App.toolbarButton)
        .clipped()
        .fontWeight(.medium)
    }

    private var touchDownGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { value, state, transaction in
                transaction.animation = .easeInOut
                state = true
            }
    }

    private var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                action?()
            }
    }
}


struct SendContainerButton_Previews: PreviewProvider {
    static var previews: some View {
        SendContainerButton()
    }
}
