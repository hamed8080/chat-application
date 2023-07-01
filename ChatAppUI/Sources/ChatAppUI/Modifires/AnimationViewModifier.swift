//
//  AnimationViewModifier.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/30/21.
//

import SwiftUI

public struct AnimationViewModifier<T>: ViewModifier where T: Equatable {

    let value: T
    public init(value: T) {
        self.value = value
    }

    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.animation(.spring(.smooth), value: value)
        } else {
            content.animation(.easeInOut, value: value)
        }
    }
}

public extension View {
    func springAnimation<T: Equatable>(value: T) -> some View {
        self.modifier(AnimationViewModifier(value: value))
    }
}
