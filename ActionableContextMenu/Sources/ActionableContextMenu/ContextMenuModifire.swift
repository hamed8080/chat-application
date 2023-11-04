//
//  File.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI

struct ContextMenuModifire<V: View, T: View>: ViewModifier {
    @EnvironmentObject var viewModel: ContextMenuModel
    @State var scale: CGFloat = 1.0
    @GestureState var isTouched: Bool = false
    @GestureState var isTouchedLocalPosition: Bool = false
    let menus: () -> V
    let topView: () -> T
    let root: any View
    let width: CGFloat
    @State var globalFrame: CGRect = .zero

    init(root: any View, width: CGFloat, @ViewBuilder menus: @escaping () -> V, @ViewBuilder topView: @escaping () -> T) {
        self.root = root
        self.width = width
        self.menus = menus
        self.topView = topView
    }

    func body(content: Content) -> some View {
        content
            .background(frameRedaer)
            .scaleEffect(x: scale, y: scale, anchor: .center)
            .gesture(tapgesture)
            .gesture(longGesture.simultaneously(with: postionGesture).simultaneously(with: localPostionGesture))
            .onChange(of: viewModel.isPresented) { newValue in
                withAnimation {
                    if viewModel.isPresented == false {
                        scale = 1.0
                    }
                }
            }
    }

    var tapgesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                print("on tapped")
            }
    }


    var longGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2, maximumDistance: 0)
            .onEnded { finished in
                withAnimation(.easeInOut(duration: 0.39)) {
                    scale = 0.9
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut) {
                        viewModel.menus = AnyView(menus().environmentObject(viewModel))
                        scale = 1.2
                        viewModel.itemWidth = width
                        viewModel.globalFrame = globalFrame
                        viewModel.topView = AnyView(topView())
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
                print("global touched value location x: \(value.location.x) y: \(value.location.y)")
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
                    print("local touched value location x: \(value.location.x) y:\(value.location.y)")
                }
            }
    }

    func isPastTheMargin(first: CGFloat, newValue: CGFloat) -> Bool {
        let padding: CGFloat = 12
        return newValue > first + padding || newValue < first - padding
    }

    var frameRedaer: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                globalFrame = reader.frame(in: .global)
                print("globalFrame width: \(globalFrame.width) height: \(globalFrame.height)  originX: \(globalFrame.origin.x) originY: \(globalFrame.origin.y)")
            }
        }
    }
}

public extension View {
    func customContextMenu<V: View, T: View>(self: any View,
                                             width: CGFloat,
                                             @ViewBuilder menus: @escaping () -> V,
                                             @ViewBuilder topView: @escaping () -> T
    ) -> some View {
        modifier(ContextMenuModifire(root: self, width: width, menus: menus, topView: topView))
    }
}
