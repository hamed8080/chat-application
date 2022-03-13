//
//  AnimatingCellHeight.swift
//  ChatApplication
//
//  Created by hamed on 2/19/22.
//

import SwiftUI

struct AnimatingCellHeight: AnimatableModifier {
    var height: CGFloat = 0

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content.frame(height: height)
    }
}
