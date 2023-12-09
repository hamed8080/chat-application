//
//  ContextMenuModifire.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI
import OSLog

struct ContextMenuModifire<V: View>: ViewModifier {
    private let logger = Logger(subsystem: "ActionableContextMenu", category: "ContextMenuModifire")
    @EnvironmentObject var viewModel: ContextMenuModel
    @State var scale: CGFloat = 1.0
    @GestureState var isTouched: Bool = false
    @GestureState var isTouchedLocalPosition: Bool = false
    let menus: () -> V
    let root: any View
    var id: Int?
    @State var itemWidth: CGFloat = 0
    @State var globalFrame: CGRect = .zero

    init(id: Int?, root: any View, @ViewBuilder menus: @escaping () -> V) {
        self.id = id
        self.root = root
        self.menus = menus
    }

    func body(content: Content) -> some View {
        content
            .background(frameReader)
            .scaleEffect(x: scale, y: scale, anchor: .center)
            .gesture(tapgesture)
            .gesture(longGesture.simultaneously(with: postionGesture).simultaneously(with: localPostionGesture))
            .onChange(of: viewModel.isPresented) { newValue in
                var transaction = Transaction()
                transaction.animation = .easeInOut(duration: 0.2)
                withTransaction(transaction) {
                    if viewModel.isPresented == false {
                        scale = 1.0
                    }
                }
            }
    }

    var tapgesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                log("on tapped")
            }
    }

    var longGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5, maximumDistance: 0)
            .onEnded { finished in
                withAnimation(.easeInOut(duration: 0.1)) {
                    scale = 0.9
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut) {
                        viewModel.menus = AnyView(menus().environmentObject(viewModel))
                        scale = 1.2
                        viewModel.presentedId = id
                        viewModel.globalFrame = globalFrame
                        viewModel.mainView = AnyView(root)
                        viewModel.isPresented.toggle()
                    }
                }
            }
    }

    var postionGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isTouched) { value, state, transaction in
                state = true
            }
            .onChanged { value in
                viewModel.globalPosition = value.location
                log("global touched value location x: \(value.location.x) y: \(value.location.y)")
            }
    }

    var localPostionGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isTouchedLocalPosition) { value, state, transaction in
                state = true
            }
            .onChanged { value in
                /// We check this to prevent rapidally update the UI.
                let beofreX = viewModel.localPosition?.x ?? 0
                let beofreY = viewModel.localPosition?.y ?? 0
                if isPastTheMargin(first: beofreX, newValue: value.location.x) || isPastTheMargin(first: beofreY, newValue: value.location.y) {
                    viewModel.localPosition = value.location
                    log("local touched value location x: \(value.location.x) y:\(value.location.y)")
                }
            }
    }

    func isPastTheMargin(first: CGFloat, newValue: CGFloat) -> Bool {
        let padding: CGFloat = 12
        return newValue > first + padding || newValue < first - padding
    }

    var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                DispatchQueue.main.async {
                    /// We must check the presented is equal to the id of the initialized modifier, unless the viewModel.item Width will be set to another wrong view width.
                    if viewModel.isPresented, viewModel.presentedId == id {
                        viewModel.itemWidth = reader.frame(in: .local).width
                    }
                    globalFrame = reader.frame(in: .global)
                    log("globalFrame width: \(globalFrame.width) height: \(globalFrame.height)  originX: \(globalFrame.origin.x) originY: \(globalFrame.origin.y)")
                }
            }
        }
    }

    private func log(_ string: String) {
#if DEBUG
        logger.info("\(string)")
#endif
    }
}

public extension View {
    func customContextMenu<V: View>(id: Int?, self: any View, @ViewBuilder menus: @escaping () -> V) -> some View {
        modifier(ContextMenuModifire(id: id, root: self, menus: menus))
    }
}
