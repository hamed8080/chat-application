//
//  GalleyOffsetViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import SwiftUI

public class GalleyOffsetViewModel: ObservableObject {
    @Published public var endScale: CGFloat = 1.0
    @Published public var isDragging = false
    @Published public var dragOffset: CGSize = .zero
    @Published public var previousDragOffset: CGSize = .zero
    public weak var appOverlayVM: AppOverlayViewModel?

    public func onDragChanged(_ value: DragGesture.Value) {
        isDragging = true
        if endScale > 1 {
            scrollInZoomMode(value)
        }
    }

    public func onDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        previousDragOffset = dragOffset

        if value.translation.height < 100, endScale <= 1 {
            dragOffset = .zero
        } else if value.translation.height > 100, endScale == 1 {
            dismiss()
        }
    }

    public func onDoubleTapped() {
        withAnimation(.easeOut) {
            if endScale == 1 {
                doubleZoom()
            } else {
                resetZoom()
            }
        }
    }

    public func onMagnificationEnded(_ value: GestureStateGesture<MagnificationGesture, CGFloat>.Value) {
        if isDragging { return }
        if value > 1 {
            endScale = value
        } else {
            endScale = max(1, endScale - value)
        }
    }

    private func scrollInZoomMode(_ value: DragGesture.Value) {
        let width = value.translation.width + previousDragOffset.width
        let height = value.translation.height + previousDragOffset.height
        dragOffset = .init(width: width, height: height)
    }

    private func doubleZoom() {
        endScale = 2
    }

    private func resetZoom() {
        endScale = 1
        dragOffset = .zero
    }

    public func dismiss() {
        dragOffset.height = 1000
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.appOverlayVM?.isPresented = false
            self?.appOverlayVM?.clear()
            self?.resetZoom()
        }
    }
}
