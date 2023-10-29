//
//  File.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI

public struct ContextMenuButton: View {
    private let title: String
    private let image: String
    private let showSeparator: Bool
    private let action: (() -> Void)?
    @State private var scale: CGFloat = 0.0001
    @EnvironmentObject var viewModel: ContextMenuModel
    @Environment(\.colorScheme) var scheme

    public init(title: String, image: String, showSeparator: Bool = true, action: ( () -> Void)?) {
        self.title = title
        self.image = image
        self.showSeparator = showSeparator
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
            viewModel.isPresented = false
        } label: {
            HStack {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(scheme == .dark ? Color(red: 0.6, green: 0.62, blue: 0.68) : Color(red: 0.36, green: 0.4, blue: 0.47))
                Text(String(localized: .init(title)))
                    .padding(.leading, 12)
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .scaleEffect(x: scale, y: scale, anchor: .center)
        }
        .environment(\.layoutDirection, isRTLLanguage ? .rightToLeft : .leftToRight)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onAppear {
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 0.3, damping: 0.5, initialVelocity: 0).speed(30)) {
                scale = 1.0
            }
        }
    }

    private var isRTLLanguage: Bool {
        let rtlIdentifiers = ["fa", "ar"]
        let identifier = Locale.current.identifier
        return rtlIdentifiers.first(where: {identifier.contains($0)}) != nil
    }
}
