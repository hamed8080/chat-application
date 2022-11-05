//
//  LazyView.swift
//  ChatApplication
//
//  Created by hamed on 10/21/22.
//

import SwiftUI
public struct LazyView<Content: View>: View {
    private let build: () -> Content
    public init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    public var body: Content {
        build()
    }
}
