//
//  File.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI

struct CustomContextMenuContainer: ViewModifier {
    @StateObject var viewModel: ContextMenuModel = .init()

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
                .opacity(viewModel.isPresented ? 0.7 : 1.0)
            if viewModel.isPresented {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .onTapGesture(perform: viewModel.onTapBackground)
                        .transition(.opacity)
                        .background(containerSafeAreaReader)

                    if let mainView = viewModel.mainView {
                        mainView
                            .scaleEffect(x: viewModel.scale, y: viewModel.scale, anchor: .center)
                            .position(x: viewModel.x, y: viewModel.y) /// cenetr of the view
                            .onAppear(perform: viewModel.animateOnAppear)
                            .transition(.asymmetric(insertion: .identity, removal: .opacity))
                    }

                    menusAndTopViewStack
                        .position(x: viewModel.stackX, y: viewModel.stackY)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
        }
        .environmentObject(viewModel)
    }

    var containerSafeAreaReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                viewModel.containerSize = reader.size
                viewModel.safeAreaInsets = reader.safeAreaInsets
                print("container size width: \(viewModel.containerSize.width) height: \(viewModel.containerSize.height)")
                print("container safeAreaInsets:\(viewModel.safeAreaInsets)")
            }
        }
    }    

    @ViewBuilder
    var menusAndTopViewStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            viewModel.topView
            viewModel.menus
        }
        .frame(maxWidth: 256)
        .background(stackSizeReader)
    }

    var stackSizeReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                viewModel.stackSize = reader.size
            }
        }
    }
}

public extension View {
    func contextMenuContainer() -> some View {
        modifier(CustomContextMenuContainer())
    }
}
