//
//  File.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI

public final class ContextMenuModel: ObservableObject {
    @Published public var isPresented: Bool = false {
        didSet {
            if !isPresented {
                reset()
            }
        }
    }
    @Published var globalPosition: CGPoint?
    @Published var localPosition: CGPoint?
    @Published var globalFrame: CGRect?
    var mainView: AnyView?
    var topView: AnyView?
    var menus: AnyView?
    var itemWidth: CGFloat = 0.0
    var containerSize: CGSize = .zero
    @Published var menusAndTopViewSize: CGSize = .zero
    @Published var scale = 1.0
    @Published var safeAreaInsets: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    var stackSize: CGSize = .zero

    public init() {}

    var itemSize: CGSize {
        globalFrame?.size ?? .zero
    }

    var isInTopPartOfTheContainer: Bool {
        return (y + itemSize.height / 2) < (containerSize.height / 2)
    }

    var stackX: CGFloat {
        return x
    }

    var stackY: CGFloat {
        let stackPadding: CGFloat = topView != nil ? 8 : 0
        var stackY: CGFloat = 0.0
        let stackHeight = stackSize.height
        let itemHalf = itemSize.height / 2
        if isInTopPartOfTheContainer {
            stackY = (y + itemHalf) + stackPadding + stackHeight - (stackHeight / 2) + stackPadding
        } else {
            stackY = (y - itemHalf) - stackPadding - stackHeight + (stackHeight / 2) - stackPadding
        }
        print("stakcY: \(stackHeight)")
        return stackY
    }

    var computedAlignment: Alignment {
        y > containerSize.height / 2 ? .topLeading : .bottomLeading
    }

    var x: CGFloat {
        let originalX: CGFloat = (itemWidth / 2) + ((globalPosition?.x ?? 0) - (localPosition?.x ?? 0))
        let x = originalX
        print("calculated x: \(x)")
        return x
    }

    var y: CGFloat {
        let topSafeArea = safeAreaInsets.top
        let locaTouchedY = localPosition?.y ?? 0
        let touchedPositionY = globalPosition?.y ?? 0
        let topfTheItem = touchedPositionY - locaTouchedY
        let m: CGFloat = topfTheItem + (itemSize.height / 2)
        let centerY = abs(m - topSafeArea)
        print("calculated y: \(centerY)")
        return centerY
    }

    func onTapBackground() {
        withAnimation {
            scale = 1.0
            isPresented.toggle()
        }
    }

    func animateOnAppear() {
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 0.3, damping: 0.5, initialVelocity: 0).speed(20)) {
            scale = 1.1
        }
    }

    func reset() {
        globalPosition = nil
        localPosition = nil
        globalFrame = nil
        mainView = nil
        topView = nil
        menus = nil
    }
}
