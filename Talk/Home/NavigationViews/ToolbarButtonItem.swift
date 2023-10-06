//
//  ToolbarButtonItem.swift
//  Talk
//
//  Created by hamed on 10/1/23.
//

import Foundation
import SwiftUI

public struct ToolbarButtonItem: View {
    let imageName: String
    let hint: String
    let action: (() -> Void)?
    static let buttonWidth: CGFloat = 38

    init(imageName: String, hint: String = "", action: (() -> Void)? = nil) {
        self.imageName = imageName
        self.hint = hint
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
                .accessibilityHint(hint)
                .fontWeight(.light)
        }
        .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
    }
}
