//
//  BorderedTextFieldStyle.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI

struct BorderedTextFieldStyle: TextFieldStyle {
    let minHeight: CGFloat
    let cornerRadius: CGFloat

    init(minHeight: CGFloat = 36, cornerRadius: CGFloat = 5) {
        self.minHeight = minHeight
        self.cornerRadius = cornerRadius
    }

    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .frame(minHeight: minHeight)
            .padding(8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
    }
}

struct BorderedTextFieldStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextField("type contact", text: Binding(get: { "" }, set: { _ in }))
                .textFieldStyle(BorderedTextFieldStyle())
        }
    }
}

extension TextFieldStyle where Self == BorderedTextFieldStyle {
    /// A custom bordered text filed style.
    static func customBorderedWith(minHeight: CGFloat = 36, cornerRadius: CGFloat = 5) -> BorderedTextFieldStyle { BorderedTextFieldStyle(minHeight: minHeight, cornerRadius: cornerRadius) }
    static var customBordered: BorderedTextFieldStyle { BorderedTextFieldStyle() }
}
