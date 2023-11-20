//
//  CustomContextMenuContainer.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI
import OSLog

struct CustomContextMenuContainer: ViewModifier {
    private let logger = Logger(subsystem: "ActionableContextMenu", category: "CustomContextMenuContainer")
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
                        .onTapGesture(perform: viewModel.hide)
                        .transition(.opacity)
                        .background(containerSafeAreaReader)

                    if let mainView = viewModel.mainView {
                        mainView
                            .scaleEffect(x: viewModel.scale, y: viewModel.scale, anchor: .center)
                            .position(x: viewModel.x, y: viewModel.y) /// center of the view
                            .onAppear(perform: viewModel.animateOnAppear)
                            .transition(.asymmetric(insertion: .identity, removal: .opacity))
                    }

                    viewModel.menus
                    .background(stackSizeReader)
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
                #if DEBUG
                logger.info("container size width: \(viewModel.containerSize.width) height: \(viewModel.containerSize.height)")
                logger.info("container safeAreaInsets Top:\(viewModel.safeAreaInsets.top)")
                logger.info("container safeAreaInsets Bottom:\(viewModel.safeAreaInsets.bottom)")
                #endif
            }
        }
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
